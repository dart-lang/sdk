// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandConstructorInvocationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DotShorthandConstructorInvocationResolutionTest
    extends PubPackageResolutionTest {
  test_abstractClass() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class Foo<T> {
  Foo();
}

void main() {
  Foo _ = .new();
//        ^^^^^^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');
  }

  test_abstractClass_const() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  static C fn() => CB.named(1);
}

class CB implements C {
  final int x;
  CB.named(this.x);
}

void main() {
  C c = const .fn(1);
//             ^^
// [diag.constWithUndefinedConstructor] The class 'C' doesn't have a constant constructor 'fn'.
  print(c);
}
''');
  }

  test_abstractClass_const_typeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  static C fn() => CB.named(1);
}

class CB implements C {
  final int x;
  CB.named(this.x);
}

void main() {
  C c = const .fn<int>(1);
//             ^^
// [diag.constWithUndefinedConstructor] The class 'C' doesn't have a constant constructor 'fn'.
//               ^^^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'C.fn', and type parameters can't be applied to dot shorthand constructor invocations.
  print(c);
}
''');
  }

  test_abstractClass_factory() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void main() async {
  var iter = [1, 2];
  await for (var x in .fromIterable(iter)) {
    print(x);
  }
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: fromIterable
    element: SubstitutedConstructorElementImpl
      baseElement: dart:async::@class::Stream::@constructor::fromIterable
      substitution: {T: int}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: iter
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: dart:async::@class::Stream::@constructor::fromIterable::@formalParameter::elements
          substitution: {T: int}
        element: iter@26
        staticType: List<int>
    rightParenthesis: )
  isDotShorthand: true
  staticType: Stream<int>
''');
  }

  test_abstractClass_factory_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class Foo<T> {
  const factory Foo.a() = _Foo;

  const Foo();
}

class _Foo<T> extends Foo<T> {
  const _Foo();
}

Foo<T> bar<T>() => const .a();
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: a
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::Foo::@constructor::a
      substitution: {T: Never}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticType: Foo<Never>
''');
  }

  test_abstractClass_factory_const_typeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class Foo<T> {
  const factory Foo.a() = _Foo;

  const Foo();
}

class _Foo<T> extends Foo<T> {
  const _Foo();
}

Foo<int> bar<T>() => const .a<int>();
//                           ^^^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'Foo.a', and type parameters can't be applied to dot shorthand constructor invocations.
''');
  }

  test_abstractClass_factory_typeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class Foo<T> {
  factory Foo.a() = _Foo;

  Foo();
}

class _Foo<T> extends Foo<T> {
  _Foo();
}

Foo<T> bar<T>() => .a<T>();
//                   ^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'Foo.a', and type parameters can't be applied to dot shorthand constructor invocations.
''');
  }

  test_abstractClass_function() async {
    await resolveTestCodeWithDiagnostics(r'''
Function getFunction() {
  return .new();
//       ^^^^^^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');
  }

  test_abstractClass_typeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class Foo<T> {
  Foo();
}

void main() {
  Foo _ = .new<int>();
//        ^^^^^^^^^^^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');
  }

  test_chain_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C(this.x);
  C method() => C(1);
}

void main() {
  C c = .new(1).method();
  print(c);
}
''');

    var node = result.findNode.methodInvocation('method();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: DotShorthandConstructorInvocation
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          staticType: int
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: method
    element: <testLibrary>::@class::C::@method::method
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_chain_method_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  const C(this.x);
  C method() => C(1);
}

void main() {
  C c = const .new(1).method();
  print(c);
}
''');

    var node = result.findNode.methodInvocation('method();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: DotShorthandConstructorInvocation
    constKeyword: const
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          staticType: int
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: method
    element: <testLibrary>::@class::C::@method::method
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_chain_property() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C(this.x);
  C get property => C(1);
}

void main() {
  C c = .new(1).property;
  print(c);
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: DotShorthandConstructorInvocation
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          staticType: int
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: property
    element: <testLibrary>::@class::C::@getter::property
    staticType: C
  staticType: C
''');
  }

  test_chain_property_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  const C(this.x);
  C get property => C(1);
}

