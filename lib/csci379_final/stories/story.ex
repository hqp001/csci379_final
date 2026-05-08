defmodule Csci379Final.Stories.Story do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stories" do
    field :title, :string
    field :topic, :string
    field :status, Ecto.Enum, values: [:generating, :ready, :failed], default: :generating

    belongs_to :user, Csci379Final.Accounts.User
    has_many :chapters, Csci379Final.Stories.Chapter, preload_order: [asc: :position]

    timestamps()
  end

  def changeset(story, attrs) do
    story
    |> cast(attrs, [:title, :topic, :status, :user_id])
    |> validate_required([:title, :topic, :user_id])
  end
end
