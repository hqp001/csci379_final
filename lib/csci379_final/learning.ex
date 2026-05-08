defmodule Csci379Final.Learning do
  import Ecto.Query
  alias Csci379Final.Repo
  alias Csci379Final.Learning.{QuestAttempt, SceneCompletion}
  alias Csci379Final.Stories.{Chapter, Scene, Quest}

  @xp_per_correct 10
  @xp_scene_bonus 50

  def get_scene_with_quests!(scene_id, story_id) do
    Repo.one!(
      from s in Scene,
        join: c in assoc(s, :chapter),
        where: s.id == ^scene_id and c.story_id == ^story_id,
        preload: [quests: ^from(q in Quest, order_by: q.position)]
    )
  end

  def get_scene_completion(user_id, scene_id) do
    Repo.one(
      from sc in SceneCompletion,
        where: sc.user_id == ^user_id and sc.scene_id == ^scene_id
    )
  end

  def record_attempt(scope, quest_id, user_answer, is_correct, ai_feedback) do
    %QuestAttempt{}
    |> QuestAttempt.changeset(%{
      user_id: scope.user.id,
      quest_id: quest_id,
      user_answer: user_answer,
      is_correct: is_correct,
      ai_feedback: ai_feedback
    })
    |> Repo.insert!()
  end

  def complete_scene(scope, scene_id, correct_count, _total_count) do
    xp = correct_count * @xp_per_correct + @xp_scene_bonus
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case %SceneCompletion{}
         |> SceneCompletion.changeset(%{
           user_id: scope.user.id,
           scene_id: scene_id,
           xp_earned: xp,
           completed_at: now
         })
         |> Repo.insert() do
      {:ok, _} ->
        unlock_next_scene(scene_id)
        {:ok, xp}

      {:error, _} ->
        existing = get_scene_completion(scope.user.id, scene_id)
        {:ok, existing.xp_earned}
    end
  end

  def get_user_stats(user_id) do
    total_xp =
      Repo.one(
        from sc in SceneCompletion,
          where: sc.user_id == ^user_id,
          select: sum(sc.xp_earned)
      ) || 0

    scenes_completed =
      Repo.aggregate(from(sc in SceneCompletion, where: sc.user_id == ^user_id), :count)

    total_attempts =
      Repo.aggregate(from(qa in QuestAttempt, where: qa.user_id == ^user_id), :count)

    correct_attempts =
      Repo.aggregate(
        from(qa in QuestAttempt, where: qa.user_id == ^user_id and qa.is_correct == true),
        :count
      )

    %{
      total_xp: total_xp,
      scenes_completed: scenes_completed,
      total_attempts: total_attempts,
      correct_attempts: correct_attempts
    }
  end

  def list_recent_completions(user_id, limit \\ 5) do
    Repo.all(
      from sc in SceneCompletion,
        where: sc.user_id == ^user_id,
        order_by: [desc: sc.completed_at],
        limit: ^limit,
        preload: :scene
    )
  end

  def list_xp_history(user_id) do
    completions =
      Repo.all(
        from sc in SceneCompletion,
          where: sc.user_id == ^user_id,
          order_by: [asc: sc.completed_at],
          select: {sc.completed_at, sc.xp_earned}
      )

    completions
    |> Enum.scan({nil, 0}, fn {date, xp}, {_, cum} -> {date, cum + xp} end)
    |> Enum.map(fn {date, cum_xp} ->
      %{date: Calendar.strftime(date, "%b %d"), xp: cum_xp}
    end)
  end

  defp unlock_next_scene(scene_id) do
    scene = Repo.get!(Scene, scene_id)
    chapter = Repo.get!(Chapter, scene.chapter_id)

    next_scene =
      Repo.one(
        from s in Scene,
          where: s.chapter_id == ^scene.chapter_id and s.position == ^(scene.position + 1)
      )

    if next_scene do
      Repo.update_all(from(s in Scene, where: s.id == ^next_scene.id), set: [is_locked: false])
    else
      next_chapter =
        Repo.one(
          from c in Chapter,
            where: c.story_id == ^chapter.story_id and c.position == ^(chapter.position + 1)
        )

      if next_chapter do
        first_scene =
          Repo.one(from s in Scene, where: s.chapter_id == ^next_chapter.id and s.position == 1)

        if first_scene do
          Repo.update_all(from(s in Scene, where: s.id == ^first_scene.id), set: [is_locked: false])
        end
      end
    end
  end
end
