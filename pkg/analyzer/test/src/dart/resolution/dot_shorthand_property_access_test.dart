// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandPropertyAccessResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DotShorthandPropertyAccessResolutionTest
    extends PubPackageResolutionTest {
  test_chain_method() async {
    await assertNoErrorsInCode(r'''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
  C method() => C(1);
}

void main() {
  C c = .member.method();
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibraryFragment>::@class::C::@getter::member#element
    staticType: C
  staticType: C
''');
  }

  test_chain_property() async {
    await assertNoErrorsInCode(r'''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
  C get property => C(1);
}

void main() {
  C c = .member.property;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibraryFragment>::@class::C::@getter::member#element
    staticType: C
  staticType: C
''');
  }

  test_class_basic() async {
    await assertNoErrorsInCode('''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = .member;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibraryFragment>::@class::C::@getter::member#element
    staticType: C
  staticType: C
''');
  }

  test_const_assert_class() async {
    await assertNoErrorsInCode(r'''
class Integer {
  static const Integer one = const Integer._(1);
  final int integer;
  Integer(this.integer);
  const Integer._(this.integer);
}

class CAssert {
  const CAssert.one(Integer i): assert(i == .one);
}
''');

    var node = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(node, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: one
    element: <testLibraryFragment>::@class::Integer::@getter::one#element
    staticType: Integer
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: Integer
''');
  }

  test_const_assert_enum() async {
    await assertNoErrorsInCode(r'''
enum Color { red, green, blue }

class CAssert {
  const CAssert.blue(Color color): assert(color == .blue);
}
''');

    var node = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(node, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: blue
    element: <testLibraryFragment>::@enum::Color::@getter::blue#element
    staticType: Color
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: Color
''');
  }

  test_const_class() async {
    await assertNoErrorsInCode('''
class C {
  static const C member = const C._(1);
  final int x;
  C(this.x);
  const C._(this.x);
}

void main() {
  const C c = .member;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibraryFragment>::@class::C::@getter::member#element
    staticType: C
  staticType: C
''');
  }

  test_const_enum() async {
    await assertNoErrorsInCode('''
enum Color { red, green, blue }

void main() {
  const Color c = .blue;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: blue
    element: <testLibraryFragment>::@enum::Color::@getter::blue#element
    staticType: Color
  staticType: Color
''');
  }

  test_const_extensionType() async {
    await assertNoErrorsInCode('''
extension type C(int x) {
  static const C member = const C._(1);
  const C._(this.x);
}

void main() {
  const C c = .member;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibraryFragment>::@extensionType::C::@getter::member#element
    staticType: C
  staticType: C
''');
  }

  test_enum_basic() async {
    await assertNoErrorsInCode('''
enum C { red }

void main() {
  C c = .red;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: red
    element: <testLibraryFragment>::@enum::C::@getter::red#element
    staticType: C
  staticType: C
''');
  }

  test_equality() async {
    await assertNoErrorsInCode('''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
}

void main() {
  C lhs = C.member;
  bool b = lhs == .member;
  print(b);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibraryFragment>::@class::C::@getter::member#element
    staticType: C
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: C
''');
  }

  test_equality_indexExpression() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
  static List<C> instances = [C(1)];
}

void main() {
  print(C(1) == .instances[0]);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: instances
    element: <testLibraryFragment>::@class::C::@getter::instances#element
    staticType: List<C>
  staticType: List<C>
''');
  }

  test_equality_nullAssert() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
  static C? nullable = C(1);
}

main() {
  print(C(1) == .nullable!);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: nullable
    element: <testLibraryFragment>::@class::C::@getter::nullable#element
    staticType: C?
  staticType: C?
''');
  }

  test_equality_nullAssert_chain() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
  static C? nullable = C(1);
  C? member = C(1);
}

