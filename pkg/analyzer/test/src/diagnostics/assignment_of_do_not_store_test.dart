// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentOfDoNotStoreTest);
  });
}

@reflectiveTest
class AssignmentOfDoNotStoreTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
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
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 106, 5),
    ]);
  }

  test_classMemberVariable() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A{
  @doNotStore
  final f = '';
}

class B {
  String f = A().f;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 99, 5),
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
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 113, 3),
    ]);
  }

  test_classStaticVariable() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A{
  @doNotStore
  static final f = '';
}

class B {
  String f = A.f;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 106, 3),
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
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 90, 6),
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
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 106, 10),
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
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 89, 1),
    ]);
  }

  test_topLevelVariable() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
final v = '';

class A {
  final f = v;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 83, 1),
    ]);
  }
}
