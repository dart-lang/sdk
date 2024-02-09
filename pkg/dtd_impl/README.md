The server implementation for the Dart Tooling Daemon. This is meant to be run
by our internal tooling and facilitates communication between our internal
tools.

# Running the sample

## Running with the Dart SDK

You can run the example with the [Dart SDK](https://dart.dev/get-dart)
like this:

```
$ dart run bin/dtd_server.dart
The Dart Tooling Daemon is listening on 0.0.0.0:8080
```

## Compiling the binary

`dart compile exe bin/dtd_server.dart -o bin/dtd_server`
