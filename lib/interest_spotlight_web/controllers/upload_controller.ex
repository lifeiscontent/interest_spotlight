defmodule InterestSpotlightWeb.UploadController do
  use InterestSpotlightWeb, :controller

  @doc """
  Serves an uploaded file from the external filesystem.
  Files are public and can be accessed by anyone with the path.
  """
  def show(conn, %{"path" => path_parts}) do
    uploads_dir = Application.get_env(:interest_spotlight, :uploads_directory)

    # Join path parts (e.g., ["5", "profile_photo", "5.jpg"])
    relative_path = Path.join(path_parts)
    file_path = Path.join([uploads_dir, relative_path])

    if File.exists?(file_path) do
      # Determine content type based on file extension
      content_type = MIME.from_path(file_path)

      # Get just the filename for the header
      filename = List.last(path_parts)

      conn
      |> put_resp_content_type(content_type)
      |> put_resp_header("content-disposition", ~s(inline; filename="#{filename}"))
      |> send_file(200, file_path)
    else
      conn
      |> put_status(:not_found)
      |> text("File not found")
    end
  end
end
