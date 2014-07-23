// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.correction.fix;

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/fix.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  group('FixProcessorTest', () {
    runReflectiveTests(FixProcessorTest);
  });
}


@ReflectiveTestCase()
class FixProcessorTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  Fix fix;
  Change change;
  String resultCode;

  void assertHasFix(FixKind kind, String expected) {
    AnalysisError error = _findErrorToFix();
    fix = _assertHasFix(kind, error);
    change = fix.change;
    // apply to "file"
    List<FileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    resultCode = _applyEdits(testCode, change.edits[0].edits);
    // verify
    expect(resultCode, expected);
  }

  void assertHasPositionGroup(String id, List<Position> expectedPositions) {
    List<LinkedPositionGroup> linkedPositionGroups =
        change.linkedPositionGroups;
    for (LinkedPositionGroup group in linkedPositionGroups) {
      if (group.id == id) {
        expect(group.positions, unorderedEquals(expectedPositions));
        return;
      }
    }
    fail('No PositionGroup with id=$id found in $linkedPositionGroups');
  }

  void assertNoFix(FixKind kind) {
    AnalysisError error = _findErrorToFix();
    List<Fix> fixes = computeFixes(searchEngine, testFile, testUnit, error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        throw fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  Position expectedPosition(String search) {
    int offset = resultCode.indexOf(search);
    int length = getLeadingIdentifierLength(search);
    return new Position(testFile, offset, length);
  }

  List<Position> expectedPositions(List<String> patterns) {
    List<Position> positions = <Position>[];
    patterns.forEach((String search) {
      positions.add(expectedPosition(search));
    });
    return positions;
  }

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    verifyNoTestUnitErrors = false;
  }

  void test_boolean() {
    _indexTestUnit('''
main() {
  boolean v;
}
''');
    assertHasFix(FixKind.REPLACE_BOOLEAN_WITH_BOOL, '''
main() {
  bool v;
}
''');
  }

  void test_changeToStaticAccess_method() {
    _indexTestUnit('''
class A {
  static foo() {}
}
main(A a) {
  a.foo();
}
''');
    assertHasFix(FixKind.CHANGE_TO_STATIC_ACCESS, '''
class A {
  static foo() {}
}
main(A a) {
  A.foo();
}
''');
  }

  void test_changeToStaticAccess_method_prefixLibrary() {
    _indexTestUnit('''
import 'dart:async' as pref;
main(pref.Future f) {
  f.wait([]);
}
''');
    assertHasFix(FixKind.CHANGE_TO_STATIC_ACCESS, '''
import 'dart:async' as pref;
main(pref.Future f) {
  pref.Future.wait([]);
}
''');
  }

  void test_changeToStaticAccess_property() {
    _indexTestUnit('''
class A {
  static get foo => 42;
}
main(A a) {
  a.foo;
}
''');
    assertHasFix(FixKind.CHANGE_TO_STATIC_ACCESS, '''
class A {
  static get foo => 42;
}
main(A a) {
  A.foo;
}
''');
  }

  void test_createClass() {
    _indexTestUnit('''
main() {
  Test v = null;
}
''');
    assertHasFix(FixKind.CREATE_CLASS, '''
main() {
  Test v = null;
}

class Test {
}
''');
    assertHasPositionGroup('NAME', expectedPositions(['Test v =', 'Test {']));
  }

  void test_createConstructorSuperExplicit() {
    _indexTestUnit('''
class A {
  A(bool p1, int p2, double p3, String p4, {p5});
}
class B extends A {
  B() {}
}
''');
    assertHasFix(FixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION, '''
class A {
  A(bool p1, int p2, double p3, String p4, {p5});
}
class B extends A {
  B() : super(false, 0, 0.0, '') {}
}
''');
  }

  void test_createConstructorSuperExplicit_hasInitializers() {
    _indexTestUnit('''
class A {
  A(int p);
}
class B extends A {
  int field;
  B() : field = 42 {}
}
''');
    assertHasFix(FixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION, '''
class A {
  A(int p);
}
class B extends A {
  int field;
  B() : field = 42, super(0) {}
}
''');
  }

  void test_createConstructorSuperExplicit_named() {
    _indexTestUnit('''
class A {
  A.named(int p);
}
class B extends A {
  B() {}
}
''');
    assertHasFix(FixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION, '''
class A {
  A.named(int p);
}
class B extends A {
  B() : super.named(0) {}
}
''');
  }

  void test_createConstructorSuperExplicit_named_private() {
    _indexTestUnit('''
class A {
  A._named(int p);
}
class B extends A {
  B() {}
}
''');
    assertNoFix(FixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION);
  }

  void test_createConstructor_insteadOfSyntheticDefault() {
    _indexTestUnit('''
class A {
  int field;

  method() {}
}
main() {
  new A(1, 2.0);
}
''');
    assertHasFix(FixKind.CREATE_CONSTRUCTOR, '''
class A {
  int field;

  A(int i, double d) {
  }

  method() {}
}
main() {
  new A(1, 2.0);
}
''');
  }

  void test_createConstructor_named() {
    _indexTestUnit('''
class A {
  method() {}
}
main() {
  new A.named(1, 2.0);
}
''');
    assertHasFix(FixKind.CREATE_CONSTRUCTOR, '''
class A {
  A.named(int i, double d) {
  }

  method() {}
}
main() {
  new A.named(1, 2.0);
}
''');
  }

  void test_expectedToken_semicolon() {
    _indexTestUnit('''
main() {
  print(0)
}
''');
    assertHasFix(FixKind.INSERT_SEMICOLON, '''
main() {
  print(0);
}
''');
  }

  void test_isNotNull() {
    _indexTestUnit('''
main(p) {
  p is! Null;
}
''');
    assertHasFix(FixKind.USE_NOT_EQ_NULL, '''
main(p) {
  p != null;
}
''');
  }

  void test_isNull() {
    _indexTestUnit('''
main(p) {
  p is Null;
}
''');
    assertHasFix(FixKind.USE_EQ_EQ_NULL, '''
main(p) {
  p == null;
}
''');
  }

  void test_makeEnclosingClassAbstract_declaresAbstractMethod() {
    _indexTestUnit('''
class A {
  m();
}
''');
    assertHasFix(FixKind.MAKE_CLASS_ABSTRACT, '''
abstract class A {
  m();
}
''');
  }

  void test_makeEnclosingClassAbstract_inheritsAbstractMethod() {
    _indexTestUnit('''
abstract class A {
  m();
}
class B extends A {
}
''');
    assertHasFix(FixKind.MAKE_CLASS_ABSTRACT, '''
abstract class A {
  m();
}
abstract class B extends A {
}
''');
  }

  void test_removeParentheses_inGetterDeclaration() {
    _indexTestUnit('''
class A {
  int get foo() => 0;
}
''');
    assertHasFix(FixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION, '''
class A {
  int get foo => 0;
}
''');
  }

  void test_removeParentheses_inGetterInvocation() {
    _indexTestUnit('''
class A {
  int get foo => 0;
}
main(A a) {
  a.foo();
}
''');
    assertHasFix(FixKind.REMOVE_PARENTHESIS_IN_GETTER_INVOCATION, '''
class A {
  int get foo => 0;
}
main(A a) {
  a.foo;
}
''');
  }

  void test_removeUnnecessaryCast_assignment() {
    _indexTestUnit('''
main(Object p) {
  if (p is String) {
    String v = ((p as String));
  }
}
''');
    assertHasFix(FixKind.REMOVE_UNNECASSARY_CAST, '''
main(Object p) {
  if (p is String) {
    String v = p;
  }
}
''');
  }

  void test_removeUnusedImport() {
    _indexTestUnit('''
import 'dart:math';
main() {
}
''');
    assertHasFix(FixKind.REMOVE_UNUSED_IMPORT, '''
main() {
}
''');
  }

  void test_removeUnusedImport_anotherImportOnLine() {
    _indexTestUnit('''
import 'dart:math'; import 'dart:async';

main() {
  Future f;
}
''');
    assertHasFix(FixKind.REMOVE_UNUSED_IMPORT, '''
import 'dart:async';

main() {
  Future f;
}
''');
  }

  void test_removeUnusedImport_severalLines() {
    _indexTestUnit('''
import
  'dart:math';
main() {
}
''');
    assertHasFix(FixKind.REMOVE_UNUSED_IMPORT, '''
main() {
}
''');
  }

  void test_replaceWithConstInstanceCreation() {
    _indexTestUnit('''
class A {
  const A();
}
const a = new A();
''');
    assertHasFix(FixKind.USE_CONST, '''
class A {
  const A();
}
const a = const A();
''');
  }

  void test_useEffectiveIntegerDivision() {
    _indexTestUnit('''
main() {
  var a = 5;
  var b = 2;
  print((a / b).toInt());
}
''');
    assertHasFix(FixKind.USE_EFFECTIVE_INTEGER_DIVISION, '''
main() {
  var a = 5;
  var b = 2;
  print(a ~/ b);
}
''');
  }

  String _applyEdits(String code, List<Edit> edits) {
    edits.sort((a, b) => b.offset - a.offset);
    edits.forEach((Edit edit) {
      code = code.substring(0, edit.offset) +
          edit.replacement +
          code.substring(edit.end);
    });
    return code;
  }

  /**
   * Computes fixes and verifies that there is a fix of the given kind.
   */
  Fix _assertHasFix(FixKind kind, AnalysisError error) {
    List<Fix> fixes = computeFixes(searchEngine, testFile, testUnit, error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        return fix;
      }
    }
    throw fail('Expected to find fix $kind in\n${fixes.join('\n')}');
  }

  AnalysisError _findErrorToFix() {
    List<AnalysisError> errors = context.computeErrors(testSource);
    expect(
        errors,
        hasLength(1),
        reason: 'Exactly 1 error expected, but ${errors.length} found:\n' +
            errors.join('\n'));
    return errors[0];
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(context, testUnit);
  }
}