void main() {
  C c = const .new(1).property;
  print(c);
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: DotShorthandConstructorInvocation
    constKeyword: const
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          staticType: int
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: property
    element: <testLibrary>::@class::C::@getter::property
    staticType: C
  staticType: C
''');
  }

  test_conflict_instance_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int value; // Same name as constructor
  A.value(this.value);
}

void main() {
  A _ = .value(1);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: value
    element: <testLibrary>::@class::A::@constructor::value
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::A::@constructor::value::@formalParameter::value
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: A
''');
  }

  test_conflict_instance_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int val;
  A.value(this.val);
  A? value() => null; // Same name as constructor
}

void main() {
  A _ = .value(1);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: value
    element: <testLibrary>::@class::A::@constructor::value
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::A::@constructor::value::@formalParameter::val
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: A
''');
  }

  test_conflict_instance_method_factory() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int val;
  A._(this.val);
  factory A.foo() => A._(1);
  A? foo() => A._(2); // Same name as constructor
}

void main() {
  A _ = .foo();
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@constructor::foo
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticType: A
''');
  }

  test_conflict_instance_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? val;
  A.value(this.val);

  // Same name as constructor
  set value(int v) {
    val = v;
  }
}

void main() {
  A _ = .value(1);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: value
    element: <testLibrary>::@class::A::@constructor::value
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::A::@constructor::value::@formalParameter::val
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: A
''');
  }

  test_const_assert() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  const C.named(this.x);
}

class CAssert {
  const CAssert.regular(C ctor)
    : assert(ctor == const .named(1));
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibrary>::@class::C::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: C
''');
  }

  test_const_inConstantContext() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  const C.named(this.x);
}

void main() {
  const C c = .named(1);
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibrary>::@class::C::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: C
''');
  }

  test_const_keyword() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  const C.named(this.x);
}

void main() {
  C c = const .named(1);
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibrary>::@class::C::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: C
''');
  }

  test_const_nonConst_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  C.named(this.x);
}

void main() {
  C c = const .named(1);
//      ^^^^^
// [diag.constWithNonConst] The constructor being called isn't a const constructor.
  print(c);
}
''');
  }

  test_const_nonConst_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static C fn() => C.named(1);
  final int x;
  C.named(this.x);
}

void main() {
  C c = const .fn(1);
//             ^^
// [diag.constWithUndefinedConstructor] The class 'C' doesn't have a constant constructor 'fn'.
  print(c);
}
''');
  }

  test_constructor_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C.named(this.x);
}

void main() {
  C c = .named(1);
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibrary>::@class::C::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: C
''');
  }

  test_constructor_named_futureOr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class C<T> {
  T value;
  C.id(this.value);
}

void main() async {
  FutureOr<C?>? c = .id(2);
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: id
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::C::@constructor::id
      substitution: {T: dynamic}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@constructor::id::@formalParameter::value
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: C<dynamic>
''');
  }

  test_enum_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named();

  const E.named();
}

void f() {
  E e = .named();
//       ^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  print(e);
}
''');
  }

  test_equality() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C.named(this.x);
}

void main() {
  C lhs = C.named(2);
  bool b = lhs == .named(1);
  print(b);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibrary>::@class::C::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: C
''');
  }

  test_equality_inferTypeParameters() async {
    var result = await resolveTestCodeWithDiagnostics('''
void main() {
  bool x = <int>[] == .filled(2, '2');
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: filled
    element: SubstitutedConstructorElementImpl
      baseElement: dart:core::@class::List::@constructor::filled
      substitution: {E: String}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: dart:core::@class::List::@constructor::filled::@formalParameter::length
          substitution: {E: String}
        staticType: int
      SimpleStringLiteral
        literal: '2'
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: List<String>
''');
  }

  test_equality_pattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  const C.named(this.x);
}

