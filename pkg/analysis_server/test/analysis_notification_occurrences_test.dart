// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis.notification.occurrences;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisNotificationOccurrencesTest);
}


@ReflectiveTestCase()
class AnalysisNotificationOccurrencesTest extends AbstractAnalysisTest {
  List<Occurrences> occurrencesList;
  Occurrences testOccurences;

  /**
   * Asserts that there is an offset of [search] in [testOccurences].
   */
  void assertHasOffset(String search) {
    int offset = findOffset(search);
    expect(testOccurences.offsets, contains(offset));
  }

  /**
   * Validates that there is a region at the offset of [search] in [testFile].
   * If [length] is not specified explicitly, then length of an identifier
   * from [search] is used.
   */
  void assertHasRegion(String search, [int length = -1]) {
    int offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    findRegion(offset, length, true);
  }

  /**
   * Finds an [Occurrences] with the given [offset] and [length].
   *
   * If [exists] is `true`, then fails if such [Occurrences] does not exist.
   * Otherwise remembers this it into [testOccurences].
   *
   * If [exists] is `false`, then fails if such [Occurrences] exists.
   */
  void findRegion(int offset, int length, [bool exists]) {
    for (Occurrences occurrences in occurrencesList) {
      if (occurrences.length != length) {
        continue;
      }
      for (int occurrenceOffset in occurrences.offsets) {
        if (occurrenceOffset == offset) {
          if (exists == false) {
            fail(
                'Not expected to find (offset=$offset; length=$length) in\n'
                    '${occurrencesList.join('\n')}');
          }
          testOccurences = occurrences;
          return;
        }
      }
    }
    if (exists == true) {
      fail(
          'Expected to find (offset=$offset; length=$length) in\n'
              '${occurrencesList.join('\n')}');
    }
  }

  Future prepareOccurrences() {
    addAnalysisSubscription(AnalysisService.OCCURRENCES, testFile);
    return waitForTasksFinished();
  }

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_OCCURRENCES) {
      var params = new AnalysisOccurrencesParams.fromNotification(notification);
      if (params.file == testFile) {
        occurrencesList = params.occurrences;
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  test_afterAnalysis() {
    addTestFile('''
main() {
  var vvv = 42;
  print(vvv);
}
''');
    return waitForTasksFinished().then((_) {
      return prepareOccurrences().then((_) {
        assertHasRegion('vvv =');
        expect(testOccurences.element.kind, ElementKind.LOCAL_VARIABLE);
        expect(testOccurences.element.name, 'vvv');
        assertHasOffset('vvv = 42');
        assertHasOffset('vvv);');
      });
    });
  }

  test_field() {
    addTestFile('''
class A {
  int fff;
  A(this.fff); // constructor
  main() {
    fff = 42;
    print(fff); // print
  }
}
''');
    return prepareOccurrences().then((_) {
      assertHasRegion('fff;');
      expect(testOccurences.element.kind, ElementKind.FIELD);
      assertHasOffset('fff); // constructor');
      assertHasOffset('fff = 42;');
      assertHasOffset('fff); // print');
    });
  }

  test_localVariable() {
    addTestFile('''
main() {
  var vvv = 42;
  vvv += 5;
  print(vvv);
}
''');
    return prepareOccurrences().then((_) {
      assertHasRegion('vvv =');
      expect(testOccurences.element.kind, ElementKind.LOCAL_VARIABLE);
      expect(testOccurences.element.name, 'vvv');
      assertHasOffset('vvv = 42');
      assertHasOffset('vvv += 5');
      assertHasOffset('vvv);');
    });
  }

  test_memberField() {
    addTestFile('''
class A<T> {
  T fff;
}
main() {
  var a = new A<int>();
  var b = new A<String>();
  a.fff = 1;
  b.fff = 2;
}
''');
    return prepareOccurrences().then((_) {
      assertHasRegion('fff;');
      expect(testOccurences.element.kind, ElementKind.FIELD);
      assertHasOffset('fff = 1;');
      assertHasOffset('fff = 2;');
    });
  }

  test_memberMethod() {
    addTestFile('''
class A<T> {
  T mmm() {}
}
main() {
  var a = new A<int>();
  var b = new A<String>();
  a.mmm(); // a
  b.mmm(); // b
}
''');
    return prepareOccurrences().then((_) {
      assertHasRegion('mmm() {}');
      expect(testOccurences.element.kind, ElementKind.METHOD);
      assertHasOffset('mmm(); // a');
      assertHasOffset('mmm(); // b');
    });
  }

  test_topLevelVariable() {
    addTestFile('''
var VVV = 1;
main() {
  VVV = 2;
  print(VVV);
}
''');
    return prepareOccurrences().then((_) {
      assertHasRegion('VVV = 1;');
      expect(testOccurences.element.kind, ElementKind.TOP_LEVEL_VARIABLE);
      assertHasOffset('VVV = 2;');
      assertHasOffset('VVV);');
    });
  }

  test_type_class() {
    addTestFile('''
main() {
  int a = 1;
  int b = 2;
  int c = 3;
}
int VVV = 4;
''');
    return prepareOccurrences().then((_) {
      assertHasRegion('int a');
      expect(testOccurences.element.kind, ElementKind.CLASS);
      expect(testOccurences.element.name, 'int');
      assertHasOffset('int a');
      assertHasOffset('int b');
      assertHasOffset('int c');
      assertHasOffset('int VVV');
    });
  }

  test_type_dynamic() {
    addTestFile('''
main() {
  dynamic a = 1;
  dynamic b = 2;
}
dynamic V = 3;
''');
    return prepareOccurrences().then((_) {
      int offset = findOffset('dynamic a');
      findRegion(offset, 'dynamic'.length, false);
    });
  }

  test_type_void() {
    addTestFile('''
void main() {
}
''');
    return prepareOccurrences().then((_) {
      int offset = findOffset('void main()');
      findRegion(offset, 'void'.length, false);
    });
  }
}
