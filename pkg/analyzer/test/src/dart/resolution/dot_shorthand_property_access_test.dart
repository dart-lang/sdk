// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  test_object_new() async {
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
