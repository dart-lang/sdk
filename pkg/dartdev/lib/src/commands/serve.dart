// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:dartdev/src/web/project.dart';
import 'package:dartdev/src/web/serve/dev_server.dart';

/// `dart experimental-serve`: serves a Dart web app over HTTP.
///
/// The implementation is in `lib/src/web/`. This command parses the
/// arguments, prints progress, and stops the server on Ctrl+C.
class ServeCommand extends DartdevCommand {
  // The name says that the command is still changing, so that nobody depends
  // on how it behaves today.
  // TODO(https://github.com/dart-lang/sdk/issues/64679): Rename it to `serve`
  // when the feature is ready.
  static const String _cmdName = 'experimental-serve';

  static const String _portOption = 'port';
  static const String _hostnameOption = 'hostname';

  // Hidden until the feature is ready.
  ServeCommand({bool verbose = false})
    : super(
        _cmdName,
        'Serve a Dart web app over HTTP.',
        verbose,
        hidden: true,
      ) {
    argParser
      ..addOption(
        _hostnameOption,
        defaultsTo: DevServer.defaultHostname,
        help: 'The host name to serve the app on.',
      )
      ..addOption(
        _portOption,
        defaultsTo: '${DevServer.defaultPort}',
        help: 'The port to serve the app on, or 0 to pick a free port.',
      );
  }

  @override
  CommandCategory get commandCategory => CommandCategory.project;

  @override
  String get invocation => '${super.invocation} [<entrypoint>]';

  @override
  Future<int> run() async {
    log.stderr(
      '`dart $_cmdName` is under active development and is likely to change.',
    );
    final args = argResults!;
    if (args.rest.length > 1) {
      usageException('Expected at most one entrypoint, such as web/main.dart.');
    }
    final hostname = args.option(_hostnameOption)!;
    final port = int.tryParse(args.option(_portOption)!);
    if (port == null || port < 0 || port > 65535) {
      usageException('--$_portOption must be a number from 0 to 65535.');
    }

    final WebProject project;
    try {
      project = await WebProject.find(
        Directory.current.path,
        entrypoint: args.rest.firstOrNull,
      );
    } on ProjectException catch (e) {
      log.stderr(e.message);
      return DartdevCommand.errorExitCode;
    }

    log.stdout('Compiling ${project.entrypoint}...');
    final DevServer server;
    try {
      server = await DevServer.start(
        project,
        hostname: hostname,
        port: port,
        // dartdev is AOT-compiled, so tell the compiler where the SDK is.
        sdkRoot: sdk.sdkPath,
      );
    } on SocketException catch (e) {
      log.stderr(
        'Could not serve on $hostname:$port: '
        '${e.osError?.message ?? e.message}',
      );
      return DartdevCommand.errorExitCode;
    }
    // The app is served even with compile errors, so show them and go on.
    for (final error in server.compileErrors) {
      log.stderr(error);
    }
    if (!server.isLoopback) {
      // Ends with an empty line, to set it apart from the URL below.
      log.stderr(
        'WARNING: Serving on ${server.url.host}, which other devices on your '
        'network can reach.\n'
        'The server has no authentication: anyone who can reach it can read '
        "your app's files and Dart sources.\n",
      );
    }
    // TODO(https://github.com/dart-lang/sdk/issues/64663): Also clean up on
    // Ctrl+C during the first compile, before this handler is set up.
    _closeOnSignals(server);
    log.stdout('Serving ${project.relativeWebDirectory} on ${server.url}');
    log.stdout('Press Ctrl+C to stop.');
    // Returning lets dartdev finish the command (and send its analytics). The
    // process keeps running while the server is open.
    return 0;
  }

  /// Closes [server] on Ctrl+C (or SIGTERM), so the compiler's temporary
  /// directory is deleted. The process then exits, because nothing else keeps
  /// it running.
  static void _closeOnSignals(DevServer server) {
    final subscriptions = <StreamSubscription<ProcessSignal>>[];
    Future<void> close(ProcessSignal _) async {
      // Stop listening first, so that a second Ctrl+C kills the process if
      // closing hangs. Every listener is cancelled before the first `await`,
      // so that another signal can't start a second close.
      await Future.wait([
        for (final subscription in subscriptions) subscription.cancel(),
      ]);
      await server.close();
    }

    subscriptions.add(ProcessSignal.sigint.watch().listen(close));
    // Windows has no SIGTERM.
    if (!Platform.isWindows) {
      subscriptions.add(ProcessSignal.sigterm.watch().listen(close));
    }
  }
}
