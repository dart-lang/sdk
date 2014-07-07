// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis.notification.navigation;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';


main() {
  group('notification.navigation', () {
    runReflectiveTests(AnalysisNotificationNavigationTest);
  });
}


@ReflectiveTestCase()
class AnalysisNotificationNavigationTest extends AbstractAnalysisTest {
  List<NavigationRegion> regions;
  NavigationRegion testRegion;
  List<Element> testTargets;
  Element testTarget;

  /**
   * Validates that there is a target in [testTargets]  with [file], at [offset]
   * and with the given [length].
   */
  void assertHasFileTarget(String file, int offset, int length) {
    for (Element target in testTargets) {
      Location location = target.location;
      if (location.file == file && location.offset == offset && location.length ==
          length) {
        testTarget = target;
        return;
      }
    }
    fail(
        'Expected to find target (file=$file; offset=$offset; length=$length) in\n'
        '${testRegion} in\n' '${regions.join('\n')}');
  }

  void assertHasOperatorRegion(String regionSearch, int regionLength,
      String targetSearch, int targetLength) {
    assertHasRegion(regionSearch, regionLength);
    assertHasTarget(targetSearch, targetLength);
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
   * Validates that there is a region at the offset of [search] in [testFile]
   * with the length of [search].
   */
  void assertHasRegionString(String search) {
    int offset = findOffset(search);
    int length = search.length;
    findRegion(offset, length, true);
  }

  /**
   * Validates that there is an identifier region at [regionSearch] with target
   * at [targetSearch].
   */
  void assertHasRegionTarget(String regionSearch, String targetSearch) {
    assertHasRegion(regionSearch);
    assertHasTarget(targetSearch);
  }

  /**
   * Validates that there is a target in [testTargets]  with [testFile], at the
   * offset of [search] in [testFile], and with the given [length] or the length
   * of an leading identifier in [search].
   */
  void assertHasTarget(String search, [int length = -1]) {
    int offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    assertHasFileTarget(testFile, offset, length);
  }

  /**
   * Validates that there is no a region at [search] and with the given
   * [length].
   */
  void assertNoRegion(String search, int length) {
    int offset = findOffset(search);
    findRegion(offset, length, false);
  }

  /**
   * Validates that there is no a region at [search] with any length.
   */
  void assertNoRegionAt(String search) {
    int offset = findOffset(search);
    findRegion(offset, -1, false);
  }

  /**
   * Validates that there is no a region for [search] string.
   */
  void assertNoRegionString(String search) {
    int offset = findOffset(search);
    int length = search.length;
    findRegion(offset, length, false);
  }

  /**
   * Finds the navigation region with the given [offset] and [length].
   * If [length] is `-1`, then it is ignored.
   *
   * If [exists] is `true`, then fails if such region does not exist.
   * Otherwise remembers this it into [testRegion].
   * Also fills [testTargets] with its targets.
   *
   * If [exists] is `false`, then fails if such region exists.
   */
  void findRegion(int offset, int length, [bool exists]) {
    for (NavigationRegion region in regions) {
      if (region.offset == offset && (length == -1 || region.length == length))
          {
        if (exists == false) {
          fail('Not expected to find (offset=$offset; length=$length) in\n'
              '${regions.join('\n')}');
        }
        testRegion = region;
        testTargets = region.targets;
        return;
      }
    }
    if (exists == true) {
      fail('Expected to find (offset=$offset; length=$length) in\n'
          '${regions.join('\n')}');
    }
  }

  Future prepareNavigation(then()) {
    addAnalysisSubscription(AnalysisService.NAVIGATION, testFile);
    return waitForTasksFinished().then((_) {
      then();
    });
  }

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NAVIGATION) {
      String file = notification.getParameter(FILE);
      if (file == testFile) {
        regions = <NavigationRegion>[];
        List<Map<String, Object>> regionsJson = notification.getParameter(
            REGIONS);
        for (Map<String, Object> regionJson in regionsJson) {
          var regionOffset = regionJson[OFFSET];
          var regionLength = regionJson[LENGTH];
          List<Element> targets = <Element>[];
          for (Map<String, Object> targetJson in regionJson[TARGETS]) {
            targets.add(new Element.fromJson(targetJson));
          }
          var region = new NavigationRegion(regionOffset, regionLength,
              targets);
          regions.add(region);
        }
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
class AAA {}
AAA aaa;
''');
    return waitForTasksFinished().then((_) {
      return prepareNavigation(() {
        assertHasRegionTarget('AAA aaa;', 'AAA {}');
      });
    });
  }

  test_constructor_named() {
    addTestFile('''
class A {
  A.named(BBB p) {}
}
class BBB {}
''');
    return prepareNavigation(() {
      // has region for complete "A.named"
      assertHasRegionString('A.named');
      assertHasTarget('named(BBB');
      // no separate regions for "A" and "named"
      assertNoRegion('A.named(', 'A'.length);
      assertNoRegion('named(', 'named'.length);
      // validate that we don't forget to resolve parameters
      assertHasRegionTarget('BBB p', 'BBB {}');
    });
  }

  test_constructor_unnamed() {
    addTestFile('''
class A {
  A(BBB p) {}
}
class BBB {}
''');
    return prepareNavigation(() {
      // has region for complete "A.named"
      assertHasRegion("A(BBB");
      assertHasTarget("A(BBB", 0);
      // validate that we don't forget to resolve parameters
      assertHasRegionTarget('BBB p', 'BBB {}');
    });
  }

  test_fieldFormalParameter() {
    addTestFile('''
class AAA {
  int fff = 123;
  AAA(this.fff);
}
''');
    return prepareNavigation(() {
      assertHasRegionTarget('fff);', 'fff = 123');
    });
  }

  test_identifier_resolved() {
    addTestFile('''
class AAA {}
main() {
  AAA aaa = null;
  print(aaa);
}
''');
    return prepareNavigation(() {
      assertHasRegionTarget('AAA aaa', 'AAA {}');
      assertHasRegionTarget('aaa);', 'aaa = null');
      assertHasRegionTarget('main() {', 'main() {');
    });
  }

  test_identifier_unresolved() {
    addTestFile('''
main() {
  print(vvv);
}
''');
    return prepareNavigation(() {
      assertNoRegionString('vvv');
    });
  }

  test_instanceCreation_implicit() {
    addTestFile('''
class A {
}
main() {
  new A();
}
''');
    return prepareNavigation(() {
      assertHasRegionString('new A');
      assertHasTarget('A {');
    });
  }

  test_instanceCreation_named() {
    addTestFile('''
class A {
  A.named() {}
}
main() {
  new A.named();
}
''');
    return prepareNavigation(() {
      assertHasRegionString('new A.named');
      assertHasTarget('named() {}');
    });
  }

  test_instanceCreation_unnamed() {
    addTestFile('''
class A {
  A() {}
}
main() {
  new A();
}
''');
    return prepareNavigation(() {
      assertHasRegionString('new A');
      assertHasTarget("A() {}", 0);
    });
  }

  test_operator_arithmetic() {
    addTestFile('''
class A {
  A operator +(other) => null;
  A operator -() => null;
  A operator -(other) => null;
  A operator *(other) => null;
  A operator /(other) => null;
}
main() {
  var a = new A();
  a - 1;
  a + 2;
  -a; // unary
  --a;
  ++a;
  a--; // mm
  a++; // pp
  a -= 3;
  a += 4;
  a *= 5;
  a /= 6;
}
''');
    return prepareNavigation(() {
      assertHasOperatorRegion('- 1', 1, '-(other) => null', 1);
      assertHasOperatorRegion('+ 2', 1, '+(other) => null', 1);
      assertHasOperatorRegion('-a; // unary', 1, '-() => null', 1);
      assertHasOperatorRegion('--a;', 2, '-(other) => null', 1);
      assertHasOperatorRegion('++a;', 2, '+(other) => null', 1);
      assertHasOperatorRegion('--; // mm', 2, '-(other) => null', 1);
      assertHasOperatorRegion('++; // pp', 2, '+(other) => null', 1);
      assertHasOperatorRegion('-= 3', 2, '-(other) => null', 1);
      assertHasOperatorRegion('+= 4', 2, '+(other) => null', 1);
      assertHasOperatorRegion('*= 5', 2, '*(other) => null', 1);
      assertHasOperatorRegion('/= 6', 2, '/(other) => null', 1);
    });
  }

  test_operator_index() {
    addTestFile('''
class A {
  A operator +(other) => null;
}
class B {
  A operator [](index) => null;
  operator []=(index, A value) {}
}
main() {
  var b = new B();
  b[0] // [];
  b[1] = 1; // []=;
  b[2] += 2;
}
''');
    return prepareNavigation(() {
      assertHasOperatorRegion('] // []', 1, '[](index)', 2);
      assertHasOperatorRegion('] = 1;', 1, '[]=(index,', 3);
      assertHasOperatorRegion('] += 2;', 1, '[]=(index,', 3);
      assertHasOperatorRegion('+= 2;', 2, '+(other)', 1);
    });
  }

  test_partOf() {
    var libCode = 'library lib; part "test.dart";';
    var libFile = addFile('$projectPath/bin/lib.dart', libCode);
    addTestFile('part of lib;');
    return prepareNavigation(() {
      assertHasRegionString('part of lib');
      assertHasFileTarget(libFile, libCode.indexOf('lib;'), 'lib'.length);
    });
  }

  test_string_export() {
    var libCode = 'library lib;';
    var libFile = addFile('$projectPath/bin/lib.dart', libCode);
    addTestFile('export "lib.dart";');
    return prepareNavigation(() {
      assertHasRegionString('export "lib.dart"');
      assertHasFileTarget(libFile, libCode.indexOf('lib;'), 'lib'.length);
    });
  }

  test_string_export_unresolvedUri() {
    addTestFile('export "no.dart";');
    return prepareNavigation(() {
      assertNoRegionString('export "no.dart"');
    });
  }

  test_string_import() {
    var libCode = 'library lib;';
    var libFile = addFile('$projectPath/bin/lib.dart', libCode);
    addTestFile('import "lib.dart";');
    return prepareNavigation(() {
      assertHasRegionString('import "lib.dart"');
      assertHasFileTarget(libFile, libCode.indexOf('lib;'), 'lib'.length);
    });
  }

  test_string_import_noUri() {
    addTestFile('import ;');
    return prepareNavigation(() {
      assertNoRegionAt('import ;');
    });
  }

  test_string_import_unresolvedUri() {
    addTestFile('import "no.dart";');
    return prepareNavigation(() {
      assertNoRegionString('import "no.dart"');
    });
  }

  test_string_part() {
    var unitCode = 'part of lib;  f() {}';
    var unitFile = addFile('$projectPath/bin/test_unit.dart', unitCode);
    addTestFile('''
library lib;
part "test_unit.dart";
''');
    return prepareNavigation(() {
      assertHasRegionString('part "test_unit.dart"');
      assertHasFileTarget(unitFile, 0, 0);
    });
  }

  test_string_part_unresolvedUri() {
    addTestFile('''
library lib;
part "test_unit.dart";
''');
    return prepareNavigation(() {
      assertNoRegionString('part "test_unit.dart"');
    });
  }

  test_targetElement() {
    addTestFile('''
class AAA {}
main() {
  AAA aaa = null;
}
''');
    return prepareNavigation(() {
      assertHasRegionTarget('AAA aaa', 'AAA {}');
      expect(testTarget.kind, ElementKind.CLASS);
      expect(testTarget.name, 'AAA');
      expect(testTarget.isAbstract, false);
      expect(testTarget.parameters, isNull);
      expect(testTarget.returnType, isNull);
    });
  }
}


class NavigationRegion {
  final int offset;
  final int length;
  final List<Element> targets;

  NavigationRegion(this.offset, this.length, this.targets);

  @override
  String toString() {
    return 'NavigationRegion(offset=$offset; length=$length; targets=$targets';
  }
}
