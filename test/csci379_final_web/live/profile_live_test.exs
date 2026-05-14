defmodule Csci379FinalWeb.ProfileLiveTest do
  use Csci379FinalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Csci379Final.AccountsFixtures
  import Csci379Final.StoriesFixtures

  alias Csci379Final.Learning

  setup %{conn: conn} do
    user = user_fixture()
    scope = Csci379Final.Accounts.Scope.for_user(user)
    conn = log_in_user(conn, user)
    %{conn: conn, scope: scope}
  end

  test "renders profile with zero stats for new user", %{conn: conn, scope: scope} do
    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ scope.user.email
    assert html =~ "0 XP total"
  end

  test "shows XP after completing a scene", %{conn: conn, scope: scope} do
    {_story, _chapter, scene, quest} = story_tree_fixture(scope)
    Learning.record_attempt(scope, quest.id, "a", true, "Good!")
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "Test Scene"
    assert html =~ "60 XP total"
  end

  test "shows xp chart placeholder when no completions", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "Complete scenes to see XP"
  end

  test "shows xp chart canvas when completions exist", %{conn: conn, scope: scope} do
    {_story, _chapter, scene, _quest} = story_tree_fixture(scope)
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "xp-chart"
  end

  test "shows accuracy chart canvas when attempts exist", %{conn: conn, scope: scope} do
    {_story, _chapter, scene, quest} = story_tree_fixture(scope)
    Learning.record_attempt(scope, quest.id, "a", true, "Good!")
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "accuracy-chart"
  end

  test "shows accuracy placeholder when no attempts", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "No attempts yet"
  end

  test "redirects unauthenticated users to login", %{conn: conn} do
    conn = Phoenix.ConnTest.build_conn()
    {:error, {:redirect, %{to: path}}} = live(conn, ~p"/profile")
    assert path =~ "/users/log-in"
  end

  test "chart_mounted event pushes chart_data", %{conn: conn, scope: scope} do
    {_story, _chapter, scene, _quest} = story_tree_fixture(scope)
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, lv, _html} = live(conn, ~p"/profile")
    lv |> render_hook("chart_mounted", %{})
    assert render(lv) =~ "xp-chart"
  end

  test "accuracy_mounted event pushes accuracy_data", %{conn: conn, scope: scope} do
    {_story, _chapter, scene, quest} = story_tree_fixture(scope)
    Learning.record_attempt(scope, quest.id, "a", true, "Good!")
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, lv, _html} = live(conn, ~p"/profile")
    lv |> render_hook("accuracy_mounted", %{})
    assert render(lv) =~ "accuracy-chart"
  end

  test "story picker shows story titles when completions exist", %{conn: conn, scope: scope} do
    {_story, _chapter, scene, _quest} = story_tree_fixture(scope)
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "Test Story"
  end

  test "selecting a story updates chart data", %{conn: conn, scope: scope} do
    {story, _chapter, scene, _quest} = story_tree_fixture(scope)
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, lv, _html} = live(conn, ~p"/profile")
    lv |> element("form[phx-change=select_story]") |> render_change(%{story_id: story.id})
    assert render(lv) =~ "xp-chart"
  end

  test "shows story progress bars", %{conn: conn, scope: scope} do
    {_story, _chapter, _scene, _quest} = story_tree_fixture(scope)

    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "Story Progress"
    assert html =~ "Test Story"
  end

  test "shows story progress placeholder when no stories", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "Create a story to track your progress"
  end

  test "shows non-zero accuracy when user has attempts", %{conn: conn, scope: scope} do
    {_story, _chapter, scene, quest} = story_tree_fixture(scope)
    Learning.record_attempt(scope, quest.id, "a", true, "Good!")
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "%"
  end
end
