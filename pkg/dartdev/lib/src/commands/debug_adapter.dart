// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dap.dart';

import '../core.dart';

/// A command to start a debug adapter process that communicates over
/// stdin/stdout using the Debug Adapter Protocol to allow editors to run debug
/// sessions in a standard way.
class DebugAdapterCommand extends DartdevCommand {
  static const String cmdName = 'debug_adapter';

  static const argIpv6 = 'ipv6';
  static const argDds = 'dds';
  static const argAuthCodes = 'auth-codes';
  static const argTest = 'test';

  DebugAdapterCommand({bool verbose = false})
      : super(
          cmdName,
          'Start a debug adapter that conforms to the Debug Adapter Protocol.',
          verbose,
          hidden: true,
        ) {
    argParser
      ..addFlag(
        argIpv6,
        defaultsTo: false,
        help: 'Whether to bind DAP/VM Service/DDS to IPv6 addresses.',
      )
      ..addFlag(
        // Deprecated - DAP never spawns DDS now, but this flag is left
        // temporarily to not crash clients passing it.
        // TODO(dantup): Remove this after verifying nobody uses it.
        argDds,
        defaultsTo: true,
        help: 'Whether to enable DDS for debug sessions.',
        hide: true,
      )
      ..addFlag(
        // Deprecated - DAP never spawns DDS now, but this flag is left
        // temporarily to not crash clients passing it.
        // TODO(dantup): Remove this after verifying nobody uses it.
        argAuthCodes,
        defaultsTo: true,
        help: 'Whether to enable authentication codes for VM Services.',
        hide: true,
      )
      ..addFlag(
        argTest,
        defaultsTo: false,
        help: 'Whether to use the "dart test" debug adapter to run tests'
            ' and emit custom events for test progress/results.',
      );
  }

  @override
  CommandCategory get commandCategory => CommandCategory.tools;

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    final ipv6 = args.flag(argIpv6);

    // Because we use stdout.nonBlocking, exceptions may go unhandled if the
    // stream closes while data is being flushed ("The pipe is being closed").
    // To prevent this, install an error handler that ignores any errors writing
    // to the stream.
    stdout.nonBlocking.done.catchError((e) {});

    final server = DapServer(
      stdin,
      stdout.nonBlocking,
      ipv6: ipv6,
      test: args.flag(argTest),
      // Protocol errors should be written to stderr to help debug (or in the
      // case of a user running this command to explain it's for tools).
      onError: (e) => stderr.writeln(
        'Input could not be parsed as a Debug Adapter Protocol message.\n'
        'The "dart debug_adapter" command is intended for use by tooling that '
        'communicates using the Debug Adapter Protocol.\n\n'
        '$e',
      ),
    );

    await server.channel.closed;

    return 0;
  }
}
