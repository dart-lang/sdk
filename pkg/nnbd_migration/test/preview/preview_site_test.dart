// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide NavigationTarget;
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/front_end/dartfix_listener.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/migration_state.dart';
import 'package:nnbd_migration/src/front_end/navigation_tree_renderer.dart';
import 'package:nnbd_migration/src/front_end/offset_mapper.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:nnbd_migration/src/front_end/web/navigation_tree.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../front_end/nnbd_migration_test_base.dart';
import '../utilities/test_logger.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreviewSiteTest);
    defineReflectiveTests(PreviewSiteWithEngineTest);
  });
}

@reflectiveTest
class PreviewSiteTest with ResourceProviderMixin, PreviewSiteTestMixin {
  @override
  Future<void> performEdit(String path, int offset, String replacement) {
    final pathUri = Uri.file(path).path;
    return site
        .performEdit(Uri.parse('localhost://$pathUri?offset=$offset&end=$offset'
            '&replacement=${Uri.encodeComponent(replacement)}'));
  }

  void setUp() {
    dartfixListener = DartFixListener(null, ListenerClient());
    resourceProvider = MemoryResourceProvider();
    final migrationInfo =
        MigrationInfo({}, {}, resourceProvider.pathContext, null);
    state = MigrationState(null, null, dartfixListener, null, {});
    state.pathMapper = PathMapper(resourceProvider);
    state.migrationInfo = migrationInfo;
    logger = TestLogger(false /*isVerbose*/);
    site = PreviewSite(state, () async {
      return state;
    }, () {}, logger);
  }

  void test_apply_regress41391() async {
    final path = convertPath('/test.dart');
    final file = getFile(path);
    final analysisOptionsPath = convertPath('/analysis_options.yaml');
    final analysisOptions = getFile(analysisOptionsPath);
    analysisOptions.writeAsStringSync('analyzer:');
    final content = 'void main() {}';
    file.writeAsStringSync(content);
    site.unitInfoMap[path] = UnitInfo(path)..diskContent = content;
    // Add a source change for analysis_options, which has no UnitInfo.
    dartfixListener.addSourceFileEdit(
        'enable experiment',
        Location(analysisOptionsPath, 9, 0, 1, 9),
        SourceFileEdit(analysisOptionsPath, 0, edits: [
          SourceEdit(9, 0, '\n  enable-experiment:\n  - non-nullable')
        ]));
    // This should not crash.
    site.performApply([]);
    expect(analysisOptions.readAsStringSync(), '''
analyzer:
  enable-experiment:
  - non-nullable''');
    expect(state.hasBeenApplied, true);
  }

  void test_applyChangesEmpty() {
    final file = getFile('/test.dart');
    file.writeAsStringSync('void main() {}');
    site.performApply([]);
    expect(file.readAsStringSync(), 'void main() {}');
    expect(state.hasBeenApplied, true);
  }

  void test_applyChangesTwiceThrows() {
    site.performApply([]);
    expect(() => site.performApply([]), throwsA(isA<StateError>()));
  }

  void test_applyMigration_sanityCheck_dontApply() async {
    final path = convertPath('/test.dart');
    final file = getFile(path);
    site.unitInfoMap[path] = UnitInfo(path)
      ..diskContent = '// different content';
    final currentContent = 'void main() {}';
    file.writeAsStringSync(currentContent);
    dartfixListener.addSourceFileEdit(
        'test change',
        Location(path, 10, 0, 1, 10),
        SourceFileEdit(path, 0, edits: [SourceEdit(10, 0, 'List args')]));
    expect(() => site.performApply([]), throwsA(isA<StateError>()));
    expect(file.readAsStringSync(), currentContent);
    expect(state.hasBeenApplied, false);
  }

  void test_applyMultipleChanges() {
    final path = convertPath('/test.dart');
    final file = getFile(path);
    final content = 'void main() {}';
    file.writeAsStringSync(content);
    site.unitInfoMap[path] = UnitInfo(path)..diskContent = content;
    dartfixListener.addSourceFileEdit(
        'test change',
        Location(path, 10, 0, 1, 10),
        SourceFileEdit(path, 0, edits: [
          SourceEdit(10, 0, 'List args'),
          SourceEdit(13, 0, '\n  print(args);\n')
        ]));
    site.performApply([]);
    expect(file.readAsStringSync(), '''
void main(List args) {
  print(args);
}''');
    expect(state.hasBeenApplied, true);
  }