main() {
  print(C(1) == .nullable!.member!);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: nullable
    element: <testLibraryFragment>::@class::C::@getter::nullable#element
    staticType: C?
  staticType: C?
''');
  }

  test_equality_pattern() async {
    await assertNoErrorsInCode('''
enum Color { red, blue }

void main() {
  Color c = Color.red;
  if (c case == .blue) print('ok');
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: blue
    element: <testLibraryFragment>::@enum::Color::@getter::blue#element
    staticType: Color
  staticType: Color
''');
  }

  test_error_context_invalid() async {
    await assertErrorsInCode(
      '''
class C { }

void main() {
  C Function() c = .member;
  print(c);
}
''',
      [error(CompileTimeErrorCode.DOT_SHORTHAND_MISSING_CONTEXT, 46, 7)],
    );
  }

  test_error_context_none() async {
    await assertErrorsInCode(
      '''
void main() {
  var c = .member;
  print(c);
}
''',
      [error(CompileTimeErrorCode.DOT_SHORTHAND_MISSING_CONTEXT, 24, 7)],
    );
  }

  test_error_unresolved() async {
    await assertErrorsInCode(
      '''
class C { }

void main() {
  C c = .getter;
  print(c);
}
''',
      [error(CompileTimeErrorCode.DOT_SHORTHAND_UNDEFINED_GETTER, 36, 6)],
    );
  }

  test_error_unresolved_new() async {
    await assertErrorsInCode(
      '''
class C {
  C.named();
}

void main() {
  C c = .new;
  print(c);
}
''',
      [error(CompileTimeErrorCode.DOT_SHORTHAND_UNDEFINED_GETTER, 49, 3)],
    );
  }

  test_extensionType() async {
    await assertNoErrorsInCode('''
extension type C(int integer) {
  static C get one => C(1);
}

void main() {
  C c = .one;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: one
    element: <testLibraryFragment>::@extensionType::C::@getter::one#element
    staticType: C
  staticType: C
''');
  }

  test_functionReference() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static String foo<X>() => "C<$X>";

  @override
  bool operator ==(Object other) {
    return false;
  }
}

void test<T extends num>() {
  C() == .foo<T>;
}

main() {
  test<int>();
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibraryFragment>::@class::C::@method::foo#element
    staticType: String Function<X>()
  staticType: String Function<X>()
''');
  }

  test_futureOr() async {
    await assertNoErrorsInCode('''
import 'dart:async';

enum C { red }

void main() {
  FutureOr<C> c = .red;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: red
    element: <testLibraryFragment>::@enum::C::@getter::red#element
    staticType: C
  staticType: C
''');
  }

  test_futureOr_nested() async {
    await assertNoErrorsInCode('''
import 'dart:async';

enum C { red }

void main() {
  FutureOr<FutureOr<C>> c = .red;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: red
    element: <testLibraryFragment>::@enum::C::@getter::red#element
    staticType: C
  staticType: C
''');
  }

  test_mixin() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
}

mixin CMixin on C {
  static CMixin get mixinOne => _CWithMixin(1);
}

class _CWithMixin extends C with CMixin {
  _CWithMixin(super.x);
}

void main() {
  CMixin c = .mixinOne;
  print(c);
}

''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: mixinOne
    element: <testLibraryFragment>::@mixin::CMixin::@getter::mixinOne#element
    staticType: CMixin
  staticType: CMixin
''');
  }

  test_tearOff_constructor() async {
    await assertNoErrorsInCode(r'''
class C1 {
  C1.id();

  @override
  bool operator ==(Object other) => identical(C1.id, other);
}

main() {
  bool x = C1.id() == .id;
  print(x);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: id
    element: <testLibraryFragment>::@class::C1::@constructor::id#element
    staticType: C1 Function()
  correspondingParameter: <testLibraryFragment>::@class::C1::@method::==::@parameter::other#element
  staticType: C1 Function()
''');
  }

  test_tearOff_constructor_new() async {
    await assertNoErrorsInCode('''
void main() {
  Object o = .new;
  print(o);
}
''');

    var identifier = findNode.singleDotShorthandPropertyAccess;
    assertResolvedNodeText(identifier, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: new
    element: dart:core::<fragment>::@class::Object::@constructor::new#element
    staticType: Object Function()
  staticType: Object Function()
''');
  }
}
