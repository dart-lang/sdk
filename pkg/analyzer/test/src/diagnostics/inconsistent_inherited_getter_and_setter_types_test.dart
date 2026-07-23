// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentInheritedGetterAndSetterTypesTest);
  });
}

@reflectiveTest
class InconsistentInheritedGetterAndSetterTypesTest
    extends PubPackageResolutionTest {
  test_finalField() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set m(int _) {}
  num get m => 0;
}

class C extends A {
  final m = 0;
}
''');
  }

  test_genericSubstitution() async {
    await resolveTestCodeWithDiagnostics('''
class A<T, U> {
  void set m(T _) {}
  U get m => throw 0;
}

class C extends A<int, num> {
  var m = 0;
//    ^
// [diag.inconsistentInheritedGetterAndSetterTypes] Can't infer a type for 'm' because the combined member signature of the getter has return type 'num', which doesn't match the parameter type 'int' of the combined member signature of the setter.
}
''');
  }

  test_getterSupertypeOfSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set m(int _) {}
  num get m => 0;
}

class C extends A {
  var m = 0;
//    ^
// [diag.inconsistentInheritedGetterAndSetterTypes] Can't infer a type for 'm' because the combined member signature of the getter has return type 'num', which doesn't match the parameter type 'int' of the combined member signature of the setter.
}
''');
  }

  test_setterSupertypeOfGetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set m(num _) {}
//         ^
// [context 1] The setter being overridden.
  int get m => 0;
}

class C extends A {
  var m = 0;
//    ^
// [diag.inconsistentInheritedGetterAndSetterTypes] Can't infer a type for 'm' because the combined member signature of the getter has return type 'int', which doesn't match the parameter type 'num' of the combined member signature of the setter.
// [diag.invalidOverrideSetter][context 1] The setter 'C.m' ('void Function(int)') isn't a valid override of 'A.m' ('void Function(num)').
}
''');
  }

  test_sameType() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set m(int _) {}
  int get m => 0;
}

class C extends A {
  var m = 0;
}
''');
  }

  test_sameType_afterCombiningGetters() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  num get m => 0;
}

class B {
  int get m => 0;
}

class C {
  void set m(int _) {}
}

class D implements A, B, C {
  var m = 0;
}
''');
  }
}
