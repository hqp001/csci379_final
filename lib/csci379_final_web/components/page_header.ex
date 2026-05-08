defmodule Csci379FinalWeb.Components.PageHeader do
  use Phoenix.Component
  import Csci379FinalWeb.CoreComponents, only: [icon: 1]

  @doc """
  A page-level header with an optional back-navigation link, title, subtitle, and actions slot.

  ## Examples

      <.page_header>My Stories</.page_header>

      <.page_header back_navigate={~p"/dashboard"} back_label="My Stories">
        Story Title
        <:subtitle>Learn about the Roman Empire</:subtitle>
        <:actions><.button variant="primary">New</.button></:actions>
      </.page_header>
  """
  attr :back_navigate, :string, default: nil
  attr :back_label, :string, default: "Back"
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class="mb-8">
      <.link
        :if={@back_navigate}
        navigate={@back_navigate}
        class="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-slate-500 hover:text-slate-800 transition-colors"
      >
        <.icon name="hero-arrow-left" class="size-3.5" />
        {@back_label}
      </.link>
      <div class={[@actions != [] && "flex items-start justify-between gap-6"]}>
        <div>
          <h1 class="text-3xl font-bold text-slate-900">{render_slot(@inner_block)}</h1>
          <p :if={@subtitle != []} class="mt-1 text-slate-500">{render_slot(@subtitle)}</p>
        </div>
        <div :if={@actions != []} class="flex-none">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end
end
