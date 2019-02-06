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
class NonNullableFix extends FixCodeTask {
  static void task(DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerCodeTask(new NonNullableFix(listener));
  }

  final DartFixListener listener;

  // TODO(danrubel): Remove this caching and add a 2nd processing pass
  // for nullability migration. This cache works around a current limitation
  // in the migration engine which expects the same AST objects
  // in the 2nd pass as the 1st pass.
  List<ResolvedUnitResult> cache = <ResolvedUnitResult>[];

  // TODO(danrubel): consider integrating NullabilityMigration into this class
  final NullabilityMigration migration = new NullabilityMigration();

  NonNullableFix(this.listener);

  @override
  Future<void> finish() async {
    // TODO(danrubel): Remove this caching and add a 2nd processing pass
    // for nullability migration. This cache works around a current limitation
    // in the migration engine which expects the same AST objects
    // in the 2nd pass as the 1st pass.
    while (cache.isNotEmpty) {
      migration.processInput(cache.removeLast());
    }

    List<SourceFileEdit> edits = migration.finish();
    for (SourceFileEdit edit in edits) {
      // TODO(danrubel): integrate NullabilityMigration to provide
      // better user feedback on what changes are being made.
      Location location = null;
      listener.addSourceFileEdit(
          'Update non-nullable type references', location, edit);
    }
  }

  /// Update the source to be non-nullable by
  /// 1) adding trailing '?' to type references of nullable variables, and
  /// 2) removing trailing '?' from type references of non-nullable variables.
  @override
  Future<void> processUnit(ResolvedUnitResult result) async {
    migration.prepareInput(result);

    // TODO(danrubel): Remove this caching and add a 2nd processing pass
    // for nullability migration. This cache works around a current limitation
    // in the migration engine which expects the same AST objects
    // in the 2nd pass as the 1st pass.
    cache.add(result);
  }
}
