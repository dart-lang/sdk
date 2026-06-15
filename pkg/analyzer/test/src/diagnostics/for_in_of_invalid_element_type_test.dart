// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInOfInvalidElementTypeTest);
  });
}

@reflectiveTest
class ForInOfInvalidElementTypeTest extends PubPackageResolutionTest {
  test_await_declaredVariable_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(dynamic a) async {
  await for (int i in a) {
    i;
  }
}
''');
  }

  test_await_declaredVariableWrongType() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Stream<String> stream) async {
  await for (int i in stream) {
//                    ^^^^^^
// [diag.forInOfInvalidElementType] The type 'Stream<String>' used in the 'for' loop must implement 'Stream' with a type argument that can be assigned to 'int'.
    i;
  }
}
''');
  }

  test_await_existingVariableWrongType() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Stream<String> stream) async {
  int i;
  await for (i in stream) {
//                ^^^^^^
// [diag.forInOfInvalidElementType] The type 'Stream<String>' used in the 'for' loop must implement 'Stream' with a type argument that can be assigned to 'int'.
    i;
  }
}
''');
  }

  test_bad_type_bound() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {
//                   ^^^^^^^^
// [diag.forInOfInvalidElementType] The type 'Iterable<int>' used in the 'for' loop must implement 'Iterable' with a type argument that can be assigned to 'String'.
      i;
    }
  }
}
''');
  }

  test_declaredVariable_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(dynamic a) {
  for (int i in a) {
    i;
  }
}
''');
  }

  test_declaredVariable_implicitCallReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call() {}
}
void foo(C c) {
  for (void Function() f in [c]) {
    f;
  }
}
''');
  }

  test_declaredVariable_implicitCallReference_genericFunctionInstantiation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call<T>(T p) {}
}
void foo(C c) {
  for (void Function(int) f in [c]) {
    f;
  }
}
''');
  }

  test_declaredVariable_interfaceTypeTypedef_ok() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef S = String;
f() {
  for (S i in <String>[]) {
    i;
  }
}
''');
  }

  test_declaredVariable_ok() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (String i in <String>[]) {
    i;
  }
}
''');
  }

  test_declaredVariable_wrongType() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (int i in <String>[]) {
//              ^^^^^^^^^^
// [diag.forInOfInvalidElementType] The type 'List<String>' used in the 'for' loop must implement 'Iterable' with a type argument that can be assigned to 'int'.
    i;
  }
}
''');
  }

  test_existingVariableWrongType() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  int i;
  for (i in <String>[]) {
//          ^^^^^^^^^^
// [diag.forInOfInvalidElementType] The type 'List<String>' used in the 'for' loop must implement 'Iterable' with a type argument that can be assigned to 'int'.
    i;
  }
}
''');
  }

  test_implicitCallReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int a) {}
}
void foo(Iterable<C> iterable) {
  void Function(int) f;
  for (f in iterable) {
    f;
  }
}
''');
  }

  test_implicitCallReference_genericFunctionInstantiation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call<T>(T p) {}
}
void foo(Iterable<C> iterable) {
  void Function(int) f;
  for (f in iterable) {
    f;
  }
}
''');
  }

  test_implicitCallReference_unassignableFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int a) {}
}
void foo(Iterable<C> iterable) {
  void Function(String) f;
  for (f in iterable) {
//          ^^^^^^^^
// [diag.forInOfInvalidElementType] The type 'Iterable<C>' used in the 'for' loop must implement 'Iterable' with a type argument that can be assigned to 'void Function(String)'.
    f;
  }
}
''');
  }
}
