defmodule Csci379FinalWeb.LocaleControllerTest do
  use Csci379FinalWeb.ConnCase, async: true

  test "sets locale in session and redirects back", %{conn: conn} do
    conn =
      conn
      |> put_req_header("referer", "http://localhost/dashboard")
      |> get(~p"/set-locale?locale=es")

    assert get_session(conn, :locale) == "es"
    assert redirected_to(conn) == "http://localhost/dashboard"
  end

  test "falls back to en for unsupported locale", %{conn: conn} do
    conn = get(conn, ~p"/set-locale?locale=fr")
    assert get_session(conn, :locale) == "en"
  end

  test "sets en locale", %{conn: conn} do
    conn = get(conn, ~p"/set-locale?locale=en")
    assert get_session(conn, :locale) == "en"
  end
end
