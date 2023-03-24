defmodule ObsidianClipperExtensionWeb.ExtensionController do
  use ObsidianClipperExtensionWeb, :controller
  alias ObsidianClipperExtension.Browserextension.Manifest

  def index(conn, %{"name" => name, "bookmarklet_code" => bookmarklet_code}) do
    conn =
      conn
      |> put_resp_content_type("application/zip")
      |> put_resp_header(
        "content-disposition",
        ~s[attachment; filename="obsidian-clipper-#{name}-extention.zip"]
      )
      |> send_chunked(:ok)

    zip =
      Zstream.zip([
        Zstream.entry(
          get_zip_filename(name, "bookmarklet.js"),
          get_string_stream(bookmarklet_code)
        ),
        Zstream.entry(
          get_zip_filename(name, "background.js"),
          get_file_stream("background.js", false)
        ),
        Zstream.entry(
          get_zip_filename(name, "manifest.json"),
          get_string_stream(Manifest.manifest(name))
        ),
        Zstream.entry(
          get_zip_filename(name, "icon-16.png"),
          get_file_stream("icon-16.png", true)
        ),
        Zstream.entry(
          get_zip_filename(name, "icon-48.png"),
          get_file_stream("icon-48.png", true)
        ),
        Zstream.entry(
          get_zip_filename(name, "icon-128.png"),
          get_file_stream("icon-128.png", true)
        )
      ])

    Enum.reduce_while(zip, conn, fn chunk, conn ->
      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)
  end

  def index(conn, _params) do
    conn
    |> Plug.Conn.resp(:found, "")
    |> Plug.Conn.put_resp_header("location", "https://github.com/jgchristopher/obsidian-clipper")
  end

  defp get_zip_filename(extension_name, filename) do
    extension_name = "obsidian-clipper-#{extension_name}-extension"
    "#{extension_name}/#{filename}"
  end

  defp get_file_stream(filename, _binary = true) do
    File.stream!(
      Path.join([:code.priv_dir(:obsidian_clipper_extension), "browser_extension/", filename]),
      [],
      2048
    )
  end

  defp get_file_stream(filename, _binary) do
    File.stream!(
      Path.join([:code.priv_dir(:obsidian_clipper_extension), "browser_extension/", filename])
    )
  end

  defp get_string_stream(data) do
    data
    |> URI.decode()
    |> Stream.unfold(&String.next_codepoint/1)
  end
end
