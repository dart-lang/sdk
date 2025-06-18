// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CascadeExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class CascadeExpressionResolutionTest extends PubPackageResolutionTest {
  test_nullAware_indexGet_promotableField() async {
    await assertNoErrorsInCode(r'''
class C {
  final D? _d;
  C(this._d);
}

abstract class D {
  void f();
  void g();
  D operator[](int i);
}

test(C c) {
  c.._d?[0].f().._d?.g();
}
''');
    // The null shorting for the index get `.._d?[0]` ends at the end of the
    // cascade section, therefore in the cascade section that follows, `..d_`
    // has static type `D?`.
    var node = findNode.simple('_d?.g()');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _d
  element: <testLibrary>::@class::C::@getter::_d
  staticType: D?
''');
  }

  test_nullAware_indexGet_promotableLocal() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  D? get d;
}

abstract class D {
  void f(int i);
  void g(int i);
  D operator[](int i);
}

test(C c, int? i) {
  c..d?[0].f(i!)..d?.g(i!);
}

''');
    // The null shorting for the index get `..d?[0]` ends at the end of the
    // cascade section, therefore in the cascade section that follows, `i` has
    // static type `int?`.
    var node = findNode.simple('i!);');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_nullAware_indexSet_promotableLocal() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  D get d;
  void f(int i);
}

abstract class D {
  int? operator[](int i);
  operator[]=(int i, int? j);
}

test(C c, int? i) {
  c..d[0] ??= i!..f(i!);
}
''');
    // The null shorting for the index set `..d[0] ??= i!` ends at the end of
    // the cascade section, therefore in the cascade section that follows, `i`
    // has static type `int?`.
    var node = findNode.simple('i!);');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_nullAware_methodInvocation_promotableField() async {
    await assertNoErrorsInCode(r'''
class C {
  final D? _d;
  C(this._d);
}

abstract class D {
  void f();
  void g();
}

test(C c) {
  c.._d?.f().._d?.g();
}
''');
    // The null shorting for the method invocation `.._d?.f()` ends at the end
    // of the cascade section, therefore in the cascade section that follows,
    // `.._d` has static type `D?`.
    var node = findNode.simple('_d?.g()');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _d
  element: <testLibrary>::@class::C::@getter::_d
  staticType: D?
''');
  }

  test_nullAware_methodInvocation_promotableLocal() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  D? get d;
}

abstract class D {
  void f(int i);
  void g(int i);
}

test(C c, int? i) {
  c..d?.f(i!)..d?.g(i!);
}
''');
    // The null shorting for the method invocation `..d?.f(i!)` ends at the end
    // of the cascade section, therefore in the cascade section that follows,
    // `i` has static type `int?`.
    var node = findNode.simple('i!);');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_nullAware_propertyGet_promotableField() async {
    await assertNoErrorsInCode(r'''
class C {
  final D? _d;
  C(this._d);
}

abstract class D {
  void f();
  void g();
  D get d;
}

test(C c) {
  c.._d?.d.f().._d?.g();
}
''');
    // The null shorting for the property get `.._d?.d` ends at the end of the
    // cascade section, therefore in the cascade section that follows, `..d_`
    // has static type `D?`.
    var node = findNode.simple('_d?.g()');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _d
  element: <testLibrary>::@class::C::@getter::_d
  staticType: D?
''');
  }

  test_nullAware_propertyGet_promotableLocal() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  D? get d;
}

abstract class D {
  void f(int i);
  void g(int i);
  D get d;
}

test(C c, int? i) {
  c..d?.d.f(i!)..d?.g(i!);
}

''');
    // The null shorting for the property get `..d?.d` ends at the end of the
    // cascade section, therefore in the cascade section that follows, `i` has
    // static type `int?`.
    var node = findNode.simple('i!);');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_nullAware_propertySet_promotableLocal() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  int? x;
  void f(int i);
}

test(C c, int? i) {
  c..x ??= i!..f(i!);
}
''');
    // The null shorting for the property set `..x ??= i!` ends at the end of
    // the cascade section, therefore in the cascade section that follows, `i`
    // has static type `int?`.
    var node = findNode.simple('i!);');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }
}
