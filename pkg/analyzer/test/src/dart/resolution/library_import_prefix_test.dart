// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportPrefixResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ImportPrefixResolutionTest extends PubPackageResolutionTest {
  test_asExpression_expressionStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as p;

main() {
  p; // use
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.simple('p; // use');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: p
  element: <testLibraryFragment>::@prefix::p
  staticType: InvalidType
''');
  }

  test_asExpression_forIn_iterable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as p;

main() {
  for (var x in p) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//              ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: x
      declaredFragment: isPublic x@47
        element: hasImplicitType isPublic
          type: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: InvalidType
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_asExpression_instanceCreation_argument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as p;

class C<T> {
  C(a);
}

main() {
  var x = new C(p);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//              ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: C
      element: <testLibrary>::@class::C
      type: C<dynamic>
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::C::@constructor::new
      substitution: {T: dynamic}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: p
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@constructor::new::@formalParameter::a
          substitution: {T: dynamic}
        element: <testLibraryFragment>::@prefix::p
        staticType: InvalidType
    rightParenthesis: )
  staticType: C<dynamic>
''');
  }

  test_asPrefix_methodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

main() {
  p.max(0, 0);
}
''');

    var node = result.findNode.simple('p.max');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: p
  element: <testLibraryFragment>::@prefix::p
  staticType: null
''');
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
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as _;
import 'b.dart' as _;

f() {
  ''.stringExt;
  ''.stringExt2;
  _.a;
//^
// [diag.undefinedIdentifier] Undefined name '_'.
}
''');
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

    var result = await resolveTestCodeWithDiagnostics(r'''
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
    var node = result.findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: package:test/a.dart::@getter::a
  staticType: int
''');
  }
}
