defmodule Csci379Final.ListOptionsAdapter do
  @behaviour Csci379Final.AI.GeneratorPort

  @impl true
  def generate_story(_params) do
    {:ok,
     %{
       "title" => "List Opts Story",
       "chapters" => [
         %{
           "title" => "Ch 1",
           "description" => "desc",
           "scenes" => [
             %{
               "title" => "Sc 1",
               "description" => "desc",
               "quests" => [
                 %{
                   "type" => "multiple_choice",
                   "question" => "Pick one?",
                   "options" => [%{"key" => "a", "text" => "Alpha"}, %{"key" => "b", "text" => "Beta"}],
                   "correct_answer" => "a",
                   "explanation" => "Alpha."
                 }
               ]
             }
           ]
         }
       ]
     }}
  end

  @impl true
  def grade_answer(_q, _a), do: {:ok, %{is_correct: true, feedback: "ok"}}
end

defmodule Csci379Final.FailAdapter do
  @behaviour Csci379Final.AI.GeneratorPort
  def generate_story(_params), do: {:error, "simulated failure"}
  def grade_answer(_q, _a), do: {:error, "simulated failure"}
end

defmodule Csci379Final.CrashAdapter do
  @behaviour Csci379Final.AI.GeneratorPort
  def generate_story(_params), do: raise("boom")
  def grade_answer(_q, _a), do: raise("boom")
end

defmodule Csci379Final.StoriesTest do
  use Csci379Final.DataCase, async: false

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

  describe "start_generation/2 - success path" do
    test "runs full generation and marks story ready", %{scope: scope} do
      {:ok, story} = Stories.create_story_async("The Roman Empire", scope)
      Phoenix.PubSub.subscribe(Csci379Final.PubSub, "story:#{story.id}")

      {:ok, _task} = Stories.start_generation(story.id, "The Roman Empire")

      story_id = story.id
      assert_receive {:story_ready, ^story_id}, 5000
      updated = Csci379Final.Repo.get!(Story, story.id)
      assert updated.status == :ready
    end
  end

  describe "start_generation/2 - failure path" do
    setup do
      Application.put_env(:csci379_final, :ai_adapter, Csci379Final.FailAdapter)
      on_exit(fn -> Application.put_env(:csci379_final, :ai_adapter, Csci379Final.AI.StubAdapter) end)
    end

    test "marks story failed when AI returns error", %{scope: scope} do
      {:ok, story} = Stories.create_story_async("anything", scope)
      Phoenix.PubSub.subscribe(Csci379Final.PubSub, "story:#{story.id}")

      {:ok, _task} = Stories.start_generation(story.id, "anything")

      assert_receive {:story_failed, _reason}, 5000
      updated = Csci379Final.Repo.get!(Story, story.id)
      assert updated.status == :failed
    end
  end

  describe "start_generation/2 - crash path" do
    setup do
      Application.put_env(:csci379_final, :ai_adapter, Csci379Final.CrashAdapter)
      on_exit(fn -> Application.put_env(:csci379_final, :ai_adapter, Csci379Final.AI.StubAdapter) end)
    end

    test "marks story failed when AI adapter crashes", %{scope: scope} do
      {:ok, story} = Stories.create_story_async("anything", scope)
      Phoenix.PubSub.subscribe(Csci379Final.PubSub, "story:#{story.id}")

      {:ok, _task} = Stories.start_generation(story.id, "anything")

      assert_receive {:story_failed, _reason}, 5000
      updated = Csci379Final.Repo.get!(Story, story.id)
      assert updated.status == :failed
    end
  end

  describe "insert_tree with list options" do
    setup do
      Application.put_env(:csci379_final, :ai_adapter, Csci379Final.ListOptionsAdapter)
      on_exit(fn -> Application.put_env(:csci379_final, :ai_adapter, Csci379Final.AI.StubAdapter) end)
    end

    test "handles options returned as a pre-built list from the AI adapter", %{scope: scope} do
      {:ok, story} = Stories.create_story_async("list-opts", scope)
      Phoenix.PubSub.subscribe(Csci379Final.PubSub, "story:#{story.id}")
      {:ok, _task} = Stories.start_generation(story.id, "list-opts")
      story_id = story.id
      assert_receive {:story_ready, ^story_id}, 5000
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
