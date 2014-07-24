## Initializing

By default, the logging package does not do anything useful with the
log messages. You must configure the logging level and add a handler
for the log messages.

Here is a simple logging configuration that logs all messages
via `print`.

```dart
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((LogRecord rec) {
  print('${rec.level.name}: ${rec.time}: ${rec.message}');
});
```

First, set the root [Level]. All messages at or above the level are
sent to the [onRecord] stream.

Then, listen on the [onRecord] stream for [LogRecord] events. The
[LogRecord] class has various properties for the message, error,
logger name, and more.

## Logging messages

Create a [Logger] with a unique name to easily identify the source
of the log messages.

```dart
final Logger log = new Logger('MyClassName');
```

Here is an example of logging a debug message and an error:

```dart
var future = doSomethingAsync().then((result) {
  log.fine('Got the result: $result');
  processResult(result);
}).catchError((e, stackTrace) => log.severe('Oh noes!', e, stackTrace));
```

See the [Logger] class for the different logging methods.
