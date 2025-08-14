// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterResolutionTest);
  });
}

@reflectiveTest
class SuperFormalParameterResolutionTest extends PubPackageResolutionTest {
  test_element_typeParameterSubstitution_chained() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A({int? key});
}

class B<U> extends A<U> {
  B({super.key});
}

class C<V> extends B<V> {
  C({super.key});
}
''');

    var C = findElement2.unnamedConstructor('C');
    var C_key = C.superFormalParameter('key');

    var B_key_member = C_key.superConstructorParameter;
    B_key_member as SubstitutedSuperFormalParameterElementImpl;

    var B = findElement2.unnamedConstructor('B');
    var B_key = B.superFormalParameter('key');
    assertElement(B_key_member, declaration: B_key, substitution: {'U': 'V'});

    var A_key_member = B_key_member.superConstructorParameter;
    A_key_member as SubstitutedFormalParameterElementImpl;

    var A = findElement2.unnamedConstructor('A');
    var A_key = A.parameter('key');
    assertElement(A_key_member, declaration: A_key, substitution: {'T': 'V'});
  }

  test_functionTyped() async {
    await assertNoErrorsInCode(r'''
class A {
  A(Object a);
}

class B extends A {
  B(T super.a<T>(int b));
}
''');

    var node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  type: NamedType
    name: T
    element2: #E0 T
    type: T
  superKeyword: super
  period: .
  name: a
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: <testLibraryFragment> T@62
          defaultType: null
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: b
      declaredElement: <testLibraryFragment> b@69
        element: isPublic
          type: int
    rightParenthesis: )
  declaredElement: <testLibraryFragment> a@60
    element: isFinal isPublic
      type: T Function<T>(int)
''');
  }

  test_invalid_notConstructor() async {
    await assertErrorsInCode(
      r'''
void f(super.a) {}
''',
      [error(CompileTimeErrorCode.invalidSuperFormalParameterLocation, 7, 5)],
    );

    var node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
  declaredElement: <testLibraryFragment> a@13
    element: hasImplicitType isFinal isPublic
      type: dynamic
''');
  }

  test_optionalNamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}

class B extends A {
  B({super.a});
}
''');

    var node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
  declaredElement: <testLibraryFragment> a@59
    element: hasImplicitType isFinal isPublic
      type: int?
''');
  }

  test_optionalPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}

class B extends A {
  B([super.a]);
}
''');

    var node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
  declaredElement: <testLibraryFragment> a@59
    element: hasImplicitType isFinal isPublic
      type: int?
''');
  }

  test_requiredNamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a});
}
''');

    var node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  requiredKeyword: required
  superKeyword: super
  period: .
  name: a
  declaredElement: <testLibraryFragment> a@76
    element: hasImplicitType isFinal isPublic
      type: int
''');
  }

  test_requiredPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a);
}
''');

    var node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
  declaredElement: <testLibraryFragment> a@55
    element: hasImplicitType isFinal isPublic
      type: int
''');
  }

  test_scoping_inBody() async {
    await assertNoErrorsInCode(r'''
class A {
  final int a;
  A(this.a);
}

class B extends A {
  B(super.a) {
    a; // ref
  }
}
''');

    var node = findNode.simple('a; // ref');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@class::A::@getter::a
  staticType: int
''');
  }

  test_scoping_inInitializer() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  var f;
  B(super.a) : f = ((){ a; });
}
''');

    var node = findNode.simple('a; }');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
  staticType: int
''');
  }
}
