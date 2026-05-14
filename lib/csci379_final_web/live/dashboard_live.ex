defmodule Csci379FinalWeb.DashboardLive do
  use Csci379FinalWeb, :live_view

  alias Csci379Final.Stories

  def mount(_params, _session, socket) do
    stories = Stories.list_stories(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "My Stories")
     |> assign(:stories, stories)
     |> assign(:confirm_delete_id, nil)}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirm_delete_id, String.to_integer(id))}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :confirm_delete_id, nil)}
  end

  def handle_event("delete_story", %{"id" => id}, socket) do
    story = Stories.get_story!(String.to_integer(id), socket.assigns.current_scope)
    {:ok, _} = Stories.delete_story(story, socket.assigns.current_scope)

    stories = Stories.list_stories(socket.assigns.current_scope)
    {:noreply, socket |> assign(:stories, stories) |> assign(:confirm_delete_id, nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto p-6">
      <.page_header>
        {gettext("My Stories")}
        <:actions>
          <.button navigate={~p"/stories/new"} variant="primary">{gettext("New Story")}</.button>
        </:actions>
      </.page_header>

      <div :if={@stories == []} class="text-center py-20 text-slate-400 dark:text-slate-500">
        <p class="text-lg">{gettext("No stories yet.")}</p>
        <p class="mt-1 text-sm">{gettext("Create your first story to get started.")}</p>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <.card :for={story <- @stories} class="relative p-5">
          <div class="mb-3 flex items-start justify-between">
            <.status_badge status={story.status} />
            <button
              phx-click="confirm_delete"
              phx-value-id={story.id}
              class="text-slate-400 hover:text-red-600 dark:text-slate-500 dark:hover:text-red-400 transition-colors"
              title={gettext("Delete story")}
            >
              <.icon name="hero-trash" class="size-4" />
            </button>
          </div>
          <.link navigate={~p"/stories/#{story.id}"}>
            <h2 class="text-lg font-semibold hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors">{story.title}</h2>
            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">{story.topic}</p>
          </.link>
        </.card>
      </div>

      <%!-- Animated delete confirmation modal (always in DOM, CSS transitions) --%>
      <div
        id="delete-modal"
        class={[
          "fixed inset-0 z-50 flex items-center justify-center transition-all duration-200 px-4",
          if(@confirm_delete_id, do: "opacity-100 pointer-events-auto", else: "opacity-0 pointer-events-none")
        ]}
      >
        <div
          class={[
            "absolute inset-0 bg-black/50 transition-opacity duration-200",
            if(@confirm_delete_id, do: "opacity-100", else: "opacity-0")
          ]}
          phx-click="cancel_delete"
        ></div>
        <div class={[
          "relative w-full max-w-sm transition-all duration-200",
          if(@confirm_delete_id, do: "scale-100 opacity-100", else: "scale-95 opacity-0")
        ]}>
          <.card class="p-6" variant="elevated">
            <h3 class="text-lg font-semibold dark:text-slate-100">{gettext("Delete this story?")}</h3>
            <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">{gettext("This cannot be undone. All chapters, scenes, and quests will be deleted.")}</p>
            <div class="mt-6 flex justify-end gap-3">
              <.button variant="ghost" size="sm" phx-click="cancel_delete">{gettext("Cancel")}</.button>
              <.button variant="danger" size="sm" phx-click="delete_story" phx-value-id={@confirm_delete_id}>{gettext("Delete")}</.button>
            </div>
          </.card>
        </div>
      </div>
    </div>
    """
  end
end
