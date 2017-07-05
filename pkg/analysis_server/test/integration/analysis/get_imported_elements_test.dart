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
  final String text = r'''
main() {}
''';

  /**
   * Check that an analysis.getImportedElements request on the region starting
   * with the first character that matches [target] and having the given
   * [length] matches the given list of [expected] imported elements.
   */
  checkElements(
      String target, int length, List<ImportedElements> expected) async {
    int offset = text.indexOf(target);
    AnalysisGetImportedElementsResult result =
        await sendAnalysisGetImportedElements(pathname, offset, length);

    expect(result.elements, hasLength(expected.length));
    // TODO(brianwilkerson) Finish implementing this.
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

  test_getImportedElements() async {
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    List<Future> tests = [];
    tests.add(checkNoElements('main() {}'));
    return Future.wait(tests);
  }
}
