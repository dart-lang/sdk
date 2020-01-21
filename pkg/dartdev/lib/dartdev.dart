// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import 'src/commands/format.dart';
import 'src/core.dart';

class DartdevRunner extends CommandRunner {
  static const String dartdevDescription =
      'A command-line utility for Dart development';

  DartdevRunner() : super('dartdev', '$dartdevDescription.') {
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show verbose output.');

    // The list of currently supported commands:
    addCommand(FormatCommand());
  }

  @override
  Future runCommand(ArgResults results) async {
    isVerbose = results['verbose'];

    log = isVerbose ? Logger.verbose(ansi: ansi) : Logger.standard(ansi: ansi);

    return await super.runCommand(results);
  }
}
