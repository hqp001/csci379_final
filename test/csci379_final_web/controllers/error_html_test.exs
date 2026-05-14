defmodule Csci379FinalWeb.ErrorHTMLTest do
  use Csci379FinalWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    assert render_to_string(Csci379FinalWeb.ErrorHTML, "404", "html", []) =~ "Page not found"
  end

  test "renders 500.html" do
    assert render_to_string(Csci379FinalWeb.ErrorHTML, "500", "html", []) =~ "Something went wrong"
  end

  test "render/2 returns generic status message for unknown templates" do
    assert Csci379FinalWeb.ErrorHTML.render("418.html", %{}) =~ "I'm a teapot"
  end
end
