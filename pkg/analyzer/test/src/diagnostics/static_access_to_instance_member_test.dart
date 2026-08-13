// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticAccessToInstanceMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class StaticAccessToInstanceMemberTest extends PubPackageResolutionTest {
  test_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.name();
}
@A.name()
main() {
}
''');
  }

  test_extension_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get g => 0;
}
f() {
  E.g;
//  ^
// [diag.staticAccessToInstanceMember] Instance member 'g' can't be accessed using static access.
}
''');
  }

  test_extension_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void m() {}
}
f() {
  E.m();
//  ^
// [diag.staticAccessToInstanceMember] Instance member 'm' can't be accessed using static access.
}
''');
  }

  test_extension_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void set s(int i) {}
}
f() {
  E.s = 2;
//  ^
// [diag.staticAccessToInstanceMember] Instance member 's' can't be accessed using static access.
}
''');
  }

  test_method_invocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m() {}
}
main() {
  A.m();
//  ^
// [diag.staticAccessToInstanceMember] Instance member 'm' can't be accessed using static access.
}''');
  }

  test_method_reference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m() {}
}
main() {
  A.m;
//  ^
// [diag.staticAccessToInstanceMember] Instance member 'm' can't be accessed using static access.
}''');
  }

  test_propertyAccess_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var f;
}
main() {
  A.f;
//  ^
// [diag.staticAccessToInstanceMember] Instance member 'f' can't be accessed using static access.
}''');
  }

  test_propertyAccess_field_toplevel_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  List<T> t = [];
}
var x = C.t;
//        ^
// [diag.staticAccessToInstanceMember] Instance member 't' can't be accessed using static access.
''');
  }

  test_propertyAccess_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  get f => 42;
}
main() {
  A.f;
//  ^
// [diag.staticAccessToInstanceMember] Instance member 'f' can't be accessed using static access.
}''');
  }

  test_propertyAccess_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set f(x) {}
}
main() {
  A.f = 42;
//  ^
// [diag.staticAccessToInstanceMember] Instance member 'f' can't be accessed using static access.
}''');
  }

  test_static_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static m() {}
}
main() {
  A.m;
  A.m();
}
''');
  }

  test_static_propertyAccess_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static var f;
}
main() {
  A.f;
  A.f = 1;
}
''');
  }

  test_static_propertyAccess_propertyAccessor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static get f => 42;
  static set f(x) {}
}
main() {
  A.f;
  A.f = 1;
}
''');
  }
}
