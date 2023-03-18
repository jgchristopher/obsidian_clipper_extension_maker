defmodule ObsidianClipperExtensionWeb.ExtensionController do
  use ObsidianClipperExtensionWeb, :controller

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
          "obsidian-clipper-#{name}-extension/bookmarklet.js",
          bookmarklet_code |> URI.decode() |> Stream.unfold(&String.next_codepoint/1)
        ),
        Zstream.entry(
          "obsidian-clipper-#{name}-extension/background.js",
          File.stream!(Path.join(__DIR__, "../../../browserextension/background.js"))
        ),
        Zstream.entry(
          "obsidian-clipper-#{name}-extension/manifest.json",
          EEx.eval_file(Path.join(__DIR__, "../../../browserextension/manifest.json.eex"),
            name: name
          )
          |> Stream.unfold(&String.next_codepoint/1)
        ),
        Zstream.entry(
          "obsidian-clipper-#{name}-extension/icon-16.png",
          File.stream!(Path.join(__DIR__, "../../../browserextension/icon-16.png"), [], 2048)
        ),
        Zstream.entry(
          "obsidian-clipper-#{name}-extension/icon-48.png",
          File.stream!(Path.join(__DIR__, "../../../browserextension/icon-48.png"), [], 2048)
        ),
        Zstream.entry(
          "obsidian-clipper-#{name}-extension/icon-128.png",
          File.stream!(
            Path.join(__DIR__, "../../../browserextension/icon-128.png"),
            [],
            2048
          )
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
    render(conn, :index)
  end
end
