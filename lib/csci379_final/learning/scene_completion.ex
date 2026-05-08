defmodule Csci379Final.Learning.SceneCompletion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scene_completions" do
    field :xp_earned, :integer, default: 0
    field :completed_at, :utc_datetime

    belongs_to :user, Csci379Final.Accounts.User
    belongs_to :scene, Csci379Final.Stories.Scene

    timestamps()
  end

  def changeset(completion, attrs) do
    completion
    |> cast(attrs, [:xp_earned, :completed_at, :user_id, :scene_id])
    |> validate_required([:xp_earned, :completed_at, :user_id, :scene_id])
    |> unique_constraint([:user_id, :scene_id])
  end
end
