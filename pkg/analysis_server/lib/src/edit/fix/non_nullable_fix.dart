// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analysis_server/src/nullability/provisional_api.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// [NonNullableFix] visits each named type in a resolved compilation unit
/// and determines whether the associated variable or parameter can be null
/// then adds or removes a '?' trailing the named type as appropriate.
class NonNullableFix extends FixCodeTask2 {
  static void task(DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerCodeTask(new NonNullableFix(listener));
  }

  final DartFixListener listener;

  // TODO(danrubel): consider integrating NullabilityMigration into this class
  final NullabilityMigration migration = new NullabilityMigration();

  NonNullableFix(this.listener);

  @override
  Future<void> finish() async {
    var fixes = migration.finish();
    for (var fix in fixes) {
      // TODO(danrubel): Update the description based upon the [fix.kind]
      listener.addSourceEdits('Update non-nullable type references',
          fix.location, fix.source, fix.sourceEdits);
    }
  }

  @override
  Future<void> processUnit(ResolvedUnitResult result) async {
    migration.prepareInput(result);
  }

  @override
  Future<void> processUnit2(ResolvedUnitResult result) async {
    migration.processInput(result);
  }
}
