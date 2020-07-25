# NIST RS274/NGC G-code Parser and Command Tokenizer
# Parses modal G and M commands, word addresses, parameters, and comments

class GcodeCommand
  (raw-line = '') ->
    @raw = raw-line
    @comment = null
    @cmd = null        # e.g. 'G1', 'M104', 'G28'
    @words = {}        # e.g. { X: 10.0, Y: 20.0, E: 1.5, F: 3000.0 }

  has: (letter) ->
    @words[letter]?

  get: (letter, default-val = null) ->
    if @words[letter]? then @words[letter] else default-val

class GcodeParser
  @parse-line = (line) ->
    cmd-obj = new GcodeCommand line
    trimmed = line.trim!
    if trimmed.length == 0
      return cmd-obj

    # Extract semicolon comments
    semi-idx = trimmed.index-of ';'
    clean-code = trimmed
    if semi-idx != -1
      cmd-obj.comment = trimmed.slice(semi-idx + 1).trim!
      clean-code = trimmed.slice(0, semi-idx).trim!

    # Extract parenthesis comments
    paren-open = clean-code.index-of '('
    paren-close = clean-code.index-of ')'
    if paren-open != -1 and paren-close > paren-open
      cmd-obj.comment = clean-code.slice(paren-open + 1, paren-close).trim!
      clean-code = clean-code.slice(0, paren-open) + clean-code.slice(paren-close + 1)
      clean-code = clean-code.trim!

    if clean-code.length == 0
      return cmd-obj

    # Regex token match: Letter followed by number
    tokens = clean-code.match /[A-Za-z][-+]?[0-9]*\.?[0-9]+/g
    if not tokens? or tokens.length == 0
      return cmd-obj

    # First token is typically command letter + number, e.g. G1 or M104
    cmd-token = tokens[0].to-upper-case!
    first-letter = cmd-token.char-at 0
    if first-letter == 'G' or first-letter == 'M' or first-letter == 'T'
      cmd-obj.cmd = cmd-token
      # Subsequent tokens are word parameters
      for i from 1 til tokens.length
        t = tokens[i]
        letter = t.char-at(0).to-upper-case!
        num = parse-float t.slice(1)
        cmd-obj.words[letter] = num
    else
      # Modal continuation without explicit G/M command
      for t in tokens
        letter = t.char-at(0).to-upper-case!
        num = parse-float t.slice(1)
        cmd-obj.words[letter] = num

    cmd-obj

  @parse-text = (text) ->
    lines = text.split /\r?\n/
    commands = []
    for line in lines
      cmd = @parse-line line
      if cmd.cmd? or Object.keys(cmd.words).length > 0
        commands.push cmd
    commands

module.exports = {
  GcodeCommand
  GcodeParser
}
