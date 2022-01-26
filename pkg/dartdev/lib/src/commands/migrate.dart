// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:dartdev/src/core.dart';
import 'package:nnbd_migration/migration_cli.dart';

class MigrateCommand extends DartdevCommand {
  static const String cmdName = 'migrate';

  static const String cmdDescription =
      'Perform null safety migration on a project.';

  /// Return whether the SDK has null safety on by default.
  static bool get nullSafetyOnByDefault => IsEnabledByDefault.non_nullable;

  final bool verbose;

  MigrateCommand({this.verbose = false})
      : super(cmdName, '$cmdDescription\n\n${MigrationCli.migrationGuideLink}',
            verbose) {
    MigrationCli.defineOptions(argParser, !verbose);
  }

  @override
  String get invocation {
    return '${super.invocation} [project or directory]';
  }

  @override
  FutureOr<int> run() async {
    var cli = MigrationCli(binaryName: 'dart $name');
    try {
      await cli.decodeCommandLineArgs(argResults!, isVerbose: verbose)?.run();
    } on MigrationExit catch (migrationExit) {
      return migrationExit.exitCode;
    }
    return 0;
  }
}
