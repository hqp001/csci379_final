defmodule Csci379Final.Stories.Quest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quests" do
    field :type, Ecto.Enum, values: [:multiple_choice, :fill_blank, :short_answer]
    field :question, :string
    field :correct_answer, :string
    field :explanation, :string
    field :position, :integer

    embeds_many :options, Csci379Final.Stories.Quest.Option, on_replace: :delete

    belongs_to :scene, Csci379Final.Stories.Scene

    timestamps()
  end

  def changeset(quest, attrs) do
    quest
    |> cast(attrs, [:type, :question, :correct_answer, :explanation, :position, :scene_id])
    |> cast_embed(:options, with: &Csci379Final.Stories.Quest.Option.changeset/2)
    |> validate_required([:type, :question, :correct_answer, :position, :scene_id])
  end
end
