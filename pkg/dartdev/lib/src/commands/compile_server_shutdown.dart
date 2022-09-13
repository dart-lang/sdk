// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File, FileSystemException;

import 'package:args/args.dart';

import '../core.dart';
import '../resident_frontend_constants.dart';
import '../resident_frontend_utils.dart';
import '../utils.dart';

/// Implement `dart compiler-server-shutdown`.
class CompileServerShutdownCommand extends DartdevCommand {
  static const cmdName = 'compiler-server-shutdown';

  CompileServerShutdownCommand({bool verbose = false})
      : super(cmdName, 'Shut down the Resident Frontend Compiler.', false) {
    argParser.addOption(
      'resident-server-info-file',
      hide: !verbose,
      help: 'Specify the file that the Dart CLI uses to communicate with '
          'the Resident Frontend Compiler. Passing this flag results in '
          'having one unique resident frontend compiler per file. '
          'This is needed when writing unit '
          'tests that utilize resident mode in order to maintain isolation.',
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
        : File(defaultResidentServerInfoFile);
    try {
      final serverResponse = await sendAndReceiveResponse(
        residentServerShutdownCommand,
        serverInfoFile,
      );
      cleanupResidentServerInfo(serverInfoFile);
      if (serverResponse.containsKey(responseErrorString)) {
        log.stderr(serverResponse[responseErrorString]);
        return DartdevCommand.errorExitCode;
      }
    } on FileSystemException catch (_) {} // no server is running
    return 0;
  }
}
