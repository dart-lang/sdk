// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.update.content;

import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import '../integration_tests.dart';

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_updateContent() {
    String pathname = sourcePath('test.dart');
    String goodText = r'''
main() {
  print("Hello, world!");
}''';
    String badText = goodText.replaceAll(';', '');
    writeFile(pathname, badText);
    standardAnalysisSetup();
    return analysisFinished.then((_) {
      // The contents on disk (badText) are missing a semicolon.
      expect(currentAnalysisErrors[pathname], isNot(isEmpty));
    }).then((_) => sendAnalysisUpdateContent({
      pathname: {
        'type': 'add',
        'content': goodText
      }
    })).then((result) => analysisFinished).then((_) {
      // There should be no errors now because the contents on disk have been
      // overriden with goodText.
      expect(currentAnalysisErrors[pathname], isEmpty);
      return sendAnalysisUpdateContent({
        pathname: {
          'type': 'change',
          'edits': [{
              'offset': goodText.indexOf(';'),
              'length': 1,
              'replacement': ''
            }]
        }
      });
    }).then((result) => analysisFinished).then((_) {
      // There should be errors now because we've removed the semicolon.
      expect(currentAnalysisErrors[pathname], isNot(isEmpty));
      return sendAnalysisUpdateContent({
        pathname: {
          'type': 'change',
          'edits': [{
              'offset': goodText.indexOf(';'),
              'length': 0,
              'replacement': ';'
            }]
        }
      });
    }).then((result) => analysisFinished).then((_) {
      // There should be no errors now because we've added the semicolon back.
      expect(currentAnalysisErrors[pathname], isEmpty);
      return sendAnalysisUpdateContent({
        pathname: {
          'type': 'remove'
        }
      });
    }).then((result) => analysisFinished).then((_) {
      // Now there should be errors again, because the contents on disk are no
      // longer overridden.
      expect(currentAnalysisErrors[pathname], isNot(isEmpty));
    });
  }
}

main() {
  runReflectiveTests(Test);
}
