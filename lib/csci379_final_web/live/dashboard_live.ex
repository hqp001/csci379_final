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
        My Stories
        <:actions>
          <.button navigate={~p"/stories/new"} variant="primary">New Story</.button>
        </:actions>
      </.page_header>

      <div :if={@stories == []} class="text-center py-20 text-slate-400">
        <p class="text-lg">No stories yet.</p>
        <p class="mt-1 text-sm">Create your first story to get started.</p>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <.card :for={story <- @stories} class="relative p-5">
          <div class="mb-3 flex items-start justify-between">
            <.status_badge status={story.status} />
            <button
              phx-click="confirm_delete"
              phx-value-id={story.id}
              class="text-slate-400 hover:text-red-600 transition-colors"
              title="Delete story"
            >
              <.icon name="hero-trash" class="size-4" />
            </button>
          </div>
          <.link navigate={~p"/stories/#{story.id}"}>
            <h2 class="text-lg font-semibold hover:text-indigo-600 transition-colors">{story.title}</h2>
            <p class="mt-1 text-sm text-slate-500">{story.topic}</p>
          </.link>
        </.card>
      </div>

      <div :if={@confirm_delete_id} class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <.card class="w-full max-w-sm p-6" variant="elevated">
          <h3 class="text-lg font-semibold">Delete this story?</h3>
          <p class="mt-2 text-sm text-slate-500">This cannot be undone. All chapters, scenes, and quests will be deleted.</p>
          <div class="mt-6 flex justify-end gap-3">
            <.button variant="ghost" size="sm" phx-click="cancel_delete">Cancel</.button>
            <.button variant="danger" size="sm" phx-click="delete_story" phx-value-id={@confirm_delete_id}>Delete</.button>
          </div>
        </.card>
      </div>
    </div>
    """
  end
end
