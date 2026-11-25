// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterReferencedByStaticTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeParameterReferencedByStaticTest extends PubPackageResolutionTest {
  test_class_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T? foo;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_class_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T? get foo => null;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_class_method_bodyReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static foo() {
    // ignore:unused_local_variable
    T v;
//  ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
  }
}
''');
  }

  test_class_method_closure() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static Object foo() {
    return (T a) {};
//          ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
  }
}
''');
  }

  test_class_method_constructorInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static foo() {
    new T();
//      ^
// [diag.newWithNonType] The name 'T' isn't a class.
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
  }
}
''');
  }

  test_class_method_constructorTearOff() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A.named();

  static void foo() {
    A<T>.named;
//    ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
  }
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: T
          element: #E0 T
          type: InvalidType
      rightBracket: >
    element: <testLibrary>::@class::A
    type: A<InvalidType>
  selector: ConstructorSelector
    period: .
    name2: named
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: InvalidType}
  staticType: A<InvalidType> Function()
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
            element: #E0 T
            type: InvalidType
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: InvalidType}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: InvalidType}
  staticType: A<InvalidType> Function()
''');
  }

  test_class_method_constructorTearOff_recordTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

class A<T> {
  static void foo() {
    R<T>.foo;
//    ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
  }
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: T
          element: #E0 T
          type: InvalidType
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (InvalidType,)
      alias: <testLibrary>::@typeAlias::R
        typeArguments
          InvalidType
  selector: ConstructorSelector
    period: .
    name2: foo
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
            element: #E0 T
            type: InvalidType
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_class_method_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static foo(T a) {}
//           ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_class_method_return() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T foo() {
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
    throw 0;
  }
}
''');
  }

  test_class_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static set foo(T _) {}
//               ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_enum_constant_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E<T> {
  v<T>();
//  ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_expression_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static foo() {
    T;
//  ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
  }
}
''');
  }

  test_extension_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E<T> on int {
  static T? foo;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_extension_method_return() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E<T> on int {
  static T foo() => throw 0;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_mixin_field() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<T> {
  static T? foo;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }
}
