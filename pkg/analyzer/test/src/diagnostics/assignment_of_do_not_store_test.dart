// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentOfDoNotStoreTest);
    defineReflectiveTests(AssignmentOfDoNotStoreInTestsTest);
  });
}

@reflectiveTest
class AssignmentOfDoNotStoreInTestsTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_noHintsInTestDir() async {
    // Code that is in a test dir (the default for PubPackageResolutionTests)
    // should not trigger the hint.
    // (See:https://github.com/dart-lang/sdk/issues/45594)
    await assertNoErrorsInCode(
      '''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get v => '';
}

class B {
  String f = A().v;
}
''',
    );
  }
}

@reflectiveTest
class AssignmentOfDoNotStoreTest extends PubPackageResolutionTest {
  /// Override the default which is in .../test and should not trigger hints.
  @override
  String get testPackageRootPath => '$workspaceRootPath/test_project';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_containingInstanceGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';
@doNotStore
class A {
  String get v => '';
}

String f = A().v;
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 91, 5),
    ]);
  }

  test_class_containingInstanceMethod() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';
@doNotStore
class A {
  String v() => '';
}

String f = A().v();
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 89, 7),
    ]);
  }

  test_class_containingStaticGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';
@doNotStore
class A {
  static String get v => '';
}

String f = A.v;
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 98, 3),
    ]);
  }

  test_class_containingStaticMethod() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';
@doNotStore
class A {
  static String v() => '';
}

String f = A.v();
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 96, 5),
    ]);
  }

  test_classMemberGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get v => '';
}

class B {
  String f = A().v;
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 106, 5,
          messageContains: ["'v'"]),
    ]);
  }

  test_classStaticGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  static String get v => '';
}

class B {
  String f = A.v;
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 113, 3),
    ]);
  }

  test_functionAssignment() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String g(int i) => '';

class C {
  String Function(int) f = g;
}
''');
  }

  test_functionReturnValue() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String getV() => '';

class A {
  final f = getV();
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 90, 6),
    ]);
  }

  test_methodReturnValue() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String getV() => '';
}

class B {
  final f = A().getV();
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 106, 10),
    ]);
  }

  test_mixin_containingInstanceMethod() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';
@doNotStore
mixin M {
  String v() => '';
}

abstract class A {
  M get m;
  late String f = m.v();
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 126, 5),
    ]);
  }

  test_tearOff() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String getV() => '';

class A {
  final f = getV;
}
''');
  }

  test_topLevelGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String get v => '';

class A {
  final f = v;
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 89, 1),
    ]);
  }

  test_topLevelGetter_binaryExpression() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String? get v => '';

class A {
  final f = v ?? v;
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 90, 1),
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 95, 1),
    ]);
  }

  test_topLevelGVariable_assignment_getter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

String top = v;

@doNotStore
String get v => '';
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 47, 1,
          messageContains: ["'v'"]),
    ]);
  }

  test_topLevelVariable_assignment_field() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

String top = A().f;

class A{
  @doNotStore
  String get f => '';
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 47, 5,
          messageContains: ["'f'"]),
    ]);
  }

  test_topLevelVariable_assignment_functionExpression() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

var c = () => _v;

String v = c();
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 82, 2),
    ]);
  }

  test_topLevelVariable_assignment_method() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

String top = A().v();

class A{
  @doNotStore
  String v() => '';
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 47, 7,
          messageContains: ["'v'"]),
    ]);
  }

  test_topLevelVariable_libraryAnnotation() async {
    newFile('$testPackageLibPath/library.dart', '''
@doNotStore
library lib;

import 'package:meta/meta.dart';

final v = '';
''');

    await assertErrorsInCode('''
import 'library.dart';

class A {
  final f = v;
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 46, 1),
    ]);
  }

  test_topLevelVariable_ternary() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String get v => '';

class A {
  static bool c = false;
  final f = c ? v : v;
}
''', [
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 118, 1),
      error(WarningCode.ASSIGNMENT_OF_DO_NOT_STORE, 122, 1),
    ]);
  }
}
