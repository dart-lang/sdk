// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisGetImportElementsIntegrationTest);
  });
}

@reflectiveTest
class AnalysisGetImportElementsIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  /**
   * Pathname of the file containing Dart code.
   */
  String pathname;

  /**
   * Check that an edit.importElements request with the given list of [elements]
   * produces the [expected] list of edits.
   */
  checkEdits(List<ImportedElements> elements, List<SourceEdit> expected,
      {String expectedFile}) async {
    bool equals(SourceEdit actualEdit, SourceEdit expectedEdit) {
      return actualEdit.offset == expectedEdit.offset &&
          actualEdit.length == expectedEdit.length &&
          actualEdit.replacement == expectedEdit.replacement;
    }

    int find(List<SourceEdit> actual, SourceEdit expectedEdit) {
      for (int i = 0; i < actual.length; i++) {
        SourceEdit actualEdit = actual[i];
        if (equals(actualEdit, expectedEdit)) {
          return i;
        }
      }
      return -1;
    }

    EditImportElementsResult result =
        await sendEditImportElements(pathname, elements);

    SourceFileEdit edit = result.edit;
    expect(edit, isNotNull);
    if (expectedFile == null) {
      expect(edit.file, pathname);
    } else {
      expect(edit.file, expectedFile);
    }
    List<SourceEdit> actual = edit.edits;
    expect(actual, hasLength(expected.length));
    for (SourceEdit expectedEdit in expected) {
      int index = find(actual, expectedEdit);
      if (index < 0) {
        fail('Expected $expectedEdit; not found');
      }
      actual.removeAt(index);
    }
  }

  /**
   * Check that an edit.importElements request with the given list of [elements]
   * produces no edits.
   */
  Future<Null> checkNoEdits(List<ImportedElements> elements) async {
    EditImportElementsResult result =
        await sendEditImportElements(pathname, <ImportedElements>[]);

    SourceFileEdit edit = result.edit;
    expect(edit, isNotNull);
    expect(edit.edits, hasLength(0));
  }

  Future setUp() async {
    await super.setUp();
    pathname = sourcePath('test.dart');
  }

  test_importElements_definingUnit() async {
    writeFile(pathname, 'main() {}');
    standardAnalysisSetup();
    await analysisFinished;
    PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
    String sdkPath = FolderBasedDartSdk.defaultSdkDirectory(provider).path;
    String mathPath =
        provider.pathContext.join(sdkPath, 'lib', 'math', 'math.dart');

    await checkEdits(<ImportedElements>[
      new ImportedElements(mathPath, '', <String>['Random'])
    ], [
      new SourceEdit(0, 0, "import 'dart:math';\n\n")
    ]);
  }

  test_importElements_noEdits() async {
    writeFile(pathname, '');
    standardAnalysisSetup();
    await analysisFinished;

    await checkNoEdits(<ImportedElements>[]);
  }

  test_importElements_part() async {
    String libName = sourcePath('lib.dart');
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
    PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
    String sdkPath = FolderBasedDartSdk.defaultSdkDirectory(provider).path;
    String mathPath =
        provider.pathContext.join(sdkPath, 'lib', 'math', 'math.dart');

    await checkEdits(<ImportedElements>[
      new ImportedElements(mathPath, '', <String>['Random'])
    ], [
      new SourceEdit(0, 0, "import 'dart:math';\n\n")
    ], expectedFile: libName);
  }
}
