// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;

import 'package:args/args.dart';
import 'package:dartdev/src/generate_kernel.dart';
import 'package:frontend_server/resident_frontend_server_utils.dart'
    show ResidentCompilerInfo;

import '../core.dart';
import '../resident_frontend_constants.dart';
import '../resident_frontend_utils.dart';

class CompilationServerCommand extends DartdevCommand {
  static const commandName = 'compilation-server';

  static const commandDescription = 'Control resident frontend compilers.';

  static const legacyResidentServerInfoFileFlag = 'resident-server-info-file';
  static const residentCompilerInfoFileFlag = residentCompilerInfoFileOption;
  static const residentCompilerInfoFileFlagDescription =
      'The path to an info file that the Dart CLI will use to communicate with '
      'a resident frontend compiler. Each unique info file is associated with '
      'a unique resident frontend compiler. If this flag is ommitted, the '
      'default info file will be used.';

  static const inaccessibleDefaultResidentCompilerInfoFileMessage =
      'The default resident frontend compiler info file could not be accessed. '
      'Please explicitly provide the path to a resident compiler info file '
      'using the --resident-compiler-info-file option.';

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
    argParser
      ..addOption(
        CompilationServerCommand.residentCompilerInfoFileFlag,
        help: CompilationServerCommand.residentCompilerInfoFileFlagDescription,
      )
      ..addOption(
        CompilationServerCommand.legacyResidentServerInfoFileFlag,
        // This option is only available for backwards compatibility, and should
        // never be shown in the help message.
        hide: true,
      );
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;

    final File? residentCompilerInfoFile =
        getResidentCompilerInfoFileConsideringArgs(args);
    if (residentCompilerInfoFile == null) {
      log.stderr(
        CompilationServerCommand
            .inaccessibleDefaultResidentCompilerInfoFileMessage,
      );
      return DartdevCommand.errorExitCode;
    }

    try {
      await ensureCompilationServerIsRunning(residentCompilerInfoFile);
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
    argParser
      ..addOption(
        CompilationServerCommand.residentCompilerInfoFileFlag,
        help: CompilationServerCommand.residentCompilerInfoFileFlagDescription,
      )
      ..addOption(
        CompilationServerCommand.legacyResidentServerInfoFileFlag,
        // This option is only available for backwards compatibility, and should
        // never be shown in the help message.
        hide: true,
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

    final File? residentCompilerInfoFile =
        getResidentCompilerInfoFileConsideringArgs(args);
    if (residentCompilerInfoFile == null) {
      log.stderr(
        CompilationServerCommand
            .inaccessibleDefaultResidentCompilerInfoFileMessage,
      );
      return DartdevCommand.errorExitCode;
    }

    if (!residentCompilerInfoFile.existsSync()) {
      log.stdout('No resident frontend compiler instance running.');
      return 0;
    }

    final residentCompilerInfo =
        ResidentCompilerInfo.fromFile(residentCompilerInfoFile);
    final address = residentCompilerInfo.address;
    final port = residentCompilerInfo.port;
    // There is nothing actionable the user can do in response to an error
    // occurring when shutting down. So, we call
    // [shutDownOrForgetResidentFrontendCompiler] here to ensure that when such
    // an error occurs, we don't report it to the user and instead just forget
    // about the compiler that couldn't be shut down.
    await shutDownOrForgetResidentFrontendCompiler(residentCompilerInfoFile);
    log.stdout(
      'The Resident Frontend Compiler instance at ${address.host}:$port was '
      'successfully shutdown.',
    );
    return 0;
  }
}
