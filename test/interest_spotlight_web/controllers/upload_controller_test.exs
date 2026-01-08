defmodule InterestSpotlightWeb.UploadControllerTest do
  use InterestSpotlightWeb.ConnCase, async: true

  setup do
    uploads_dir = Application.get_env(:interest_spotlight, :uploads_directory)

    # Create test uploads directory
    test_dir = Path.join([uploads_dir, "test_user", "profile_photo"])
    File.mkdir_p!(test_dir)

    # Create a test file
    test_file_path = Path.join(test_dir, "test.jpg")
    File.write!(test_file_path, "fake image content")

    on_exit(fn ->
      # Clean up test files
      File.rm_rf!(Path.join(uploads_dir, "test_user"))
    end)

    %{test_file_path: test_file_path, uploads_dir: uploads_dir}
  end

  describe "GET /uploads/*path" do
    test "serves an existing file", %{conn: conn} do
      conn = get(conn, ~p"/uploads/test_user/profile_photo/test.jpg")

      assert conn.status == 200
      assert conn.resp_body == "fake image content"
    end

    test "returns 404 for non-existent file", %{conn: conn} do
      conn = get(conn, ~p"/uploads/nonexistent/file.jpg")

      assert conn.status == 404
      assert conn.resp_body == "File not found"
    end

    test "sets correct content-type header for images", %{conn: conn} do
      conn = get(conn, ~p"/uploads/test_user/profile_photo/test.jpg")

      assert get_resp_header(conn, "content-type") == ["image/jpeg; charset=utf-8"]
    end

    test "sets content-disposition header", %{conn: conn} do
      conn = get(conn, ~p"/uploads/test_user/profile_photo/test.jpg")

      [disposition] = get_resp_header(conn, "content-disposition")
      assert disposition =~ "inline"
      assert disposition =~ "test.jpg"
    end
  end
end
