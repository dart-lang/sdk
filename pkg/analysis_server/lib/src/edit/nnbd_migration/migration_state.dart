// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/nnbd_migration/info_builder.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:nnbd_migration/nnbd_migration.dart';

/// The state of an NNBD migration.
class MigrationState {
  bool _hasBeenApplied = false;

  /// The migration associated with the state.
  final NullabilityMigration migration;

  /// The adapter to dartfix for this migration.
  final NullabilityMigrationAdapter adapter;

  /// The root directory that contains all of the files that were migrated.
  final String includedRoot;

  /// The listener used to collect fixes.
  final DartFixListener listener;

  /// The listener that collected information during the migration.
  final InstrumentationListener instrumentationListener;

  /// The information that was built from the rest of the migration state.
  MigrationInfo migrationInfo;

  /// The object used to map paths.
  PathMapper pathMapper;

  /// If there have been changes to disk so the migration needs to be rerun.
  bool needsRerun = false;

  /// Initialize a newly created migration state with the given values.
  MigrationState(this.migration, this.includedRoot, this.listener,
      this.instrumentationListener, this.adapter);

  /// If the migration has been applied to disk.
  bool get hasBeenApplied => _hasBeenApplied;

  /// Mark that the migration has been applied to disk.
  void markApplied() {
    assert(!hasBeenApplied);
    _hasBeenApplied = true;
  }

  /// Refresh the state of the migration after the migration has been updated.
  Future<void> refresh() async {
    assert(!hasBeenApplied);
    var provider = listener.server.resourceProvider;
    var infoBuilder = InfoBuilder(provider, includedRoot,
        instrumentationListener.data, listener, adapter, migration);
    var unitInfos = await infoBuilder.explainMigration();
    var pathContext = provider.pathContext;
    migrationInfo = MigrationInfo(
        unitInfos, infoBuilder.unitMap, pathContext, includedRoot);
    pathMapper = PathMapper(provider);
  }
}
