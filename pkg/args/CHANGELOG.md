## 0.12.0

* Removed public constructors for `ArgResults` and `Option`.
 
* `ArgResults.wasParsed()` can be used to determine if an option was actually
  parsed or the default value is being returned.

* Replaced `isFlag` and `allowMultiple` fields in the `Option` class with a
  three-value `OptionType` enum.
  
* Options may define `valueHelp` which will then be shown in the usage.

## 0.11.0

* Move handling trailing options from `ArgParser.parse()` into `ArgParser`
  itself. This lets subcommands have different behavior for how they handle
  trailing options.

## 0.10.0+2

* Usage ignores hidden options when determining column widths.
