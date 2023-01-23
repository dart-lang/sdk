// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;

import 'package:args/args.dart';

import '../core.dart';
import '../resident_frontend_constants.dart';
import '../resident_frontend_utils.dart';
import '../utils.dart';

/// Implement `dart compiler-server-shutdown`.
class CompileServerShutdownCommand extends DartdevCommand {
  static const commandName = 'compiler-server-shutdown';

  static const commandDescription = '''
Shut down the resident frontend compiler.

Frontend compilers stay resident in memory when using 'dart run --resident'. This command will shutdown any remaining frontend compiler processes.

Note that this command name and usage could change as we evolve the resident frontend compiler behavior.''';

  static const residentServerInfoFileFlag = 'resident-server-info-file';

  CompileServerShutdownCommand({bool verbose = false})
      : super(commandName, commandDescription, false, hidden: !verbose) {
    argParser.addOption(
      residentServerInfoFileFlag,
      help: 'Specify the file that the Dart CLI uses to communicate with the '
          'resident frontend compiler. Passing this flag results in having one '
          'unique resident frontend compiler per file. This is needed when '
          'writing unit tests that utilize resident mode in order to maintain '
          'isolation.',
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
        ? File(maybeUriToFilename(args[serverInfoOption]))
        : defaultResidentServerInfoFile;

    if (serverInfoFile == null || !serverInfoFile.existsSync()) {
      log.stdout('No server instance running.');
      return 0;
    }

    final serverResponse = await sendAndReceiveResponse(
      residentServerShutdownCommand,
      serverInfoFile,
    );

    cleanupResidentServerInfo(serverInfoFile);
    if (serverResponse.containsKey(responseErrorString)) {
      log.stderr(serverResponse[responseErrorString]);
      return DartdevCommand.errorExitCode;
    } else {
      log.stdout('Server instance shutdown.');
    }

    return 0;
  }
}
