defmodule Csci379Final.AI.GeneratorPort do
  @callback generate_story(%{
              topic: String.t(),
              pdf_data: binary() | nil,
              pdf_name: String.t() | nil
            }) :: {:ok, map()} | {:error, String.t()}

  @callback grade_answer(question :: String.t(), user_answer :: String.t()) ::
              {:ok, %{is_correct: boolean(), feedback: String.t()}} | {:error, String.t()}
end
