# package:dtd

A package for communicating with the Dart Tooling Daemon.

## What is the Dart Tooling Daemon?

The Dart Tooling Daemon is a long running process meant to facilitate
communication between Dart tools and minimal file system access for a Dart
development workspace.

When writing or running a Dart or Flutter application, in an IDE, the Dart
Tooling Daemon is started by the IDE. It persists over the life of the IDE's
workspace.

When running a Dart or Flutter application from the command line, the Dart
Tooling Daemon  is started by the DevTools server, which is owned by the Dart or
Flutter command line runner. It will persist for the life of the application's
run process.

## Quick Start

```dart
import "package:dtd"

/// Since the Dart Tooling Daemon exists within the context of a development
/// environment, any tool using DTD can expect a development environment to
/// exist. This development environment can be an IDE session or a command line
/// run process.
///
/// To develop tools that use package:dtd to connect to the Dart Tooling Daemon,
/// you must have a real DTD instance to interact with. To get the URI of a
/// real DTD instance, you will need to simulate the development environment of
/// a user of your tool. Use one of the following methods:
///
/// 1) Open a Dart or Flutter project in an IDE workspace. The supported IDEs
/// include Android Studio / IntelliJ or VS Code. This simulates how your user
/// may be writing code or running a Dart or Flutter app, and then using your
/// tool. The IDE will automatically start DTD, and you can copy the URI to use
/// for developing your tool.
///
/// From Android Studio / IntelliJ, go to Help > Find Action > Copy DTD URI to
/// Clipboard from VS Code, use the "Dart: Copy DTD URI to Clipboard" command
/// from the command palette
/// 2) Run a Dart or Flutter application from the command line with the
/// --print-dtd flag. This simulates how your user may be running an app from
/// the terminal, and then using your tool. A DTD URI will be printed to CLI,
/// and you can copy that to use for developing your tool.
final dtdUri = 'ws://127.0.0.1:62925/';

final client = await DartToolingDaemon.connectToDaemonAt(dtdUri);
```

`client` can then be used to interact with the Dart Tooling Daemon.

See the [Examples](#examples) for details on the built in interactions.

## Examples

### FileSystem service example

This example shows how to access the file system through the Dart Tooling
Daemon.

See [dtd_file_system_service_example.dart](./example/dtd_file_system_service_example.dart)

### Service Method Example

This example shows how to set up your own service method callbacks through the
Dart Tooling Daemon.

See [dtd_service_example.dart](./example/dtd_service_example.dart)

### Stream Example

This example shows how to send and listen for stream events, through the Dart
Tooling Daemon.

See [dtd_stream_example.dart](./example/dtd_stream_example.dart)
