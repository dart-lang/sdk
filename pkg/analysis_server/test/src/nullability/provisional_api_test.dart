// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/provisional_api.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ProvisionalApiTest);
  });
}

@reflectiveTest
class ProvisionalApiTest extends AbstractContextTest {
  test_single_file_multiple_changes() async {
    var content = '''
int f() => null;
int g() => null;
''';
    var expected = '''
int? f() => null;
int? g() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_single_file_single_change() async {
    var content = '''
int f() => null;
''';
    var expected = '''
int? f() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future _checkSingleFileChanges(String content, String expected) async {
    var sourcePath = convertPath('/home/test/lib/test.dart');
    newFile(sourcePath, content: content);
    var resolvedUnitResult = await session.getResolvedUnit(sourcePath);
    var migration = NullabilityMigration();
    migration.prepareInput(resolvedUnitResult, -1);
    migration.processInput(resolvedUnitResult);
    var result = migration.finish();
    expect(result, hasLength(1));
    expect(SourceEdit.applySequence(content, result[0].edits), expected);
  }
}
