defmodule AmbryWeb.Admin.PersonLive.FormComponent do
  @moduledoc false

  use AmbryWeb, :live_component

  import AmbryWeb.Admin.ParamHelpers, only: [map_to_list: 2]
  import AmbryWeb.Admin.UploadHelpers

  alias Ambry.People
  alias AmbryWeb.Admin.Components.SaveButton

  alias Surface.Components.{Form, LiveFileInput}

  alias Surface.Components.Form.{
    Checkbox,
    ErrorTag,
    Field,
    HiddenInputs,
    Inputs,
    Label,
    TextArea,
    TextInput
  }

  prop title, :string, required: true
  prop person, :any, required: true
  prop action, :atom, required: true
  prop return_to, :string, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket = allow_image_upload(socket)
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{person: person} = assigns, socket) do
    changeset = People.change_person(person, init_person_param(person))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"person" => person_params}, socket) do
    person_params = clean_person_params(person_params)

    changeset =
      socket.assigns.person
      |> People.change_person(person_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    person_params =
      case consume_uploaded_image(socket) do
        {:ok, :no_file} -> person_params
        {:ok, path} -> Map.put(person_params, "image_path", path)
        {:error, :too_many_files} -> raise "too many files"
      end

    save_person(socket, socket.assigns.action, person_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("add-author", _params, socket) do
    params =
      socket.assigns.changeset.params
      |> map_to_list("authors")
      |> Map.update!("authors", fn authors_params ->
        authors_params ++ [%{}]
      end)

    changeset = People.change_person(socket.assigns.person, params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add-narrator", _params, socket) do
    params =
      socket.assigns.changeset.params
      |> map_to_list("narrators")
      |> Map.update!("narrators", fn narrators_params ->
        narrators_params ++ [%{}]
      end)

    changeset = People.change_person(socket.assigns.person, params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp clean_person_params(params) do
    params
    |> map_to_list("authors")
    |> Map.update!("authors", fn authors ->
      Enum.reject(authors, fn author_params ->
        is_nil(author_params["id"]) && author_params["delete"] == "true"
      end)
    end)
    |> map_to_list("narrators")
    |> Map.update!("narrators", fn narrators ->
      Enum.reject(narrators, fn narrator_params ->
        is_nil(narrator_params["id"]) && narrator_params["delete"] == "true"
      end)
    end)
  end

  defp save_person(socket, :edit, person_params) do
    case People.update_person(socket.assigns.person, person_params) do
      {:ok, _person} ->
        {:noreply,
         socket
         |> put_flash(:info, "Person updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_person(socket, :new, person_params) do
    case People.create_person(person_params) do
      {:ok, _person} ->
        {:noreply,
         socket
         |> put_flash(:info, "Person created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp init_person_param(person) do
    %{
      "authors" => Enum.map(person.authors, &%{"id" => &1.id}),
      "narrators" => Enum.map(person.narrators, &%{"id" => &1.id})
    }
  end
end
