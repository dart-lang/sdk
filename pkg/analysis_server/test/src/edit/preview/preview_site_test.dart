// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_state.dart';
import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide NavigationTarget;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../nnbd_migration/nnbd_migration_test_base.dart';

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
    reranPaths = null;
    dartfixListener = DartFixListener(null);
    resourceProvider = MemoryResourceProvider();
    final migrationInfo = MigrationInfo({}, {}, null, null);
    state = MigrationState(null, null, dartfixListener, null, null);
    state.pathMapper = PathMapper(resourceProvider);
    state.migrationInfo = migrationInfo;
    site = PreviewSite(state, ([paths]) async {
      reranPaths = paths;
      return state;
    });
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
    dartfixListener.addSourceChange(
        'enable experiment',
        Location(analysisOptionsPath, 9, 0, 1, 9),
        SourceChange('enable experiment', edits: [
          SourceFileEdit(analysisOptionsPath, 0, edits: [
            SourceEdit(9, 0, '\n  enable-experiment:\n  - non-nullable')
          ])
        ]));
    // This should not crash.
    site.performApply();
    expect(analysisOptions.readAsStringSync(), '''
analyzer:
  enable-experiment:
  - non-nullable''');
    expect(state.hasBeenApplied, true);
  }

  void test_applyChangesEmpty() {
    final file = getFile('/test.dart');
    file.writeAsStringSync('void main() {}');
    site.performApply();
    expect(file.readAsStringSync(), 'void main() {}');
    expect(state.hasBeenApplied, true);
  }

  void test_applyChangesTwiceThrows() {
    site.performApply();
    expect(site.performApply, throwsA(isA<StateError>()));
  }

  void test_applyMigration_sanityCheck_dontApply() async {
    final path = convertPath('/test.dart');
    final file = getFile(path);
    site.unitInfoMap[path] = UnitInfo(path)
      ..diskContent = '// different content';
    final currentContent = 'void main() {}';
    file.writeAsStringSync(currentContent);
    dartfixListener.addSourceChange(
        'test change',
        Location(path, 10, 0, 1, 10),
        SourceChange('test change', edits: [
          SourceFileEdit(path, 0, edits: [SourceEdit(10, 0, 'List args')])
        ]));
    expect(() => site.performApply(), throwsA(isA<StateError>()));
    expect(file.readAsStringSync(), currentContent);
    expect(state.hasBeenApplied, false);
  }

  void test_applyMultipleChanges() {
    final path = convertPath('/test.dart');
    final file = getFile(path);
    final content = 'void main() {}';
    file.writeAsStringSync(content);
    site.unitInfoMap[path] = UnitInfo(path)..diskContent = content;
    dartfixListener.addSourceChange(
        'test change',
        Location(path, 10, 0, 1, 10),
        SourceChange('test change', edits: [
          SourceFileEdit(path, 0, edits: [
            SourceEdit(10, 0, 'List args'),
            SourceEdit(13, 0, '\n  print(args);\n')
          ])
        ]));
    site.performApply();
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
    dartfixListener.addSourceChange(
        'test change',
        Location(path, 10, 0, 1, 10),
        SourceChange('test change', edits: [
          SourceFileEdit(path, 0, edits: [SourceEdit(10, 0, 'List args')])
        ]));
    site.performApply();
    expect(file.readAsStringSync(), 'void main(List args) {}');
    expect(state.hasBeenApplied, true);
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
    expect(reranPaths, null);
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
  List<String> reranPaths;

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
  @override
  void setUp() {
    super.setUp();
    reranPaths = null;
    dartfixListener = DartFixListener(null);
    final migrationInfo = MigrationInfo({}, {}, null, null);
    state = MigrationState(null, null, dartfixListener, null, null);
    state.pathMapper = PathMapper(resourceProvider);
    state.migrationInfo = migrationInfo;
    site = PreviewSite(state, ([paths]) async {
      reranPaths = paths;
      return state;
    });
  }

  void test_performEdit_multiple() async {
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
    assertTraceEntry(unitInfo, trace.entries[0], null,
        unitInfo.content.indexOf('int/*?*/? y'), contains('explicit type'));
    assertTraceEntry(unitInfo, trace.entries[1], 'y',
        unitInfo.content.indexOf('= x;') + '= '.length, contains('data flow'));
    expect(state.hasBeenApplied, false);
    expect(state.needsRerun, true);
    expect(reranPaths, null);
  }
}
