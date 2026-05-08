defmodule Csci379FinalWeb.Components.QuestCard do
  use Phoenix.Component

  @doc """
  A card wrapping a quest question with a type label and a left-border primary accent.
  The inner_block holds the answer UI: multiple-choice buttons, text input, or feedback.

  ## Examples

      <.quest_card type={:multiple_choice} question="What year did Rome fall?">
        <!-- answer options -->
      </.quest_card>

      <.quest_card type={:short_answer} question="Explain the causes of WWI.">
        <textarea ...></textarea>
      </.quest_card>
  """
  attr :type, :atom, required: true, values: [:multiple_choice, :fill_blank, :short_answer]
  attr :question, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def quest_card(assigns) do
    ~H"""
    <div class={["rounded-2xl border border-slate-200 bg-white overflow-hidden shadow-sm", @class]}>
      <div class="border-l-4 border-indigo-600 px-6 pt-5 pb-4">
        <p class="text-xs font-bold uppercase tracking-widest text-indigo-500 mb-2">
          {quest_type_label(@type)}
        </p>
        <p class="text-base font-semibold text-slate-900 leading-snug">{@question}</p>
      </div>
      <div class="px-6 py-4 border-t border-slate-100">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp quest_type_label(:multiple_choice), do: "Multiple Choice"
  defp quest_type_label(:fill_blank), do: "Fill in the Blank"
  defp quest_type_label(:short_answer), do: "Short Answer"
end
