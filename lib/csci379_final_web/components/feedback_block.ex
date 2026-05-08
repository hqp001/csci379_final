defmodule Csci379FinalWeb.Components.FeedbackBlock do
  use Phoenix.Component

  @doc """
  Displays correct/incorrect feedback after a quest answer is submitted.

  ## Examples

      <.feedback_block is_correct={true} feedback="Great job!" />
      <.feedback_block is_correct={false} feedback="Not quite." correct_answer="476 AD" />
  """
  attr :is_correct, :boolean, required: true
  attr :feedback, :string, default: nil
  attr :correct_answer, :string, default: nil

  def feedback_block(assigns) do
    ~H"""
    <div class={[
      "rounded-xl p-4 flex items-start gap-3 border",
      @is_correct && "bg-emerald-50 border-emerald-200",
      !@is_correct && "bg-red-50 border-red-200"
    ]}>
      <div class={[
        "mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-xs font-bold",
        @is_correct && "bg-emerald-600 text-white",
        !@is_correct && "bg-red-600 text-white"
      ]}>
        {if @is_correct, do: "✓", else: "✗"}
      </div>
      <div class="flex-1 min-w-0">
        <p class={["text-sm font-semibold", @is_correct && "text-emerald-800", !@is_correct && "text-red-800"]}>
          {if @is_correct, do: "Correct!", else: "Incorrect"}
        </p>
        <p :if={@feedback} class="mt-1 text-sm text-slate-600">{@feedback}</p>
        <p :if={@correct_answer} class="mt-1.5 text-xs text-slate-500">
          Correct answer: <span class="font-medium">{@correct_answer}</span>
        </p>
      </div>
    </div>
    """
  end
end
