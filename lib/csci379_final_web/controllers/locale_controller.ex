defmodule Csci379FinalWeb.LocaleController do
  use Csci379FinalWeb, :controller

  @supported_locales ~w(en es)

  def set(conn, %{"locale" => locale}) do
    locale = if locale in @supported_locales, do: locale, else: "en"
    return_to = get_req_header(conn, "referer") |> List.first() || "/"

    conn
    |> put_session(:locale, locale)
    |> redirect(external: return_to)
  end
end
