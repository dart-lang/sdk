# analysis_server_client

analysis_server_client is a client wrapper over Analysis Server.

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
