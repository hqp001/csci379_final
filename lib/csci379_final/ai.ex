defmodule Csci379Final.AI do
  @behaviour Csci379Final.AI.GeneratorPort

  @impl true
  def generate_story(topic), do: adapter().generate_story(topic)

  @impl true
  def grade_answer(question, user_answer), do: adapter().grade_answer(question, user_answer)

  defp adapter do
    Application.fetch_env!(:csci379_final, :ai_adapter)
  end
end