void main() {
  C c = C.named(1);
  if (c case == const .named(2)) print('ok');
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibrary>::@class::C::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        correspondingParameter: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: C
''');
  }

  test_factory() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Foo<T> {
  factory Foo.a() = _Foo;

  Foo();
}

class _Foo<T> extends Foo<T> {
  _Foo();
}

Foo<T> bar<T>() => .a();
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: a
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::Foo::@constructor::a
      substitution: {T: T}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticType: Foo<T>
''');
  }

  test_factory_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Foo<T> {
  const factory Foo.a() = _Foo;

  const Foo();
}

class _Foo<T> extends Foo<T> {
  const _Foo();
}

Foo<T> bar<T>() => const .a();
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: a
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::Foo::@constructor::a
      substitution: {T: Never}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticType: Foo<Never>
''');
  }

  test_factory_const_typeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo<T> {
  const factory Foo.a() = _Foo;

  const Foo();
}

class _Foo<T> extends Foo<T> {
  const _Foo();
}

Foo<int> bar<T>() => const .a<int>();
//                           ^^^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'Foo.a', and type parameters can't be applied to dot shorthand constructor invocations.
''');
  }

  test_factory_typeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo<T> {
  factory Foo.a() = _Foo;

  Foo();
}

class _Foo<T> extends Foo<T> {
  _Foo();
}

Foo<T> bar<T>() => .a<T>();
//                   ^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'Foo.a', and type parameters can't be applied to dot shorthand constructor invocations.
''');
  }

  test_functionExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

void main() {
  final C _ = .new()();
//            ^^^^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');
  }

  test_functionExpression_call() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C call() => this;
}

void main() {
  final C _ = .new()();
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: DotShorthandConstructorInvocation
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_call_argument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C call(int x) => this;
}

void main() {
  C _ = .new()(0);
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: DotShorthandConstructorInvocation
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::C::@method::call::@formalParameter::x
        staticType: int
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function(int)
  staticType: C
''');
  }

  test_functionExpression_call_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension CallC on C {
  C call() => this;
}

void main() {
  final C _ = .new()();
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: DotShorthandConstructorInvocation
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::CallC::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_call_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C call<T>(T t) => this;
}

void main() {
  C _ = .new()<int>(0);
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: DotShorthandConstructorInvocation
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@method::call::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function(int)
  staticType: C
  typeArgumentTypes
    int
''');
  }

  test_functionExpression_call_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C.named();
  C call() => this;
}

void main() {
  final C _ = .named()();
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: DotShorthandConstructorInvocation
    period: .
    constructorName: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::C::@constructor::named
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_call_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C(C c);
  C.a();
  C call() => this;
}

void main() {
  C _ = .new(.a())();
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: DotShorthandConstructorInvocation
    period: .
    constructorName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        DotShorthandConstructorInvocation
          period: .
          constructorName: SimpleIdentifier
            token: a
            element: <testLibrary>::@class::C::@constructor::a
            staticType: null
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          isDotShorthand: true
          correspondingParameter: <testLibrary>::@class::C::@constructor::new::@formalParameter::c
          staticType: C
      rightParenthesis: )
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C(C c);
  C.a();
}

void main() {
  C _ = .new(.a())();
//      ^^^^^^^^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');
  }

  test_nested_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  static C member() => C(1);
  T x;
  C(this.x);
}

void main() {
  C<C> c = .new(.member());
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::C::@constructor::new
      substitution: {T: C<dynamic>}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DotShorthandInvocation
        period: .
        memberName: SimpleIdentifier
          token: member
          element: <testLibrary>::@class::C::@method::member
          staticType: C<dynamic> Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        isDotShorthand: true
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          substitution: {T: C<dynamic>}
        staticInvokeType: C<dynamic> Function()
        staticType: C<dynamic>
    rightParenthesis: )
  isDotShorthand: true
  staticType: C<C<dynamic>>
''');
  }

  test_nested_property() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  static C get member => C(1);
  T x;
  C(this.x);
}

