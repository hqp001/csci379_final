defmodule Csci379Final.StoriesTest do
  use Csci379Final.DataCase, async: true

  import Csci379Final.AccountsFixtures
  import Csci379Final.StoriesFixtures

  alias Csci379Final.Stories
  alias Csci379Final.Stories.{Story, Quest}

  setup do
    scope = user_scope_fixture()
    %{scope: scope}
  end

  describe "list_stories/1" do
    test "returns all stories for the user", %{scope: scope} do
      story = story_fixture(scope)
      assert Stories.list_stories(scope) == [story]
    end

    test "does not return other users' stories", %{scope: scope} do
      other_scope = user_scope_fixture()
      story_fixture(other_scope)
      assert Stories.list_stories(scope) == []
    end
  end

  describe "get_story!/2" do
    test "returns story for owner", %{scope: scope} do
      story = story_fixture(scope)
      assert Stories.get_story!(story.id, scope).id == story.id
    end

    test "raises for wrong user", %{scope: scope} do
      story = story_fixture(scope)
      other_scope = user_scope_fixture()
      assert_raise Ecto.NoResultsError, fn -> Stories.get_story!(story.id, other_scope) end
    end
  end

  describe "get_story_with_tree!/2" do
    test "preloads chapters, scenes, and quests", %{scope: scope} do
      {story, _chapter, _scene, _quest} = story_tree_fixture(scope)
      loaded = Stories.get_story_with_tree!(story.id, scope)
      assert [chapter] = loaded.chapters
      assert [scene] = chapter.scenes
      assert [_quest] = scene.quests
    end
  end

  describe "create_story_async/2" do
    test "inserts a story with generating status", %{scope: scope} do
      assert {:ok, story} = Stories.create_story_async("quantum physics", scope)
      assert story.status == :generating
      assert story.topic == "quantum physics"
      assert story.user_id == scope.user.id
    end
  end

  describe "delete_story/2" do
    test "deletes own story", %{scope: scope} do
      story = story_fixture(scope)
      assert {:ok, _} = Stories.delete_story(story, scope)
      assert Stories.list_stories(scope) == []
    end

    test "refuses to delete another user's story", %{scope: scope} do
      other_scope = user_scope_fixture()
      story = story_fixture(other_scope)
      assert_raise FunctionClauseError, fn -> Stories.delete_story(story, scope) end
    end
  end

  describe "Quest embedded schema" do
    test "changeset casts options as embedded structs", %{scope: scope} do
      {_story, _chapter, scene, _} = story_tree_fixture(scope)

      {:ok, quest} =
        %Quest{}
        |> Quest.changeset(%{
          type: :multiple_choice,
          question: "Who?",
          options: [%{"key" => "a", "text" => "Alice"}, %{"key" => "b", "text" => "Bob"}],
          correct_answer: "a",
          position: 2,
          scene_id: scene.id
        })
        |> Csci379Final.Repo.insert()

      assert [%{key: "a", text: "Alice"}, %{key: "b", text: "Bob"}] = quest.options
    end

    test "fill_blank quest has empty options list", %{scope: scope} do
      {_story, _chapter, scene, _} = story_tree_fixture(scope)

      {:ok, quest} =
        %Quest{}
        |> Quest.changeset(%{
          type: :fill_blank,
          question: "Fill: ___",
          options: [],
          correct_answer: "answer",
          position: 3,
          scene_id: scene.id
        })
        |> Csci379Final.Repo.insert()

      assert quest.options == []
    end
  end
end
