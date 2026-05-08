defmodule Csci379Final.Learning.QuestAttempt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quest_attempts" do
    field :user_answer, :string
    field :is_correct, :boolean
    field :ai_feedback, :string

    belongs_to :user, Csci379Final.Accounts.User
    belongs_to :quest, Csci379Final.Stories.Quest

    timestamps()
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [:user_answer, :is_correct, :ai_feedback, :user_id, :quest_id])
    |> validate_required([:user_answer, :is_correct, :user_id, :quest_id])
  end
end
