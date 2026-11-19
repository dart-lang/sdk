// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/server/driver.dart' as server;
import 'package:args/args.dart';

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';
import '../vm_interop_handler.dart';

class LanguageServerCommand extends DartdevCommand {
  static const String commandName = 'language-server';

  @override
  CommandCategory get commandCategory => CommandCategory.tools;

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
    const protocol = server.Driver.serverProtocolOption;
    const lsp = server.Driver.protocolLsp;

    var args = argResults!.arguments;
    if (!argResults!.wasParsed(protocol)) {
      args = [...args, '--$protocol=$lsp'];
    }
    try {
      final script = sdk.analysisServerAotSnapshot;
      if (!checkArtifactExists(script)) {
        log.stderr('Error: launching language analysis server failed');
        log.stderr('$script not found');
        return _genericErrorExitCode;
      }
      VmInteropHandler.run(script, args, useExecProcess: false);
      return 0;
    } catch (e, st) {
      log.stderr('Error: launching language analysis server failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return _genericErrorExitCode;
    }
  }

  static const _genericErrorExitCode = 255;
}
