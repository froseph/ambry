defmodule AmbryWeb.Admin.PersonLive.Index do
  @moduledoc """
  LiveView for person admin interface.
  """

  use AmbryWeb, :live_view

  import AmbryWeb.Admin.PaginationHelpers

  alias Ambry.People
  alias Ambry.People.Person

  alias AmbryWeb.Admin.Components.AdminNav
  alias AmbryWeb.Admin.PersonLive.FormComponent
  alias AmbryWeb.Components.Modal

  alias Surface.Components.{Form, LivePatch}
  alias Surface.Components.Form.{Field, TextInput}

  on_mount {AmbryWeb.UserLiveAuth, :ensure_mounted_current_user}
  on_mount {AmbryWeb.Admin.Auth, :ensure_mounted_admin_user}

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {:ok, maybe_update_people(socket, params, true)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> maybe_update_people(params)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    person = People.get_person!(id)

    socket
    |> assign(:page_title, person.name)
    |> assign(:person, person)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Person")
    |> assign(:person, %Person{authors: [], narrators: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing People")
    |> assign(:person, nil)
  end

  defp maybe_update_people(socket, params, force \\ false) do
    old_list_opts = get_list_opts(socket)
    new_list_opts = get_list_opts(params)
    list_opts = Map.merge(old_list_opts, new_list_opts)

    if list_opts != old_list_opts || force do
      {people, has_more?} = list_people(list_opts)

      socket
      |> assign(:list_opts, list_opts)
      |> assign(:has_more?, has_more?)
      |> assign(:people, people)
    else
      socket
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    person = People.get_person!(id)

    case People.delete_person(person) do
      :ok ->
        list_opts = get_list_opts(socket)

        params = %{
          "filter" => to_string(list_opts.filter),
          "page" => to_string(list_opts.page)
        }

        {:noreply,
         socket
         |> maybe_update_people(params, true)
         |> put_flash(:info, "Person deleted successfully")}

      {:error, {:has_authored_books, books}} ->
        message = """
        Can't delete person because they have authored the following books:
        #{Enum.join(books, ", ")}.
        You must delete the books before you can delete this person.
        """

        {:noreply, put_flash(socket, :error, message)}

      {:error, {:has_narrated_books, books}} ->
        message = """
        Can't delete person because they have narrated the following books:
        #{Enum.join(books, ", ")}.
        You must delete the books before you can delete this person.
        """

        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    socket = maybe_update_people(socket, %{"filter" => query, "page" => "1"})
    list_opts = get_list_opts(socket)

    {:noreply,
     push_patch(socket, to: Routes.admin_person_index_path(socket, :index, patch_opts(list_opts)))}
  end

  defp list_people(opts) do
    People.list_people(page_to_offset(opts.page), limit(), opts.filter)
  end
end
