// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartfix/src/migrate/migrate.dart';

import 'src/commands/analyze.dart';
import 'src/commands/create.dart';
import 'src/commands/format.dart';
import 'src/commands/pub.dart';
import 'src/commands/test.dart';
import 'src/core.dart';

class DartdevRunner<int> extends CommandRunner {
  static const String dartdevDescription =
      'A command-line utility for Dart development';

  DartdevRunner(List<String> args) : super('dart', '$dartdevDescription.') {
    final bool verbose = args.contains('-v') || args.contains('--verbose');

    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show verbose output.');

    addCommand(AnalyzeCommand(verbose: verbose));
    addCommand(CreateCommand(verbose: verbose));
    addCommand(FormatCommand(verbose: verbose));
    addCommand(MigrateCommand(logProvider: () => log));
    addCommand(PubCommand(verbose: verbose));
    addCommand(TestCommand(verbose: verbose));
  }

  @override
  Future<int> runCommand(ArgResults results) async {
    isVerbose = results['verbose'];

    final Ansi ansi = Ansi(Ansi.terminalSupportsAnsi);
    log = isVerbose ? Logger.verbose(ansi: ansi) : Logger.standard(ansi: ansi);

    return await super.runCommand(results);
  }
}
