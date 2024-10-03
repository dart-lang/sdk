// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportPrefixResolutionTest);
  });
}

@reflectiveTest
class ImportPrefixResolutionTest extends PubPackageResolutionTest {
  test_asExpression_expressionStatement() async {
    await assertErrorsInCode(r'''
import 'dart:async' as p;

main() {
  p; // use
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 38, 1),
    ]);

    var node = findNode.simple('p; // use');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: p
  staticElement: <testLibraryFragment>::@prefix::p
  element: <testLibraryFragment>::@prefix2::p
  staticType: InvalidType
''');
  }

  test_asExpression_forIn_iterable() async {
    await assertErrorsInCode(r'''
import 'dart:async' as p;

main() {
  for (var x in p) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 52, 1),
    ]);

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: x
      declaredElement: hasImplicitType x@47
        type: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: p
      staticElement: <testLibraryFragment>::@prefix::p
      element: <testLibraryFragment>::@prefix2::p
      staticType: InvalidType
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_asExpression_instanceCreation_argument() async {
    await assertErrorsInCode(r'''
import 'dart:async' as p;

class C<T> {
  C(a);
}

main() {
  var x = new C(p);
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 66, 1),
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 76, 1),
    ]);

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: C
      element: <testLibraryFragment>::@class::C
      element2: <testLibraryFragment>::@class::C#element
      type: C<dynamic>
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::C::@constructor::new
      substitution: {T: dynamic}
    element: <testLibraryFragment>::@class::C::@constructor::new#element
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: p
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::C::@constructor::new::@parameter::a
          substitution: {T: dynamic}
        staticElement: <testLibraryFragment>::@prefix::p
        element: <testLibraryFragment>::@prefix2::p
        staticType: InvalidType
    rightParenthesis: )
  staticType: C<dynamic>
''');
  }

  test_asPrefix_methodInvocation() async {
    await assertNoErrorsInCode(r'''
import 'dart:math' as p;

main() {
  p.max(0, 0);
}
''');

    var pRef = findNode.simple('p.max');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeNull(pRef);
  }

  test_asPrefix_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
import 'dart:async' as p;

main() {
  p.Future;
}
''');

    var pRef = findNode.simple('p.Future');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeNull(pRef);
  }

  test_wildcardResolution() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension ExtendedString on String {
  bool get stringExt => true;
}

var a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
extension ExtendedString2 on String {
  bool get stringExt2 => true;
}
''');

    // Import prefixes named `_` provide access to non-private extensions
    // in the imported library but are non-binding.
    await assertErrorsInCode(r'''
import 'a.dart' as _;
import 'b.dart' as _;

f() {
  ''.stringExt;
  ''.stringExt2;
  _.a;
}
''', [
      // String extensions are found but `_` is not bound.
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 86, 1),
    ]);
  }

  test_wildcardResolution_preWildcards() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension ExtendedString on String {
  bool get stringExt => true;
}

var a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
extension ExtendedString on String {
  bool get stringExt2 => true;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

import 'a.dart' as _;
import 'b.dart' as _;

f() {
  ''.stringExt;
  ''.stringExt2;
  _.a;
}
''');

    // `_` is bound so `a` resolves to the int declared in `a.dart`.
    var node = findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  staticElement: package:test/a.dart::<fragment>::@getter::a
  element: package:test/a.dart::<fragment>::@getter::a#element
  staticType: int
''');
  }
}
