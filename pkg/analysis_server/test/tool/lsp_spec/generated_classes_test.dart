// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('generated classes', () {
    test('can be checked for equality', () {
      var a = TextDocumentIdentifier(uri: Uri.file('/a'));
      var b = TextDocumentIdentifier(uri: Uri.file('/a'));

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with list fields can be checked for equality', () {
      var a = ClientCodeActionKindOptions(
        valueSet: [CodeActionKind.QuickFix],
      );
      var b = ClientCodeActionKindOptions(
        valueSet: [CodeActionKind.QuickFix],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with aliased list fields can be checked for equality', () {
      var a = TextDocumentRegistrationOptions(documentSelector: [
        TextDocumentFilterScheme(language: 'dart', scheme: 'file')
      ]);
      var b = TextDocumentRegistrationOptions(documentSelector: [
        TextDocumentFilterScheme(language: 'dart', scheme: 'file')
      ]);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with map fields can be checked for equality', () {
      var a = WorkspaceEdit(changes: {
        Uri.file('/a'): [
          TextEdit(
              range: Range(
                  start: Position(line: 0, character: 0),
                  end: Position(line: 0, character: 0)),
              newText: 'a')
        ]
      });
      var b = WorkspaceEdit(changes: {
        Uri.file('/a'): [
          TextEdit(
              range: Range(
                  start: Position(line: 0, character: 0),
                  end: Position(line: 0, character: 0)),
              newText: 'a')
        ]
      });

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with unions of lists can be checked for equality', () {
      var a = Either2<List<String>, List<int>>.t1(['test']);
      var b = Either2<List<String>, List<int>>.t1(['test']);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with union fields can be checked for equality', () {
      var a = SignatureInformation(
          label: 'a',
          documentation: Either2<MarkupContent, String>.t2('a'),
          parameters: []);
      var b = SignatureInformation(
          label: 'a',
          documentation: Either2<MarkupContent, String>.t2('a'),
          parameters: []);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('consider subclasses when checking for equality', () {
      var a = TextDocumentRegistrationOptions(documentSelector: [
        TextDocumentFilterScheme(language: 'dart', scheme: 'file')
      ]);
      var b = TextDocumentSaveRegistrationOptions(
          includeText: true,
          documentSelector: [
            TextDocumentFilterScheme(language: 'dart', scheme: 'file')
          ]);

      expect(a, isNot(equals(b)));
      expect(b, isNot(equals(a)));
    });
  });
}
