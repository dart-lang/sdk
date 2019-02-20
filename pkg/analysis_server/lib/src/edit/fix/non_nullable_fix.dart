// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analysis_server/src/nullability/provisional_api.dart';
import 'package:analyzer/dart/analysis/results.dart';

/// [NonNullableFix] visits each named type in a resolved compilation unit
/// and determines whether the associated variable or parameter can be null
/// then adds or removes a '?' trailing the named type as appropriate.
class NonNullableFix extends FixCodeTask {
  /// TODO(paulberry): stop using permissive mode once the migration logic is
  /// mature enough.
  static const bool _usePermissiveMode = true;

  final DartFixListener listener;

  final NullabilityMigration migration;

  NonNullableFix(this.listener)
      : migration = new NullabilityMigration(
            new NullabilityMigrationAdapter(listener),
            permissive: _usePermissiveMode);

  @override
  int get numPhases => 2;

  @override
  Future<void> finish() async {
    migration.finish();
  }

  @override
  Future<void> processUnit(int phase, ResolvedUnitResult result) async {
    switch (phase) {
      case 0:
        migration.prepareInput(result);
        break;
      case 1:
        migration.processInput(result);
        break;
      default:
        throw new ArgumentError('Unsupported phase $phase');
    }
  }

  static void task(DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerCodeTask(new NonNullableFix(listener));
  }
}

class NullabilityMigrationAdapter implements NullabilityMigrationListener {
  final DartFixListener listener;

  NullabilityMigrationAdapter(this.listener);

  @override
  void addFix(SingleNullabilityFix fix) {
    // TODO(danrubel): Update the description based upon the [fix.kind]
    listener.addSourceEdits(
        fix.kind.appliedMessage, fix.location, fix.source, fix.sourceEdits);
  }
}
