// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cli_util/cli_logging.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/migration_cli.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/front_end/dartfix_listener.dart';
import 'package:nnbd_migration/src/front_end/info_builder.dart';
import 'package:nnbd_migration/src/front_end/instrumentation_listener.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:pub_semver/src/version.dart';

/// The state of an NNBD migration.
class MigrationState {
  bool _hasBeenApplied = false;

  /// The migration associated with the state.
  final NullabilityMigration migration;

  /// The root directory that contains all of the files that were migrated.
  final String includedRoot;

  /// The mapper user to give nodes ids.
  final NodeMapper nodeMapper = SimpleNodeMapper();

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

  final AnalysisResult analysisResult;

  /*late*/ List<String> previewUrls;

  /// Map of additional package dependencies that will be required by the
  /// migrated code.  Keys are package names; values indicate the minimum
  /// required version of each package.
  final Map<String, Version> neededPackages;

  /// Initialize a newly created migration state with the given values.
  MigrationState(this.migration, this.includedRoot, this.listener,
      this.instrumentationListener, this.neededPackages,
      [this.analysisResult])
      : assert(neededPackages != null);

  /// If the migration has been applied to disk.
  bool get hasBeenApplied => _hasBeenApplied;

  bool get hasErrors => analysisResult?.hasErrors ?? false;

  /// Mark that the migration has been applied to disk.
  void markApplied() {
    assert(!hasBeenApplied);
    _hasBeenApplied = true;
  }

  /// Refresh the state of the migration after the migration has been updated.
  Future<void> refresh(Logger logger) async {
    assert(!hasBeenApplied);
    var provider = listener.server.resourceProvider;
    var infoBuilder = InfoBuilder(provider, includedRoot,
        instrumentationListener.data, listener, migration, nodeMapper, logger);
    var unitInfos = await infoBuilder.explainMigration();
    var pathContext = provider.pathContext;
    migrationInfo = MigrationInfo(
        unitInfos, infoBuilder.unitMap, pathContext, includedRoot);
    pathMapper = PathMapper(provider);
  }
}
