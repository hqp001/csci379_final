defmodule Csci379Final.Stories.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chapters" do
    field :title, :string
    field :description, :string
    field :position, :integer

    belongs_to :story, Csci379Final.Stories.Story
    has_many :scenes, Csci379Final.Stories.Scene, preload_order: [asc: :position]

    timestamps()
  end

  def changeset(chapter, attrs) do
    chapter
    |> cast(attrs, [:title, :description, :position, :story_id])
    |> validate_required([:title, :position, :story_id])
  end
end
