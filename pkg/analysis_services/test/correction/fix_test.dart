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
import 'package:analysis_testing/abstract_context.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(FixProcessorTest);
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
    List<FileEdit> fileEdits = change.fileEdits;
    expect(fileEdits, hasLength(1));
    resultCode = _applyEdits(testCode, change.fileEdits[0].edits);
    // verify
    expect(resultCode, expected);
  }

  void assertHasPositionGroup(String id, List<Position> expectedPositions) {
    List<LinkedEditGroup> linkedPositionGroups = change.linkedEditGroups;
    for (LinkedEditGroup group in linkedPositionGroups) {
      if (group.id == id) {
        expect(group.positions, unorderedEquals(expectedPositions));
        return;
      }
    }
    fail('No PositionGroup with id=$id found in $linkedPositionGroups');
  }

  void assertNoFix(FixKind kind) {
    AnalysisError error = _findErrorToFix();
    List<Fix> fixes = computeFixes(searchEngine, testUnit, error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        throw fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  void assert_undefinedFunction_create_returnType_bool(String lineWithTest) {
    _indexTestUnit('''
main() {
  bool b = true;
  $lineWithTest
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  bool b = true;
  $lineWithTest
}

bool test() {
}
''');
  }

  Position expectedPosition(String search) {
    int offset = resultCode.indexOf(search);
    int length = getLeadingIdentifierLength(search);
    return new Position(testFile, offset);
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

  void test_createConstructorSuperImplicit() {
    _indexTestUnit('''
class A {
  A(p1, int p2, List<String> p3, [int p4]);
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    assertHasFix(FixKind.CREATE_CONSTRUCTOR_SUPER, '''
class A {
  A(p1, int p2, List<String> p3, [int p4]);
}
class B extends A {
  int existingField;

  B(p1, int p2, List<String> p3) : super(p1, p2, p3);

  void existingMethod() {}
}
''');
  }

  void test_createConstructorSuperImplicit_fieldInitializer() {
    _indexTestUnit('''
class A {
  int _field;
  A(this._field);
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    assertHasFix(FixKind.CREATE_CONSTRUCTOR_SUPER, '''
class A {
  int _field;
  A(this._field);
}
class B extends A {
  int existingField;

  B(int field) : super(field);

  void existingMethod() {}
}
''');
  }

  void test_createConstructorSuperImplicit_named() {
    _indexTestUnit('''
class A {
  A.named(p1, int p2);
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    assertHasFix(FixKind.CREATE_CONSTRUCTOR_SUPER, '''
class A {
  A.named(p1, int p2);
}
class B extends A {
  int existingField;

  B.named(p1, int p2) : super.named(p1, p2);

  void existingMethod() {}
}
''');
  }

  void test_createConstructorSuperImplicit_private() {
    _indexTestUnit('''
class A {
  A._named(p);
}
class B extends A {
}
''');
    assertNoFix(FixKind.CREATE_CONSTRUCTOR_SUPER);
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

  void test_createMissingOverrides_functionType() {
    _indexTestUnit('''
abstract class A {
  forEach(int f(double p1, String p2));
}

class B extends A {
}
''');
    assertHasFix(FixKind.CREATE_MISSING_OVERRIDES, '''
abstract class A {
  forEach(int f(double p1, String p2));
}

class B extends A {
  @override
  forEach(int f(double p1, String p2)) {
    // TODO: implement forEach
  }
}
''');
  }

  void test_createMissingOverrides_generics() {
    _indexTestUnit('''
class Iterator<T> {
}

abstract class IterableMixin<T> {
  Iterator<T> get iterator;
}

class Test extends IterableMixin<int> {
}
''');
    assertHasFix(FixKind.CREATE_MISSING_OVERRIDES, '''
class Iterator<T> {
}

abstract class IterableMixin<T> {
  Iterator<T> get iterator;
}

class Test extends IterableMixin<int> {
  // TODO: implement iterator
  @override
  Iterator<int> get iterator => null;
}
''');
  }

  void test_createMissingOverrides_getter() {
    _indexTestUnit('''
abstract class A {
  get g1;
  int get g2;
}

class B extends A {
}
''');
    assertHasFix(FixKind.CREATE_MISSING_OVERRIDES, '''
abstract class A {
  get g1;
  int get g2;
}

class B extends A {
  // TODO: implement g1
  @override
  get g1 => null;

  // TODO: implement g2
  @override
  int get g2 => null;
}
''');
  }

  void test_createMissingOverrides_importPrefix() {
    _indexTestUnit('''
import 'dart:async' as aaa;
abstract class A {
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p);
}

class B extends A {
}
''');
    assertHasFix(FixKind.CREATE_MISSING_OVERRIDES, '''
import 'dart:async' as aaa;
abstract class A {
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p);
}

class B extends A {
  @override
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p) {
    // TODO: implement g
  }
}
''');
  }

  void test_createMissingOverrides_method() {
    _indexTestUnit('''
abstract class A {
  m1();
  int m2();
  String m3(int p1, double p2, Map<int, List<String>> p3);
  String m4(p1, p2);
  String m5(p1, [int p2 = 2, int p3, p4 = 4]);
  String m6(p1, {int p2: 2, int p3, p4: 4});
}

class B extends A {
}
''');
    String expectedCode = '''
abstract class A {
  m1();
  int m2();
  String m3(int p1, double p2, Map<int, List<String>> p3);
  String m4(p1, p2);
  String m5(p1, [int p2 = 2, int p3, p4 = 4]);
  String m6(p1, {int p2: 2, int p3, p4: 4});
}

class B extends A {
  @override
  m1() {
    // TODO: implement m1
  }

  @override
  int m2() {
    // TODO: implement m2
  }

  @override
  String m3(int p1, double p2, Map<int, List<String>> p3) {
    // TODO: implement m3
  }

  @override
  String m4(p1, p2) {
    // TODO: implement m4
  }

  @override
  String m5(p1, [int p2 = 2, int p3, p4 = 4]) {
    // TODO: implement m5
  }

  @override
  String m6(p1, {int p2: 2, int p3, p4: 4}) {
    // TODO: implement m6
  }
}
''';
    assertHasFix(FixKind.CREATE_MISSING_OVERRIDES, expectedCode);
    // end position should be on "m1", not on "m2", "m3", etc
    {
      Position endPosition = change.selection;
      expect(endPosition, isNotNull);
      expect(endPosition.file, testFile);
      int endOffset = endPosition.offset;
      String endString = expectedCode.substring(endOffset, endOffset + 25);
      expect(endString, contains('m1'));
      expect(endString, isNot(contains('m2')));
      expect(endString, isNot(contains('m3')));
      expect(endString, isNot(contains('m4')));
      expect(endString, isNot(contains('m5')));
      expect(endString, isNot(contains('m6')));
    }
  }

  void test_createMissingOverrides_operator() {
    _indexTestUnit('''
abstract class A {
  int operator [](int index);
  void operator []=(int index, String value);
}

class B extends A {
}
''');
    assertHasFix(FixKind.CREATE_MISSING_OVERRIDES, '''
abstract class A {
  int operator [](int index);
  void operator []=(int index, String value);
}

class B extends A {
  @override
  int operator [](int index) {
    // TODO: implement []
  }

  @override
  void operator []=(int index, String value) {
    // TODO: implement []=
  }
}
''');
  }

  void test_createMissingOverrides_setter() {
    _indexTestUnit('''
abstract class A {
  set s1(x);
  set s2(int x);
  void set s3(String x);
}

class B extends A {
}
''');
    assertHasFix(FixKind.CREATE_MISSING_OVERRIDES, '''
abstract class A {
  set s1(x);
  set s2(int x);
  void set s3(String x);
}

class B extends A {
  @override
  set s1(x) {
    // TODO: implement s1
  }

  @override
  set s2(int x) {
    // TODO: implement s2
  }

  @override
  void set s3(String x) {
    // TODO: implement s3
  }
}
''');
  }

  void test_createNoSuchMethod() {
    _indexTestUnit('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  existing() {}
}
''');
    assertHasFix(FixKind.CREATE_NO_SUCH_METHOD, '''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  existing() {}

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  void test_creationFunction_forFunctionType_cascadeSecond() {
    _indexTestUnit('''
class A {
  B ma() => null;
}
class B {
  useFunction(int g(double a, String b)) {}
}

main() {
  A a = new A();
  a..ma().useFunction(test);
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
class A {
  B ma() => null;
}
class B {
  useFunction(int g(double a, String b)) {}
}

main() {
  A a = new A();
  a..ma().useFunction(test);
}

int test(double a, String b) {
}
''');
  }

  void test_creationFunction_forFunctionType_dynamicArgument() {
    _indexTestUnit('''
main() {
  useFunction(test);
}
useFunction(int g(a, b)) {}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  useFunction(test);
}
useFunction(int g(a, b)) {}

int test(a, b) {
}
''');
  }

  void test_creationFunction_forFunctionType_function() {
    _indexTestUnit('''
main() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}

int test(double a, String b) {
}
''');
  }

  void test_creationFunction_forFunctionType_method_enclosingClass_static() {
    _indexTestUnit('''
class A {
  static foo() {
    useFunction(test);
  }
}
useFunction(int g(double a, String b)) {}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  static foo() {
    useFunction(test);
  }

  static int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  void test_creationFunction_forFunctionType_method_enclosingClass_static2() {
    _indexTestUnit('''
class A {
  var f;
  A() : f = useFunction(test);
}
useFunction(int g(double a, String b)) {}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  var f;
  A() : f = useFunction(test);

  static int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  void test_creationFunction_forFunctionType_method_targetClass() {
    _indexTestUnit('''
main(A a) {
  useFunction(a.test);
}
class A {
}
useFunction(int g(double a, String b)) {}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
main(A a) {
  useFunction(a.test);
}
class A {
  int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  void
      test_creationFunction_forFunctionType_method_targetClass_hasOtherMember() {
    _indexTestUnit('''
main(A a) {
  useFunction(a.test);
}
class A {
  m() {}
}
useFunction(int g(double a, String b)) {}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
main(A a) {
  useFunction(a.test);
}
class A {
  m() {}

  int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  void test_creationFunction_forFunctionType_notFunctionType() {
    _indexTestUnit('''
main(A a) {
  useFunction(a.test);
}
typedef A();
useFunction(g) {}
''');
    assertNoFix(FixKind.CREATE_METHOD);
    assertNoFix(FixKind.CREATE_FUNCTION);
  }

  void test_creationFunction_forFunctionType_unknownTarget() {
    _indexTestUnit('''
main(A a) {
  useFunction(a.test);
}
class A {
}
useFunction(g) {}
''');
    assertNoFix(FixKind.CREATE_METHOD);
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

  void test_importLibraryPackage_withType() {
    provider.newFile('/packages/my_pkg/lib/my_lib.dart', '''
library my_lib;
class Test {}
''');
    {
      Folder myPkgFolder = provider.getResource('/packages/my_pkg/lib');
      UriResolver pkgResolver = new PackageMapUriResolver(provider, {
        'my_pkg': [myPkgFolder]
      });
      context.sourceFactory = new SourceFactory(
          [AbstractContextTest.SDK_RESOLVER, resourceResolver, pkgResolver]);
    }
    // force 'my_pkg' resolution
    addSource('/tmp/other.dart', "import 'package:my_pkg/my_lib.dart';");
    // try to find a fix
    _indexTestUnit('''
main() {
  Test test = null;
}
''');
    performAllAnalysisTasks();
    assertHasFix(FixKind.IMPORT_LIBRARY_PROJECT, '''
import 'package:my_pkg/my_lib.dart';

main() {
  Test test = null;
}
''');
  }

  void test_importLibraryPrefix_withTopLevelVariable() {
    _indexTestUnit('''
import 'dart:math' as pref;
main() {
  print(pref.E);
  print(PI);
}
''');
    assertHasFix(FixKind.IMPORT_LIBRARY_PREFIX, '''
import 'dart:math' as pref;
main() {
  print(pref.E);
  print(pref.PI);
}
''');
  }

  void test_importLibraryPrefix_withType() {
    _indexTestUnit('''
import 'dart:async' as pref;
main() {
  pref.Stream s = null;
  Future f = null;
}
''');
    assertHasFix(FixKind.IMPORT_LIBRARY_PREFIX, '''
import 'dart:async' as pref;
main() {
  pref.Stream s = null;
  pref.Future f = null;
}
''');
  }

  void test_importLibraryProject_withFunction() {
    addSource('/lib.dart', '''
library lib;
myFunction() {}
''');
    _indexTestUnit('''
main() {
  myFunction();
}
''');
    performAllAnalysisTasks();
    assertHasFix(FixKind.IMPORT_LIBRARY_PROJECT, '''
import 'lib.dart';

main() {
  myFunction();
}
''');
  }

  void test_importLibraryProject_withTopLevelVariable() {
    addSource('/lib.dart', '''
library lib;
int MY_VAR = 42;
''');
    _indexTestUnit('''
main() {
  print(MY_VAR);
}
''');
    performAllAnalysisTasks();
    assertHasFix(FixKind.IMPORT_LIBRARY_PROJECT, '''
import 'lib.dart';

main() {
  print(MY_VAR);
}
''');
  }

  void test_importLibraryProject_withType_inParentFolder() {
    testFile = '/project/bin/test.dart';
    addSource('/project/lib.dart', '''
library lib;
class Test {}
''');
    _indexTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    assertHasFix(FixKind.IMPORT_LIBRARY_PROJECT, '''
import '../lib.dart';

main() {
  Test t = null;
}
''');
  }

  void test_importLibraryProject_withType_inRelativeFolder() {
    testFile = '/project/bin/test.dart';
    addSource('/project/lib/sub/folder/lib.dart', '''
library lib;
class Test {}
''');
    _indexTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    assertHasFix(FixKind.IMPORT_LIBRARY_PROJECT, '''
import '../lib/sub/folder/lib.dart';

main() {
  Test t = null;
}
''');
  }

  void test_importLibraryProject_withType_inSameFolder() {
    testFile = '/project/bin/test.dart';
    addSource('/project/bin/lib.dart', '''
library lib;
class Test {}
''');
    _indexTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    assertHasFix(FixKind.IMPORT_LIBRARY_PROJECT, '''
import 'lib.dart';

main() {
  Test t = null;
}
''');
  }

  void test_importLibrarySdk_withTopLevelVariable() {
    _ensureSdkMathLibraryResolved();
    _indexTestUnit('''
main() {
  print(PI);
}
''');
    performAllAnalysisTasks();
    assertHasFix(FixKind.IMPORT_LIBRARY_SDK, '''
import 'dart:math';

main() {
  print(PI);
}
''');
  }

  void test_importLibrarySdk_withType_invocationTarget() {
    _ensureSdkAsyncLibraryResolved();
    _indexTestUnit('''
main() {
  Future.wait(null);
}
''');
    assertHasFix(FixKind.IMPORT_LIBRARY_SDK, '''
import 'dart:async';

main() {
  Future.wait(null);
}
''');
  }

  void test_importLibrarySdk_withType_typeAnnotation() {
    _ensureSdkAsyncLibraryResolved();
    _indexTestUnit('''
main() {
  Future f = null;
}
''');
    assertHasFix(FixKind.IMPORT_LIBRARY_SDK, '''
import 'dart:async';

main() {
  Future f = null;
}
''');
  }

  void test_importLibrarySdk_withType_typeAnnotation_PrefixedIdentifier() {
    _ensureSdkAsyncLibraryResolved();
    _indexTestUnit('''
main() {
  Future.wait;
}
''');
    assertHasFix(FixKind.IMPORT_LIBRARY_SDK, '''
import 'dart:async';

main() {
  Future.wait;
}
''');
  }

  void test_importLibraryShow() {
    _indexTestUnit('''
import 'dart:async' show Stream;
main() {
  Stream s = null;
  Future f = null;
}
''');
    assertHasFix(FixKind.IMPORT_LIBRARY_SHOW, '''
import 'dart:async' show Future, Stream;
main() {
  Stream s = null;
  Future f = null;
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

  void test_undefinedClass_useSimilar_fromImport() {
    _indexTestUnit('''
main() {
  Stirng s = 'abc';
}
''');
    assertHasFix(FixKind.CHANGE_TO, '''
main() {
  String s = 'abc';
}
''');
  }

  void test_undefinedClass_useSimilar_fromThisLibrary() {
    _indexTestUnit('''
class MyClass {}
main() {
  MyCalss v = null;
}
''');
    assertHasFix(FixKind.CHANGE_TO, '''
class MyClass {}
main() {
  MyClass v = null;
}
''');
  }

  void test_undefinedFunction_create_fromFunction() {
    _indexTestUnit('''
main() {
  int v = myUndefinedFunction(1, 2.0, '3');
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  int v = myUndefinedFunction(1, 2.0, '3');
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  void test_undefinedFunction_create_fromMethod() {
    _indexTestUnit('''
class A {
  main() {
    int v = myUndefinedFunction(1, 2.0, '3');
  }
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
class A {
  main() {
    int v = myUndefinedFunction(1, 2.0, '3');
  }
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  void test_undefinedFunction_create_returnType_bool_expressions() {
    assert_undefinedFunction_create_returnType_bool("!test();");
    assert_undefinedFunction_create_returnType_bool("b && test();");
    assert_undefinedFunction_create_returnType_bool("test() && b;");
    assert_undefinedFunction_create_returnType_bool("b || test();");
    assert_undefinedFunction_create_returnType_bool("test() || b;");
  }

  void test_undefinedFunction_create_returnType_bool_statements() {
    assert_undefinedFunction_create_returnType_bool("assert ( test() );");
    assert_undefinedFunction_create_returnType_bool("if ( test() ) {}");
    assert_undefinedFunction_create_returnType_bool("while ( test() ) {}");
    assert_undefinedFunction_create_returnType_bool("do {} while ( test() );");
  }

  void test_undefinedFunction_create_returnType_fromAssignment_eq() {
    _indexTestUnit('''
main() {
  int v;
  v = myUndefinedFunction();
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  int v;
  v = myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  void test_undefinedFunction_create_returnType_fromAssignment_plusEq() {
    _indexTestUnit('''
main() {
  int v;
  v += myUndefinedFunction();
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  int v;
  v += myUndefinedFunction();
}

num myUndefinedFunction() {
}
''');
  }

  void test_undefinedFunction_create_returnType_fromBinary_right() {
    _indexTestUnit('''
main() {
  0 + myUndefinedFunction();
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  0 + myUndefinedFunction();
}

num myUndefinedFunction() {
}
''');
  }

  void test_undefinedFunction_create_returnType_fromInitializer() {
    _indexTestUnit('''
main() {
  int v = myUndefinedFunction();
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  int v = myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  void test_undefinedFunction_create_returnType_fromInvocationArgument() {
    _indexTestUnit('''
foo(int p) {}
main() {
  foo( myUndefinedFunction() );
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
foo(int p) {}
main() {
  foo( myUndefinedFunction() );
}

int myUndefinedFunction() {
}
''');
  }

  void test_undefinedFunction_create_returnType_fromReturn() {
    _indexTestUnit('''
int main() {
  return myUndefinedFunction();
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
int main() {
  return myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  void test_undefinedFunction_create_returnType_void() {
    _indexTestUnit('''
main() {
  myUndefinedFunction();
}
''');
    assertHasFix(FixKind.CREATE_FUNCTION, '''
main() {
  myUndefinedFunction();
}

void myUndefinedFunction() {
}
''');
  }

  void test_undefinedFunction_useSimilar_fromImport() {
    _indexTestUnit('''
main() {
  pritn(0);
}
''');
    assertHasFix(FixKind.CHANGE_TO, '''
main() {
  print(0);
}
''');
  }

  void test_undefinedFunction_useSimilar_thisLibrary() {
    _indexTestUnit('''
myFunction() {}
main() {
  myFuntcion();
}
''');
    assertHasFix(FixKind.CHANGE_TO, '''
myFunction() {}
main() {
  myFunction();
}
''');
  }

  void test_undefinedMethod_createQualified_fromClass() {
    _indexTestUnit('''
class A {
}
main() {
  A.myUndefinedMethod();
}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  static void myUndefinedMethod() {
  }
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  void test_undefinedMethod_createQualified_fromClass_hasOtherMember() {
    _indexTestUnit('''
class A {
  foo() {}
}
main() {
  A.myUndefinedMethod();
}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  foo() {}

  static void myUndefinedMethod() {
  }
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  void test_undefinedMethod_createQualified_fromInstance() {
    _indexTestUnit('''
class A {
}
main(A a) {
  a.myUndefinedMethod();
}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  void myUndefinedMethod() {
  }
}
main(A a) {
  a.myUndefinedMethod();
}
''');
  }

  void test_undefinedMethod_createQualified_targetIsFunctionType() {
    _indexTestUnit('''
typedef A();
main() {
  A.myUndefinedMethod();
}
''');
    assertNoFix(FixKind.CREATE_METHOD);
  }

  void test_undefinedMethod_createQualified_targetIsUnresolved() {
    _indexTestUnit('''
main() {
  NoSuchClass.myUndefinedMethod();
}
''');
    assertNoFix(FixKind.CREATE_METHOD);
  }

  void test_undefinedMethod_createUnqualified_parameters() {
    _indexTestUnit('''
class A {
  main() {
    myUndefinedMethod(0, 1.0, '3');
  }
}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  main() {
    myUndefinedMethod(0, 1.0, '3');
  }

  void myUndefinedMethod(int i, double d, String s) {
  }
}
''');
    // linked positions
    _assertHasLinkedPositions(
        'NAME',
        ['myUndefinedMethod(0', 'myUndefinedMethod(int']);
    _assertHasLinkedPositions('RETURN_TYPE', ['void myUndefinedMethod(']);
    _assertHasLinkedPositions('TYPE0', ['int i']);
    _assertHasLinkedPositions('TYPE1', ['double d']);
    _assertHasLinkedPositions('TYPE2', ['String s']);
    _assertHasLinkedPositions('ARG0', ['i,']);
    _assertHasLinkedPositions('ARG1', ['d,']);
    _assertHasLinkedPositions('ARG2', ['s)']);
    // linked proposals
    _assertHasLinkedSuggestions(
        'TYPE0',
        expectedSuggestions(
            LinkedEditSuggestionKind.TYPE,
            ['int', 'num', 'Object', 'Comparable']));
    _assertHasLinkedSuggestions(
        'TYPE1',
        expectedSuggestions(
            LinkedEditSuggestionKind.TYPE,
            ['double', 'num', 'Object', 'Comparable']));
    _assertHasLinkedSuggestions(
        'TYPE2',
        expectedSuggestions(
            LinkedEditSuggestionKind.TYPE,
            ['String', 'Object', 'Comparable']));
  }

  List<LinkedEditSuggestion> expectedSuggestions(LinkedEditSuggestionKind kind,
      List<String> values) {
    return values.map((value) {
      return new LinkedEditSuggestion(kind, value);
    }).toList();
  }

  void test_undefinedMethod_createUnqualified_returnType() {
    _indexTestUnit('''
class A {
  main() {
    int v = myUndefinedMethod();
  }
}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  main() {
    int v = myUndefinedMethod();
  }

  int myUndefinedMethod() {
  }
}
''');
    // linked positions
    _assertHasLinkedPositions(
        'NAME',
        ['myUndefinedMethod();', 'myUndefinedMethod() {']);
    _assertHasLinkedPositions('RETURN_TYPE', ['int myUndefinedMethod(']);
  }

  void test_undefinedMethod_createUnqualified_staticFromField() {
    _indexTestUnit('''
class A {
  static var f = myUndefinedMethod();
}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  static var f = myUndefinedMethod();

  static myUndefinedMethod() {
  }
}
''');
  }

  void test_undefinedMethod_createUnqualified_staticFromMethod() {
    _indexTestUnit('''
class A {
  static main() {
    myUndefinedMethod();
  }
}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  static main() {
    myUndefinedMethod();
  }

  static void myUndefinedMethod() {
  }
}
''');
  }

  void test_undefinedMethod_hint_createQualified_fromInstance() {
    _indexTestUnit('''
class A {
}
main() {
  var a = new A();
  a.myUndefinedMethod();
}
''');
    assertHasFix(FixKind.CREATE_METHOD, '''
class A {
  void myUndefinedMethod() {
  }
}
main() {
  var a = new A();
  a.myUndefinedMethod();
}
''');
  }

  void test_undefinedMethod_useSimilar_ignoreOperators() {
    _indexTestUnit('''
main(Object object) {
  object.then();
}
''');
    assertNoFix(FixKind.CHANGE_TO);
  }

  void test_undefinedMethod_useSimilar_qualified() {
    _indexTestUnit('''
class A {
  myMethod() {}
}
main() {
  A a = new A();
  a.myMehtod();
}
''');
    assertHasFix(FixKind.CHANGE_TO, '''
class A {
  myMethod() {}
}
main() {
  A a = new A();
  a.myMethod();
}
''');
  }

  void test_undefinedMethod_useSimilar_unqualified_superClass() {
    _indexTestUnit('''
class A {
  myMethod() {}
}
class B extends A {
  main() {
    myMehtod();
  }
}
''');
    assertHasFix(FixKind.CHANGE_TO, '''
class A {
  myMethod() {}
}
class B extends A {
  main() {
    myMethod();
  }
}
''');
  }

  void test_undefinedMethod_useSimilar_unqualified_thisClass() {
    _indexTestUnit('''
class A {
  myMethod() {}
  main() {
    myMehtod();
  }
}
''');
    assertHasFix(FixKind.CHANGE_TO, '''
class A {
  myMethod() {}
  main() {
    myMethod();
  }
}
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
    List<Fix> fixes = computeFixes(searchEngine, testUnit, error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        return fix;
      }
    }
    throw fail('Expected to find fix $kind in\n${fixes.join('\n')}');
  }

  void _assertHasLinkedPositions(String groupId, List<String> expectedStrings) {
    List<Position> expectedPositions = _findResultPositions(expectedStrings);
    List<LinkedEditGroup> groups = change.linkedEditGroups;
    for (LinkedEditGroup group in groups) {
      if (group.id == groupId) {
        List<Position> actualPositions = group.positions;
        expect(actualPositions, unorderedEquals(expectedPositions));
        return;
      }
    }
    fail('No group with ID=$groupId foind in\n${groups.join('\n')}');
  }

  void _assertHasLinkedSuggestions(String groupId,
      List<LinkedEditSuggestion> expected) {
    List<LinkedEditGroup> groups = change.linkedEditGroups;
    for (LinkedEditGroup group in groups) {
      if (group.id == groupId) {
        expect(group.suggestions, expected);
        return;
      }
    }
    fail('No group with ID=$groupId foind in\n${groups.join('\n')}');
  }

  /**
   * We search for elements only already resolved lbiraries, and we use
   * `dart:async` elements in tests.
   */
  void _ensureSdkAsyncLibraryResolved() {
    resolveLibraryUnit(addSource('/other.dart', 'import "dart:async";'));
  }

  /**
   * We search for elements only already resolved lbiraries, and we use
   * `dart:async` elements in tests.
   */
  void _ensureSdkMathLibraryResolved() {
    resolveLibraryUnit(addSource('/other.dart', 'import "dart:math";'));
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

  List<Position> _findResultPositions(List<String> searchStrings) {
    List<Position> positions = <Position>[];
    for (String search in searchStrings) {
      int offset = resultCode.indexOf(search);
      int length = getLeadingIdentifierLength(search);
      positions.add(new Position(testFile, offset));
    }
    return positions;
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(context, testUnit);
  }
}
