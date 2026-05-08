defmodule Csci379FinalWeb.Components.Card do
  use Phoenix.Component

  @doc """
  A content card with optional variant styling.

  ## Examples

      <.card>Content</.card>
      <.card variant="elevated" class="p-6">Elevated</.card>
      <.card variant="flat">Flat</.card>
  """
  attr :class, :any, default: nil
  attr :variant, :string, default: "default", values: ~w(default elevated flat)
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={[
      "rounded-2xl border border-slate-200 bg-white",
      @variant == "elevated" && "shadow-md",
      @variant == "flat" && "border-0 bg-slate-50",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
