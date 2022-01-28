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
        argDds,
        defaultsTo: true,
        help: 'Whether to enable DDS for debug sessions.',
      )
      ..addFlag(
        argAuthCodes,
        defaultsTo: true,
        help: 'Whether to enable authentication codes for VM Services.',
      )
      ..addFlag(
        argTest,
        defaultsTo: false,
        help: 'Whether to use the "dart test" debug adapter to run tests'
            ' and emit custom events for test progress/results.',
      );
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    final ipv6 = args[argIpv6] as bool;

    final server = DapServer(
      stdin,
      stdout.nonBlocking,
      ipv6: ipv6,
      enableDds: args[argDds],
      enableAuthCodes: args[argAuthCodes],
      test: args[argTest],
    );

    await server.channel.closed;

    return 0;
  }
}
