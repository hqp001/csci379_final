defmodule Csci379FinalWeb.ProfileLive do
  use Csci379FinalWeb, :live_view

  alias Csci379Final.Learning
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    stats = Learning.get_user_stats(user.id)
    recent = Learning.list_recent_completions(user.id)
    xp_history = Learning.list_xp_history(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Profile")
     |> assign(:user, user)
     |> assign(:stats, stats)
     |> assign(:recent_completions, recent)
     |> assign(:xp_history, xp_history)}
  end

  def handle_event("chart_mounted", _params, socket) do
    history = socket.assigns.xp_history
    labels = Enum.map(history, & &1.date)
    values = Enum.map(history, & &1.xp)
    {:noreply, push_event(socket, "chart_data", %{labels: labels, values: values})}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6">
      <.page_header>Profile</.page_header>

      <%!-- User info --%>
      <div class="flex items-center gap-4 mb-8">
        <div class="flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-indigo-50 text-2xl font-bold text-indigo-600">
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

      <%!-- XP over time chart --%>
      <div class="mb-8">
        <h2 class="mb-3 text-lg font-semibold">{gettext("XP Progress")}</h2>
        <%= if @xp_history == [] do %>
          <div class="rounded-xl border border-dashed border-slate-200 py-10 text-center">
            <p class="text-sm text-slate-400">Complete scenes to see your XP growth.</p>
          </div>
        <% else %>
          <div class="rounded-xl border border-slate-200 bg-white p-4" style="height: 220px;">
            <canvas
              id="xp-chart"
              phx-hook="XpChart"
              phx-mounted={JS.push("chart_mounted")}
            />
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
          class="flex items-center justify-between rounded-lg border border-slate-200 bg-white px-4 py-3"
        >
          <div>
            <p class="text-sm font-medium">{completion.scene.title}</p>
            <p class="text-xs text-slate-400">
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
end
