defmodule Csci379Final.Stories.Quest.Option do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :key, :string
    field :text, :string
  end

  def changeset(option, attrs) do
    option
    |> cast(attrs, [:key, :text])
    |> validate_required([:key, :text])
  end
end
