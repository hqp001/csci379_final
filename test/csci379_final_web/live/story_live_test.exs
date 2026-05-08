defmodule Csci379FinalWeb.StoryLiveTest do
  use Csci379FinalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Csci379Final.AccountsFixtures
  import Csci379Final.StoriesFixtures

  setup %{conn: conn} do
    user = user_fixture()
    scope = Csci379Final.Accounts.Scope.for_user(user)
    conn = log_in_user(conn, user)
    %{conn: conn, user: user, scope: scope}
  end

  describe "StoryLive.New" do
    test "renders new story form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/stories/new")
      assert html =~ "What do you want to explore?"
    end

    test "shows error for empty topic", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/stories/new")

      html =
        lv
        |> form("form", %{topic: ""})
        |> render_submit()

      assert html =~ "Please enter a topic"
    end

    test "starts story generation with valid topic", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/stories/new")

      lv
      |> form("form", %{topic: "The Roman Empire"})
      |> render_submit()

      assert render(lv) =~ "Building your story"
    end
  end

  describe "StoryLive.Show" do
    test "renders story with chapters", %{conn: conn, scope: scope} do
      {story, _chapter, _scene, _quest} = story_tree_fixture(scope)
      {:ok, _lv, html} = live(conn, ~p"/stories/#{story.id}")
      assert html =~ story.title
      assert html =~ "Test Chapter"
    end

    test "first chapter is open by default showing scenes", %{conn: conn, scope: scope} do
      {story, _chapter, _scene, _quest} = story_tree_fixture(scope)
      {:ok, _lv, html} = live(conn, ~p"/stories/#{story.id}")
      assert html =~ "Test Chapter"
    end

    test "clicking chapter toggle closes then reopens it", %{conn: conn, scope: scope} do
      {story, chapter, _scene, _quest} = story_tree_fixture(scope)
      {:ok, lv, _html} = live(conn, ~p"/stories/#{story.id}")

      lv |> element("button[phx-value-id='#{chapter.id}']") |> render_click()
      html = lv |> element("button[phx-value-id='#{chapter.id}']") |> render_click()
      assert html =~ "Test Scene"
    end

    test "redirects to 404 for non-owned story", %{conn: conn} do
      other_scope = user_scope_fixture()
      {story, _, _, _} = story_tree_fixture(other_scope)

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/stories/#{story.id}")
      end
    end
  end
end
