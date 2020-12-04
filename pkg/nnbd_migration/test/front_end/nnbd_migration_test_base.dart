// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/front_end/dartfix_listener.dart';
import 'package:nnbd_migration/src/front_end/driver_provider_impl.dart';
import 'package:nnbd_migration/src/front_end/info_builder.dart';
import 'package:nnbd_migration/src/front_end/instrumentation_listener.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/non_nullable_fix.dart';
import 'package:nnbd_migration/src/front_end/offset_mapper.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities/test_logger.dart';
import 'analysis_abstract.dart';

class ListenerClient implements DartFixListenerClient {
  @override
  void onException(String detail) {
    fail('Unexpected call to onException($detail)');
  }

  @override
  void onFatalError(String detail) {
    fail('Unexpected call to onFatalError($detail)');
  }

  @override
  void onMessage(String detail) {
    fail('Unexpected call to onMessage($detail)');
  }
}

@reflectiveTest
class NnbdMigrationTestBase extends AbstractAnalysisTest {
  /// The information produced by the InfoBuilder, or `null` if [buildInfo] has
  /// not yet completed.
  Set<UnitInfo> infos;
  NodeMapper nodeMapper;

  /// Assert that some target in [targets] has various properties.
  void assertInTargets(
      {@required Iterable<NavigationTarget> targets,
      int offset,
      int length,
      OffsetMapper offsetMapper}) {
    var failureReasons = [
      if (offset != null) 'offset: $offset',
      if (length != null) 'length: $length',
      if (offsetMapper != null) 'match a custom offset mapper',
    ].join(' and ');
    offsetMapper ??= OffsetMapper.identity;
    expect(targets.any((t) {
      return (offset == null || offset == offsetMapper.map(t.offset)) &&
          (length == null || length == t.length);
    }), isTrue, reason: 'Expected one of $targets to contain $failureReasons');
  }

  /// Assert various properties of the given [region]. If an [offset] is
  /// provided but no [length] is provided, a default length of `1` will be
  /// used.
  void assertRegion(
      {@required RegionInfo region,
      int offset,
      int length,
      Object explanation = anything,
      Object edits = anything,
      Object traces = anything,
      Object kind = NullabilityFixKind.makeTypeNullable}) {
    if (offset != null) {
      expect(region.offset, offset);
      expect(region.length, length ?? 1);
    } else if (length != null) {
      expect(region.length, length);
    }
    expect(region.kind, kind);
    expect(region.edits, edits);
    expect(region.explanation, explanation);
    expect(region.traces, traces);
  }

  /// Asserts various properties of the pair of [regions], `regions[index]` and
  /// `regions[index + 1]`.  The expected offsets and lengths are specified
  /// separately; everything else is asserted using the same matcher.
  void assertRegionPair(List<RegionInfo> regions, int index,
      {int offset1,
      int length1,
      int offset2,
      int length2,
      Object explanation = anything,
      Object edits = anything,
      Object traces = anything,
      Object kind = anything}) {
    assertRegion(
        region: regions[index],
        offset: offset1,
        length: length1,
        explanation: explanation,
        edits: edits,
        traces: traces,
        kind: kind);
    assertRegion(
        region: regions[index + 1],
        offset: offset2,
        length: length2,
        explanation: explanation,
        edits: edits,
        traces: traces,
        kind: kind);
  }

  void assertTraceEntry(UnitInfo unit, TraceEntryInfo entryInfo,
      String function, int offset, Object descriptionMatcher,
      {Set<HintActionKind> hintActions}) {
    if (offset == null) {
      expect(entryInfo.target, isNull);
    } else {
      assert(offset >= 0);
      var lineInfo = LineInfo.fromContent(unit.content);
      var expectedLocation = lineInfo.getLocation(offset);
      expect(entryInfo.target.filePath, unit.path);
      expect(entryInfo.target.line, expectedLocation.lineNumber);
      expect(unit.offsetMapper.map(entryInfo.target.offset), offset);
    }
    expect(entryInfo.function, function);
    expect(entryInfo.description, descriptionMatcher);
    if (hintActions != null) {
      assertTraceHintActions(unit, entryInfo, hintActions, offset);
    }
  }

