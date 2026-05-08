defmodule Csci379Final.AI.GeneratorPort do
  @callback generate_story(topic :: String.t()) ::
              {:ok, map()} | {:error, String.t()}

  @callback grade_answer(question :: String.t(), user_answer :: String.t()) ::
              {:ok, %{is_correct: boolean(), feedback: String.t()}} | {:error, String.t()}
end
