defmodule Csci379FinalWeb.LocalePlug do
  import Plug.Conn

  @supported_locales ~w(en es)

  def init(opts), do: opts

  def call(conn, _opts) do
    locale =
      get_session(conn, :locale) ||
        conn.params["locale"] ||
        "en"

    locale = if locale in @supported_locales, do: locale, else: "en"

    Gettext.put_locale(Csci379FinalWeb.Gettext, locale)
    assign(conn, :locale, locale)
  end
end
