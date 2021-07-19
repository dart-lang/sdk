// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dds/src/dap/server.dart';

Future<void> main(List<String> arguments) async {
  // TODO(dantup): "dap_tool" is a placeholder and will likely eventually be a
  // "dart" command.
  final runner = CommandRunner('dap_tool', 'Dart DAP Tool')
    ..addCommand(DapCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(e);
    exit(64);
  }
}

class DapCommand extends Command {
  static const argHost = 'host';
  static const argPort = 'port';
  static const argIpv6 = 'ipv6';
  static const argDds = 'dds';
  static const argAuthCodes = 'auth-codes';
  static const argVerbose = 'verbose';

  @override
  final String description = 'Start a DAP debug server.';

  @override
  final String name = 'dap';

  DapCommand() {
    argParser
      ..addOption(
        argHost,
        help: 'The hostname/IP to bind the server to. If not supplied, will'
            ' use the appropriate loopback address depending on whether'
            ' --ipv6 is set',
      )
      ..addOption(
        argPort,
        abbr: 'p',
        defaultsTo: '0',
        help: 'The port to bind the server to',
      )
      ..addFlag(
        argIpv6,
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
        argVerbose,
        abbr: 'v',
        help: 'Whether to print diagnostic output to stdout',
      );
  }

  Future<void> run() async {
    final args = argResults!;
    final port = int.parse(args[argPort]);
    final host = args[argHost];
    final ipv6 = args[argIpv6] as bool;

    final server = await DapServer.create(
      host: host,
      port: port,
      ipv6: ipv6,
      enableDdds: args[argDds],
      enableAuthCodes: args[argAuthCodes],
      logger: args[argVerbose] ? print : null,
    );

    stdout.write(jsonEncode({
      'state': 'started',
      'dapHost': server.host,
      'dapPort': server.port,
    }));
  }
}
