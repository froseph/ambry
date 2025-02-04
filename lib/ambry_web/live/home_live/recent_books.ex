defmodule AmbryWeb.HomeLive.RecentBooks do
  @moduledoc false

  use AmbryWeb, :live_component

  alias Ambry.Books
  alias AmbryWeb.Components.BookTiles

  @limit 25

  data show_load_more?, :boolean, default: true
  data books, :list, default: []

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> load_books()}
  end

  @impl Phoenix.LiveComponent
  def handle_event("load-more", _params, socket) do
    {:noreply, load_books(socket)}
  end

  defp load_books(%{assigns: assigns} = socket) do
    books = Map.get(assigns, :books, [])
    offset = Map.get(assigns, :offset, 0)
    {more_books, has_more?} = Books.get_recent_books!(offset, @limit)
    books = books ++ more_books

    socket
    |> assign(:books, books)
    |> assign(:offset, offset + @limit)
    |> assign(:show_load_more?, has_more?)
  end
end
