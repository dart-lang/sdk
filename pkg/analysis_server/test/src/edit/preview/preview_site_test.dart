// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_state.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreviewSiteTest);
  });
}

@reflectiveTest
class PreviewSiteTest with ResourceProviderMixin {
  PreviewSite site;
  DartFixListener dartfixListener;
  MigrationState state;
  List<String> reranPaths;

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
      ..originalContent = '// different content';
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
    site.unitInfoMap[path] = UnitInfo(path)..originalContent = content;
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
    site.unitInfoMap[path] = UnitInfo(path)..originalContent = content;
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
    final pathUri = Uri.file(path).path;
    final file = getFile(path);
    final content = 'int foo() {}';
    site.unitInfoMap[path] = UnitInfo(path)..originalContent = content;
    file.writeAsStringSync(content);
    site.performEdit(Uri.parse(
        'localhost://$pathUri?offset=3&end=3&replacement=${Uri.encodeComponent('/*?*/')}'));
    expect(file.readAsStringSync(), 'int/*?*/ foo() {}');
    expect(state.hasBeenApplied, false);
    expect(reranPaths, [path]);
  }

  void test_performEdit_sanityCheck_dontApply() {
    final path = convertPath('/test.dart');
    final pathUri = Uri.file(path).path;
    final file = getFile(path);
    site.unitInfoMap[path] = UnitInfo(path)
      ..originalContent = '// different content';
    final currentContent = 'void main() {}';
    file.writeAsStringSync(currentContent);
    expect(
        () => site.performEdit(
            Uri.parse('localhost://$pathUri?offset=0&end=0&replacement=foo')),
        throwsA(isA<StateError>()));
    expect(file.readAsStringSync(), currentContent);
    expect(state.hasBeenApplied, false);
  }
}
