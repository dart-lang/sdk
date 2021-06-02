// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:dds/src/dap/server.dart';

Future<void> main(List<String> arguments) async {
  final args = argParser.parse(arguments);
  if (args[argHelp]) {
    print(argParser.usage);
    return;
  }

  final port = int.parse(args[argPort]);
  final host = args[argHost];

  await DapServer.create(
    host: host,
    port: port,
    logger: args[argVerbose] ? print : null,
  );
}

const argHelp = 'help';
const argHost = 'host';
const argPort = 'port';
const argVerbose = 'verbose';
final argParser = ArgParser()
  ..addFlag(argHelp, hide: true)
  ..addOption(
    argHost,
    defaultsTo: 'localhost',
    help: 'The hostname/IP to bind the server to',
  )
  ..addOption(
    argPort,
    abbr: 'p',
    defaultsTo: DapServer.defaultPort.toString(),
    help: 'The port to bind the server to',
  )
  ..addFlag(
    argVerbose,
    abbr: 'v',
    help: 'Whether to print diagnostic output to stdout',
  );
