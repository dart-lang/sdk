// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ReplaceWithSyncValue extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  FixKind get fixKind => DartFixKind.replaceWithSyncValue;

  @override
  FixKind get multiFixKind => DartFixKind.replaceWithSyncValueMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(node.sourceRange, 'syncValue');
    });
  }
}
