// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.occurrences;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

main() {
  runReflectiveTests(Test);
}

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_occurrences() {
    String pathname = sourcePath('test.dart');
    String text = r'''
main() {
  int sum = 0;
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < i; j++) {
      sum += j;
    }
  }
  print(sum);
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    sendAnalysisSetSubscriptions({
      AnalysisService.OCCURRENCES: [pathname]
    });
    List<Occurrences> occurrences;
    onAnalysisOccurrences.listen((AnalysisOccurrencesParams params) {
      expect(params.file, equals(pathname));
      occurrences = params.occurrences;
    });
    return analysisFinished.then((_) {
      expect(currentAnalysisErrors[pathname], isEmpty);
      Set<int> findOffsets(String elementName) {
        for (Occurrences occurrence in occurrences) {
          if (occurrence.element.name == elementName) {
            return occurrence.offsets.toSet();
          }
        }
        fail('No element found matching $elementName');
        return null;
      }
      void check(String elementName, Iterable<String> expectedOccurrences) {
        Set<int> expectedOffsets =
            expectedOccurrences.map((String substring) => text.indexOf(substring)).toSet();
        Set<int> foundOffsets = findOffsets(elementName);
        expect(foundOffsets, equals(expectedOffsets));
      }
      check('i', ['i = 0', 'i < 10', 'i++', 'i;']);
      check('j', ['j = 0', 'j < i', 'j++', 'j;']);
      check('sum', ['sum = 0', 'sum +=', 'sum)']);
    });
  }
}
