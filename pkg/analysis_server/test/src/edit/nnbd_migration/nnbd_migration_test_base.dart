// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/nnbd_migration/info_builder.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_abstract.dart';

@reflectiveTest
class NnbdMigrationTestBase extends AbstractAnalysisTest {
  /// The information produced by the InfoBuilder, or `null` if [buildInfo] has
  /// not yet completed.
  Set<UnitInfo> infos;

  /// Uses the InfoBuilder to build information for [testFile].
  ///
  /// The information is stored in [infos].
  Future<void> buildInfo({bool removeViaComments = true}) async {
    var includedRoot = resourceProvider.pathContext.dirname(testFile);
    await _buildMigrationInfo([testFile],
        includedRoot: includedRoot, removeViaComments: removeViaComments);
  }

  /// Uses the InfoBuilder to build information for a single test file.
  ///
  /// Asserts that [originalContent] is migrated to [migratedContent]. Returns
  /// the singular UnitInfo which was built.
  Future<UnitInfo> buildInfoForSingleTestFile(String originalContent,
      {@required String migratedContent, bool removeViaComments = true}) async {
    addTestFile(originalContent);
    await buildInfo(removeViaComments: removeViaComments);
    // Ignore info for dart:core.
    var filteredInfos = [
      for (var info in infos) if (!info.path.contains('core.dart')) info
    ];
    expect(filteredInfos, hasLength(1));
    UnitInfo unit = filteredInfos[0];
    expect(unit.path, testFile);
    expect(unit.content, migratedContent);
    return unit;
  }

  /// Uses the InfoBuilder to build information for test files.
  ///
  /// Returns
  /// the singular UnitInfo which was built.
  Future<List<UnitInfo>> buildInfoForTestFiles(Map<String, String> files,
      {String includedRoot}) async {
    var testPaths = <String>[];
    files.forEach((String path, String content) {
      newFile(path, content: content);
      testPaths.add(path);
    });
    await _buildMigrationInfo(testPaths, includedRoot: includedRoot);
    // Ignore info for dart:core.
    var filteredInfos = [
      for (var info in infos) if (!info.path.contains('core.dart')) info
    ];
    return filteredInfos;
  }

  /// Uses the InfoBuilder to build information for files at [testPaths], which
  /// should all share a common parent directory, [includedRoot].
  Future<void> _buildMigrationInfo(List<String> testPaths,
      {String includedRoot, bool removeViaComments = true}) async {
    // Compute the analysis results.
    server.setAnalysisRoots('0', [includedRoot], [], {});
    // Run the migration engine.
    DartFixListener listener = DartFixListener(server);
    InstrumentationListener instrumentationListener = InstrumentationListener();
    NullabilityMigrationAdapter adapter = NullabilityMigrationAdapter(listener);
    NullabilityMigration migration = NullabilityMigration(adapter,
        permissive: false,
        instrumentation: instrumentationListener,
        removeViaComments: removeViaComments);
    Future<void> _forEachPath(
        void Function(ResolvedUnitResult) callback) async {
      for (var testPath in testPaths) {
        var result = await server
            .getAnalysisDriver(testPath)
            .currentSession
            .getResolvedUnit(testPath);
        callback(result);
      }
    }

    await _forEachPath(migration.prepareInput);
    await _forEachPath(migration.processInput);
    await _forEachPath(migration.finalizeInput);
    migration.finish();
    // Build the migration info.
    InstrumentationInformation info = instrumentationListener.data;
    InfoBuilder builder = InfoBuilder(
        resourceProvider, includedRoot, info, listener, adapter, migration);
    infos = await builder.explainMigration();
  }
}
