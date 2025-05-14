// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OccurrencesTest);
  });
}

@reflectiveTest
class OccurrencesTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_occurrences() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
void f() {
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
    await standardAnalysisSetup();
    await sendAnalysisSetSubscriptions({
      AnalysisService.OCCURRENCES: [pathname],
    });

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);

    var params = await onAnalysisOccurrences.first;
    expect(params.file, equals(pathname));
    var occurrences = params.occurrences;

    Set<int> findOffsets(String elementName) {
      for (var occurrence in occurrences) {
        if (occurrence.element.name == elementName) {
          return occurrence.offsets.toSet();
        }
      }
      fail('No element found matching $elementName');
    }

    void check(String elementName, Iterable<String> expectedOccurrences) {
      var expectedOffsets =
          expectedOccurrences
              .map((String substring) => text.indexOf(substring))
              .toSet();
      var foundOffsets = findOffsets(elementName);
      expect(foundOffsets, equals(expectedOffsets));
    }

    check('i', ['i = 0', 'i < 10', 'i++', 'i;']);
    check('j', ['j = 0', 'j < i', 'j++', 'j;']);
    check('sum', ['sum = 0', 'sum +=', 'sum)']);
  }

  Future<void> test_occurrences_inList_nullAware() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
int? g(int x) => x % 2 == 0 ? null : x;
void f() {
  List<int> sum = [];
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < i; j++) {
      sum += [?g(i), ?g(j)];
    }
  }
  print(sum);
}
''';
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await sendAnalysisSetSubscriptions({
      AnalysisService.OCCURRENCES: [pathname],
    });

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);

    var params = await onAnalysisOccurrences.first;
    expect(params.file, equals(pathname));
    var occurrences = params.occurrences;

    Set<int> findOffsets(String elementName) {
      for (var occurrence in occurrences) {
        if (occurrence.element.name == elementName) {
          return occurrence.offsets.toSet();
        }
      }
      fail('No element found matching $elementName');
    }

    void check(String elementName, Iterable<String> expectedOccurrences) {
      var expectedOffsets =
          expectedOccurrences
              .map((String substring) => text.indexOf(substring))
              .toSet();
      var foundOffsets = findOffsets(elementName);
      expect(foundOffsets, equals(expectedOffsets));
    }

    check('i', ['i = 0', 'i < 10', 'i++', 'i;', 'i),']);
    check('j', ['j = 0', 'j < i', 'j++', 'j)];']);
    check('sum', ['sum = []', 'sum +=', 'sum)']);
  }

  Future<void> test_occurrences_inMap_nullAware() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
int? g1(int x) => x % 2 == 0 ? null : x;
int? g2(int x) => x % 3 == 0 ? null : x;
int? g3(int x) => x % 5 == 0 ? null : x;
void f() {
  Map<int, int> sum = {};
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < i; j++) {
      sum.addAll({?g1(i): ?g1(j)});
      sum.addAll({?g2(i): j});
      sum.addAll({i: ?g3(j,)});
    }
  }
  print(sum);
}
''';
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await sendAnalysisSetSubscriptions({
      AnalysisService.OCCURRENCES: [pathname],
    });

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);

    var params = await onAnalysisOccurrences.first;
    expect(params.file, equals(pathname));
    var occurrences = params.occurrences;

    Set<int> findOffsets(String elementName) {
      for (var occurrence in occurrences) {
        if (occurrence.element.name == elementName) {
          return occurrence.offsets.toSet();
        }
      }
      fail('No element found matching $elementName');
    }

    void check(String elementName, Iterable<String> expectedOccurrences) {
      var expectedOffsets =
          expectedOccurrences
              .map((String substring) => text.indexOf(substring))
              .toSet();
      var foundOffsets = findOffsets(elementName);
      expect(foundOffsets, equals(expectedOffsets));
    }

    check('i', ['i = 0', 'i < 10', 'i++', 'i;', 'i): ?', 'i): j', 'i:']);
    check('j', ['j = 0', 'j < i', 'j++', 'j)});', 'j});', 'j,)});']);
    check('sum', [
      'sum = {}',
      'sum.addAll({?g1',
      'sum.addAll({?g2',
      'sum.addAll({i',
      'sum)',
    ]);
  }

  Future<void> test_occurrences_inSet_nullAware() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
int? g(int x) => x % 2 == 0 ? null : x;
void f() {
  Set<int> sum = {};
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < i; j++) {
      sum.addAll({?g(i), ?g(j)});
    }
  }
  print(sum);
}
''';
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await sendAnalysisSetSubscriptions({
      AnalysisService.OCCURRENCES: [pathname],
    });

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);

    var params = await onAnalysisOccurrences.first;
    expect(params.file, equals(pathname));
    var occurrences = params.occurrences;

    Set<int> findOffsets(String elementName) {
      for (var occurrence in occurrences) {
        if (occurrence.element.name == elementName) {
          return occurrence.offsets.toSet();
        }
      }
      fail('No element found matching $elementName');
    }

    void check(String elementName, Iterable<String> expectedOccurrences) {
      var expectedOffsets =
          expectedOccurrences
              .map((String substring) => text.indexOf(substring))
              .toSet();
      var foundOffsets = findOffsets(elementName);
      expect(foundOffsets, equals(expectedOffsets));
    }

    check('i', ['i = 0', 'i < 10', 'i++', 'i;', 'i),']);
    check('j', ['j = 0', 'j < i', 'j++', 'j)});']);
    check('sum', ['sum = {}', 'sum.addAll', 'sum)']);
  }
}
