defmodule Csci379FinalWeb.ProfileLive do
  use Csci379FinalWeb, :live_view

  alias Csci379Final.Learning
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    stats = Learning.get_user_stats(user.id)
    recent = Learning.list_recent_completions(user.id)
    xp_history = Learning.list_xp_history(user.id)
    completed_stories = Learning.list_completed_stories(user.id)
    story_progress = Learning.list_story_progress(user.id)

    selected_story_id =
      case completed_stories do
        [first | _] -> first.id
        [] -> nil
      end

    {:ok,
     socket
     |> assign(:page_title, "Profile")
     |> assign(:user, user)
     |> assign(:stats, stats)
     |> assign(:recent_completions, recent)
     |> assign(:xp_history, xp_history)
     |> assign(:completed_stories, completed_stories)
     |> assign(:story_progress, story_progress)
     |> assign(:selected_story_id, selected_story_id)}
  end

  def handle_event("chart_mounted", _params, socket) do
    {:noreply, push_chart_data(socket)}
  end

  def handle_event("accuracy_mounted", _params, socket) do
    %{correct_attempts: correct, total_attempts: total} = socket.assigns.stats
    {:noreply, push_event(socket, "accuracy_data", %{correct: correct, incorrect: total - correct})}
  end

  def handle_event("select_story", %{"story_id" => story_id}, socket) do
    socket =
      socket
      |> assign(:selected_story_id, String.to_integer(story_id))
      |> push_chart_data()

    %{correct_attempts: correct, total_attempts: total} = socket.assigns.stats
    {:noreply, push_event(socket, "accuracy_data", %{correct: correct, incorrect: total - correct})}
  end

  defp push_chart_data(%{assigns: %{selected_story_id: nil}} = socket) do
    push_event(socket, "chart_data", %{labels: [], values: []})
  end

  defp push_chart_data(%{assigns: %{selected_story_id: story_id, current_scope: scope}} = socket) do
    history = Learning.list_xp_by_story(scope.user.id, story_id)
    push_event(socket, "chart_data", %{
      labels: Enum.map(history, & &1.label),
      values: Enum.map(history, & &1.xp)
    })
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto p-6">
      <.page_header>Profile</.page_header>

      <%!-- User info --%>
      <div class="flex items-center gap-4 mb-8">
        <div class="flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-indigo-50 dark:bg-indigo-900/30 text-2xl font-bold text-indigo-600 dark:text-indigo-400">
          {String.first(String.upcase(@user.email))}
        </div>
        <div>
          <p class="text-base font-semibold">{@user.email}</p>
          <p class="text-sm font-bold text-indigo-600">{@stats.total_xp} XP total</p>
        </div>
      </div>

      <%!-- Stats grid --%>
      <div class="grid grid-cols-3 gap-4 mb-8">
        <.stat_card value={to_string(@stats.scenes_completed)} label={gettext("Scenes")} />
        <.stat_card value={to_string(@stats.total_attempts)} label={gettext("Quests")} />
        <.stat_card value={accuracy(@stats)} label={gettext("Accuracy")} />
      </div>

      <%!-- Charts row --%>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <%!-- Accuracy doughnut --%>
        <div class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-4">
          <h2 class="text-sm font-semibold mb-3 text-slate-600 dark:text-slate-300">{gettext("Quest Accuracy")}</h2>
          <%= if @stats.total_attempts == 0 do %>
            <div class="flex items-center justify-center h-36 text-xs text-slate-400">No attempts yet</div>
          <% else %>
            <div id="accuracy-chart-wrapper" phx-update="ignore">
              <div style="height: 160px; position: relative;">
                <canvas
                  id="accuracy-chart"
                  phx-hook="AccuracyChart"
                  phx-mounted={JS.push("accuracy_mounted")}
                />
              </div>
            </div>
          <% end %>
        </div>

        <%!-- XP per scene bar --%>
        <div class="md:col-span-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-4">
          <div class="flex items-center justify-between mb-3">
            <h2 class="text-sm font-semibold text-slate-600 dark:text-slate-300">{gettext("XP per Scene")}</h2>
            <form :if={@completed_stories != []} phx-change="select_story">
              <select
                name="story_id"
                class="text-xs rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-2 py-1 text-slate-700 dark:text-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option :for={story <- @completed_stories} value={story.id} selected={@selected_story_id == story.id}>
                  {story.title}
                </option>
              </select>
            </form>
          </div>
          <%= if @completed_stories == [] do %>
            <div class="flex items-center justify-center h-36 text-xs text-slate-400">Complete scenes to see XP</div>
          <% else %>
            <div style="height: 160px;">
              <canvas
                id="xp-chart"
                phx-hook="XpChart"
                phx-mounted={JS.push("chart_mounted")}
              />
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Story progress bars --%>
      <div class="mb-8">
        <h2 class="text-lg font-semibold mb-4">{gettext("Story Progress")}</h2>
        <%= if @story_progress == [] do %>
          <div class="rounded-xl border border-dashed border-slate-200 py-8 text-center">
            <p class="text-sm text-slate-400">Create a story to track your progress.</p>
            <.link navigate={~p"/stories/new"} class="mt-2 inline-block text-sm text-indigo-600 hover:text-indigo-500">
              Create your first story →
            </.link>
          </div>
        <% else %>
          <div class="space-y-3">
            <div
              :for={story <- @story_progress}
              class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-3"
            >
              <div class="flex items-center justify-between mb-2">
                <p class="text-sm font-medium truncate mr-4">{story.title}</p>
                <span class="text-xs text-slate-400 shrink-0">{story.completed_scenes}/{story.total_scenes} scenes</span>
              </div>
              <div class="h-2 rounded-full bg-slate-100 dark:bg-slate-700 overflow-hidden">
                <div
                  class="h-2 rounded-full bg-indigo-500 transition-all duration-500"
                  style={"width: #{progress_pct(story)}%"}
                />
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%!-- Recent activity --%>
      <h2 class="mb-3 text-lg font-semibold">{gettext("Recent Activity")}</h2>

      <div :if={@recent_completions == []} class="rounded-xl border border-dashed border-slate-200 py-10 text-center">
        <p class="text-sm text-slate-400">No completed scenes yet.</p>
        <.link navigate={~p"/dashboard"} class="mt-2 inline-block text-sm text-indigo-600 hover:text-indigo-500">
          Start a story →
        </.link>
      </div>

      <div class="space-y-2">
        <div
          :for={completion <- @recent_completions}
          class="flex items-center justify-between rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-3"
        >
          <div>
            <p class="text-sm font-medium">{completion.scene.title}</p>
            <p class="text-xs text-slate-400 dark:text-slate-500">
              {Calendar.strftime(completion.completed_at, "%b %d, %Y")}
            </p>
          </div>
          <span class="text-sm font-bold text-indigo-600">+{completion.xp_earned} XP</span>
        </div>
      </div>
    </div>
    """
  end

  defp accuracy(%{total_attempts: 0}), do: "—"

  defp accuracy(%{correct_attempts: correct, total_attempts: total}) do
    "#{trunc(correct / total * 100)}%"
  end

  defp progress_pct(%{total_scenes: 0}), do: 0

  defp progress_pct(%{completed_scenes: c, total_scenes: t}) do
    trunc(c / t * 100)
  end
end
