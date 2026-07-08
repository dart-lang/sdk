// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../src/dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonHintCodeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonHintCodeTest extends PubPackageResolutionTest {
  test_issue20904BuggyTypePromotionAtIfJoin_1() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    await resolveTestCodeWithDiagnostics(r'''
f(message, dynamic_) {
  if (message is Function) {
    message = dynamic_;
  }
  int s = message;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 's' isn't used.
}
''');
  }

  test_issue20904BuggyTypePromotionAtIfJoin_3() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    await resolveTestCodeWithDiagnostics(r'''
f(message) {
  var dynamic_;
  if (message is Function) {
    message = dynamic_;
  } else {
    return;
  }
  int s = message;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 's' isn't used.
}
''');
  }

  test_issue20904BuggyTypePromotionAtIfJoin_4() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    await resolveTestCodeWithDiagnostics(r'''
f(message) {
  if (message is Function) {
    message = '';
  } else {
    return;
  }
  String s = message;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 's' isn't used.
}
''');
  }

  test_propagatedFieldType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A { }
class X<T> {
  final x = <T>[];
}
class Z {
  final X<A> y = new X<A>();
  foo() {
    y.x.add(new A());
  }
}
''');
  }

  test_undefinedMethod_assignmentExpression_inSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(a, a2) {
  a = new A();
  a2 = new A();
  a += a2;
}
''');
  }

  test_undefinedMethod_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class D<T extends dynamic> {
  fieldAccess(T t) => t.abc;
  methodAccess(T t) => t.xyz(1, 2, 'three');
}
''');
  }

  test_undefinedMethod_unionType_all() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int m(int x) => 0;
}
class B {
  String m() => '0';
}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m();
}
''');
  }

  test_undefinedMethod_unionType_some() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int m(int x) => 0;
}
class B {}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m(0);
}
''');
  }
}
