# Starting the server

The analysis server is run by executing the `dart language_server` command,
which is implemented in the `dartdev` package. That command invokes the `main`
function in `bin/server.dart`. The only thing `main` does is to create an
instance of `ServerStarter` and pass the command-line arguments to it.

The starter interprets the command-line arguments in order to create and
initialize an `AnalysisServer`.

Even though the command-line tools don't use it that way, the analysis server is
designed to be a long-lived process.

The server communicates with a single client (the process that started the
server) using one of two wire protocols: a legacy protocol, which is used to
support IntelliJ and Android Studio, and LSP (the
[Language Server Protocol](https://microsoft.github.io/language-server-protocol)
from Microsoft), which is used to support VS Code and several other IDEs and
editors. The protocol is selected at start-up via command-line arguments.

To learn more about how the server communicates with the client, you can read
about either [LSP](lsp.md) or the [legacy protocol](legacy.md).

Based on the selected protocol, the starter creates an instance of one of the
two concrete subclasses of `AnalysisServer`, either `LspAnalysisServer` or
`LegacyAnalysisServer`, and initializes it.

To learn how the server implements support for the protocols, read about the
[request handlers](handlers.md).
