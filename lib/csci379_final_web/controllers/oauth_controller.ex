defmodule Csci379FinalWeb.OAuthController do
  use Csci379FinalWeb, :controller

  plug Ueberauth

  alias Csci379Final.Accounts

  def request(conn, _params), do: conn

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    reason = hd(failure.errors).message

    conn
    |> put_flash(:error, "Google login failed: #{reason}")
    |> redirect(to: ~p"/users/log-in")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.info.email
    provider = to_string(auth.provider)
    uid = to_string(auth.uid)

    case Accounts.find_or_create_user_from_oauth(%{provider: provider, uid: uid, email: email}) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> Csci379FinalWeb.UserAuth.log_in_user(user)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not sign in with Google. Please try again.")
        |> redirect(to: ~p"/users/log-in")
    end
  end
end
