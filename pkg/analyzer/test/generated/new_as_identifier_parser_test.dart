// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewAsIdentifierParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Tests exercising the fasta parser's handling of generic instantiations.
@reflectiveTest
class NewAsIdentifierParserTest extends ParserDiagnosticsTest {
  void test_constructor_field_initializer() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  C() : this.new = null;
//      ^^^^
// [diag.missingAssignmentInInitializer] Expected an assignment after the field name.
//           ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingFunctionBody] A function body must be provided.
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
//               ^
// [diag.redirectionInNonFactoryConstructor] Only factory constructor can specify '=' redirection.
//                 ^^^^
// [diag.expectedIdentifierButGotKeyword] 'null' can't be used as an identifier because it's a keyword.
}
''');

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
    leftBracket: {
    members
      ConstructorDeclaration
        typeName: SimpleIdentifier
          token: C
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        separator: :
        initializers
          ConstructorFieldInitializer
            fieldName: SimpleIdentifier
              token: <empty> <synthetic>
            equals: = <synthetic>
            expression: PropertyAccess
              target: ThisExpression
                thisKeyword: this
              operator: .
              propertyName: SimpleIdentifier
                token: <empty> <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
      ConstructorDeclaration
        newKeyword: new
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        separator: =
        redirectedConstructor: ConstructorName
          type: NamedType
            name: null
        body: EmptyFunctionBody
          semicolon: ;
    rightBracket: }
''');
  }

  void test_constructor_invocation_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = const C.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: const
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: C
        period: .
      name: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_const_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = const C<int>.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: const
  constructorName: ConstructorName
    type: NamedType
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_const_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = const prefix.C.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: const
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
      name: C
    period: .
    name: SimpleIdentifier
      token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_const_prefixed_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = const prefix.C<int>.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: const
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_explicit() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = new C.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: C
        period: .
      name: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_explicit_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = new C<int>.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_explicit_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = new prefix.C.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
      name: C
    period: .
    name: SimpleIdentifier
      token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_explicit_prefixed_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = new prefix.C<int>.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_implicit() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = C.new();
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
  operator: .
  methodName: SimpleIdentifier
    token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_implicit_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = C<int>.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_implicit_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = prefix.C.new();
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
    period: .
    identifier: SimpleIdentifier
      token: C
  operator: .
  methodName: SimpleIdentifier
    token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_invocation_implicit_prefixed_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = prefix.C<int>.new();
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_name() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  C.new();
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  period: .
  name: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_constructor_name_factory() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  factory C.new() => C._();
  C._();
}
''');
    var node = parseResult.findNode.constructor('C.new');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  period: .
  name: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: MethodInvocation
      target: SimpleIdentifier
        token: C
      operator: .
      methodName: SimpleIdentifier
        token: _
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
    semicolon: ;
''');
  }

  void test_constructor_tearoff() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = C.new;
''');
    var node = parseResult.findNode.singlePrefixedIdentifier;
    assertParsedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
  period: .
  identifier: SimpleIdentifier
    token: new
''');
  }

  void test_constructor_tearoff_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = C<int>.new;
''');
    var node = parseResult.findNode.singlePropertyAccess;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: FunctionReference
    function: SimpleIdentifier
      token: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  operator: .
  propertyName: SimpleIdentifier
    token: new
''');
  }

  void test_constructor_tearoff_generic_method_invocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = C<int>.new.toString();
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: PropertyAccess
    target: FunctionReference
      function: SimpleIdentifier
        token: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    operator: .
    propertyName: SimpleIdentifier
      token: new
  operator: .
  methodName: SimpleIdentifier
    token: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_tearoff_in_comment_reference() {
    var parseResult = parseTestCodeWithDiagnostics('''
/// [C.new]
class C {}
''');
    var node = parseResult.findNode.commentReference('C.new');
    assertParsedNodeText(node, r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
    period: .
    identifier: SimpleIdentifier
      token: new
''');
  }

  void test_constructor_tearoff_method_invocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = C.new.toString();
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
    period: .
    identifier: SimpleIdentifier
      token: new
  operator: .
  methodName: SimpleIdentifier
    token: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_tearoff_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = prefix.C.new;
''');
    var node = parseResult.findNode.singlePropertyAccess;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
    period: .
    identifier: SimpleIdentifier
      token: C
  operator: .
  propertyName: SimpleIdentifier
    token: new
''');
  }

  void test_constructor_tearoff_prefixed_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = prefix.C<int>.new;
''');
    var node = parseResult.findNode.singlePropertyAccess;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: FunctionReference
    function: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
      period: .
      identifier: SimpleIdentifier
        token: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  operator: .
  propertyName: SimpleIdentifier
    token: new
''');
  }

  void test_constructor_tearoff_prefixed_generic_method_invocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = prefix.C<int>.new.toString();
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: PropertyAccess
    target: FunctionReference
      function: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: prefix
        period: .
        identifier: SimpleIdentifier
          token: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    operator: .
    propertyName: SimpleIdentifier
      token: new
  operator: .
  methodName: SimpleIdentifier
    token: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_constructor_tearoff_prefixed_method_invocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = prefix.C.new.toString();
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
      period: .
      identifier: SimpleIdentifier
        token: C
    operator: .
    propertyName: SimpleIdentifier
      token: new
  operator: .
  methodName: SimpleIdentifier
    token: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_disabled() {
    var parseResult = parseTestCodeWithDiagnostics(
      '''
class C {
  C.new();
//  ^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
}
''',
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version.parse('2.13.0'),
        flags: [],
      ),
    );
    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  period: .
  name: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_factory_redirection() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  factory C() = D.new;
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: D
        period: .
      name: new
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_factory_redirection_generic() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  factory C() = D<int>.new;
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: D
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: new
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_factory_redirection_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  factory C() = prefix.D.new;
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
      name: D
    period: .
    name: SimpleIdentifier
      token: new
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_factory_redirection_prefixed_generic() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  factory C() = prefix.D<int>.new;
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
      name: D
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: new
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_super_invocation() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C extends B {
  C() : super.new();
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    SuperConstructorInvocation
      superKeyword: super
      period: .
      constructorName: SimpleIdentifier
        token: new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_this_redirection() {
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  C.named() : this.new();
  C();
}
''');
    var node = parseResult.findNode.constructor('named');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    RedirectingConstructorInvocation
      thisKeyword: this
      period: .
      constructorName: SimpleIdentifier
        token: new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }
}
