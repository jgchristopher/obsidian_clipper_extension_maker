defmodule ObsidianClipperExtensionWeb.ExtensionApiController do
  use ObsidianClipperExtensionWeb, :controller
  alias ObsidianClipperExtension.Browserextension.Manifest

  def index(conn, params) do
    name = params["name"]
    bookmarklet_code = params["bookmarklet_code"]

    filename = "obsidian-clipper-#{name}-extension.zip"

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
    |> Stream.into(File.stream!("/tmp/#{filename}"))
    |> Stream.run()

    local_zip = File.read!("/tmp/#{filename}")

    ExAws.S3.put_object("obsidianclipper", filename, local_zip)
    |> ExAws.request!()

    {:ok, link} =
      ExAws.Config.new(:s3) |> ExAws.S3.presigned_url(:get, "obsidianclipper", filename)

    File.rm!("/tmp/#{filename}")

    render(conn, :index, link: link)
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
