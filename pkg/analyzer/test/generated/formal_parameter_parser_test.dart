// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormalParameterParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// The class [FormalParameterParserTest] defines parser tests that test
/// the parsing of formal parameters.
@reflectiveTest
class FormalParameterParserTest extends ParserDiagnosticsTest {
  void test_fieldFormalParameter_optionalPositional_type_namedType_int() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  int a;
  A([int this.a = 0]);
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: FieldFormalParameter
    type: NamedType
      name: int
    thisKeyword: this
    period: .
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: IntegerLiteral
        literal: 0
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredNamed_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A({required this.a});
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  int a;
  A({required int this.a});
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  int a;
  A({required int this.a = 0});
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: FieldFormalParameter
    requiredKeyword: required
    type: NamedType
      name: int
    thisKeyword: this
    period: .
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: IntegerLiteral
        literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredPositional_const_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(const this.a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  constFinalOrVarKeyword: const
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_const_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(const int this.a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  constFinalOrVarKeyword: const
  type: NamedType
    name: int
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_covariant_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(covariant this.a);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(covariant int this.a);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(final this.a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  constFinalOrVarKeyword: final
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_final_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(final int this.a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  constFinalOrVarKeyword: final
  type: NamedType
    name: int
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_functionTyped_nested() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(this.a(int b));
}
''');

    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: b
      rightParenthesis: )
''');
  }

  void
  test_fieldFormalParameter_requiredPositional_functionTyped_noParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(this.a());
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredPositional_functionTyped_nullable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(void this.a()?);
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: void
  thisKeyword: this
  period: .
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    question: ?
''');
  }

  void
  test_fieldFormalParameter_requiredPositional_functionTyped_withDocComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var f;
  A(
    /// Doc
    this.f(),
  );
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  documentationComment: Comment
    tokens
      /// Doc
  thisKeyword: this
  period: .
  name: f
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void test_fieldFormalParameter_requiredPositional_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(this.a);
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(int this.a);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  final Object Function(int, double) field;
  C(String Function(num, Object) this.field);
}''');

    var node = parseResult.findNode.fieldFormalParameter('this.field');
    assertParsedNodeText(node, r'''
FieldFormalParameter
  type: GenericFunctionType
    returnType: NamedType
      name: String
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: num
      parameter: RegularFormalParameter
        type: NamedType
          name: Object
      rightParenthesis: )
  thisKeyword: this
  period: .
  name: field
''');
  }

  void test_fieldFormalParameter_requiredPositional_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(var this.a);
//  ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
FieldFormalParameter
  constFinalOrVarKeyword: var
  thisKeyword: this
  period: .
  name: a
''');
  }

  void test_fieldFormalParameter_requiredPositional_withDocComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  var a;
  A(
    /// Doc
    this.a,
  );
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(this.a) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({A a : 1, B b, C c : 3}) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: IntegerLiteral
        literal: 1
  parameter: RegularFormalParameter
    type: NamedType
      name: B
    name: b
  parameter: RegularFormalParameter
    type: NamedType
      name: C
    name: c
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: IntegerLiteral
        literal: 3
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_optionalNamed_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a, {B b,}) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: B
    name: b
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_optionalPositional_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f([A a = null, B b, C c = null]) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  parameter: RegularFormalParameter
    type: NamedType
      name: B
    name: b
  parameter: RegularFormalParameter
    type: NamedType
      name: C
    name: c
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_optionalPositional_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a, [B b,]) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
  leftDelimiter: [
  parameter: RegularFormalParameter
    type: NamedType
      name: B
    name: b
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a, B b, C c) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
  parameter: RegularFormalParameter
    type: NamedType
      name: B
    name: b
  parameter: RegularFormalParameter
    type: NamedType
      name: C
    name: c
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_optionalNamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a, {B b}) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: B
    name: b
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_optionalNamed_inFunctionType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = void Function(A, {B b});
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: A
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: B
    name: b
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_optionalPositional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a, [B b]) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
  leftDelimiter: [
  parameter: RegularFormalParameter
    type: NamedType
      name: B
    name: b
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_single_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a,) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
  rightParenthesis: )
''');
  }

  void
  test_formalParameterList_regularFormalParameter_requiredPositional_type_prefixed_partial_withFollowingParameter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(io.,a) {}
//        ^
// [diag.expectedTypeName] Expected a type name.
// [diag.missingIdentifier] Expected an identifier.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      importPrefix: ImportPrefixReference
        name: io
        period: .
      name: <empty> <synthetic>
    name: <empty> <synthetic>
  parameter: RegularFormalParameter
    name: a
  rightParenthesis: )
''');
  }

  void test_formalParameterList_separator_missing_optionalNamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({int a int b}) {}
//            ^^^
// [diag.expectedToken] Expected to find '}'.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_formalParameterList_separator_missing_requiredPositional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int a int b) {}
//           ^^^
// [diag.expectedToken] Expected to find ','.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: a
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: b
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_metadata_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(@deprecated a) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: deprecated
  name: a
''');
  }

  void test_regularFormalParameter_metadata_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(@deprecated int a) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f({covariant final a : null}) {}
