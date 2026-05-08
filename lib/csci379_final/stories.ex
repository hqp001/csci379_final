defmodule Csci379Final.Stories do
  require Logger
  import Ecto.Query
  alias Csci379Final.Repo
  alias Csci379Final.Stories.{Story, Chapter, Scene, Quest}
  alias Csci379Final.AI

  @progress_steps [
    "Analyzing your topic...",
    "Outlining chapters and scenes...",
    "Writing quest questions...",
    "Saving your story..."
  ]

  def list_stories(%{user: user}) do
    Repo.all(from s in Story, where: s.user_id == ^user.id, order_by: [desc: s.inserted_at])
  end

  def get_story!(id, %{user: user}) do
    Repo.get_by!(Story, id: id, user_id: user.id)
  end

  def get_story_with_tree!(id, %{user: user}) do
    Repo.get_by!(Story, id: id, user_id: user.id)
    |> Repo.preload(chapters: [scenes: :quests])
  end

  def create_story_async(topic, scope) do
    %Story{}
    |> Story.changeset(%{
      title: topic,
      topic: topic,
      status: :generating,
      user_id: scope.user.id
    })
    |> Repo.insert()
  end

  def start_generation(story_id, topic) do
    parent = self()

    Task.Supervisor.start_child(Csci379Final.TaskSupervisor, fn ->
      maybe_allow_sandbox(parent)
      run_generation(story_id, topic)
    end)
  end

  def delete_story(%Story{} = story, %{user: user}) when story.user_id == user.id do
    Repo.delete(story)
  end

  defp run_generation(story_id, topic) do
    broadcast(story_id, {:progress, Enum.at(@progress_steps, 0)})

    case AI.generate_story(topic) do
      {:ok, data} ->
        broadcast(story_id, {:progress, Enum.at(@progress_steps, 1)})
        insert_tree(story_id, data)
        broadcast(story_id, {:progress, Enum.at(@progress_steps, 2)})
        broadcast(story_id, {:progress, Enum.at(@progress_steps, 3)})
        Repo.update_all(from(s in Story, where: s.id == ^story_id),
          set: [status: :ready, title: data["title"]]
        )
        broadcast(story_id, {:story_ready, story_id})

      {:error, reason} ->
        Logger.error("Story generation failed for story #{story_id}: #{inspect(reason)}")
        mark_failed(story_id)
    end
  rescue
    e ->
      Logger.error("Story generation crashed for story #{story_id}: #{Exception.format(:error, e, __STACKTRACE__)}")
      mark_failed(story_id)
  end

  defp insert_tree(story_id, data) do
    data["chapters"]
    |> Enum.with_index(1)
    |> Enum.each(fn {ch, ch_pos} ->
      {:ok, chapter} =
        %Chapter{}
        |> Chapter.changeset(%{
          title: ch["title"],
          description: ch["description"],
          position: ch_pos,
          story_id: story_id
        })
        |> Repo.insert()

      ch["scenes"]
      |> Enum.with_index(1)
      |> Enum.each(fn {sc, sc_pos} ->
        {:ok, scene} =
          %Scene{}
          |> Scene.changeset(%{
            title: sc["title"],
            description: sc["description"],
            position: sc_pos,
            is_locked: sc_pos > 1 or ch_pos > 1,
            chapter_id: chapter.id
          })
          |> Repo.insert()

        sc["quests"]
        |> Enum.with_index(1)
        |> Enum.each(fn {q, q_pos} ->
          options =
            case q["options"] do
              nil -> []
              map when is_map(map) ->
                map
                |> Enum.map(fn {k, v} -> %{"key" => k, "text" => v} end)
                |> Enum.sort_by(& &1["key"])
              list when is_list(list) -> list
            end

          %Quest{}
          |> Quest.changeset(%{
            type: String.to_existing_atom(q["type"]),
            question: q["question"],
            options: options,
            correct_answer: q["correct_answer"],
            explanation: q["explanation"],
            position: q_pos,
            scene_id: scene.id
          })
          |> Repo.insert!()
        end)
      end)
    end)
  end

  defp mark_failed(story_id) do
    Repo.update_all(from(s in Story, where: s.id == ^story_id), set: [status: :failed])
    broadcast(story_id, {:story_failed, "Something went wrong generating your story."})
  end

  defp broadcast(story_id, message) do
    Phoenix.PubSub.broadcast(Csci379Final.PubSub, "story:#{story_id}", message)
  end

  defp maybe_allow_sandbox(parent) do
    pool = Application.get_env(:csci379_final, Csci379Final.Repo, [])[:pool]

    if pool == Ecto.Adapters.SQL.Sandbox do
      Ecto.Adapters.SQL.Sandbox.allow(Csci379Final.Repo, parent, self())
    end
  end
end
