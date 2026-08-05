// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclarationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionDeclarationResolutionTest extends PubPackageResolutionTest {
  test_blockBody_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}
''');

    var node = result.findNode.singleExtensionDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> E@10
''');
  }

  test_blockBody_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int f = 0;
}
''');

    var node = result.findNode.singleExtensionDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        fields: VariableDeclarationList
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          variables
            VariableDeclaration
              name: f
              equals: =
              initializer: IntegerLiteral
                literal: 0
                staticType: int
              declaredFragment: <testLibraryFragment> f@34
        semicolon: ;
        declaredFragment: <null>
    rightBracket: }
  declaredFragment: <testLibraryFragment> E@10
''');
  }

  test_blockBody_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get g => 0;
}
''');

    var node = result.findNode.singleExtensionDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        propertyKeyword: get
        name: g
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
            staticType: int
          semicolon: ;
        declaredFragment: <testLibraryFragment> g@31
          element: <testLibrary>::@extension::E::@getter::g
            type: int Function()
    rightBracket: }
  declaredFragment: <testLibraryFragment> E@10
''');
  }

  test_blockBody_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void m() {}
}
''');

    var node = result.findNode.singleExtensionDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: void
          element: <null>
          type: void
        name: m
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
        declaredFragment: <testLibraryFragment> m@28
          element: <testLibrary>::@extension::E::@method::m
            type: void Function()
    rightBracket: }
  declaredFragment: <testLibraryFragment> E@10
''');
  }

  test_blockBody_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set s(int v) {}
}
''');

    var node = result.findNode.singleExtensionDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        propertyKeyword: set
        name: s
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
              element: dart:core::@class::int
              type: int
            name: v
            declaredFragment: <testLibraryFragment> v@33
              element: isPublic
                type: int
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
        declaredFragment: <testLibraryFragment> s@27
          element: <testLibrary>::@extension::E::@setter::s
            type: void Function(int)
    rightBracket: }
  declaredFragment: <testLibraryFragment> E@10
''');
  }

  test_emptyBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int;
''');

    var node = result.findNode.singleExtensionDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
  body: EmptyClassBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> E@10
''');
  }

  test_emptyBody_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension E on int;
//                ^
// [diag.experimentNotEnabled] This requires the 'primary-constructors' language feature to be enabled.
''');

    var node = result.findNode.singleExtensionDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
  body: EmptyClassBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> E@26
''');
  }
}
