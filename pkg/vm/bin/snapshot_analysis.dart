#!/usr/bin/env dart
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';

import 'package:vm/snapshot/commands/compare.dart';
import 'package:vm/snapshot/commands/summary.dart';
import 'package:vm/snapshot/commands/treemap.dart';

final runner = CommandRunner('snapshot_analysis.dart',
    'Tools for binary size analysis of Dart VM AOT snapshots.')
  ..addCommand(TreemapCommand())
  ..addCommand(CompareCommand())
  ..addCommand(SummaryCommand());

void main(List<String> args) async {
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    print(e.toString());
  }
}
