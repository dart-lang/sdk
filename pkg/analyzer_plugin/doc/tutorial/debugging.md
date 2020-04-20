# Debugging Plugins

Unfortunately, debugging a plugin is not well supported at this point. The
server is typically run as a sub-process by a client. Some clients provide a way
to add command-line arguments when invoking the server, others don't. To make
matters worse, each plugin is run in a separate isolate.

Nevertheless, there are a few ways to get some information about what's going on
in a plugin. Those are outlined below. If you know of other useful techniques,
or if you have a request for better support, please let us know.

## Check the Status Pages

The analysis server has the ability to host a set of web pages that describe the
current state of the server. One of the pieces of information available through
those pages is a list of the plugins that are currently being run.

The server does not host these pages unless it has been requested to do so. You
can request it by passing a command-line argument to the server when it is being
started. The argument should be similar to `--port=10000` (any valid port number
will work). You can then point your browser to `http://localhost:10000/status`.

If you're using IntelliJ as your client, there is a gear icon on the Dart
Analysis view's header that can be used to open the status pages.

The plugin information can be displayed by clicking on "Plugins" in the list on
the left.

## Check the Instrumentation Log

The analysis server has the ability to log debugging data to a file. For
historic reasons this file is referred to as the _instrumentation log_. The data
primarily consists of a record of the communications between the server and both
the client that started it and any plugins that the server is running.

The server does not write to this file unless it has been requested to do so.
You can request it by passing a command-line argument to the server when it is
being started. The argument should be similar to
`--instrumentation-log-file=/path/to/file.txt`.

## Println Debugging

You cannot use the `print` function to get debugging information because server
is run by the client in a child process, and hence doesn't have the ability to
write to the console.

The closest approximation is for the plugin to send notifications to the server
that will be written to the instrumentation log file. Currently, the best choice
for this is the `plugin.error` notification. Just be sure that `isFatal` has a
value of `false`.

## Using Observatory

If the client you're using allows you to pass command-line flags to the VM, then
you can also run the analysis server under the Observatory. Pass in both
`--observe` and `--pause-isolates-on-start`, then point your browser to
`http://localhost:8181`. To learn more, see the
[observatory][observatory] documentation.

If you're using IntelliJ as your client, open the "Registry..." dialog and edit
the entry named "dart.server.vm.options".

[observatory]: https://dart-lang.github.io/observatory/