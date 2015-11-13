# dev_compiler changelog

## 0.1.11
- moved js runtime files to lib/runtime/dart (`dart_runtime.js` -> `dart/_runtime.js`)
- bug fix to source maps
- initial support for f-bound quantification patterns

## 0.1.10
- added an `--html-report` option to create a file summarizing compilation
  issues
- added a `-f` alias to the `--force-compile` command line option
- removed many info level messages that were informational to the DDC team

## 0.1.9

## 0.1.8
- added a `--version` command-line option
- added a new entry-point - `dev_compiler` - that aliases to `dartdevc`
