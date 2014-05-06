## 0.11.0

* Move handling trailing options from `ArgParser.parse()` into `ArgParser`
  itself. This lets subcommands have different behavior for how they handle
  trailing options.

## 0.10.0+2

* Usage ignores hidden options when determining column widths.
