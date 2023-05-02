defmodule ObsidianClipperExtensionWeb.ExtensionApiJSON do
  def index(%{link: link}) do
    IO.puts("The Link is: ")
    IO.puts(link)

    %{data: %{link: link}}
  end
end
