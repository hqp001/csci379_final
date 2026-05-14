defmodule Csci379FinalWeb.Components.Button do
  use Phoenix.Component

  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary secondary ghost danger success outline)
  attr :size, :string, values: ~w(xs sm md lg), default: "md"
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    base = "inline-flex items-center justify-center gap-2 rounded-xl font-semibold transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"

    variants = %{
      "primary" => "bg-indigo-600 text-white hover:bg-indigo-500 shadow-sm",
      "secondary" => "bg-amber-400 text-slate-900 hover:bg-amber-300 shadow-sm",
      "ghost" => "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800",
      "danger" => "bg-red-600 text-white hover:bg-red-500 shadow-sm",
      "success" => "bg-emerald-600 text-white hover:bg-emerald-500 shadow-sm",
      "outline" => "border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700",
      nil => "bg-indigo-600 text-white hover:bg-indigo-500 shadow-sm"
    }

    sizes = %{
      "xs" => "px-2.5 py-1 text-xs",
      "sm" => "px-3 py-1.5 text-sm",
      "md" => "px-4 py-2 text-sm",
      "lg" => "px-5 py-2.5 text-base"
    }

    assigns =
      assign_new(assigns, :class, fn ->
        [base, Map.fetch!(variants, assigns[:variant]), Map.fetch!(sizes, assigns[:size])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end
end
