defmodule Ambry.Series do
  @moduledoc """
  Functions for dealing with Series.
  """

  import Ambry.SearchUtils
  import Ecto.Query

  alias Ambry.Repo
  alias Ambry.Series.{Series, SeriesBook}

  @doc """
  Returns a limited list of series and whether or not there are more.

  By default, it will limit to the first 10 results. Supply `offset` and `limit`
  to change this. Also can optionally filter by the given `filter` string.

  ## Examples

      iex> list_series()
      {[%Series{}, ...], true}

  """
  def list_series(offset \\ 0, limit \\ 10, filter \\ nil) do
    over_limit = limit + 1

    query =
      from s in Series,
        offset: ^offset,
        limit: ^over_limit,
        order_by: :name

    query =
      if filter do
        name_query = "%#{filter}%"

        from s in query, where: ilike(s.name, ^name_query)
      else
        query
      end

    series = Repo.all(query)
    series_to_return = Enum.slice(series, 0, limit)

    {series_to_return, series != series_to_return}
  end

  @doc """
  Gets a single series.

  Raises `Ecto.NoResultsError` if the Series does not exist.

  ## Examples

      iex> get_series!(123)
      %Series{}

      iex> get_series!(456)
      ** (Ecto.NoResultsError)

  """
  def get_series!(id) do
    series_book_query = from sb in SeriesBook, order_by: [asc: sb.book_number]

    Series
    |> preload(series_books: ^{series_book_query, [:book]})
    |> Repo.get!(id)
  end

  @doc """
  Creates a series.

  ## Examples

      iex> create_series(%{field: value})
      {:ok, %Series{}}

      iex> create_series(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_series(attrs \\ %{}) do
    %Series{}
    |> Series.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a series.

  ## Examples

      iex> update_series(series, %{field: new_value})
      {:ok, %Series{}}

      iex> update_series(series, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_series(%Series{} = series, attrs) do
    series
    |> Series.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a series.

  ## Examples

      iex> delete_series(series)
      {:ok, %Series{}}

      iex> delete_series(series)
      {:error, %Ecto.Changeset{}}

  """
  def delete_series(%Series{} = series) do
    Repo.delete(series)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking series changes.

  ## Examples

      iex> change_series(series)
      %Ecto.Changeset{data: %Series{}}

  """
  def change_series(%Series{} = series, attrs \\ %{}) do
    Series.changeset(series, attrs)
  end

  @doc """
  Gets a series and all of its books.

  Books are listed in ascending order based on series book number.
  """
  def get_series_with_books!(series_id) do
    series_book_query = from sb in SeriesBook, order_by: [asc: sb.book_number]

    Series
    |> preload(series_books: ^{series_book_query, [book: [:authors, series_books: :series]]})
    |> Repo.get!(series_id)
  end

  @doc """
  Finds series that match a query string.

  Returns a list of tuples of the form `{jaro_distance, series}`.
  """
  def search(query_string, limit \\ 15) do
    name_query = "%#{query_string}%"
    query = from s in Series, where: ilike(s.name, ^name_query), limit: ^limit
    series_book_query = from sb in SeriesBook, order_by: [asc: sb.book_number]

    query
    |> preload(series_books: ^{series_book_query, [book: [:authors, series_books: :series]]})
    |> Repo.all()
    |> sort_by_jaro(query_string, :name)
  end

  @doc """
  Returns all series for use in `Select` components.
  """
  def for_select do
    query = from s in Series, select: {s.name, s.id}, order_by: s.name

    Repo.all(query)
  end
end
