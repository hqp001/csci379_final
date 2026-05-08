defmodule Csci379FinalWeb.Components.ProgressBar do
  use Phoenix.Component

  @doc """
  A labeled progress bar for tracking quest progress within a scene.

  ## Examples

      <.progress_bar current={2} total={5} />
      <.progress_bar current={@quest_index + 1} total={length(@quests)} class="mt-6" />
  """
  attr :current, :integer, required: true
  attr :total, :integer, required: true
  attr :class, :any, default: nil

  def progress_bar(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center justify-between mb-1.5">
        <span class="text-xs text-slate-500">
          Quest {@current} of {@total}
        </span>
        <span class="text-xs font-bold text-indigo-600">
          {if @total > 0, do: "#{trunc(@current / @total * 100)}%", else: "0%"}
        </span>
      </div>
      <div class="h-2 w-full rounded-full bg-slate-100 overflow-hidden">
        <div
          class="h-full rounded-full bg-indigo-600 transition-all duration-500 ease-out"
          style={"width: #{if @total > 0, do: trunc(@current / @total * 100), else: 0}%"}
        />
      </div>
    </div>
    """
  end
end
