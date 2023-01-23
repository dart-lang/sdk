`package:analysis_server_client` is a client wrapper over the Analysis Server.

## Update: this package has been discontinued

This package has been discontinued and will not receive further updates.

People who need similar functionality could:

- continue to use the last published version; it should continue to be able to
  talk to the analysis server for the foreseeable future
- fork the package and maintain that fork (we don't expect that the analysis
  server protocol will evolve significantly)
- see if their use case could instead be satisfied by talking to the analysis
  server over the LSP protocol (`dart language-server --protocol=lsp`)

We welcome feedback about this at
[#50262](https://github.com/dart-lang/sdk/issues/50262); that would also be a
good place to discuss alternatives.

## Overview

 * Instances of [__Server__](lib/server.dart) manage a connection to an analysis server process,
   and facilitate communication to and from the server.

 * The [__Protocol__](lib/protocol.dart) library provides constants and classes
   to build requests for the server and decode responses and notifications from the server.

## Example

The [example](example/example.dart) uses the [__Server__](lib/server.dart) to
launch the analysis server, analyze all *.dart files in the specified directory,
display the results, and shutdown the analysis server.

## References

For more about the analysis server, see the
[Analysis Server page](https://github.com/dart-lang/sdk/tree/master/pkg/analysis_server).
