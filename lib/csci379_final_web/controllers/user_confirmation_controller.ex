defmodule Csci379FinalWeb.UserConfirmationController do
  use Csci379FinalWeb, :controller

  alias Csci379Final.Accounts

  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user_by_token(token) do
      :ok ->
        conn
        |> put_flash(:info, "Account confirmed! You can now log in.")
        |> redirect(to: ~p"/users/log-in")

      :error ->
        conn
        |> put_flash(:error, "Confirmation link is invalid or it has expired.")
        |> redirect(to: ~p"/users/register")
    end
  end
end
