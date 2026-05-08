defmodule Csci379FinalWeb.Components.StatCard do
  use Phoenix.Component

  @doc """
  A compact stat card showing a numeric value and a label, used on the profile page.

  ## Examples

      <.stat_card value="42" label="Scenes" />
      <.stat_card value="87%" label="Accuracy" />
  """
  attr :value, :string, required: true
  attr :label, :string, required: true
  attr :class, :any, default: nil

  def stat_card(assigns) do
    ~H"""
    <div class={["rounded-2xl border border-slate-200 bg-white p-5 text-center", @class]}>
      <p class="text-2xl font-bold text-indigo-600">{@value}</p>
      <p class="mt-1 text-xs font-semibold uppercase tracking-widest text-slate-400">{@label}</p>
    </div>
    """
  end
end
