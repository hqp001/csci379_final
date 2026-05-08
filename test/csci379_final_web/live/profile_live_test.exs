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

  test "shows chart placeholder when no completions", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "Complete scenes to see your XP growth"
  end

  test "shows chart canvas when completions exist", %{conn: conn, scope: scope} do
    {_story, _chapter, scene, _quest} = story_tree_fixture(scope)
    Learning.complete_scene(scope, scene.id, 1, 1)

    {:ok, _lv, html} = live(conn, ~p"/profile")
    assert html =~ "xp-chart"
  end

  test "redirects unauthenticated users to login", %{conn: conn} do
    conn = Phoenix.ConnTest.build_conn()
    {:error, {:redirect, %{to: path}}} = live(conn, ~p"/profile")
    assert path =~ "/users/log-in"
  end
end
