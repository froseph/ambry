defmodule AmbryWeb.API.PersonController do
  use AmbryWeb, :controller

  alias Ambry.People

  action_fallback AmbryWeb.FallbackController

  def show(conn, %{"id" => id}) do
    person = People.get_person_with_books!(id)
    render(conn, "show.json", person: person)
  end
end
