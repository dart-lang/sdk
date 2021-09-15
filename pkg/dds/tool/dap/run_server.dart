// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dds/src/dap/server.dart';

Future<void> main(List<String> arguments) async {
  // TODO(dantup): "dap_tool" is a placeholder and will likely eventually be a
  // "dart" command.
  final runner = CommandRunner('dap_tool', 'Dart DAP Tool')
    ..addCommand(DapCommand(stdin, stdout.nonBlocking));

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(e);
    exit(64);
  }
}

class DapCommand extends Command {
  static const argIpv6 = 'ipv6';
  static const argDds = 'dds';
  static const argAuthCodes = 'auth-codes';
  static const argTest = 'test';

  final Stream<List<int>> _inputStream;
  final StreamSink<List<int>> _outputSink;

  @override
  final String description = 'Start a DAP debug server.';

  @override
  final String name = 'dap';

  DapCommand(this._inputStream, this._outputSink) {
    argParser
      ..addFlag(
        argIpv6,
        defaultsTo: false,
        help: 'Whether to bind DAP/VM Service/DDS to IPv6 addresses',
      )
      ..addFlag(
        argDds,
        defaultsTo: true,
        help: 'Whether to enable DDS for debug sessions',
      )
      ..addFlag(
        argAuthCodes,
        defaultsTo: true,
        help: 'Whether to enable authentication codes for VM Services',
      )
      ..addFlag(
        argTest,
        defaultsTo: false,
        help: 'Whether to use the "dart test" debug adapter to run tests'
            ' and emit custom events for test progress',
      );
  }

  Future<void> run() async {
    final args = argResults!;
    final ipv6 = args[argIpv6] as bool;

    final server = DapServer(
      _inputStream,
      _outputSink,
      ipv6: ipv6,
      enableDds: args[argDds],
      enableAuthCodes: args[argAuthCodes],
      test: args[argTest],
    );

    await server.channel.closed;
  }
}
