defmodule ObsidianClipperExtensionWeb.ExtensionApiJSON do
  def index(%{link: link}) do
    %{data: %{link: link}}
  end
end
