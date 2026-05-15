defmodule Csci379Final.Accounts.UserNotifier do
  import Swoosh.Email
  require Logger

  alias Csci379Final.Mailer
  alias Csci379Final.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"LearnAI", "onboarding@resend.dev"})
      |> subject(subject)
      |> text_body(body)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        {:ok, email}
      {:error, reason} ->
        Logger.error("Failed to deliver email to #{recipient}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Deliver a welcome email to a newly registered user.
  """
  def deliver_welcome_email(user) do
    deliver(user.email, "Welcome to LearnAI!", """

    ==============================

    Hi #{user.email},

    Welcome to LearnAI! Your account is ready.

    Start learning by creating your first AI-generated story at:

    http://localhost:4000/stories/new

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirm your LearnAI account", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset your LearnAI password", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    This link is valid for 60 minutes.

    If you didn't request a password reset, please ignore this.

    ==============================
    """)
  end
end
