defmodule Csci379FinalWeb.OAuthControllerTest do
  use Csci379FinalWeb.ConnCase, async: true

  import Csci379Final.AccountsFixtures

  alias Csci379FinalWeb.OAuthController

  defp auth_conn(conn, email \\ nil) do
    email = email || unique_user_email()

    conn
    |> assign(:ueberauth_auth, %{
      provider: :google,
      uid: "google-uid-#{System.unique_integer()}",
      info: %{email: email}
    })
  end

  defp failure_conn(conn) do
    conn
    |> assign(:ueberauth_failure, %{
      errors: [%{message: "access_denied"}]
    })
  end

  describe "request/2" do
    test "passes through the request action", %{conn: conn} do
      # Ueberauth plug redirects to Google OAuth, halting the conn
      conn = get(conn, ~p"/auth/google")
      assert conn.halted
    end

    test "request action returns conn unchanged when called directly", %{conn: conn} do
      conn =
        conn
        |> bypass_through(Csci379FinalWeb.Router, [:browser])
        |> get("/")
        |> OAuthController.request(%{})

      refute conn.halted
    end
  end

  describe "callback/2 - failure" do
    test "redirects to login with error flash on failure", %{conn: conn} do
      conn =
        conn
        |> bypass_through(Csci379FinalWeb.Router, [:browser])
        |> get("/")
        |> failure_conn()
        |> OAuthController.callback(%{})

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "access_denied"
    end
  end

  describe "callback/2 - success" do
    test "logs in user and redirects on successful oauth", %{conn: conn} do
      email = unique_user_email()

      conn =
        conn
        |> bypass_through(Csci379FinalWeb.Router, [:browser])
        |> get("/")
        |> auth_conn(email)
        |> OAuthController.callback(%{})

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome!"
    end

    test "logs in existing user via oauth", %{conn: conn} do
      existing_user = user_fixture()

      conn =
        conn
        |> bypass_through(Csci379FinalWeb.Router, [:browser])
        |> get("/")
        |> auth_conn(existing_user.email)
        |> OAuthController.callback(%{})

      assert redirected_to(conn) == ~p"/"
    end

    test "shows error flash when user creation fails", %{conn: conn} do
      conn =
        conn
        |> bypass_through(Csci379FinalWeb.Router, [:browser])
        |> get("/")
        |> assign(:ueberauth_auth, %{
          provider: :google,
          uid: "uid-#{System.unique_integer()}",
          info: %{email: "not-a-valid-email-address"}
        })
        |> OAuthController.callback(%{})

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Could not sign in"
    end
  end
end