//                  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    constFinalOrVarKeyword: final
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_covariant_final_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f({covariant final A a : null}) {}
//                  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    constFinalOrVarKeyword: final
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_covariant_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f({covariant A a : null}) {}
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_covariant_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f({covariant var a : null}) {}
//                  ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    constFinalOrVarKeyword: var
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({final a : null}) {}
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    constFinalOrVarKeyword: final
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_final_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({final A a = null}) {}
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    constFinalOrVarKeyword: final
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_functionTyped() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({a() = null}) {}
''');

    var f = parseResult.findNode.singleFunctionDeclaration;
    var node = f.functionExpression.parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    name: a
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_functionTyped_nullable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({a()? : null}) {}
''');

    var node = parseResult
        .findNode
        .singleFunctionDeclaration
        .functionExpression
        .parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    name: a
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_optionalNamed_functionTyped_nullable_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({a<T>()? : null}) {}
''');

    var node = parseResult
        .findNode
        .singleFunctionDeclaration
        .functionExpression
        .parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    name: a
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
        rightBracket: >
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({A a : null}) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_type_noDefault() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({A a}) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalNamed_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({var a : null}) {}
//      ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    constFinalOrVarKeyword: var
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: NullLiteral
        literal: null
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_covariant_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f([covariant final a = null]) {}
//                  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    constFinalOrVarKeyword: final
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_covariant_final_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f([covariant final A a = null]) {}
//                  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    constFinalOrVarKeyword: final
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_covariant_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f([covariant A a = null]) {}
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_covariant_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f([covariant var a = null]) {}
//                  ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    constFinalOrVarKeyword: var
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f([final a = null]) {}
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    constFinalOrVarKeyword: final
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_final_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f([final A a = null]) {}
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    constFinalOrVarKeyword: final
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f([A a = null]) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_type_noDefault() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f([A a]) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    type: NamedType
      name: A
    name: a
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_optionalPositional_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f([var a = null]) {}
//      ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    constFinalOrVarKeyword: var
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: NullLiteral
        literal: null
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_covariant_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f({required covariant A a}) {}
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    requiredKeyword: required
    covariantKeyword: covariant
    type: NamedType
      name: A
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_covariant_type_ordering() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f({covariant required A a}) {}
//                  ^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'required' should be before the modifier 'covariant'.
}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    requiredKeyword: required
    covariantKeyword: covariant
    type: NamedType
      name: A
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({required final a}) {}
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    requiredKeyword: required
    constFinalOrVarKeyword: final
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_final_ordering() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({final required a}) {}
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//            ^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'required' should be before the modifier 'final'.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    requiredKeyword: required
    constFinalOrVarKeyword: final
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({required A a}) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({required int a = 0}) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    requiredKeyword: required
    type: NamedType
      name: int
    name: a
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: IntegerLiteral
        literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredNamed_type_namedType_int_noDefault() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({required int a}) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    requiredKeyword: required
    type: NamedType
      name: int
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({required var a}) {}
//               ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    requiredKeyword: required
    constFinalOrVarKeyword: var
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredNamed_var_ordering() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f({var required a}) {}
//      ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//          ^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'required' should be before the modifier 'var'.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    requiredKeyword: required
    constFinalOrVarKeyword: var
    name: a
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredPositional_const_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(const a) {}
//     ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  constFinalOrVarKeyword: const
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_const_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(const A a) {}
//     ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  constFinalOrVarKeyword: const
  type: NamedType
    name: A
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_covariant_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f(covariant final a) {}
//                 ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  covariantKeyword: covariant
  constFinalOrVarKeyword: final
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_covariant_final_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f(covariant final A a) {}
//                 ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  covariantKeyword: covariant
  constFinalOrVarKeyword: final
  type: NamedType
    name: A
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_covariant_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f(covariant A<B<C>> a) {}
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f(covariant String Function(int) a) {}
}
''');

    var node = parseResult.findNode.singleMethodDeclaration.parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    covariantKeyword: covariant
    type: GenericFunctionType
      returnType: NamedType
        name: String
      functionKeyword: Function
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: RegularFormalParameter
          type: NamedType
            name: int
        rightParenthesis: )
    name: a
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredPositional_covariant_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  void f(covariant var a) {}
//                 ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  covariantKeyword: covariant
  constFinalOrVarKeyword: var
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_external() {
    parseTestCodeWithDiagnostics(r'''
void f(external int i) {}
//     ^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'external' here.
''');
  }

  void test_regularFormalParameter_requiredPositional_final_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(final a) {}
