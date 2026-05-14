defmodule Csci379FinalWeb.Components.List do
  use Phoenix.Component

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="divide-y divide-slate-100 rounded-xl border border-slate-200">
      <li :for={item <- @item} class="px-4 py-3">
        <div>
          <div class="text-sm font-semibold text-slate-700">{item.title}</div>
          <div class="text-sm text-slate-500">{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end
end
