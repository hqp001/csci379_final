defmodule Csci379Final.LearningTest do
  use Csci379Final.DataCase, async: true

  import Csci379Final.AccountsFixtures
  import Csci379Final.StoriesFixtures

  alias Csci379Final.Learning

  setup do
    scope = user_scope_fixture()
    {story, _chapter, scene, quest} = story_tree_fixture(scope)
    %{scope: scope, story: story, scene: scene, quest: quest}
  end

  describe "get_scene_with_quests!/2" do
    test "returns scene with quests preloaded", %{scene: scene, story: story, quest: quest} do
      loaded = Learning.get_scene_with_quests!(scene.id, story.id)
      assert loaded.id == scene.id
      assert [q] = loaded.quests
      assert q.id == quest.id
    end

    test "raises for wrong story", %{scene: scene} do
      assert_raise Ecto.NoResultsError, fn ->
        Learning.get_scene_with_quests!(scene.id, 0)
      end
    end
  end

  describe "get_scene_completion/2" do
    test "returns nil when no completion exists", %{scope: scope, scene: scene} do
      assert Learning.get_scene_completion(scope.user.id, scene.id) == nil
    end

    test "returns completion after completing scene", %{scope: scope, scene: scene} do
      Learning.complete_scene(scope, scene.id, 2, 3)
      assert completion = Learning.get_scene_completion(scope.user.id, scene.id)
      assert completion.scene_id == scene.id
    end
  end

  describe "record_attempt/5" do
    test "records a quest attempt", %{scope: scope, quest: quest} do
      Learning.record_attempt(scope, quest.id, "a", true, "Correct!")
      stats = Learning.get_user_stats(scope.user.id)
      assert stats.total_attempts == 1
      assert stats.correct_attempts == 1
    end

    test "records an incorrect attempt", %{scope: scope, quest: quest} do
      Learning.record_attempt(scope, quest.id, "b", false, "Wrong.")
      stats = Learning.get_user_stats(scope.user.id)
      assert stats.total_attempts == 1
      assert stats.correct_attempts == 0
    end
  end

  describe "complete_scene/4" do
    test "awards XP and returns it", %{scope: scope, scene: scene} do
      assert {:ok, xp} = Learning.complete_scene(scope, scene.id, 3, 3)
      assert xp > 0
    end

    test "returns existing XP if already completed", %{scope: scope, scene: scene} do
      {:ok, xp1} = Learning.complete_scene(scope, scene.id, 3, 3)
      {:ok, xp2} = Learning.complete_scene(scope, scene.id, 3, 3)
      assert xp1 == xp2
    end

    test "unlocks next scene in chapter after completion", %{scope: scope} do
      other_scope = user_scope_fixture()
      story = story_fixture(other_scope)
      chapter = chapter_fixture(story)
      scene1 = scene_fixture(chapter, %{position: 1, is_locked: false})
      scene2 = scene_fixture(chapter, %{position: 2, is_locked: true})

      Learning.complete_scene(other_scope, scene1.id, 1, 1)

      updated = Csci379Final.Repo.get!(Csci379Final.Stories.Scene, scene2.id)
      assert updated.is_locked == false
    end

    test "unlocks first scene of next chapter when current chapter is done", %{scope: scope} do
      other_scope = user_scope_fixture()
      story = story_fixture(other_scope)
      ch1 = chapter_fixture(story, %{position: 1})
      ch2 = chapter_fixture(story, %{position: 2})
      last_scene_ch1 = scene_fixture(ch1, %{position: 1, is_locked: false})
      first_scene_ch2 = scene_fixture(ch2, %{position: 1, is_locked: true})

      Learning.complete_scene(other_scope, last_scene_ch1.id, 1, 1)

      updated = Csci379Final.Repo.get!(Csci379Final.Stories.Scene, first_scene_ch2.id)
      assert updated.is_locked == false
    end

    test "handles completion when no next scene and no next chapter", %{scope: scope} do
      other_scope = user_scope_fixture()
      story = story_fixture(other_scope)
      chapter = chapter_fixture(story, %{position: 1})
      only_scene = scene_fixture(chapter, %{position: 1, is_locked: false})

      assert {:ok, xp} = Learning.complete_scene(other_scope, only_scene.id, 1, 1)
      assert xp > 0
    end

    test "handles completion when next chapter has no first scene", %{scope: scope} do
      other_scope = user_scope_fixture()
      story = story_fixture(other_scope)
      ch1 = chapter_fixture(story, %{position: 1})
      _ch2 = chapter_fixture(story, %{position: 2})
      only_scene_ch1 = scene_fixture(ch1, %{position: 1, is_locked: false})

      assert {:ok, xp} = Learning.complete_scene(other_scope, only_scene_ch1.id, 1, 1)
      assert xp > 0
    end
  end

  describe "get_user_stats/1" do
    test "returns zeros for new user", %{scope: scope} do
      stats = Learning.get_user_stats(scope.user.id)
      assert stats.total_xp == 0
      assert stats.scenes_completed == 0
      assert stats.total_attempts == 0
      assert stats.correct_attempts == 0
    end

    test "aggregates correctly after activity", %{scope: scope, scene: scene, quest: quest} do
      Learning.record_attempt(scope, quest.id, "a", true, "Good!")
      Learning.complete_scene(scope, scene.id, 1, 1)
      stats = Learning.get_user_stats(scope.user.id)
      assert stats.total_xp > 0
      assert stats.scenes_completed == 1
      assert stats.total_attempts == 1
    end
  end

  describe "list_recent_completions/1" do
    test "returns empty list for new user", %{scope: scope} do
      assert Learning.list_recent_completions(scope.user.id) == []
    end

    test "returns completions with scene preloaded", %{scope: scope, scene: scene} do
      Learning.complete_scene(scope, scene.id, 2, 3)
      [completion] = Learning.list_recent_completions(scope.user.id)
      assert completion.scene.id == scene.id
    end
  end

  describe "list_xp_history/1" do
    test "returns empty list for new user", %{scope: scope} do
      assert Learning.list_xp_history(scope.user.id) == []
    end

    test "returns XP grouped by story", %{scope: scope, scene: scene} do
      Learning.complete_scene(scope, scene.id, 2, 3)
      history = Learning.list_xp_history(scope.user.id)
      assert length(history) == 1
      assert [%{label: _, xp: xp}] = history
      assert xp > 0
    end
  end

  describe "list_completed_stories/1" do
    test "returns empty list for new user", %{scope: scope} do
      assert Learning.list_completed_stories(scope.user.id) == []
    end

    test "returns stories with at least one scene completion", %{scope: scope, scene: scene, story: story} do
      Learning.complete_scene(scope, scene.id, 1, 1)
      stories = Learning.list_completed_stories(scope.user.id)
      assert length(stories) == 1
      assert hd(stories).id == story.id
    end
  end

  describe "list_xp_by_story/2" do
    test "returns empty list when no completions for story", %{scope: scope, story: story} do
      assert Learning.list_xp_by_story(scope.user.id, story.id) == []
    end

    test "returns per-scene XP for a story", %{scope: scope, scene: scene, story: story} do
      Learning.complete_scene(scope, scene.id, 2, 3)
      history = Learning.list_xp_by_story(scope.user.id, story.id)
      assert length(history) == 1
      assert [%{label: _, xp: xp}] = history
      assert xp > 0
    end
  end

  describe "list_story_progress/1" do
    test "returns empty list when user has no stories" do
      empty_scope = user_scope_fixture()
      assert Learning.list_story_progress(empty_scope.user.id) == []
    end

    test "returns progress for each ready story", %{scope: scope, story: story, scene: scene} do
      progress = Learning.list_story_progress(scope.user.id)
      assert length(progress) == 1
      [entry] = progress
      assert entry.id == story.id
      assert entry.total_scenes > 0
      assert entry.completed_scenes == 0

      Learning.complete_scene(scope, scene.id, 1, 1)
      [updated] = Learning.list_story_progress(scope.user.id)
      assert updated.completed_scenes == 1
    end
  end
end