  void assertTraceHintActions(UnitInfo unit, TraceEntryInfo traceEntry,
      Set<HintActionKind> expectedHints, int nodeOffset) {
    final actionsByKind = Map<HintActionKind, HintAction>.fromIterables(
        traceEntry.hintActions.map((action) => action.kind),
        traceEntry.hintActions);
    expect(actionsByKind, hasLength(expectedHints.length));
    for (final expectedHint in expectedHints) {
      final action = actionsByKind[expectedHint];
      expect(action, isNotNull);
      final node = nodeMapper.nodeForId(action.nodeId);
      expect(node, isNotNull);
      expect(unit.offsetMapper.map(node.codeReference.offset), nodeOffset);
    }
  }

  /// Uses the InfoBuilder to build information for [testFile].
  ///
  /// The information is stored in [infos].
  Future<void> buildInfo(
      {bool removeViaComments = true, bool warnOnWeakCode = false}) async {
    var includedRoot = resourceProvider.pathContext.dirname(testFile);
    await _buildMigrationInfo([testFile],
        includedRoot: includedRoot,
        removeViaComments: removeViaComments,
        warnOnWeakCode: warnOnWeakCode);
  }

  /// Uses the InfoBuilder to build information for a single test file.
  ///
  /// Asserts that [originalContent] is migrated to [migratedContent]. Returns
  /// the singular UnitInfo which was built.
  Future<UnitInfo> buildInfoForSingleTestFile(String originalContent,
      {@required String migratedContent,
      bool removeViaComments = true,
      bool warnOnWeakCode = false}) async {
    addTestFile(originalContent);
    await buildInfo(
        removeViaComments: removeViaComments, warnOnWeakCode: warnOnWeakCode);
    // Ignore info for dart:core.
    var filteredInfos = [
      for (var info in infos)
        if (!info.path.contains('core.dart')) info
    ];
    expect(filteredInfos, hasLength(1));
    var unit = filteredInfos[0];
    expect(unit.path, testFile);
    expect(unit.content, migratedContent);
    return unit;
  }

  /// Uses the [InfoBuilder] to build information for test files.
  ///
  /// Returns the singular [UnitInfo] which was built.
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
      for (var info in infos)
        if (!info.path.contains('core.dart')) info
    ];
    return filteredInfos;
  }

  void setUp() {
    super.setUp();
    nodeMapper = SimpleNodeMapper();
  }

  /// Uses the InfoBuilder to build information for files at [testPaths], which
  /// should all share a common parent directory, [includedRoot].
  Future<void> _buildMigrationInfo(List<String> testPaths,
      {String includedRoot,
      bool removeViaComments = true,
      bool warnOnWeakCode = false}) async {
    // Compute the analysis results.
    var server = DriverProviderImpl(resourceProvider, driver.analysisContext);
    // Run the migration engine.
    var listener = DartFixListener(server, ListenerClient());
    var instrumentationListener = InstrumentationListener();
    var adapter = NullabilityMigrationAdapter(listener);
    var migration = NullabilityMigration(adapter, getLineInfo,
        permissive: false,
        instrumentation: instrumentationListener,
        removeViaComments: removeViaComments,
        warnOnWeakCode: warnOnWeakCode);
    Future<void> _forEachPath(
        void Function(ResolvedUnitResult) callback) async {
      for (var testPath in testPaths) {
        var result = await driver.currentSession.getResolvedUnit(testPath);
        callback(result);
      }
    }

    await _forEachPath(migration.prepareInput);
    expect(migration.unmigratedDependencies, isEmpty);
    await _forEachPath(migration.processInput);
    await _forEachPath(migration.finalizeInput);
    migration.finish();
    // Build the migration info.
    var info = instrumentationListener.data;
    var logger = TestLogger(false);
    var builder = InfoBuilder(resourceProvider, includedRoot, info, listener,
        migration, nodeMapper, logger);
    infos = await builder.explainMigration();
  }
}
