defmodule Ambry.Media.Processor.MP4 do
  @moduledoc """
  A media processor that converts a single MP4 to dash & hls streaming format.
  """

  import Ambry.Media.Processor.Shared

  alias Ambry.Media.Media

  @extensions ~w(.mp4 .m4a .m4b)

  def name do
    "Single MP4 As-is"
  end

  def can_run?(%Media{} = media) do
    media |> files(@extensions) |> length() == 1
  end

  def can_run?(filenames) when is_list(filenames) do
    filenames |> filter_filenames(@extensions) |> length() == 1
  end

  def run(media) do
    id = copy!(media)
    create_stream!(media, id)
    finalize!(media, id)
  end

  defp copy!(media) do
    [mp4_file] = files(media, @extensions)
    id = get_id(media)

    File.cp!(
      source_path(media, mp4_file),
      out_path(media, "#{id}.mp4")
    )

    id
  end
end
