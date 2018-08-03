# analysis_server

A long-running process that provides analysis results to other tools.

The analysis server is designed to provide on-going analysis of one or more code
bases as those code bases are changing.

## Using the server

The analysis server is not intended to be used stand-alone, and therefore does
not have a human-friendly user interface.

Clients (typically tools, such as an editor) are expected to run the analysis
server in a separate process and communicate with it using a JSON protocol. The
protocol is specified in the file [`analysis_server/doc/api.html`][api].

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/sdk/issues
[api]: https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/master/pkg/analysis_server/doc/api.html
