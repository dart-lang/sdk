// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/src/arg_results.dart';
import 'package:nnbd_migration/migration_cli.dart';

void main(List<String> args) async {
  var cli = MigrationCli(binaryName: 'nnbd_migration');
  ArgResults argResults;
  try {
    try {
      argResults = MigrationCli.createParser().parse(args);
    } on FormatException catch (e) {
      cli.handleArgParsingException(e);
    }
    await cli.decodeCommandLineArgs(argResults)?.run();
  } on MigrationExit catch (migrationExit) {
    exitCode = migrationExit.exitCode;
  }
}
