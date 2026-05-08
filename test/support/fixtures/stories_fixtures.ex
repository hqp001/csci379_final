defmodule Csci379Final.StoriesFixtures do
  alias Csci379Final.Repo
  alias Csci379Final.Stories.{Story, Chapter, Scene, Quest}

  def story_fixture(scope, attrs \\ %{}) do
    {:ok, story} =
      %Story{}
      |> Story.changeset(
        Enum.into(attrs, %{
          title: "Test Story",
          topic: "Test Topic",
          status: :ready,
          user_id: scope.user.id
        })
      )
      |> Repo.insert()

    story
  end

  def chapter_fixture(story, attrs \\ %{}) do
    {:ok, chapter} =
      %Chapter{}
      |> Chapter.changeset(
        Enum.into(attrs, %{
          title: "Test Chapter",
          description: "A test chapter",
          position: 1,
          story_id: story.id
        })
      )
      |> Repo.insert()

    chapter
  end

  def scene_fixture(chapter, attrs \\ %{}) do
    {:ok, scene} =
      %Scene{}
      |> Scene.changeset(
        Enum.into(attrs, %{
          title: "Test Scene",
          description: "A test scene",
          position: 1,
          is_locked: false,
          chapter_id: chapter.id
        })
      )
      |> Repo.insert()

    scene
  end

  def quest_fixture(scene, attrs \\ %{}) do
    {:ok, quest} =
      %Quest{}
      |> Quest.changeset(
        Enum.into(attrs, %{
          type: :multiple_choice,
          question: "Test question?",
          options: [%{"key" => "a", "text" => "Option A"}, %{"key" => "b", "text" => "Option B"}],
          correct_answer: "a",
          explanation: "Because A.",
          position: 1,
          scene_id: scene.id
        })
      )
      |> Repo.insert()

    quest
  end

  def story_tree_fixture(scope) do
    story = story_fixture(scope)
    chapter = chapter_fixture(story)
    scene = scene_fixture(chapter)
    quest = quest_fixture(scene)
    {story, chapter, scene, quest}
  end
end
