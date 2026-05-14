defmodule Csci379FinalWeb.SceneLive.Show do
  use Csci379FinalWeb, :live_view

  alias Csci379Final.{Learning, Stories, AI}

  def mount(%{"story_id" => story_id_str, "id" => scene_id_str}, _session, socket) do
    story_id = String.to_integer(story_id_str)
    scene_id = String.to_integer(scene_id_str)
    scope = socket.assigns.current_scope

    _story = Stories.get_story!(story_id, scope)
    scene = Learning.get_scene_with_quests!(scene_id, story_id)

    if scene.is_locked do
      {:ok,
       socket
       |> put_flash(:error, gettext("This scene is locked."))
       |> push_navigate(to: ~p"/stories/#{story_id}")}
    else
      completion = Learning.get_scene_completion(scope.user.id, scene_id)

      base =
        socket
        |> assign(:page_title, scene.title)
        |> assign(:scene, scene)
        |> assign(:story_id, story_id)
        |> assign(:quests, scene.quests)
        |> assign(:quest_index, 0)
        |> assign(:answers, %{})
        |> assign(:current_answer, "")
        |> assign(:grading_ref, nil)

      if completion do
        {:ok, base |> assign(:phase, :already_completed) |> assign(:xp_earned, completion.xp_earned)}
      else
        {:ok, base |> assign(:phase, :answering) |> assign(:xp_earned, 0)}
      end
    end
  end

  def handle_event("answer_changed", %{"answer" => answer}, socket) do
    {:noreply, assign(socket, :current_answer, answer)}
  end

  def handle_event("submit_answer", params, socket) do
    answer = params["answer"] || socket.assigns.current_answer
    quest = Enum.at(socket.assigns.quests, socket.assigns.quest_index)

    case quest.type do
      :short_answer ->
        parent = self()
        ref = make_ref()

        Task.start(fn ->
          result = AI.grade_answer(quest.question, answer)
          send(parent, {:graded, ref, answer, result})
        end)

        {:noreply,
         socket
         |> assign(:phase, :grading)
         |> assign(:current_answer, answer)
         |> assign(:grading_ref, ref)}

      _ ->
        {is_correct, feedback} = grade_deterministic(quest, answer)
        Learning.record_attempt(socket.assigns.current_scope, quest.id, answer, is_correct, feedback)
        answers = Map.put(socket.assigns.answers, quest.id, %{answer: answer, is_correct: is_correct, feedback: feedback})

        {:noreply,
         socket
         |> assign(:phase, :feedback)
         |> assign(:current_answer, answer)
         |> assign(:answers, answers)}
    end
  end

  def handle_event("next_quest", _params, socket) do
    next_index = socket.assigns.quest_index + 1

    if next_index >= length(socket.assigns.quests) do
      correct_count = Enum.count(socket.assigns.answers, fn {_, v} -> v.is_correct end)

      {:ok, xp} =
        Learning.complete_scene(
          socket.assigns.current_scope,
          socket.assigns.scene.id,
          correct_count,
          length(socket.assigns.quests)
        )

      {:noreply,
       socket
       |> assign(:phase, :complete)
       |> assign(:xp_earned, xp)
       |> assign(:quest_index, next_index)}
    else
      {:noreply,
       socket
       |> assign(:phase, :answering)
       |> assign(:quest_index, next_index)
       |> assign(:current_answer, "")}
    end
  end

  def handle_info({:graded, ref, answer, result}, socket) do
    if ref == socket.assigns.grading_ref do
      quest = Enum.at(socket.assigns.quests, socket.assigns.quest_index)

      {is_correct, feedback} =
        case result do
          {:ok, %{is_correct: is_correct, feedback: feedback}} -> {is_correct, feedback}
          {:error, _} -> {false, gettext("Could not grade your answer.")}
        end

      Learning.record_attempt(socket.assigns.current_scope, quest.id, answer, is_correct, feedback)
      answers = Map.put(socket.assigns.answers, quest.id, %{answer: answer, is_correct: is_correct, feedback: feedback})

      {:noreply,
       socket
       |> assign(:phase, :feedback)
       |> assign(:answers, answers)
       |> assign(:grading_ref, nil)}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6">
      <.page_header
        back_navigate={~p"/stories/#{@story_id}"}
        back_label={gettext("Back to Story")}
      >
        {@scene.title}
        <:subtitle :if={@scene.description}>{@scene.description}</:subtitle>
      </.page_header>

      <%!-- Already completed banner --%>
      <div
        :if={@phase == :already_completed}
        class="mt-8 rounded-xl border border-emerald-200 dark:border-emerald-800 bg-emerald-50 dark:bg-emerald-900/20 p-8 text-center"
      >
        <div class="text-4xl mb-2">✓</div>
        <h2 class="text-xl font-bold text-emerald-700 dark:text-emerald-400">{gettext("Already Completed")}</h2>
        <p class="mt-1 text-sm text-slate-600 dark:text-slate-400">
          {gettext("You earned %{xp} XP on this scene.", xp: @xp_earned)}
        </p>
        <.link
          navigate={~p"/stories/#{@story_id}"}
          class="inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-emerald-500 transition-colors mt-4"
        >
          {gettext("Back to Story")}
        </.link>
      </div>

      <%!-- Active quest area --%>
      <div :if={@phase not in [:already_completed, :complete]}>
        <.progress_bar current={@quest_index + 1} total={length(@quests)} class="mt-6" />

        <% current_quest = Enum.at(@quests, @quest_index) %>

        <.quest_card type={current_quest.type} question={current_quest.question} class="mt-4">
          <%!-- Grading spinner --%>
          <div :if={@phase == :grading} class="flex items-center gap-3 text-slate-500">
            <svg class="h-5 w-5 animate-spin text-indigo-600" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
            <span class="text-sm">{gettext("Grading your answer…")}</span>
          </div>

          <%!-- Multiple choice options --%>
          <div
            :if={@phase == :answering and current_quest.type == :multiple_choice}
            class="grid grid-cols-1 gap-3 sm:grid-cols-2"
          >
            <button
              :for={option <- current_quest.options}
              phx-click="submit_answer"
              phx-value-answer={option.key}
              class="flex items-start gap-3 rounded-lg border border-slate-200 dark:border-slate-600 px-4 py-3 text-left text-sm transition hover:border-indigo-600 hover:bg-indigo-50/50 dark:hover:bg-indigo-900/20 dark:bg-slate-800"
            >
              <span class="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full border border-slate-200 dark:border-slate-600 text-xs font-bold uppercase dark:text-slate-300">
                {option.key}
              </span>
              <span class="text-slate-700 dark:text-slate-300">{option.text}</span>
            </button>
          </div>

          <%!-- Fill in the blank input --%>
          <form
            :if={@phase == :answering and current_quest.type == :fill_blank}
            phx-submit="submit_answer"
          >
            <input
              type="text"
              name="answer"
              value={@current_answer}
              phx-change="answer_changed"
              placeholder={gettext("Type your answer…")}
              autocomplete="off"
              class="block w-full rounded-xl border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 transition-colors"
            />
            <button type="submit" disabled={@current_answer == ""} class="inline-flex items-center justify-center gap-2 rounded-xl bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-indigo-500 transition-colors mt-3 disabled:opacity-50 disabled:cursor-not-allowed">
              {gettext("Submit")}
            </button>
          </form>

          <%!-- Short answer textarea --%>
          <form
            :if={@phase == :answering and current_quest.type == :short_answer}
            phx-submit="submit_answer"
          >
            <textarea
              name="answer"
              phx-change="answer_changed"
              placeholder={gettext("Write your answer…")}
              rows="4"
              class="block w-full rounded-xl border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 transition-colors resize-none"
            >{@current_answer}</textarea>
            <button type="submit" disabled={@current_answer == ""} class="inline-flex items-center justify-center gap-2 rounded-xl bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-indigo-500 transition-colors mt-3 disabled:opacity-50 disabled:cursor-not-allowed">
              {gettext("Submit")}
            </button>
          </form>

          <%!-- Feedback after answering --%>
          <div :if={@phase == :feedback}>
            <% result = Map.get(@answers, current_quest.id) %>
            <.feedback_block
              :if={result}
              is_correct={result.is_correct}
              feedback={result.feedback}
              correct_answer={
                if current_quest.type != :short_answer and !result.is_correct,
                  do: display_correct_answer(current_quest)
              }
            />
            <button phx-click="next_quest" class="inline-flex items-center justify-center gap-2 rounded-xl bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-indigo-500 transition-colors mt-4">
              {if @quest_index + 1 >= length(@quests), do: gettext("Complete Scene →"), else: gettext("Next Quest →")}
            </button>
          </div>
        </.quest_card>
      </div>

      <%!-- Completion banner --%>
      <div
        :if={@phase == :complete}
        class="mt-8 rounded-xl border border-indigo-200 dark:border-indigo-800 bg-indigo-50 dark:bg-indigo-900/20 p-8 text-center"
      >
        <div class="text-5xl mb-3">🎉</div>
        <h2 class="text-2xl font-bold text-indigo-600">{gettext("Scene Complete!")}</h2>
        <p class="mt-2 text-3xl font-bold text-indigo-600">+{@xp_earned} XP</p>
        <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">
          {Enum.count(@answers, fn {_, v} -> v.is_correct end)} / {length(@quests)} {gettext("correct")}
        </p>
        <.link navigate={~p"/stories/#{@story_id}"} class="inline-flex items-center justify-center gap-2 rounded-xl bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-indigo-500 transition-colors mt-6">
          {gettext("Back to Story")}
        </.link>
      </div>
    </div>
    """
  end

  defp grade_deterministic(quest, user_answer) do
    is_correct = normalize(user_answer) == normalize(quest.correct_answer)
    feedback = if is_correct, do: quest.explanation || gettext("Correct!"), else: quest.explanation || gettext("Incorrect.")
    {is_correct, feedback}
  end

  defp normalize(s), do: s |> String.trim() |> String.downcase()

  defp display_correct_answer(%{type: :multiple_choice, options: options, correct_answer: key}) do
    option = Enum.find(options, fn o -> o.key == key end)
    label = if option, do: option.text, else: key
    "#{String.upcase(key)}: #{label}"
  end

  defp display_correct_answer(%{correct_answer: answer}), do: answer
end
