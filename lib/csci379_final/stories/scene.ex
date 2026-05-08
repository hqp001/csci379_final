defmodule Csci379Final.Stories.Scene do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scenes" do
    field :title, :string
    field :description, :string
    field :position, :integer
    field :is_locked, :boolean, default: true

    belongs_to :chapter, Csci379Final.Stories.Chapter
    has_many :quests, Csci379Final.Stories.Quest, preload_order: [asc: :position]

    timestamps()
  end

  def changeset(scene, attrs) do
    scene
    |> cast(attrs, [:title, :description, :position, :is_locked, :chapter_id])
    |> validate_required([:title, :position, :chapter_id])
  end
end