void main() {
  C<C> c = .new(.member);
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::C::@constructor::new
      substitution: {T: C<dynamic>}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DotShorthandPropertyAccess
        period: .
        propertyName: SimpleIdentifier
          token: member
          element: <testLibrary>::@class::C::@getter::member
          staticType: C<dynamic>
        isDotShorthand: true
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
          substitution: {T: C<dynamic>}
        staticType: C<dynamic>
    rightParenthesis: )
  isDotShorthand: true
  staticType: C<C<dynamic>>
''');
  }

  test_new() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C(this.x);
}

void main() {
  C c = .new(1);
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibrary>::@class::C::@constructor::new
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: C
''');
  }

  test_postfixOperator() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

void main() {
  C c = .new()++;
//       ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'new' isn't defined for the context type '_'.
//            ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
  print(c);
}
''');
  }

  test_prefixOperator() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

void main() {
  C c = ++.new();
//         ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'new' isn't defined for the context type '_'.
//             ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  print(c);
}
''');
  }

  test_privateClass_otherLibrary_constConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _Private {
  const _Private.named();
}

typedef Public = _Private;
const Public p = _Private.named();
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = const .named();
//    ^^^^^^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(x);
}
''');
  }

  test_privateClass_otherLibrary_constConstructor_withUnresolvedArg() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _Private {
  const _Private.named(int a);
}

typedef Public = _Private;
const Public p = _Private.named(0);
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = const .named(unknown);
//    ^^^^^^^^^^^^^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
//                 ^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unknown'.
  print(x);
}
''');
  }

  test_privateClass_sameLibrary_constConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class _Private {
  const _Private.named();
}

typedef Public = _Private;
const Public p = _Private.named();

void main() {
  var x = p;
  x = const .named();
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibrary>::@class::_Private::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: _Private
''');
  }

  test_requiredParameters_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C({required this.x});
}

void main() {
  C c = .new();
//       ^^^
// [diag.missingRequiredArgument] The named parameter 'x' is required, but there's no corresponding argument.
  print(c);
}
''');
  }

  test_typeParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C();
}

void main() {
  C c = .new<int>();
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'C.new', and type parameters can't be applied to dot shorthand constructor invocations.
  print(c);
}
''');
  }

  test_typeParameters_const() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
}

void main() {
  C c = const .new<int>();
//                ^^^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'C.new', and type parameters can't be applied to dot shorthand constructor invocations.
  print(c);
}
''');
  }

  test_typeParameters_missingContext() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  var c = const .new<int>();
//        ^^^^^^^^^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(c);
}
''');
  }

  test_undefinedConstructor_message() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() => const .foo();
//                ^^^
// [diag.constWithUndefinedConstructor] The class 'int' doesn't have a constant constructor 'foo'.
''');
  }

  test_undefinedConstructor_message_equalityRhs() async {
    // Make sure the error message properly refers to the `int` class. See
    // https://github.com/dart-lang/sdk/issues/62352.
    await resolveTestCodeWithDiagnostics(r'''
bool f(int x) => x == const .foo();
//                           ^^^
// [diag.constWithUndefinedConstructor] The class 'int' doesn't have a constant constructor 'foo'.
''');
  }

  test_wrongNumberOfTypeArguments_message() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

C f() => .new<int>();
//           ^^^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'C.new', and type parameters can't be applied to dot shorthand constructor invocations.
''');
  }

  test_wrongNumberOfTypeArguments_message_equalityRhs() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

bool f(C c) => c == .new<int>();
//                      ^^^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'C.new', and type parameters can't be applied to dot shorthand constructor invocations.
''');
  }
}
