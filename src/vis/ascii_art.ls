# ASCII Art Banners and Terminal Formatters
# Produces high-contrast typography and status tables for CLI workflows

class AsciiArt
  @BANNER = """
   ██╗  ██╗███████╗██████╗ ███████╗
   ██║ ██╔╝██╔════╝██╔══██╗██╔════╝
   █████╔╝ █████╗  ██████╔╝█████╗  
   ██╔═██╗ ██╔══╝  ██╔══██╗██╔══╝  
   ██║  ██╗███████╗██║  ██║██║     
   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     
  """

  @TAGLINE = "A 3D slicing, toolpath generation, and kinodynamic motion planning engine in LiveScript."

  @format-header = (title) ->
    sep = "=".repeat 60
    "\n#sep\n  #title\n#sep"

  @format-table = (rows) ->
    # rows: array of [label, value]
    lines = []
    max-label-len = 0
    for r in rows
      if r[0].length > max-label-len
        max-label-len = r[0].length

    for r in rows
      pad = " ".repeat(max-label-len - r[0].length + 2)
      lines.push "  • #{r[0]}:#{pad}#{r[1]}"
    lines.join "\n"

module.exports = AsciiArt
