defmodule Csci379FinalWeb.StoryLive.Show do
  use Csci379FinalWeb, :live_view

  alias Csci379Final.Stories

  def mount(%{"id" => id}, _session, socket) do
    story = Stories.get_story_with_tree!(id, socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, story.title)
     |> assign(:story, story)
     |> assign(:open_chapters, MapSet.new([hd(story.chapters).id]))}
  end

  def handle_event("toggle_chapter", %{"id" => id}, socket) do
    id = String.to_integer(id)

    open_chapters =
      if MapSet.member?(socket.assigns.open_chapters, id) do
        MapSet.delete(socket.assigns.open_chapters, id)
      else
        MapSet.put(socket.assigns.open_chapters, id)
      end

    {:noreply, assign(socket, :open_chapters, open_chapters)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto p-6">
      <.page_header back_navigate={~p"/dashboard"} back_label={gettext("My Stories")}>
        {@story.title}
        <:subtitle>{@story.topic}</:subtitle>
      </.page_header>

      <div class="mt-8 space-y-3">
        <div :for={chapter <- @story.chapters} class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
          <button
            phx-click="toggle_chapter"
            phx-value-id={chapter.id}
            class="flex w-full items-center justify-between px-5 py-4 text-left hover:bg-slate-50 dark:hover:bg-slate-700/50 rounded-xl transition-colors"
          >
            <div>
              <span class="text-xs font-medium uppercase tracking-wide text-indigo-600 dark:text-indigo-400">
                {gettext("Chapter")} {chapter.position}
              </span>
              <h2 class="mt-0.5 text-base font-semibold dark:text-slate-100">
                {chapter.title}
              </h2>
            </div>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class={["h-5 w-5 text-slate-400 dark:text-slate-500 transition-transform", MapSet.member?(@open_chapters, chapter.id) && "rotate-180"]}
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>

          <div class={[
            "overflow-hidden transition-all duration-300 ease-in-out",
            MapSet.member?(@open_chapters, chapter.id) && "max-h-[800px] opacity-100",
            !MapSet.member?(@open_chapters, chapter.id) && "max-h-0 opacity-0"
          ]}>
          <div class="border-t border-slate-200 dark:border-slate-700 px-5 py-3">
            <p :if={chapter.description} class="mb-3 text-sm text-slate-500 dark:text-slate-400">{chapter.description}</p>
            <div class="space-y-2">
              <div :for={scene <- chapter.scenes} class={[
                "flex items-center justify-between rounded-lg px-4 py-3",
                scene.is_locked && "bg-slate-50 dark:bg-slate-700/30",
                !scene.is_locked && "bg-indigo-50 dark:bg-indigo-900/20"
              ]}>
                <div class="flex items-center gap-3">
                  <div :if={scene.is_locked} class="text-slate-400 dark:text-slate-500">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <div :if={!scene.is_locked} class="text-indigo-600 dark:text-indigo-400">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                      <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
                      <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <div>
                    <p class={["text-sm font-medium", scene.is_locked && "text-slate-400 dark:text-slate-500", !scene.is_locked && "dark:text-slate-200"]}>
                      {scene.title}
                    </p>
                    <p class="text-xs text-slate-400 dark:text-slate-500">{length(scene.quests)} {gettext("quests")}</p>
                  </div>
                </div>
                <.link
                  :if={!scene.is_locked}
                  navigate={~p"/stories/#{@story.id}/scenes/#{scene.id}"}
                  class="inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-indigo-500 transition-colors"
                >
                  {gettext("Start")}
                </.link>
              </div>
            </div>
          </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
