// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:cli_util/cli_util.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisGetImportElementsIntegrationTest);
  });
}

@reflectiveTest
class AnalysisGetImportElementsIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  /// Pathname of the file containing Dart code.
  String pathname;

  /// Check that an edit.importElements request with the given list of
  /// [elements] produces the [expected] list of edits.
  Future<void> checkEdits(
      List<ImportedElements> elements, List<SourceEdit> expected,
      {String expectedFile}) async {
    bool equals(SourceEdit actualEdit, SourceEdit expectedEdit) {
      return actualEdit.offset == expectedEdit.offset &&
          actualEdit.length == expectedEdit.length &&
          actualEdit.replacement == expectedEdit.replacement;
    }

    int find(List<SourceEdit> actual, SourceEdit expectedEdit) {
      for (var i = 0; i < actual.length; i++) {
        var actualEdit = actual[i];
        if (equals(actualEdit, expectedEdit)) {
          return i;
        }
      }
      return -1;
    }

    var result = await sendEditImportElements(pathname, elements);

    var edit = result.edit;
    expect(edit, isNotNull);
    if (expectedFile == null) {
      expect(edit.file, pathname);
    } else {
      expect(edit.file, expectedFile);
    }
    var actual = edit.edits;
    expect(actual, hasLength(expected.length));
    for (var expectedEdit in expected) {
      var index = find(actual, expectedEdit);
      if (index < 0) {
        fail('Expected $expectedEdit; not found');
      }
      actual.removeAt(index);
    }
  }

  /// Check that an edit.importElements request with the given list of
  /// [elements] produces no edits.
  Future<void> checkNoEdits(List<ImportedElements> elements) async {
    var result = await sendEditImportElements(pathname, <ImportedElements>[]);

    expect(result.edit, isNull);
  }

  @override
  Future setUp() async {
    await super.setUp();
    pathname = sourcePath('test.dart');
  }

  Future<void> test_importElements_definingUnit() async {
    writeFile(pathname, 'main() {}');
    standardAnalysisSetup();
    await analysisFinished;
    var provider = PhysicalResourceProvider.INSTANCE;
    var sdkPath = getSdkPath();
    var mathPath =
        provider.pathContext.join(sdkPath, 'lib', 'math', 'math.dart');

    await checkEdits(<ImportedElements>[
      ImportedElements(mathPath, '', <String>['Random'])
    ], [
      SourceEdit(0, 0, "import 'dart:math';\n\n")
    ]);
  }

  Future<void> test_importElements_noEdits() async {
    writeFile(pathname, '');
    standardAnalysisSetup();
    await analysisFinished;

    await checkNoEdits(<ImportedElements>[]);
  }

  Future<void> test_importElements_part() async {
    var libName = sourcePath('lib.dart');
    writeFile(libName, '''
part 'test.dart';
main() {}
''');
    writeFile(pathname, '''
part of 'lib.dart';

class C {}
''');
    standardAnalysisSetup();
    await analysisFinished;
    var provider = PhysicalResourceProvider.INSTANCE;
    var sdkPath = getSdkPath();
    var mathPath =
        provider.pathContext.join(sdkPath, 'lib', 'math', 'math.dart');

    await checkEdits(<ImportedElements>[
      ImportedElements(mathPath, '', <String>['Random'])
    ], [
      SourceEdit(0, 0, "import 'dart:math';\n\n")
    ], expectedFile: libName);
  }
}
