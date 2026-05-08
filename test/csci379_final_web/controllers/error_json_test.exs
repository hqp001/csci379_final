defmodule Csci379FinalWeb.ErrorJSONTest do
  use Csci379FinalWeb.ConnCase, async: true

  test "renders 404" do
    assert Csci379FinalWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Csci379FinalWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
