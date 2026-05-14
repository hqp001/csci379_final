defmodule Csci379FinalWeb.DashboardLiveTest do
  use Csci379FinalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Csci379Final.AccountsFixtures
  import Csci379Final.StoriesFixtures

  setup %{conn: conn} do
    user = user_fixture()
    scope = Csci379Final.Accounts.Scope.for_user(user)
    conn = log_in_user(conn, user)
    %{conn: conn, scope: scope}
  end

  test "shows empty state when no stories", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/dashboard")
    assert html =~ "No stories yet"
  end

  test "lists existing stories", %{conn: conn, scope: scope} do
    story = story_fixture(scope)
    {:ok, _lv, html} = live(conn, ~p"/dashboard")
    assert html =~ story.title
  end

  test "confirm_delete shows delete modal", %{conn: conn, scope: scope} do
    story = story_fixture(scope)
    {:ok, lv, _html} = live(conn, ~p"/dashboard")

    html = lv |> element("button[phx-value-id='#{story.id}']") |> render_click()
    assert html =~ "Delete this story?"
  end

  test "cancel_delete hides the modal", %{conn: conn, scope: scope} do
    story = story_fixture(scope)
    {:ok, lv, _html} = live(conn, ~p"/dashboard")

    lv |> element("button[phx-value-id='#{story.id}']") |> render_click()
    html = lv |> element("button[phx-click='cancel_delete']") |> render_click()
    assert html =~ "opacity-0 pointer-events-none"
  end

  test "delete_story removes the story", %{conn: conn, scope: scope} do
    story = story_fixture(scope)
    {:ok, lv, _html} = live(conn, ~p"/dashboard")

    lv |> element("button[phx-value-id='#{story.id}']") |> render_click()
    html = lv |> element("button[phx-click='delete_story']") |> render_click()

    refute html =~ story.title
    assert html =~ "No stories yet"
  end

  test "redirects unauthenticated users to login" do
    conn = Phoenix.ConnTest.build_conn()
    {:error, {:redirect, %{to: path}}} = live(conn, ~p"/dashboard")
    assert path =~ "/users/log-in"
  end
end
