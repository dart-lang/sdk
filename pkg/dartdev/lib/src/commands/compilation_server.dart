// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;

import 'package:args/args.dart';
import 'package:dartdev/src/generate_kernel.dart';

import '../core.dart';
import '../resident_frontend_constants.dart';
import '../resident_frontend_utils.dart';
import '../utils.dart';

class CompilationServerCommand extends DartdevCommand {
  static const commandName = 'compilation-server';

  static const commandDescription = 'Control resident frontend compilers.';

  static const residentServerInfoFileFlag = 'resident-server-info-file';
  static const residentServerInfoFileFlagDescription =
      'The path to an info file that the Dart CLI will use to communicate with '
      'a resident frontend compiler. Each unique info file is associated with '
      'a unique resident frontend compiler. If this flag is ommitted, the '
      'default info file will be used.';

  CompilationServerCommand({bool verbose = false})
      : super(
          commandName,
          commandDescription,
          false,
          hidden: !verbose,
        ) {
    addSubcommand(CompilationServerStartCommand());
    addSubcommand(CompilationServerShutdownCommand());
  }
}

class CompilationServerStartCommand extends DartdevCommand {
  static const commandName = 'start';

  static const commandDescription = 'Start a resident frontend compiler.';

  CompilationServerStartCommand({bool verbose = false})
      : super(
          commandName,
          commandDescription,
          false,
          hidden: !verbose,
        ) {
    argParser.addOption(
      CompilationServerCommand.residentServerInfoFileFlag,
      help: CompilationServerCommand.residentServerInfoFileFlagDescription,
    );
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    final hasServerInfoOption = args.wasParsed(serverInfoOption);
    final residentServerInfoFile = hasServerInfoOption
        ? File(maybeUriToFilename(args.option(serverInfoOption)!))
        : defaultResidentServerInfoFile;

    try {
      await ensureCompilationServerIsRunning(residentServerInfoFile!);
    } catch (e) {
      // We already print the error in `ensureCompilationServerIsRunning` when we
      // throw a state error.
      if (e is! StateError) {
        print(e.toString());
      }
      return 64;
    }
    return 0;
  }
}

class CompilationServerShutdownCommand extends DartdevCommand {
  static const commandName = 'shutdown';

  static const commandDescription = '''
Shut down a resident frontend compiler.

Note that this command name and usage could change as we evolve the resident frontend compiler behavior.''';

  CompilationServerShutdownCommand({bool verbose = false})
      : super(commandName, commandDescription, false, hidden: !verbose) {
    argParser.addOption(
      CompilationServerCommand.residentServerInfoFileFlag,
      help: CompilationServerCommand.residentServerInfoFileFlagDescription,
    );
  }

  // This argument parser is here solely to ensure that VM specific flags are
  // provided before any command and to provide a more consistent help message
  // with the rest of the tool.
  @override
  ArgParser createArgParser() {
    return ArgParser();
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    final serverInfoFile = args.wasParsed(serverInfoOption)
        ? File(maybeUriToFilename(args.option(serverInfoOption)!))
        : defaultResidentServerInfoFile;

    if (serverInfoFile == null || !serverInfoFile.existsSync()) {
      log.stdout('No server instance running.');
      return 0;
    }
    final serverInfo = await serverInfoFile.readAsString();
    final serverResponse = await sendAndReceiveResponse(
      residentServerShutdownCommand,
      serverInfoFile,
    );

    cleanupResidentServerInfo(serverInfoFile);
    if (serverResponse.containsKey(responseErrorString)) {
      log.stderr(serverResponse[responseErrorString]);
      return DartdevCommand.errorExitCode;
    } else {
      final address = getAddress(serverInfo);
      final port = getPortNumber(serverInfo);
      log.stdout(
        'The Resident Frontend Compiler instance at ${address.host}:$port was successfully shutdown.',
      );
    }
    return 0;
  }
}