  void test_applySingleChange() {
    final path = convertPath('/test.dart');
    final file = getFile(path);
    final content = 'void main() {}';
    file.writeAsStringSync(content);
    site.unitInfoMap[path] = UnitInfo(path)..diskContent = content;
    dartfixListener.addSourceFileEdit(
        'test change',
        Location(path, 10, 0, 1, 10),
        SourceFileEdit(path, 0, edits: [SourceEdit(10, 0, 'List args')]));
    site.performApply([]);
    expect(file.readAsStringSync(), 'void main(List args) {}');
    expect(state.hasBeenApplied, true);
  }

  void test_optOutOfNullSafety_blankLines() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('  \n  \n'),
        equals('// @dart=2.9\n\n  \n  \n'));
  }

  void test_optOutOfNullSafety_blankLines_windows() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('  \r\n  \r\n'),
        equals('// @dart=2.9\r\n\r\n  \r\n  \r\n'));
  }

  void test_optOutOfNullSafety_commentThenCode() {
    expect(
        IncrementalPlan.optCodeOutOfNullSafety('// comment\n\nvoid main() {}'),
        equals('// comment\n\n\n// @dart=2.9\n\nvoid main() {}'));
  }

  void test_optOutOfNullSafety_commentThenCode_windows() {
    expect(
        IncrementalPlan.optCodeOutOfNullSafety(
            '// comment\r\n\r\nvoid main() {}'),
        equals('// comment\r\n\r\n\r\n// @dart=2.9\r\n\r\nvoid main() {}'));
  }

  void test_optOutOfNullSafety_empty() {
    expect(IncrementalPlan.optCodeOutOfNullSafety(''), equals('// @dart=2.9'));
  }

  void test_optOutOfNullSafety_singleComment_multiLine() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('// line 1\n// line 2'),
        equals('// line 1\n// line 2\n\n// @dart=2.9\n'));
  }

  void test_optOutOfNullSafety_singleComment_multiLine_indented() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('  // line 1\n  // line 2'),
        equals('  // line 1\n  // line 2\n\n// @dart=2.9\n'));
  }

  void test_optOutOfNullSafety_singleComment_singleLine() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('// comment'),
        equals('// comment\n\n// @dart=2.9\n'));
  }

  void test_optOutOfNullSafety_singleComment_singleLine_trailingNewline() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('// comment\n'),
        equals('// comment\n\n\n// @dart=2.9\n'));
  }

  void test_optOutOfNullSafety_singleLine() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('void main() {}'),
        equals('// @dart=2.9\n\nvoid main() {}'));
  }

  void test_optOutOfNullSafety_singleLine_afterBlankLines() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('\n\nvoid main() {}'),
        equals('// @dart=2.9\n\n\n\nvoid main() {}'));
  }

  void test_optOutOfNullSafety_singleLine_windows() {
    expect(IncrementalPlan.optCodeOutOfNullSafety('void main() {}\r\n'),
        equals('// @dart=2.9\r\n\r\nvoid main() {}\r\n'));
  }

  void test_performEdit() {
    final path = convertPath('/test.dart');
    final file = getFile(path);
    final content = 'int foo() {}';
    final unitInfo = UnitInfo(path)
      ..diskContent = content
      ..content = content
      ..diskChangesOffsetMapper = OffsetMapper.identity;
    site.unitInfoMap[path] = unitInfo;
    file.writeAsStringSync(content);
    performEdit(path, 3, '/*?*/');
    expect(file.readAsStringSync(), 'int/*?*/ foo() {}');
    expect(state.hasBeenApplied, false);
    expect(state.needsRerun, true);
    expect(unitInfo.content, 'int/*?*/ foo() {}');
  }

  void test_performEdit_sanityCheck_dontApply() {
    final path = convertPath('/test.dart');
    final file = getFile(path);
    site.unitInfoMap[path] = UnitInfo(path)
      ..diskContent = '// different content';
    final currentContent = 'void main() {}';
    file.writeAsStringSync(currentContent);
    expect(() => performEdit(path, 0, 'foo'), throwsA(isA<StateError>()));
    expect(file.readAsStringSync(), currentContent);
    expect(state.hasBeenApplied, false);
  }
}

