defmodule ObsidianClipperExtensionWeb.ExtensionController do
  use ObsidianClipperExtensionWeb, :controller

  def index(conn, _params) do
    conn
    |> Plug.Conn.resp(:found, "")
    |> Plug.Conn.put_resp_header("location", "https://github.com/jgchristopher/obsidian-clipper")
  end
end
