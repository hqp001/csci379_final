defmodule Csci379FinalWeb.UserRegistrationController do
  use Csci379FinalWeb, :controller

  alias Csci379Final.Accounts
  alias Csci379Final.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_email(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, user} = Accounts.confirm_user(user)
        Accounts.deliver_welcome_email(user)

        conn
        |> put_flash(:info, "Account created successfully.")
        |> Csci379FinalWeb.UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
