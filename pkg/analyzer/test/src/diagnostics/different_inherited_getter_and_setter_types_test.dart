// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DifferentInheritedGetterAndSetterTypesTest);
  });
}

@reflectiveTest
class DifferentInheritedGetterAndSetterTypesTest
    extends PubPackageResolutionTest {
  test_finalField() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set foo(int _) {}
  num get foo => 0;
}

class C extends A {
  final foo = 0;
}
''');
  }

  test_genericSubstitution() async {
    await resolveTestCodeWithDiagnostics('''
class A<T, U> {
  void set foo(T _) {}
  U get foo => throw 0;
}

class C extends A<int, num> {
  var foo = 0;
//    ^^^
// [diag.differentInheritedGetterAndSetterTypes] Can't infer a type for 'foo' because the combined member signature of the getter has return type 'num', which is not the same as the parameter type 'int' of the combined member signature of the setter.
}
''');
  }

  test_getterSupertypeOfSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set foo(int _) {}
  num get foo => 0;
}

class C extends A {
  var foo = 0;
//    ^^^
// [diag.differentInheritedGetterAndSetterTypes] Can't infer a type for 'foo' because the combined member signature of the getter has return type 'num', which is not the same as the parameter type 'int' of the combined member signature of the setter.
}
''');
  }

  test_notSameType_dynamicAndObjectQuestion() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  dynamic get foo;
  set foo(Object? _);
//    ^^^
// [context 1] The setter being overridden.
}

class B extends A {
  var foo = 0;
//    ^^^
// [diag.differentInheritedGetterAndSetterTypes] Can't infer a type for 'foo' because the combined member signature of the getter has return type 'dynamic', which is not the same as the parameter type 'Object?' of the combined member signature of the setter.
// [diag.invalidOverrideSetter][context 1] The setter 'B.foo' ('void Function(int)') isn't a valid override of 'A.foo' ('void Function(Object?)').
}
''');
  }

  test_sameType() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set foo(int _) {}
  int get foo => 0;
}

class C extends A {
  var foo = 0;
}
''');
  }

  test_sameType_afterCombiningGetters() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  num get foo => 0;
}

class B {
  int get foo => 0;
}

class C {
  void set foo(int _) {}
}

class D implements A, B, C {
  var foo = 0;
}
''');
  }

  test_sameType_futureOrObject() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

abstract class A {
  Object get foo;
  set foo(FutureOr<Object> _);
}

class B extends A {
  var foo = Object();
}
''');
  }

  test_setterSupertypeOfGetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void set foo(num _) {}
//         ^^^
// [context 1] The setter being overridden.
  int get foo => 0;
}

class C extends A {
  var foo = 0;
//    ^^^
// [diag.differentInheritedGetterAndSetterTypes] Can't infer a type for 'foo' because the combined member signature of the getter has return type 'int', which is not the same as the parameter type 'num' of the combined member signature of the setter.
// [diag.invalidOverrideSetter][context 1] The setter 'C.foo' ('void Function(int)') isn't a valid override of 'A.foo' ('void Function(num)').
}
''');
  }
}
