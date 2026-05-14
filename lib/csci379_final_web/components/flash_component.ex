defmodule Csci379FinalWeb.Components.Flash do
  use Phoenix.Component
  use Gettext, backend: Csci379FinalWeb.Gettext

  import Csci379FinalWeb.Components.Icon, only: [icon: 1, hide: 2]

  alias Phoenix.LiveView.JS

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "flex w-80 items-start gap-3 rounded-2xl border p-4 shadow-lg",
        @kind == :info && "bg-indigo-50 dark:bg-indigo-900/30 border-indigo-200 dark:border-indigo-700 text-indigo-800 dark:text-indigo-200",
        @kind == :error && "bg-red-50 dark:bg-red-900/30 border-red-200 dark:border-red-700 text-red-800 dark:text-red-200"
      ]}
      {@rest}
    >
      <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
      <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
      <div class="flex-1 min-w-0">
        <p :if={@title} class="font-semibold">{@title}</p>
        <p>{msg}</p>
      </div>
      <button type="button" class="ml-auto shrink-0 text-current opacity-50 hover:opacity-100 cursor-pointer" aria-label={gettext("close")}>
        <.icon name="hero-x-mark" class="size-5" />
      </button>
    </div>
    """
  end
end