//     ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  constFinalOrVarKeyword: final
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_final_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(final A a) {}
//     ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  constFinalOrVarKeyword: final
  type: NamedType
    name: A
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_functionTyped_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(a()) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_noType_covariant() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f(covariant a()) {}
}
''');

    var node = parseResult
        .findNode
        .singleMethodDeclaration
        .parameters!
        .parameters
        .single;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  covariantKeyword: covariant
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_noType_nullable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(a()?) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    question: ?
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_noType_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(a<E>()) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: E
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_parameter_covariant() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(void g(covariant int a)) {}
''');

    var node = parseResult.findNode.regularFormalParameter('a)');
    assertParsedNodeText(node, r'''
RegularFormalParameter
  covariantKeyword: covariant
  type: NamedType
    name: int
  name: a
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_parameter_required_covariant() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(void g({required covariant int a})) {}
''');

    var node = parseResult.findNode.regularFormalParameter('a}');
    assertParsedNodeText(node, r'''
RegularFormalParameter
  requiredKeyword: required
  covariantKeyword: covariant
  type: NamedType
    name: int
  name: a
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a()) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: A
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a<E>()) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: A
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: E
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType_void() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(void a()) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: void
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType_void_covariant() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f(covariant void a()) {}
}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  covariantKeyword: covariant
  type: NamedType
    name: void
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_functionTyped_returnType_void_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(void a<E>()) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: void
  name: a
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: E
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  void
  test_regularFormalParameter_requiredPositional_functionTyped_withDocComment() {
    parseTestCodeWithDiagnostics(r'''
void f(
  /// Doc
  g(),
) {}
''');
    // TODO(scheglov): assert AST
    fail('Incomplete');
  }

  void test_regularFormalParameter_requiredPositional_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(a) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_noType_inFunctionTyped() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(void g(a)) {}
''');

    var f = parseResult.findNode.functionDeclaration('f');
    var g =
        f.functionExpression.parameters!.parameters.single
            as RegularFormalParameter;
    var node = g.functionTypedSuffix!.formalParameters.parameters.single;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_noType_nameCovariant() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(covariant) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  name: covariant
''');
  }

  void test_regularFormalParameter_requiredPositional_noType_nameRequired() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(required) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  name: required
''');
  }

  void test_regularFormalParameter_requiredPositional_noType_nameUnderscore() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(_) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  name: _
''');
  }

  void
  test_regularFormalParameter_requiredPositional_single_type_namedType_Function() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(Function f) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: Function
    name: f
  rightParenthesis: )
''');
  }

  void test_regularFormalParameter_requiredPositional_single_type_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(io.File f) {}
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(io.File) {}
//            ^
// [diag.missingIdentifier] Expected an identifier.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(io.) {}
//        ^
// [diag.expectedTypeName] Expected a type name.
// [diag.missingIdentifier] Expected an identifier.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A a) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: A
  name: a
''');
  }

  void test_regularFormalParameter_requiredPositional_type_functionType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(String Function(int) a) {}
''');

    var node = parseResult
        .findNode
        .singleFunctionDeclaration
        .functionExpression
        .parameters!;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: GenericFunctionType
      returnType: NamedType
        name: String
      functionKeyword: Function
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: RegularFormalParameter
          type: NamedType
            name: int
        rightParenthesis: )
    name: a
  rightParenthesis: )
''');
  }

  void
  test_regularFormalParameter_requiredPositional_type_namedType_int_nameUnderscore() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int _) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: int
  name: _
''');
  }

  void test_regularFormalParameter_requiredPositional_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(var a) {}
//     ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  constFinalOrVarKeyword: var
  name: a
''');
  }

  void
  test_superFormalParameter_optionalPositional_type_namedType_int_defaultValue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int a;
  A([this.a = 0]);
}
class B extends A {
  B([int super.a = 0]);
}
''');

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  type: NamedType
    name: int
  superKeyword: super
  period: .
  name: a
  defaultClause: FormalParameterDefaultClause
    separator: =
    value: IntegerLiteral
      literal: 0
''');
  }

  void test_superFormalParameter_requiredNamed_type_namedType_int() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int a;
  A({required this.a});
}
class B extends A {
  B({required int super.a});
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int a;
  A({required this.a});
}
class B extends A {
  B({required int super.a = 0});
}
''');

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  requiredKeyword: required
  type: NamedType
    name: int
  superKeyword: super
  period: .
  name: a
  defaultClause: FormalParameterDefaultClause
    separator: =
    value: IntegerLiteral
      literal: 0
''');
  }

  void test_superFormalParameter_requiredPositional_const_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(const super.a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  constFinalOrVarKeyword: const
  superKeyword: super
  period: .
  name: a
''');
  }

  void test_superFormalParameter_requiredPositional_covariant_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(covariant super.a);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(covariant int super.a);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final dynamic f;
  A(this.f);
}
class B extends A {
  B(super.f<T>()?);
}
''');

    var node = parseResult.findNode.superFormalParameter('super.f');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: f
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    question: ?
''');
  }

  void
  test_superFormalParameter_requiredPositional_functionTyped_returnType_void() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final void Function() f;
  A(this.f);
}
class B extends A {
  B(void super.f());
}
''');

    var node = parseResult.findNode.superFormalParameter('super.f');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  type: NamedType
    name: void
  superKeyword: super
  period: .
  name: f
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void test_superFormalParameter_requiredPositional_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(super.a);
}
''');

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
''');
  }

  void test_superFormalParameter_requiredPositional_type_namedType_int() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(int super.a);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(super.a) {}
''');

    var node = parseResult.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
''');
  }
}
