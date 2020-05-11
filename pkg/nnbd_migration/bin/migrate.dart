// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:nnbd_migration/migration_cli.dart';

main(List<String> args) async {
  var cli = MigrationCli(binaryName: 'nnbd_migration');
  await cli.run(args);
  exit(cli.exitCode ?? 0);
}
