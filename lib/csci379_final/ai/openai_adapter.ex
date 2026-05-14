defmodule Csci379Final.AI.OpenAIAdapter do
  @behaviour Csci379Final.AI.GeneratorPort

  @impl true
  def generate_story(%{topic: topic, pdf_data: nil}) do
    call_completion([%{role: "user", content: build_prompt(topic)}])
  end

  def generate_story(%{topic: topic, pdf_data: pdf_data} = params) do
    pdf_name = Map.get(params, :pdf_name) || "document.pdf"

    messages = [
      %{
        role: "user",
        content: [
          %{
            type: "file",
            file: %{filename: pdf_name, file_data: "data:application/pdf;base64,#{pdf_data}"}
          },
          %{type: "text", text: build_prompt(topic)}
        ]
      }
    ]

    call_completion(messages)
  end

  defp call_completion(messages) do
    case OpenAI.chat_completion(
           model: "gpt-4o-mini",
           response_format: %{type: "json_object"},
           messages: messages
         ) do
      {:ok, %{choices: [%{"message" => %{"content" => content}} | _]}} ->
        {:ok, Jason.decode!(content)}

      {:error, reason} ->
        {:error, "OpenAI error: #{inspect(reason)}"}
    end
  rescue
    e -> {:error, "Failed to generate story: #{Exception.message(e)}"}
  end

  @impl true
  def grade_answer(question, user_answer) do
    prompt = """
    You are grading a student's short answer response.

    Question: #{question}
    Student answer: #{user_answer}

    Respond with a JSON object:
    {"is_correct": true or false, "feedback": "brief explanation"}
    """

    case OpenAI.chat_completion(
           model: "gpt-4o-mini",
           response_format: %{type: "json_object"},
           messages: [%{role: "user", content: prompt}]
         ) do
      {:ok, %{choices: [%{"message" => %{"content" => content}} | _]}} ->
        %{"is_correct" => is_correct, "feedback" => feedback} = Jason.decode!(content)
        {:ok, %{is_correct: is_correct, feedback: feedback}}

      {:error, reason} ->
        {:error, "OpenAI error: #{inspect(reason)}"}
    end
  rescue
    e -> {:error, "Failed to grade answer: #{Exception.message(e)}"}
  end

  defp build_prompt(topic) do
    """
    You are a course generator. Generate a structured interactive learning story about: #{topic}

    Return a JSON object with exactly this structure — 2 chapters, 2 scenes per chapter, 3 quests per scene:

    {
      "title": "Story title",
      "chapters": [
        {
          "title": "Chapter title",
          "description": "Chapter description",
          "scenes": [
            {
              "title": "Scene title",
              "description": "Scene description",
              "quests": [
                {
                  "type": "multiple_choice",
                  "question": "Question text?",
                  "options": {"a": "Option A", "b": "Option B", "c": "Option C", "d": "Option D"},
                  "correct_answer": "a",
                  "explanation": "Why this answer is correct."
                },
                {
                  "type": "fill_blank",
                  "question": "Sentence with ___ to fill in.",
                  "options": null,
                  "correct_answer": "the answer",
                  "explanation": "Explanation of the answer."
                },
                {
                  "type": "short_answer",
                  "question": "Open-ended question requiring explanation?",
                  "options": null,
                  "correct_answer": "Model answer for grading.",
                  "explanation": "Explanation of the concept."
                }
              ]
            }
          ]
        }
      ]
    }

    Each scene must have exactly 3 quests in this order: multiple_choice, fill_blank, short_answer.
    Make the content educational, accurate, and engaging.
    """
  end
end
