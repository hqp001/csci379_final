defmodule Csci379Final.AITest do
  use ExUnit.Case, async: true

  alias Csci379Final.AI
  alias Csci379Final.AI.StubAdapter

  describe "AI facade" do
    test "generate_story/1 delegates to configured adapter" do
      assert {:ok, data} = AI.generate_story(%{topic: "test topic", pdf_data: nil, pdf_name: nil})
      assert is_map(data)
      assert Map.has_key?(data, "title")
      assert Map.has_key?(data, "chapters")
    end

    test "grade_answer/2 delegates to configured adapter" do
      assert {:ok, result} = AI.grade_answer("What is 2+2?", "4")
      assert Map.has_key?(result, :is_correct)
      assert Map.has_key?(result, :feedback)
    end
  end

  describe "StubAdapter" do
    test "generate_story/1 returns valid story structure" do
      assert {:ok, data} = StubAdapter.generate_story(%{topic: "any topic", pdf_data: nil, pdf_name: nil})
      assert is_binary(data["title"])
      assert is_list(data["chapters"])
      assert length(data["chapters"]) > 0

      [chapter | _] = data["chapters"]
      assert is_binary(chapter["title"])
      assert is_list(chapter["scenes"])

      [scene | _] = chapter["scenes"]
      assert is_list(scene["quests"])

      [quest | _] = scene["quests"]
      assert quest["type"] in ["multiple_choice", "fill_blank", "short_answer"]
      assert is_binary(quest["question"])
      assert is_binary(quest["correct_answer"])
    end

    test "grade_answer/2 returns correct grading struct" do
      assert {:ok, %{is_correct: is_correct, feedback: feedback}} =
               StubAdapter.grade_answer("question", "answer")

      assert is_boolean(is_correct)
      assert is_binary(feedback)
    end
  end
end
