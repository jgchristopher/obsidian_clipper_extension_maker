defmodule ObsidianClipperExtension.Browserextension.Manifest do
  require EEx
  EEx.function_from_file(:def, :manifest, Path.join(__DIR__, "manifest.json.eex"), [:name])
end
