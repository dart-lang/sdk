// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormalParameterParserTest);
  });
}

/// The class [FormalParameterParserTest] defines parser tests that test
/// the parsing of formal parameters.
@reflectiveTest
class FormalParameterParserTest extends ParserDiagnosticsTest {
  void test_fieldFormalParameter_optionalPositional_type_namedType_int() {
    var parseResult = parseStringWithErrors(r'''
class A {
  int a;
  A([int this.a = 0]);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: FieldFormalParameter
      type: NamedType
        name: int
      thisKeyword: this
      period: .
      name: a
    separator: =
    defaultValue: IntegerLiteral
      literal: 0
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredNamed_noType() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A({required this.a});
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FieldFormalParameter
      requiredKeyword: required
      thisKeyword: this
      period: .
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredNamed_type_namedType_int() {
    var parseResult = parseStringWithErrors(r'''
class A {
  int a;
  A({required int this.a});
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FieldFormalParameter
      requiredKeyword: required
      type: NamedType
        name: int
      thisKeyword: this
      period: .
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_fieldFormalParameter_requiredNamed_type_namedType_int_defaultValue() {
    var parseResult = parseStringWithErrors(r'''
class A {
  int a;
  A({required int this.a = 0});
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FieldFormalParameter
      requiredKeyword: required
      type: NamedType
        name: int
      thisKeyword: this
      period: .
      name: a
    separator: =
    defaultValue: IntegerLiteral
      literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredPositional_const_noType() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(const this.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 23, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  keyword: const
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_const_type() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(const int this.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 23, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  keyword: const
  type: NamedType
    name: int
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_covariant_noType() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(covariant this.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  covariantKeyword: covariant
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_covariant_type() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(covariant int this.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  covariantKeyword: covariant
  type: NamedType
    name: int
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_final_noType() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(final this.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 23, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  keyword: final
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_final_type() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(final int this.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 23, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  keyword: final
  type: NamedType
    name: int
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_functionTyped_nested() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(this.a(int b));
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: b
    rightParenthesis: )
''');
  }

  void
  test_fieldFormalParameter_requiredPositional_functionTyped_noParameters() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(this.a());
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredPositional_functionTyped_nullable() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(void this.a()?);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: void
  thisKeyword: this
  period: .
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  question: ?
''');
  }

  void
  test_fieldFormalParameter_requiredPositional_functionTyped_withDocComment() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var f;
  A(
    /// Doc
    this.f(),
  );
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  documentationComment: Comment
    tokens
      /// Doc
  thisKeyword: this
  period: .
  name: f
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredPositional_noType() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(this.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_type() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(int this.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: int
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_type_functionType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final Object Function(int, double) field;
  C(String Function(num, Object) this.field);
}''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.fieldFormalParameter('this.field');
    assertParsedNodeText(node, r'''
FieldFormalParameter
  type: GenericFunctionType
    returnType: NamedType
      name: String
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: num
      parameter: SimpleFormalParameter
        type: NamedType
          name: Object
      rightParenthesis: )
  thisKeyword: this
  period: .
  name: field
''');
  }

  void test_fieldFormalParameter_requiredPositional_var() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(var this.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 23, 3)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  keyword: var
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_withDocComment() {
    var parseResult = parseStringWithErrors(r'''
class A {
  var a;
  A(
    /// Doc
    this.a,
  );
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  documentationComment: Comment
    tokens
      /// Doc
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_topLevelFunction() {
    var parseResult = parseStringWithErrors(r'''
void f(this.a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: a
''');
  }

  void
  test_formalParameterList_regularFormalParameter_optionalNamed_multiple() {
    var parseResult = parseStringWithErrors(r'''
void f({A a : 1, B b, C c : 3}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: A
      name: a
    separator: :
    defaultValue: IntegerLiteral
      literal: 1
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: B
      name: b
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: C
      name: c
    separator: :
    defaultValue: IntegerLiteral
      literal: 3
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_optionalNamed_trailingComma() {
    var parseResult = parseStringWithErrors(r'''
void f(A a, {B b,}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: A
    name: a
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: B
      name: b
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_optionalPositional_multiple() {
    var parseResult = parseStringWithErrors(r'''
void f([A a = null, B b, C c = null]) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: A
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: B
      name: b
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: C
      name: c
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_optionalPositional_trailingComma() {
    var parseResult = parseStringWithErrors(r'''
void f(A a, [B b,]) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: A
    name: a
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: B
      name: b
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_empty() {
    var parseResult = parseStringWithErrors(r'''
void f() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_multiple() {
    var parseResult = parseStringWithErrors(r'''
void f(A a, B b, C c) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: A
    name: a
  parameter: SimpleFormalParameter
    type: NamedType
      name: B
    name: b
  parameter: SimpleFormalParameter
    type: NamedType
      name: C
    name: c
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_optionalNamed() {
    var parseResult = parseStringWithErrors(r'''
void f(A a, {B b}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: A
    name: a
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: B
      name: b
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_optionalNamed_inFunctionType() {
    var parseResult = parseStringWithErrors(r'''
typedef F = void Function(A, {B b});
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: A
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: B
      name: b
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_optionalPositional() {
    var parseResult = parseStringWithErrors(r'''
void f(A a, [B b]) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: A
    name: a
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: B
      name: b
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_single_trailingComma() {
    var parseResult = parseStringWithErrors(r'''
void f(A a,) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: A
    name: a
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_type_prefixed_partial_withFollowingParameter() {
    var parseResult = parseStringWithErrors(r'''
void f(io.,a) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 1),
      error(diag.missingIdentifier, 10, 1),
    ]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      importPrefix: ImportPrefixReference
        name: io
        period: .
      name: <empty> <synthetic>
    name: <empty> <synthetic>
  parameter: SimpleFormalParameter
    name: a
  rightParenthesis: )
''');
  }

  void test_formalParameterList_separator_missing_optionalNamed() {
    var parseResult = parseStringWithErrors(r'''
void f({int a int b}) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 3)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_formalParameterList_separator_missing_requiredPositional() {
    var parseResult = parseStringWithErrors(r'''
void f(int a int b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 3)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: int
    name: a
  parameter: SimpleFormalParameter
    type: NamedType
      name: int
    name: b
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_metadata_noType() {
    var parseResult = parseStringWithErrors(r'''
void f(@deprecated a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: deprecated
  name: a
''');
  }

  void test_regularFormalParameter_metadata_type() {
    var parseResult = parseStringWithErrors(r'''
void f(@deprecated int a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: deprecated
  type: NamedType
    name: int
  name: a
''');
  }

  void test_regularFormalParameter_optionalNamed_covariant_final() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f({covariant final a : null}) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 30, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      keyword: final
      name: a
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_covariant_final_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f({covariant final A a : null}) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 30, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      keyword: final
      type: NamedType
        name: A
      name: a
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_covariant_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f({covariant A a : null}) {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      type: NamedType
        name: A
      name: a
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_covariant_var() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f({covariant var a : null}) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 30, 3)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      keyword: var
      name: a
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_final() {
    var parseResult = parseStringWithErrors(r'''
void f({final a : null}) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      keyword: final
      name: a
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_final_type() {
    var parseResult = parseStringWithErrors(r'''
void f({final A a = null}) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      keyword: final
      type: NamedType
        name: A
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_functionTyped() {
    var parseResult = parseStringWithErrors(r'''
void f({a() = null}) {}
''');
    parseResult.assertNoErrors();

    var f = parseResult.findNode.singleFunctionDeclaration;
    var node = f.functionExpression.parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FunctionTypedFormalParameter
      name: a
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_functionTyped_nullable() {
    var parseResult = parseStringWithErrors(r'''
void f({a()? : null}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult
        .findNode
        .singleFunctionDeclaration
        .functionExpression
        .parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FunctionTypedFormalParameter
      name: a
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_optionalNamed_functionTyped_nullable_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
void f({a<T>()? : null}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult
        .findNode
        .singleFunctionDeclaration
        .functionExpression
        .parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FunctionTypedFormalParameter
      name: a
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_type() {
    var parseResult = parseStringWithErrors(r'''
void f({A a : null}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: A
      name: a
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_type_noDefault() {
    var parseResult = parseStringWithErrors(r'''
void f({A a}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: A
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_var() {
    var parseResult = parseStringWithErrors(r'''
void f({var a : null}) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 3)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      keyword: var
      name: a
    separator: :
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_covariant_final() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f([covariant final a = null]) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 30, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      keyword: final
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_covariant_final_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f([covariant final A a = null]) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 30, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      keyword: final
      type: NamedType
        name: A
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_covariant_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f([covariant A a = null]) {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      type: NamedType
        name: A
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_covariant_var() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f([covariant var a = null]) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 30, 3)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      keyword: var
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_final() {
    var parseResult = parseStringWithErrors(r'''
void f([final a = null]) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      keyword: final
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_final_type() {
    var parseResult = parseStringWithErrors(r'''
void f([final A a = null]) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      keyword: final
      type: NamedType
        name: A
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_type() {
    var parseResult = parseStringWithErrors(r'''
void f([A a = null]) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: A
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_type_noDefault() {
    var parseResult = parseStringWithErrors(r'''
void f([A a]) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: A
      name: a
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_var() {
    var parseResult = parseStringWithErrors(r'''
void f([var a = null]) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 3)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      keyword: var
      name: a
    separator: =
    defaultValue: NullLiteral
      literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_covariant_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f({required covariant A a}) {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      requiredKeyword: required
      type: NamedType
        name: A
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_covariant_type_ordering() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f({covariant required A a}) {}
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 30, 8)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      covariantKeyword: covariant
      requiredKeyword: required
      type: NamedType
        name: A
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_final() {
    var parseResult = parseStringWithErrors(r'''
void f({required final a}) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      requiredKeyword: required
      keyword: final
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_final_ordering() {
    var parseResult = parseStringWithErrors(r'''
void f({final required a}) {}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 8, 5),
      error(diag.modifierOutOfOrder, 14, 8),
    ]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      requiredKeyword: required
      keyword: final
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_type() {
    var parseResult = parseStringWithErrors(r'''
void f({required A a}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      requiredKeyword: required
      type: NamedType
        name: A
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredNamed_type_namedType_int_defaultValue() {
    var parseResult = parseStringWithErrors(r'''
void f({required int a = 0}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      requiredKeyword: required
      type: NamedType
        name: int
      name: a
    separator: =
    defaultValue: IntegerLiteral
      literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredNamed_type_namedType_int_noDefault() {
    var parseResult = parseStringWithErrors(r'''
void f({required int a}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      requiredKeyword: required
      type: NamedType
        name: int
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_var() {
    var parseResult = parseStringWithErrors(r'''
void f({required var a}) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 3)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      requiredKeyword: required
      keyword: var
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_var_ordering() {
    var parseResult = parseStringWithErrors(r'''
void f({var required a}) {}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 8, 3),
      error(diag.modifierOutOfOrder, 12, 8),
    ]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      requiredKeyword: required
      keyword: var
      name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredPositional_const_noType() {
    var parseResult = parseStringWithErrors(r'''
void f(const a) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 7, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  keyword: const
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_const_type() {
    var parseResult = parseStringWithErrors(r'''
void f(const A a) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 7, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  keyword: const
  type: NamedType
    name: A
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_covariant_final() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f(covariant final a) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 29, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  covariantKeyword: covariant
  keyword: final
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_covariant_final_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f(covariant final A a) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 29, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  covariantKeyword: covariant
  keyword: final
  type: NamedType
    name: A
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_covariant_type() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f(covariant A<B<C>> a) {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  covariantKeyword: covariant
  type: NamedType
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: B
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: C
            rightBracket: >
      rightBracket: >
  name: a
''');
  }

  void
  test_regularFormalParameter_requiredPositional_covariant_type_functionType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f(covariant String Function(int) a) {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleMethodDeclaration.parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    covariantKeyword: covariant
    type: GenericFunctionType
      returnType: NamedType
        name: String
      functionKeyword: Function
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
        rightParenthesis: )
    name: a
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredPositional_covariant_var() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void f(covariant var a) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 29, 3)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  covariantKeyword: covariant
  keyword: var
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_external() {
    var parseResult = parseStringWithErrors(r'''
void f(external int i) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 7, 8)]);
  }

  void test_regularFormalParameter_requiredPositional_final_noType() {
    var parseResult = parseStringWithErrors(r'''
void f(final a) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 7, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  keyword: final
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_final_type() {
    var parseResult = parseStringWithErrors(r'''
void f(final A a) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 7, 5)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  keyword: final
  type: NamedType
    name: A
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_functionTyped_noType() {
    var parseResult = parseStringWithErrors(r'''
void f(a()) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_noType_covariant() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f(covariant a()) {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult
        .findNode
        .singleMethodDeclaration
        .parameters!
        .parameters
        .single;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  covariantKeyword: covariant
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_noType_nullable() {
    var parseResult = parseStringWithErrors(r'''
void f(a()?) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  question: ?
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_noType_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
void f(a<E>()) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  name: a
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: E
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_parameter_covariant() {
    var parseResult = parseStringWithErrors(r'''
void f(void g(covariant int a)) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.simpleFormalParameter('a)');
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  covariantKeyword: covariant
  type: NamedType
    name: int
  name: a
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_parameter_required_covariant() {
    var parseResult = parseStringWithErrors(r'''
void f(void g({required covariant int a})) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.simpleFormalParameter('a}');
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  covariantKeyword: covariant
  requiredKeyword: required
  type: NamedType
    name: int
  name: a
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType() {
    var parseResult = parseStringWithErrors(r'''
void f(A a()) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  returnType: NamedType
    name: A
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
void f(A a<E>()) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  returnType: NamedType
    name: A
  name: a
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: E
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType_void() {
    var parseResult = parseStringWithErrors(r'''
void f(void a()) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  returnType: NamedType
    name: void
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType_void_covariant() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f(covariant void a()) {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  covariantKeyword: covariant
  returnType: NamedType
    name: void
  name: a
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType_void_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
void f(void a<E>()) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FunctionTypedFormalParameter
  returnType: NamedType
    name: void
  name: a
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: E
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  void
  test_regularFormalParameter_requiredPositional_functionTyped_withDocComment() {
    var parseResult = parseStringWithErrors(r'''
void f(
  /// Doc
  g(),
) {}
''');
    parseResult.assertNoErrors();
    // TODO(scheglov): assert AST
    fail('Incomplete');
  }

  void test_regularFormalParameter_requiredPositional_noType() {
    var parseResult = parseStringWithErrors(r'''
void f(a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_noType_inFunctionTyped() {
    var parseResult = parseStringWithErrors(r'''
void f(void g(a)) {}
''');
    parseResult.assertNoErrors();

    var f = parseResult.findNode.functionDeclaration('f');
    var g =
        f.functionExpression.parameters!.parameters.single
            as FunctionTypedFormalParameter;
    var node = g.parameters.parameters.single;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_noType_nameCovariant() {
    var parseResult = parseStringWithErrors(r'''
void f(covariant) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  name: covariant
''');
  }

  void test_regularFormalParameter_requiredPositional_noType_nameRequired() {
    var parseResult = parseStringWithErrors(r'''
void f(required) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  name: required
''');
  }

  void test_regularFormalParameter_requiredPositional_noType_nameUnderscore() {
    var parseResult = parseStringWithErrors(r'''
void f(_) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  name: _
''');
  }

  void
  test_regularFormalParameter_requiredPositional_single_type_namedType_Function() {
    var parseResult = parseStringWithErrors(r'''
void f(Function f) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      name: Function
    name: f
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredPositional_single_type_prefixed() {
    var parseResult = parseStringWithErrors(r'''
void f(io.File f) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      importPrefix: ImportPrefixReference
        name: io
        period: .
      name: File
    name: f
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_single_type_prefixed_missingName() {
    var parseResult = parseStringWithErrors(r'''
void f(io.File) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 14, 1)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      importPrefix: ImportPrefixReference
        name: io
        period: .
      name: File
    name: <empty> <synthetic>
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_single_type_prefixed_partial() {
    var parseResult = parseStringWithErrors(r'''
void f(io.) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 1),
      error(diag.missingIdentifier, 10, 1),
    ]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: NamedType
      importPrefix: ImportPrefixReference
        name: io
        period: .
      name: <empty> <synthetic>
    name: <empty> <synthetic>
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredPositional_type() {
    var parseResult = parseStringWithErrors(r'''
void f(A a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  type: NamedType
    name: A
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_type_functionType() {
    var parseResult = parseStringWithErrors(r'''
void f(String Function(int) a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult
        .findNode
        .singleFunctionDeclaration
        .functionExpression
        .parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    type: GenericFunctionType
      returnType: NamedType
        name: String
      functionKeyword: Function
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
        rightParenthesis: )
    name: a
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_type_namedType_int_nameUnderscore() {
    var parseResult = parseStringWithErrors(r'''
void f(int _) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  type: NamedType
    name: int
  name: _
''');
  }

  void test_regularFormalParameter_requiredPositional_var() {
    var parseResult = parseStringWithErrors(r'''
void f(var a) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 7, 3)]);

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  keyword: var
  name: a
''');
  }

  void
  test_superFormalParameter_optionalPositional_type_namedType_int_defaultValue() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int a;
  A([this.a = 0]);
}
class B extends A {
  B([int super.a = 0]);
}
''');
    parseResult.assertNoErrors();

    var node =
        parseResult.findNode.superFormalParameter('super.a').parent
            as DefaultFormalParameter;
    assertParsedNodeText(node, r'''
DefaultFormalParameter
  parameter: SuperFormalParameter
    type: NamedType
      name: int
    superKeyword: super
    period: .
    name: a
  separator: =
  defaultValue: IntegerLiteral
    literal: 0
''');
  }

  void test_superFormalParameter_requiredNamed_type_namedType_int() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int a;
  A({required this.a});
}
class B extends A {
  B({required int super.a});
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  requiredKeyword: required
  type: NamedType
    name: int
  superKeyword: super
  period: .
  name: a
''');
  }

  void
  test_superFormalParameter_requiredNamed_type_namedType_int_defaultValue() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int a;
  A({required this.a});
}
class B extends A {
  B({required int super.a = 0});
}
''');
    parseResult.assertNoErrors();

    var node =
        parseResult.findNode.superFormalParameter('super.a').parent
            as DefaultFormalParameter;
    assertParsedNodeText(node, r'''
DefaultFormalParameter
  parameter: SuperFormalParameter
    requiredKeyword: required
    type: NamedType
      name: int
    superKeyword: super
    period: .
    name: a
  separator: =
  defaultValue: IntegerLiteral
    literal: 0
''');
  }

  void test_superFormalParameter_requiredPositional_const_noType() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(const super.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 64, 5)]);

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  keyword: const
  superKeyword: super
  period: .
  name: a
''');
  }

  void test_superFormalParameter_requiredPositional_covariant_noType() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(covariant super.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  covariantKeyword: covariant
  superKeyword: super
  period: .
  name: a
''');
  }

  void test_superFormalParameter_requiredPositional_covariant_type() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(covariant int super.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  covariantKeyword: covariant
  type: NamedType
    name: int
  superKeyword: super
  period: .
  name: a
''');
  }

  void
  test_superFormalParameter_requiredPositional_functionTyped_nullable_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final dynamic f;
  A(this.f);
}
class B extends A {
  B(super.f<T>()?);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.f');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  question: ?
''');
  }

  void
  test_superFormalParameter_requiredPositional_functionTyped_returnType_void() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final void Function() f;
  A(this.f);
}
class B extends A {
  B(void super.f());
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.f');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  type: NamedType
    name: void
  superKeyword: super
  period: .
  name: f
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_superFormalParameter_requiredPositional_noType() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(super.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
''');
  }

  void test_superFormalParameter_requiredPositional_type_namedType_int() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(int super.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  type: NamedType
    name: int
  superKeyword: super
  period: .
  name: a
''');
  }

  void test_superFormalParameter_topLevelFunction() {
    var parseResult = parseStringWithErrors(r'''
void f(super.a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
''');
  }
}
