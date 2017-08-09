// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisGetImportedElementsIntegrationTest);
  });
}

@reflectiveTest
class AnalysisGetImportedElementsIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  /**
   * Pathname of the file containing Dart code.
   */
  String pathname;

  /**
   * Dart code under test.
   */
  String text;

  /**
   * Check that an analysis.getImportedElements request on the region starting
   * with the first character that matches [target] and having the given
   * [length] matches the given list of [expected] imported elements.
   */
  checkElements(String target, List<ImportedElements> expected) async {
    bool equals(
        ImportedElements actualElements, ImportedElements expectedElements) {
      // We can't test the path because the paths are relative to a generated
      // temporary directory.
      if (actualElements.prefix == expectedElements.prefix) {
        List<String> actual = actualElements.elements;
        List<String> expected = expectedElements.elements;
        if (actual.length == expected.length) {
          for (int i = 0; i < actual.length; i++) {
            if (!expected.contains(actual[i])) {
              return false;
            }
          }
          return true;
        }
      }
      return false;
    }

    int find(List<ImportedElements> actual, ImportedElements expectedElements) {
      for (int i = 0; i < actual.length; i++) {
        ImportedElements actualElements = actual[i];
        if (equals(actualElements, expectedElements)) {
          return i;
        }
      }
      return -1;
    }

    int offset = text.indexOf(target);
    AnalysisGetImportedElementsResult result =
        await sendAnalysisGetImportedElements(pathname, offset, target.length);

    List<ImportedElements> actual = result.elements;
    expect(actual, hasLength(expected.length));
    for (ImportedElements elements in expected) {
      int index = find(actual, elements);
      if (index < 0) {
        fail('Expected $elements; not found');
      }
      actual.removeAt(index);
    }
  }

  /**
   * Check that an analysis.getImportedElements request on the region matching
   * [target] produces an empty list of elements.
   */
  Future<Null> checkNoElements(String target) async {
    int offset = text.indexOf(target);
    AnalysisGetImportedElementsResult result =
        await sendAnalysisGetImportedElements(pathname, offset, target.length);

    expect(result.elements, hasLength(0));
  }

  setUp() {
    return super.setUp().then((_) {
      pathname = sourcePath('test.dart');
    });
  }

  test_getImportedElements_none() async {
    text = r'''
main() {}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    List<Future> tests = [];
    tests.add(checkNoElements('main() {}'));
    return Future.wait(tests);
  }

  test_getImportedElements_some() async {
    text = r'''
main() {
  String s = '';
  print(s);
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    List<Future> tests = [];
    tests.add(checkElements(text, [
      new ImportedElements('', '', ['String', 'print'])
    ]));
    return Future.wait(tests);
  }
}
