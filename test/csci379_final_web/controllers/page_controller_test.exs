defmodule Csci379FinalWeb.PageControllerTest do
  use Csci379FinalWeb.ConnCase

  import Csci379Final.AccountsFixtures

  test "GET / redirects unauthenticated users to log in", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log-in"
  end

  test "GET / redirects authenticated users to dashboard", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/dashboard"
  end
end
