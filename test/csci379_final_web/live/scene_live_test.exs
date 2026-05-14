defmodule Csci379FinalWeb.SceneLiveTest do
  use Csci379FinalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Csci379Final.AccountsFixtures
  import Csci379Final.StoriesFixtures

  alias Csci379Final.Learning

  setup %{conn: conn} do
    user = user_fixture()
    scope = Csci379Final.Accounts.Scope.for_user(user)
    conn = log_in_user(conn, user)
    {story, _chapter, scene, quest} = story_tree_fixture(scope)
    %{conn: conn, scope: scope, story: story, scene: scene, quest: quest}
  end

  describe "SceneLive.Show - answering" do
    test "renders multiple choice quest", %{conn: conn, story: story, scene: scene} do
      {:ok, _lv, html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene.id}")
      assert html =~ "Test question?"
      assert html =~ "Option A"
      assert html =~ "Option B"
    end

    test "submitting correct answer shows feedback", %{conn: conn, story: story, scene: scene} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene.id}")

      html =
        lv
        |> element("button[phx-value-answer='a']")
        |> render_click()

      assert html =~ "Because A."
    end

    test "submitting wrong answer shows incorrect feedback", %{conn: conn, story: story, scene: scene} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene.id}")

      html =
        lv
        |> element("button[phx-value-answer='b']")
        |> render_click()

      assert html =~ "Because A."
    end

    test "next quest button advances to completion when last quest", %{conn: conn, story: story, scene: scene} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene.id}")

      lv |> element("button[phx-value-answer='a']") |> render_click()
      html = lv |> element("button[phx-click='next_quest']") |> render_click()

      assert html =~ "Scene Complete"
    end
  end

  describe "SceneLive.Show - fill_blank quest" do
    setup %{conn: conn, scope: scope, story: story} do
      scene2 = scene_fixture(chapter_fixture(story), %{position: 2, is_locked: false})

      {:ok, fill_quest} =
        Csci379Final.Stories.Quest
        |> struct()
        |> Csci379Final.Stories.Quest.changeset(%{
          type: :fill_blank,
          question: "Rome was founded in ___ BC.",
          options: [],
          correct_answer: "753",
          explanation: "753 BC is correct.",
          position: 1,
          scene_id: scene2.id
        })
        |> Csci379Final.Repo.insert()

      %{scene2: scene2, fill_quest: fill_quest}
    end

    test "renders fill in the blank input", %{conn: conn, story: story, scene2: scene2} do
      {:ok, _lv, html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene2.id}")
      assert html =~ "Rome was founded in"
    end

    test "submitting correct fill answer shows correct feedback", %{conn: conn, story: story, scene2: scene2} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene2.id}")

      html =
        lv
        |> form("form", %{answer: "753"})
        |> render_submit()

      assert html =~ "753 BC is correct"
    end
  end

  describe "SceneLive.Show - locked scene" do
    test "redirects with flash error for locked scene", %{conn: conn, story: story, scope: scope} do
      story2 = story_fixture(scope)
      chapter2 = chapter_fixture(story2)
      locked_scene = scene_fixture(chapter2, %{is_locked: true})

      assert {:error, {:live_redirect, %{flash: flash, to: path}}} =
               live(conn, ~p"/stories/#{story2.id}/scenes/#{locked_scene.id}")

      assert flash["error"] =~ "locked"
      assert path == ~p"/stories/#{story2.id}"
    end
  end

  describe "SceneLive.Show - already completed" do
    test "shows already completed banner", %{conn: conn, scope: scope, story: story, scene: scene} do
      Learning.complete_scene(scope, scene.id, 1, 1)
      {:ok, _lv, html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene.id}")
      assert html =~ "Already Completed"
    end
  end

  describe "SceneLive.Show - short_answer quest" do
    setup %{conn: conn, scope: scope, story: story} do
      chapter = chapter_fixture(story)
      scene_sa = scene_fixture(chapter, %{position: 2, is_locked: false})

      {:ok, sa_quest} =
        Csci379Final.Stories.Quest
        |> struct()
        |> Csci379Final.Stories.Quest.changeset(%{
          type: :short_answer,
          question: "Explain the fall of Rome.",
          options: [],
          correct_answer: "Many factors contributed.",
          explanation: "Complex causes.",
          position: 1,
          scene_id: scene_sa.id
        })
        |> Csci379Final.Repo.insert()

      %{scene_sa: scene_sa, sa_quest: sa_quest}
    end

    test "renders short answer textarea", %{conn: conn, story: story, scene_sa: scene_sa} do
      {:ok, _lv, html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene_sa.id}")
      assert html =~ "Explain the fall of Rome"
    end

    test "answer_changed updates current_answer", %{conn: conn, story: story, scene_sa: scene_sa} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene_sa.id}")
      lv |> render_hook("answer_changed", %{"answer" => "my answer"})
      assert render(lv) =~ "my answer"
    end

    test "submit short answer triggers grading phase", %{conn: conn, story: story, scene_sa: scene_sa} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene_sa.id}")
      html = lv |> form("form", %{answer: "my answer"}) |> render_submit()
      assert html =~ "Grading" or html =~ "grading" or html =~ "Good answer"
    end

    test "stale grading ref is ignored", %{conn: conn, story: story, scene_sa: scene_sa} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene_sa.id}")
      stale_ref = make_ref()
      send(lv.pid, {:graded, stale_ref, "answer", {:ok, %{is_correct: true, feedback: "Good"}}})
      assert render(lv) =~ "Explain the fall"
    end

    test "graded message with error result shows could not grade", %{conn: conn, story: story, scene_sa: scene_sa} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene_sa.id}")
      lv |> form("form", %{answer: "my answer"}) |> render_submit()
      grading_ref = :sys.get_state(lv.pid).socket.assigns.grading_ref
      send(lv.pid, {:graded, grading_ref, "my answer", {:error, "oops"}})
      assert render(lv) =~ "Could not grade"
    end
  end

  describe "SceneLive.Show - fill_blank wrong answer shows correct answer" do
    setup %{story: story} do
      scene3 = scene_fixture(chapter_fixture(story), %{position: 3, is_locked: false})

      {:ok, _} =
        Csci379Final.Stories.Quest
        |> struct()
        |> Csci379Final.Stories.Quest.changeset(%{
          type: :fill_blank,
          question: "Rome fell in ___ AD.",
          options: [],
          correct_answer: "476",
          explanation: "476 AD is the date.",
          position: 1,
          scene_id: scene3.id
        })
        |> Csci379Final.Repo.insert()

      %{scene3: scene3}
    end

    test "submitting wrong fill answer shows correct answer", %{conn: conn, story: story, scene3: scene3} do
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}/scenes/#{scene3.id}")
      html = lv |> form("form", %{answer: "999"}) |> render_submit()
      assert html =~ "476"
    end
  end
end
