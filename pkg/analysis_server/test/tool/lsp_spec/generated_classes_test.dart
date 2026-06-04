// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GeneratedClassesTest);
  });
}

@reflectiveTest
class GeneratedClassesTest {
  void test_generatedClasses_equality() {
    var a = TextDocumentIdentifier(uri: Uri.file('/a'));
    var b = TextDocumentIdentifier(uri: Uri.file('/a'));

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  }

  void test_generatedClasses_equality_aliasedListFields() {
    var a = TextDocumentRegistrationOptions(
      documentSelector: [
        TextDocumentFilterScheme(language: 'dart', scheme: 'file'),
      ],
    );
    var b = TextDocumentRegistrationOptions(
      documentSelector: [
        TextDocumentFilterScheme(language: 'dart', scheme: 'file'),
      ],
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  }

  void test_generatedClasses_equality_listField() {
    var a = ClientCodeActionKindOptions(valueSet: [CodeActionKind.QuickFix]);
    var b = ClientCodeActionKindOptions(valueSet: [CodeActionKind.QuickFix]);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  }

  void test_generatedClasses_equality_mapField() {
    var a = WorkspaceEdit(
      changes: {
        Uri.file('/a'): [
          TextEdit(
            range: Range(
              start: Position(line: 0, character: 0),
              end: Position(line: 0, character: 0),
            ),
            newText: 'a',
          ),
        ],
      },
    );
    var b = WorkspaceEdit(
      changes: {
        Uri.file('/a'): [
          TextEdit(
            range: Range(
              start: Position(line: 0, character: 0),
              end: Position(line: 0, character: 0),
            ),
            newText: 'a',
          ),
        ],
      },
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  }

  void test_generatedClasses_equality_subclasses() {
    var a = TextDocumentRegistrationOptions(
      documentSelector: [
        TextDocumentFilterScheme(language: 'dart', scheme: 'file'),
      ],
    );
    var b = TextDocumentSaveRegistrationOptions(
      includeText: true,
      documentSelector: [
        TextDocumentFilterScheme(language: 'dart', scheme: 'file'),
      ],
    );

    expect(a, isNot(equals(b)));
    expect(b, isNot(equals(a)));
  }

  void test_generatedClasses_equality_unionFields() {
    var a = SignatureInformation(
      label: 'a',
      documentation: Either2<MarkupContent, String>.t2('a'),
      parameters: [],
    );
    var b = SignatureInformation(
      label: 'a',
      documentation: Either2<MarkupContent, String>.t2('a'),
      parameters: [],
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  }

  void test_generatedClasses_equality_unionsOfLists() {
    var a = Either2<List<String>, List<int>>.t1(['test']);
    var b = Either2<List<String>, List<int>>.t1(['test']);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  }

  void test_generatedClasses_flagsEnum_combined() {
    var combined = FileExistence.combine([.New, .Existing]);

    expect(combined.toJson(), 3);
    expect(combined.hasFlag(.New), isTrue);
    expect(combined.hasFlag(.Existing), isTrue);
    expect(combined.hasFlag(FileExistence(64)), isFalse);
  }

  void test_generatedClasses_flagsEnum_notCombined() {
    expect(FileExistence.New.hasFlag(.New), isTrue);
    expect(FileExistence.New.hasFlag(.Existing), isFalse);
  }

  void test_interactiveForms_deserialize_formFieldsIntoSubclasses() {
    var stringField = FormField.fromJson({
      'id': 'a',
      'type': {'kind': 'string'},
      'description': '',
      'required': true,
    });
    expect(stringField.type, isA<FormFieldTypeString>());

    var boolField = FormField.fromJson({
      'id': 'b',
      'type': {'kind': 'bool'},
      'description': '',
      'required': false,
    });
    expect(boolField.type, isA<FormFieldTypeBool>());
  }
}
