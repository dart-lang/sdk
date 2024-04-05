// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/server/driver.dart' as server;
import 'package:args/args.dart';

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';

class LanguageServerCommand extends DartdevCommand {
  static const String commandName = 'language-server';

  static const String commandDescription = '''
Start Dart's analysis server.

This is a long-running process used to provide language services to IDEs and other tooling clients.

It communicates over stdin and stdout and provides services like code completion, errors and warnings, and refactorings. This command is generally not user-facing but consumed by higher level tools.

For more information about the server's capabilities and configuration, see:

  https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server''';

  LanguageServerCommand({bool verbose = false})
      : super(commandName, commandDescription, verbose, hidden: !verbose);

  @override
  ArgParser createArgParser() {
    return server.Driver.createArgParser(
      usageLineLength: dartdevUsageLineLength,
      includeHelpFlag: false,
      defaultToLsp: true,
    );
  }

  @override
  Future<int> run() async {
    const protocol = server.Driver.SERVER_PROTOCOL;
    const lsp = server.Driver.PROTOCOL_LSP;

    var args = argResults!.arguments;
    if (!args.any((arg) => arg.startsWith('--$protocol'))) {
      args = [...args, '--$protocol=$lsp'];
    } else {
      // Need to make a copy as argResults!.arguments is an
      // UnmodifiableListView object which cannot be passed as
      // the args for spawnUri.
      args = [...args];
    }
    return await runFromSnapshot(
      snapshot: sdk.analysisServerSnapshot,
      args: args,
      verbose: verbose,
    );
  }
}
