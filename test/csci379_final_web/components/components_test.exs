defmodule Csci379FinalWeb.ComponentsTest do
  use Csci379FinalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias Csci379FinalWeb.Components.{Input, List, Table}
  alias Csci379FinalWeb.Components.QuestCard

  describe "Input component" do
    test "renders hidden input" do
      html =
        render_component(&Input.input/1,
          type: "hidden",
          name: "token",
          value: "abc",
          id: "tok"
        )

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="abc")
    end

    test "renders checkbox input" do
      html =
        render_component(&Input.input/1,
          type: "checkbox",
          name: "agree",
          value: "true",
          id: "agree",
          label: "I agree"
        )

      assert html =~ ~s(type="checkbox")
      assert html =~ "I agree"
    end

    test "renders select input with options and prompt" do
      html =
        render_component(&Input.input/1,
          type: "select",
          name: "color",
          value: "red",
          id: "color",
          label: "Color",
          prompt: "Pick one",
          options: [{"Red", "red"}, {"Blue", "blue"}]
        )

      assert html =~ ~s(Pick one)
      assert html =~ "Red"
    end

    test "renders textarea input" do
      html =
        render_component(&Input.input/1,
          type: "textarea",
          name: "bio",
          value: "Hello",
          id: "bio",
          label: "Bio"
        )

      assert html =~ ~s(<textarea)
      assert html =~ "Bio"
    end

    test "renders text input with error" do
      html =
        render_component(&Input.input/1,
          type: "text",
          name: "username",
          value: "",
          id: "username",
          label: "Username",
          errors: ["can't be blank"]
        )

      assert html =~ "can&#39;t be blank"
    end

    test "translate_errors/2 returns translated error list" do
      errors = [email: {"can't be blank", [validation: :required]}]
      result = Input.translate_errors(errors, :email)
      assert result == ["can't be blank"]
    end

    test "translate_error/1 handles count interpolation" do
      result = Input.translate_error({"should be at least %{count} character(s)", [count: 5, validation: :length]})
      assert result =~ "5"
    end
  end

  describe "List component" do
    test "renders items" do
      html =
        render_component(&List.list/1,
          item: [%{title: "Item One", inner_block: fn _, _ -> "details" end}]
        )

      assert html =~ "Item One"
    end
  end

  describe "Table component" do
    test "renders table with rows and columns" do
      html =
        render_component(&Table.table/1,
          id: "my-table",
          rows: [%{name: "Alice", role: "Admin"}],
          col: [
            %{label: "Name", inner_block: fn _, row -> row.name end},
            %{label: "Role", inner_block: fn _, row -> row.role end}
          ],
          action: []
        )

      assert html =~ "Name"
      assert html =~ "Alice"
    end

    test "renders table with actions column" do
      html =
        render_component(&Table.table/1,
          id: "action-table",
          rows: [%{name: "Bob"}],
          col: [%{label: "Name", inner_block: fn _, row -> row.name end}],
          action: [%{inner_block: fn _, _row -> "Edit" end}]
        )

      assert html =~ "Actions"
      assert html =~ "Bob"
    end

    test "renders table with row_click" do
      html =
        render_component(&Table.table/1,
          id: "clickable",
          rows: [%{id: 1, name: "Carol"}],
          row_id: fn row -> "row-#{row.id}" end,
          row_click: fn row -> "navigate:#{row.id}" end,
          col: [%{label: "Name", inner_block: fn _, row -> row.name end}],
          action: []
        )

      assert html =~ "Carol"
    end
  end

  describe "QuestCard component" do
    test "renders multiple_choice type label" do
      html =
        render_component(&QuestCard.quest_card/1,
          type: :multiple_choice,
          question: "What year?",
          inner_block: [%{inner_block: fn _, _ -> "options" end}]
        )

      assert html =~ "Multiple Choice"
      assert html =~ "What year?"
    end

    test "renders fill_blank type label" do
      html =
        render_component(&QuestCard.quest_card/1,
          type: :fill_blank,
          question: "Fill ___",
          inner_block: [%{inner_block: fn _, _ -> "input" end}]
        )

      assert html =~ "Fill in the Blank"
    end

    test "renders short_answer type label" do
      html =
        render_component(&QuestCard.quest_card/1,
          type: :short_answer,
          question: "Explain X.",
          inner_block: [%{inner_block: fn _, _ -> "textarea" end}]
        )

      assert html =~ "Short Answer"
    end
  end
end
