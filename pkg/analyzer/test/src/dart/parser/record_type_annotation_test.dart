// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordTypeAnnotationParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecordTypeAnnotationParserTest extends ParserDiagnosticsTest {
  void test_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
() f() {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  void test_mixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, bool, {int a, bool b}) r) {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: bool
  namedFields: RecordTypeAnnotationNamedFields
    leftBracket: {
    fields
      RecordTypeAnnotationNamedField
        type: NamedType
          name: int
        name: a
      RecordTypeAnnotationNamedField
        type: NamedType
          name: bool
        name: b
    rightBracket: }
  rightParenthesis: )
''');
  }

  void test_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(({int a, bool b}) r) {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  namedFields: RecordTypeAnnotationNamedFields
    leftBracket: {
    fields
      RecordTypeAnnotationNamedField
        type: NamedType
          name: int
        name: a
      RecordTypeAnnotationNamedField
        type: NamedType
          name: bool
        name: b
    rightBracket: }
  rightParenthesis: )
''');
  }

  void test_named_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(({int a, bool b,}) r) {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  namedFields: RecordTypeAnnotationNamedFields
    leftBracket: {
    fields
      RecordTypeAnnotationNamedField
        type: NamedType
          name: int
        name: a
      RecordTypeAnnotationNamedField
        type: NamedType
          name: bool
        name: b
    rightBracket: }
  rightParenthesis: )
''');
  }

  void test_nullable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, bool)? r) {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: bool
  rightParenthesis: )
  question: ?
''');
  }

  void test_positional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, bool) r) {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: bool
  rightParenthesis: )
''');
  }

  void test_positional_one() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int) r) {}
//         ^
// [diag.recordTypeOnePositionalNoTrailingComma] A record type with exactly one positional field requires a trailing comma.
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
  rightParenthesis: )
''');
  }

  void test_positional_one_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, ) r) {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
  rightParenthesis: )
''');
  }

  void test_positional_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, bool,) r) {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: bool
  rightParenthesis: )
''');
  }

  void test_topFunction_returnType_withTypeParameter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
(int, T) f<T>() {}
''');

    var node = parseResult.findNode.singleRecordTypeAnnotation;
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: T
  rightParenthesis: )
''');
  }
}
