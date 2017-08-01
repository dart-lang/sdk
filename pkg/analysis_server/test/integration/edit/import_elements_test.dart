// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
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
   * Dart code under test.
   */
  final String text = r'''
''';

  /**
   * Check that an edit.importElements request with the given list of [elements]
   * produces the [expected] list of edits.
   */
  checkEdits(List<ImportedElements> elements, List<SourceEdit> expected) async {
    EditImportElementsResult result =
        await sendEditImportElements(pathname, elements);

    expect(result.edits, hasLength(expected.length));
    // TODO(brianwilkerson) Finish implementing this.
  }

  /**
   * Check that an edit.importElements request with the given list of [elements]
   * produces no edits.
   */
  Future<Null> checkNoEdits(List<ImportedElements> elements) async {
    EditImportElementsResult result =
        await sendEditImportElements(pathname, <ImportedElements>[]);

    expect(result.edits, hasLength(0));
  }

  setUp() {
    return super.setUp().then((_) {
      pathname = sourcePath('test.dart');
    });
  }

  test_getImportedElements_noEdits() async {
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    List<Future> tests = [];
    // Test that an empty list of elements produces no edits.
    tests.add(checkNoEdits(<ImportedElements>[]));
    return Future.wait(tests);
  }
}
