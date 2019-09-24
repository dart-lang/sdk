// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:test/test.dart';

class TestMigrationListener implements NullabilityMigrationListener {
  final edits = <Source, List<SourceEdit>>{};

  List<String> details = [];

  @override
  void addEdit(SingleNullabilityFix fix, SourceEdit edit) {
    (edits[fix.source] ??= []).add(edit);
  }

  @override
  void addFix(SingleNullabilityFix fix) {}

  @override
  void reportException(
      Source source, AstNode node, Object exception, StackTrace stackTrace) {
    fail('Exception reported: $exception');
  }
}