mixin PreviewSiteTestMixin {
  PreviewSite site;
  DartFixListener dartfixListener;
  MigrationState state;
  TestLogger logger;

  Future<void> performEdit(String path, int offset, String replacement) {
    final pathUri = Uri.file(path).path;
    return site
        .performEdit(Uri.parse('localhost://$pathUri?offset=$offset&end=$offset'
            '&replacement=${Uri.encodeComponent(replacement)}'));
  }
}

@reflectiveTest
class PreviewSiteWithEngineTest extends NnbdMigrationTestBase
    with ResourceProviderMixin, PreviewSiteTestMixin {
  MigrationInfo migrationInfo;

  Future<void> setUpMigrationInfo(Map<String, String> files) async {
    await buildInfoForTestFiles(files, includedRoot: projectPath);
    dartfixListener = DartFixListener(null, ListenerClient());
    migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, projectPath);
    state = MigrationState(null, null, dartfixListener, null, {});
    nodeMapper = state.nodeMapper;
    state.pathMapper = PathMapper(resourceProvider);
    state.migrationInfo = migrationInfo;
    logger = TestLogger(false /*isVerbose*/);
    site = PreviewSite(state, () async {
      return state;
    }, () {}, logger);
  }

  void test_applyHintAction() async {
    await setUpMigrationInfo({});
    final path = convertPath('$projectPath/bin/test.dart');
    final file = getFile(path);
    final content = r'''
int x;
int y = x;
''';
    file.writeAsStringSync(content);
    final migratedContent = '''
int? x;
int? y = x;
''';
    final unitInfo = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    site.unitInfoMap[path] = unitInfo;
    await site.performHintAction(
        unitInfo.regions[1].traces[0].entries[0].hintActions[0]);
    await site.performHintAction(
        unitInfo.regions[1].traces[0].entries[2].hintActions[0]);
    expect(file.readAsStringSync(), '''
int/*?*/ x;
int/*?*/ y = x;
''');
    expect(unitInfo.content, '''
int/*?*/? x;
int/*?*/? y = x;
''');
    assertRegion(
        region: unitInfo.regions[0], offset: unitInfo.content.indexOf('? x'));
    assertRegion(
        region: unitInfo.regions[1], offset: unitInfo.content.indexOf('? y'));
    final targets = List<NavigationTarget>.from(unitInfo.targets);
    assertInTargets(
        targets: targets,
        offset: unitInfo.content.indexOf('x'),
        offsetMapper: unitInfo.offsetMapper);
    assertInTargets(
        targets: targets,
        offset: unitInfo.content.indexOf('y'),
        offsetMapper: unitInfo.offsetMapper);
    var trace = unitInfo.regions[1].traces[0];
    assertTraceEntry(unitInfo, trace.entries[0], 'y',
        unitInfo.content.indexOf('int/*?*/? y'), contains('y (test.dart:2:1)'));
    assertTraceEntry(unitInfo, trace.entries[1], 'y',
        unitInfo.content.indexOf('= x;') + '= '.length, contains('data flow'));
    expect(state.hasBeenApplied, false);
    expect(state.needsRerun, true);
  }

  void test_applyHintAction_removeHint() async {
    await setUpMigrationInfo({});
    final path = convertPath('$projectPath/bin/test.dart');
    final file = getFile(path);
    final content = r'''
int/*!*/ x;
int y = x;
''';
    file.writeAsStringSync(content);
    final migratedContent = '''
int/*!*/ x;
int  y = x;
''';
    final unitInfo = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    site.unitInfoMap[path] = unitInfo;
    await site.performHintAction(
        unitInfo.regions[0].traces[0].entries[0].hintActions[0]);
    expect(file.readAsStringSync(), '''
int x;
int y = x;
''');
    expect(unitInfo.content, '''
int x;
int  y = x;
''');
    expect(unitInfo.regions, hasLength(1));
    assertRegion(
        kind: NullabilityFixKind.typeNotMadeNullable,
        region: unitInfo.regions[0],
        offset: unitInfo.content.indexOf('  y'));
    final targets = List<NavigationTarget>.from(unitInfo.targets);
    assertInTargets(
        targets: targets,
        offset: unitInfo.content.indexOf('x'),
        offsetMapper: unitInfo.offsetMapper);
    expect(state.hasBeenApplied, false);
    expect(state.needsRerun, true);
  }

  void test_applyMigration_migratePreviouslyOptedOutFile() async {
    final path = convertPath('$projectPath/lib/a.dart');
    final content = '''
// @dart=2.9

void main() {}''';
    await setUpMigrationInfo({path: content});
    site.unitInfoMap[path] = UnitInfo(path)
      ..diskContent = content
      ..wasExplicitlyOptedOut = true;
    dartfixListener.addSourceFileEdit(
        'remove DLV comment',
        Location(path, 0, 14, 1, 1),
        SourceFileEdit(path, 0, edits: [SourceEdit(0, 14, '')]));
    var navigationTree =
        NavigationTreeRenderer(migrationInfo, state.pathMapper).render();
    site.performApply(navigationTree);
    expect(getFile(path).readAsStringSync(), 'void main() {}');
    expect(logger.stdoutBuffer.toString(), contains('''
Migrated 1 file:
    ${convertPath('lib/a.dart')}
'''));
  }

  void test_applyMigration_optOutEmptyFile() async {
    final path = convertPath('$projectPath/lib/a.dart');
    final content = '';
    await setUpMigrationInfo({path: content});
    site.unitInfoMap[path] = UnitInfo(path)
      ..diskContent = content
      ..wasExplicitlyOptedOut = false;
    var navigationTree =
        NavigationTreeRenderer(migrationInfo, state.pathMapper).render();
    var libDir = navigationTree.single as NavigationTreeDirectoryNode;
    (libDir.subtree.single as NavigationTreeFileNode).migrationStatus =
        UnitMigrationStatus.optingOut;
    site.performApply(navigationTree);
    expect(getFile(path).readAsStringSync(), '// @dart=2.9');
    expect(logger.stdoutBuffer.toString(), contains('''
Opted 1 file out of null safety with a new Dart language version comment:
    ${convertPath('lib/a.dart')}
'''));
  }

  void test_applyMigration_optOutFileWithEdits() async {
    final path = convertPath('$projectPath/lib/a.dart');
    final content = 'void main() {}';
    await setUpMigrationInfo({path: content});
    site.unitInfoMap[path] = UnitInfo(path)
      ..diskContent = content
      ..wasExplicitlyOptedOut = false;
    dartfixListener.addSourceFileEdit(
        'test change',
        Location(path, 10, 0, 1, 10),
        SourceFileEdit(path, 0, edits: [SourceEdit(10, 0, 'List args')]));
    var navigationTree =
        NavigationTreeRenderer(migrationInfo, state.pathMapper).render();
    var libDir = navigationTree.single as NavigationTreeDirectoryNode;
    (libDir.subtree.single as NavigationTreeFileNode).migrationStatus =
        UnitMigrationStatus.optingOut;
    site.performApply(navigationTree);
    expect(getFile(path).readAsStringSync(), '''
// @dart=2.9

void main() {}''');
    expect(logger.stdoutBuffer.toString(), contains('''
Opted 1 file out of null safety with a new Dart language version comment:
    ${convertPath('lib/a.dart')}
'''));
  }

  void test_applyMigration_optOutFileWithoutEdits() async {
    final path = convertPath('$projectPath/lib/a.dart');
    final content = 'void main() {}';
    await setUpMigrationInfo({path: content});
    site.unitInfoMap[path] = UnitInfo(path)
      ..diskContent = content
      ..wasExplicitlyOptedOut = false;
    var navigationTree =
        NavigationTreeRenderer(migrationInfo, state.pathMapper).render();
    var libDir = navigationTree.single as NavigationTreeDirectoryNode;
    (libDir.subtree.single as NavigationTreeFileNode).migrationStatus =
        UnitMigrationStatus.optingOut;
    site.performApply(navigationTree);
    expect(getFile(path).readAsStringSync(), '''
// @dart=2.9

void main() {}''');
    expect(logger.stdoutBuffer.toString(), contains('''
Opted 1 file out of null safety with a new Dart language version comment:
    ${convertPath('lib/a.dart')}
'''));
  }

  void test_applyMigration_optOutOne_migrateAnother() async {
    final pathA = convertPath('$projectPath/lib/a.dart');
    final pathB = convertPath('$projectPath/lib/b.dart');
    final content = 'void main() {}';
    await setUpMigrationInfo({pathA: content, pathB: content});
    site.unitInfoMap[pathA] = UnitInfo(pathA)
      ..diskContent = content
      ..wasExplicitlyOptedOut = false;
    site.unitInfoMap[pathB] = UnitInfo(pathB)
      ..diskContent = content
      ..wasExplicitlyOptedOut = false;
    dartfixListener.addSourceFileEdit(
        'test change',
        Location(pathA, 10, 0, 1, 10),
        SourceFileEdit(pathA, 0, edits: [SourceEdit(10, 0, 'List args')]));
    dartfixListener.addSourceFileEdit(
        'test change',
        Location(pathB, 10, 0, 1, 10),
        SourceFileEdit(pathB, 0, edits: [SourceEdit(10, 0, 'List args')]));
    var navigationTree =
        NavigationTreeRenderer(migrationInfo, state.pathMapper).render();
    var libDir = navigationTree.single as NavigationTreeDirectoryNode;
    (libDir.subtree[0] as NavigationTreeFileNode).migrationStatus =
        UnitMigrationStatus.optingOut;
    site.performApply(navigationTree);
    expect(getFile(pathA).readAsStringSync(), '''
// @dart=2.9

void main() {}''');
    expect(getFile(pathB).readAsStringSync(), '''
void main(List args) {}''');
    expect(logger.stdoutBuffer.toString(), contains('''
Migrated 1 file:
    ${convertPath('lib/b.dart')}
Opted 1 file out of null safety with a new Dart language version comment:
    ${convertPath('lib/a.dart')}
'''));
  }

  void test_applyMigration_optOutPreviouslyOptedOutFile() async {
    final path = convertPath('$projectPath/lib/a.dart');
    final content = '''
// @dart=2.9

int a;''';
    await setUpMigrationInfo({path: content});
    site.unitInfoMap[path] = UnitInfo(path)
      ..diskContent = content
      ..wasExplicitlyOptedOut = true;
    dartfixListener.addSourceFileEdit(
        'remove DLV comment',
        Location(path, 0, 14, 1, 1),
        SourceFileEdit(path, 0, edits: [SourceEdit(0, 14, '')]));
    var navigationTree =
        NavigationTreeRenderer(migrationInfo, state.pathMapper).render();
    var libDir = navigationTree.single as NavigationTreeDirectoryNode;
    (libDir.subtree.single as NavigationTreeFileNode).migrationStatus =
        UnitMigrationStatus.optingOut;
    site.performApply(navigationTree);
    expect(getFile(path).readAsStringSync(), content);
    expect(logger.stdoutBuffer.toString(), contains('''
Kept 1 file opted out of null safety:
    ${convertPath('lib/a.dart')}
'''));
  }

  void test_performEdit_multiple() async {
    await setUpMigrationInfo({});
    final path = convertPath('/test.dart');
    final file = getFile(path);
    final content = r'''
int x;
int y = x;
''';
    file.writeAsStringSync(content);
    final migratedContent = '''
int? x;
int? y = x;
''';
    final unitInfo = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    site.unitInfoMap[path] = unitInfo;
    final firstEditOffset = unitInfo.regions[0].edits[0].offset;
    performEdit(path, firstEditOffset, '/*?*/');
    final secondEditOffset = unitInfo.regions[1].edits[0].offset;
    performEdit(path, secondEditOffset, '/*?*/');
    expect(file.readAsStringSync(), '''
int/*?*/ x;
int/*?*/ y = x;
''');
    expect(unitInfo.content, '''
int/*?*/? x;
int/*?*/? y = x;
''');
    assertRegion(
        region: unitInfo.regions[0], offset: unitInfo.content.indexOf('? x'));
    assertRegion(
        region: unitInfo.regions[1], offset: unitInfo.content.indexOf('? y'));
    final targets = List<NavigationTarget>.from(unitInfo.targets);
    assertInTargets(
        targets: targets,
        offset: unitInfo.content.indexOf('x'),
        offsetMapper: unitInfo.offsetMapper);
    assertInTargets(
        targets: targets,
        offset: unitInfo.content.indexOf('y'),
        offsetMapper: unitInfo.offsetMapper);
    var trace = unitInfo.regions[1].traces[0];
    assertTraceEntry(unitInfo, trace.entries[0], 'y',
        unitInfo.content.indexOf('int/*?*/? y'), contains('y (test.dart:2:1)'));
    assertTraceEntry(unitInfo, trace.entries[1], 'y',
        unitInfo.content.indexOf('= x;') + '= '.length, contains('data flow'));
    expect(state.hasBeenApplied, false);
    expect(state.needsRerun, true);
  }
}
