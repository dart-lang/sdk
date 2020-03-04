// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_state.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreviewSiteTest);
  });
}

@reflectiveTest
class PreviewSiteTest {
  PreviewSite site;
  ResourceProvider resourceProvider;
  DartFixListener dartfixListener;
  MigrationState state;

  void setUp() {
    dartfixListener = DartFixListener(null);
    resourceProvider = MemoryResourceProvider();
    final migrationInfo = MigrationInfo({}, {}, null, null);
    state = MigrationState(null, null, dartfixListener, null, null);
    state.pathMapper = PathMapper(resourceProvider);
    state.migrationInfo = migrationInfo;
    site = PreviewSite(state);
  }

  void test_applyChangesEmpty() {
    resourceProvider.getFile('/test.dart').writeAsStringSync('void main() {}');
    site.performApply();
    expect(resourceProvider.getFile('/test.dart').readAsStringSync(),
        'void main() {}');
    expect(state.hasBeenApplied, true);
  }

  void test_applyChangesTwiceThrows() {
    site.performApply();
    expect(site.performApply, throwsA(isA<StateError>()));
  }

  void test_applyMultipleChanges() {
    resourceProvider.getFile('/test.dart').writeAsStringSync('void main() {}');
    dartfixListener.addSourceChange(
        "test change",
        Location('/test.dart', 10, 0, 1, 10),
        SourceChange("test change", edits: [
          SourceFileEdit('/test.dart', 0, edits: [
            SourceEdit(10, 0, 'List args'),
            SourceEdit(13, 0, '\n  print(args);\n')
          ])
        ]));
    site.performApply();
    expect(resourceProvider.getFile('/test.dart').readAsStringSync(), '''
void main(List args) {
  print(args);
}''');
    expect(state.hasBeenApplied, true);
  }

  void test_applySingleChange() {
    resourceProvider.getFile('/test.dart').writeAsStringSync('void main() {}');
    dartfixListener.addSourceChange(
        "test change",
        Location('/test.dart', 10, 0, 1, 10),
        SourceChange("test change", edits: [
          SourceFileEdit('/test.dart', 0,
              edits: [SourceEdit(10, 0, 'List args')])
        ]));
    site.performApply();
    expect(resourceProvider.getFile('/test.dart').readAsStringSync(),
        'void main(List args) {}');
    expect(state.hasBeenApplied, true);
  }
}
