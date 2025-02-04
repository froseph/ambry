defmodule Ambry.FileUtils do
  @moduledoc """
  Utility functions for managing files on disk.
  """

  import Ecto.Query

  alias Ambry.Books.Book
  alias Ambry.{Paths, Repo}
  alias Ambry.People.Person

  require Logger

  @doc """
  Checks the given image web_path to see if it's used by any other books or
  people, and if not, attempts to delete it from disk.
  """
  def maybe_delete_image(nil), do: :noop

  def maybe_delete_image(web_path) do
    book_count = Repo.one(from b in Book, select: count(b.id), where: b.image_path == ^web_path)

    person_count =
      Repo.one(from p in Person, select: count(p.id), where: p.image_path == ^web_path)

    if book_count + person_count == 0 do
      disk_path = Paths.web_to_disk(web_path)

      try_delete_file(disk_path)
    else
      Logger.warn(fn -> "Not deleting file because it's still in use: #{web_path}" end)
      {:error, :still_in_use}
    end
  end

  @doc """
  Tries to delete all existing media files for a given media.
  """
  def delete_media_files(media) do
    %{
      source_path: source_disk_path,
      mpd_path: mpd_path,
      hls_path: hls_path,
      mp4_path: mp4_path
    } = media

    try_delete_folder(source_disk_path)

    mpd_path |> Paths.web_to_disk() |> try_delete_file()
    hls_path |> Paths.web_to_disk() |> try_delete_file()
    mp4_path |> Paths.web_to_disk() |> try_delete_file()
    hls_path |> Paths.hls_playlist_path() |> Paths.web_to_disk() |> try_delete_file()

    :ok
  end

  @doc """
  Tries to delete the given file.

  Logs output.
  """
  def try_delete_file(nil), do: :noop

  def try_delete_file(disk_path) do
    case File.rm(disk_path) do
      :ok ->
        Logger.info(fn -> "Deleted file: #{disk_path}" end)
        :ok

      {:error, posix} ->
        Logger.warn(fn -> "Couldn't delete file (#{posix}): #{disk_path}" end)
        {:error, posix}
    end
  end

  @doc """
  Tries to delete the given folder.

  Logs output.
  """
  def try_delete_folder(nil), do: :noop

  def try_delete_folder(disk_path) do
    case File.rm_rf(disk_path) do
      {:ok, files_and_dirs} ->
        Enum.each(files_and_dirs, fn path ->
          Logger.info(fn -> "Deleted file/folder: #{path}" end)
        end)

        :ok

      {:error, posix, path} ->
        Logger.warn(fn -> "Couldn't delete file/folder (#{posix}): #{path}" end)
        {:error, posix, path}
    end
  end
end
