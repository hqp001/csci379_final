defmodule Csci379FinalWeb.StoryLive.New do
  use Csci379FinalWeb, :live_view

  alias Csci379Final.Stories

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "New Story")
     |> assign(:topic, "")
     |> assign(:status, :idle)
     |> assign(:progress, [])
     |> assign(:error, nil)
     |> allow_upload(:source_file, accept: ~w(.txt .md), max_entries: 1, max_file_size: 500_000)}
  end

  def handle_event("validate", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, :topic, topic)}
  end

  def handle_event("create", %{"topic" => topic}, socket) do
    topic = String.trim(topic)

    if topic == "" do
      {:noreply, assign(socket, :error, "Please enter a topic.")}
    else
      file_context =
        consume_uploaded_entries(socket, :source_file, fn %{path: path}, _entry ->
          {:ok, File.read!(path)}
        end)
        |> List.first()

      full_prompt =
        if file_context && file_context != "" do
          "#{topic}\n\nAdditional context from uploaded document:\n#{String.slice(file_context, 0, 4000)}"
        else
          topic
        end

      case Stories.create_story_async(topic, socket.assigns.current_scope) do
        {:ok, story} ->
          Phoenix.PubSub.subscribe(Csci379Final.PubSub, "story:#{story.id}")
          Stories.start_generation(story.id, full_prompt)

          {:noreply,
           socket
           |> assign(:status, :generating)
           |> assign(:progress, [])
           |> assign(:error, nil)}

        {:error, _} ->
          {:noreply, assign(socket, :error, "Something went wrong. Please try again.")}
      end
    end
  end

  def handle_info({:progress, step}, socket) do
    {:noreply, assign(socket, :progress, socket.assigns.progress ++ [step])}
  end

  def handle_info({:story_ready, story_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/stories/#{story_id}")}
  end

  def handle_info({:story_failed, reason}, socket) do
    {:noreply,
     socket
     |> assign(:status, :idle)
     |> assign(:progress, [])
     |> assign(:error, reason)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-[70vh] items-center justify-center px-4">
      <div class="w-full max-w-2xl">
        <%= if @status == :idle do %>
          <h1 class="mb-2 text-center text-4xl font-bold">
            {gettext("What do you want to explore?")}
          </h1>
          <p class="mb-8 text-center text-slate-500">
            {gettext("Enter any topic and we'll build an interactive story for you.")}
          </p>

          <form phx-submit="create" phx-change="validate">
            <div class="flex gap-3">
              <input
                type="text"
                name="topic"
                value={@topic}
                placeholder="e.g. The Roman Empire, Quantum Physics, JavaScript..."
                autofocus
                class="block w-full rounded-xl border border-slate-200 bg-white px-5 py-4 text-base text-slate-900 placeholder:text-slate-400 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 transition-colors"
              />
              <button type="submit" class="rounded-xl bg-amber-400 px-6 py-4 text-base font-bold text-slate-900 hover:bg-amber-300 transition-colors shadow-sm">
                {gettext("Create")}
              </button>
            </div>

            <div class="mt-4">
              <label class="flex cursor-pointer items-center gap-3 rounded-xl border border-dashed border-slate-300 px-5 py-3 text-sm text-slate-500 hover:border-indigo-400 hover:bg-indigo-50/50 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0 text-slate-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM6.293 6.707a1 1 0 010-1.414l3-3a1 1 0 011.414 0l3 3a1 1 0 01-1.414 1.414L11 5.414V13a1 1 0 11-2 0V5.414L7.707 6.707a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                </svg>
                <span>
                  <%= if uploads_to_show = @uploads.source_file.entries do %>
                    <%= case uploads_to_show do %>
                      <% [entry | _] -> %>
                        <span class="text-indigo-600 font-medium">{entry.client_name}</span>
                      <% [] -> %>
                        Upload a reference document <span class="text-slate-400">.txt or .md, optional</span>
                    <% end %>
                  <% end %>
                </span>
                <.live_file_input upload={@uploads.source_file} class="sr-only" />
              </label>
            </div>

            <p :if={@error} class="mt-2 text-sm text-red-600">{@error}</p>
          </form>
        <% else %>
          <div class="text-center">
            <div class="mb-8 flex justify-center">
              <svg
                class="h-12 w-12 animate-spin text-indigo-600"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                />
              </svg>
            </div>

            <h2 class="mb-6 text-2xl font-bold">
              {gettext("Building your story...")}
            </h2>

            <div class="mx-auto max-w-sm space-y-3 text-left">
              <%= for {step, i} <- Enum.with_index(@progress) do %>
                <div class="flex items-center gap-3">
                  <%= if i < length(@progress) - 1 do %>
                    <svg class="h-5 w-5 flex-shrink-0 text-emerald-700" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 00-1.414 0L8 12.586 4.707 9.293a1 1 0 00-1.414 1.414l4 4a1 1 0 001.414 0l8-8a1 1 0 000-1.414z" clip-rule="evenodd" />
                    </svg>
                  <% else %>
                    <svg class="h-5 w-5 flex-shrink-0 animate-spin text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                    </svg>
                  <% end %>
                  <span class={[
                    "text-sm",
                    i < length(@progress) - 1 && "text-slate-400",
                    i == length(@progress) - 1 && "font-medium"
                  ]}>
                    {step}
                  </span>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
