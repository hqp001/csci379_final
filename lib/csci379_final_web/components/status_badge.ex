defmodule Csci379FinalWeb.Components.StatusBadge do
  use Phoenix.Component
  import Csci379FinalWeb.Components.Icon, only: [icon: 1]

  @doc """
  A badge representing a story's generation status.

  ## Examples

      <.status_badge status={:ready} />
      <.status_badge status={:generating} />
      <.status_badge status={:failed} />
  """
  attr :status, :atom, required: true, values: [:ready, :generating, :failed]

  def status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ring-inset",
      @status == :ready && "bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300 ring-emerald-200 dark:ring-emerald-700",
      @status == :generating && "bg-amber-50 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300 ring-amber-200 dark:ring-amber-700",
      @status == :failed && "bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-300 ring-red-200 dark:ring-red-700"
    ]}>
      <svg :if={@status == :generating} class="h-3 w-3 animate-spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
      </svg>
      <.icon :if={@status == :ready} name="hero-check" class="size-3" />
      <.icon :if={@status == :failed} name="hero-x-mark" class="size-3" />
      {@status}
    </span>
    """
  end
end
