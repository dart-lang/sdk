// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:test/test.dart';

void main() {
  group('generated classes', () {
    test('can be checked for equality', () {
      final a = TextDocumentIdentifier('/a');
      final b = TextDocumentIdentifier('/a');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with list fields can be checked for equality', () {
      final a = TextDocumentClientCapabilitiesCodeActionKind(
          [CodeActionKind.QuickFix]);
      final b = TextDocumentClientCapabilitiesCodeActionKind(
          [CodeActionKind.QuickFix]);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with aliased list fields can be checked for equality', () {
      final a = TextDocumentRegistrationOptions(
          [DocumentFilter('dart', 'file', null)]);
      final b = TextDocumentRegistrationOptions(
          [DocumentFilter('dart', 'file', null)]);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with map fields can be checked for equality', () {
      final a = WorkspaceEdit({
        'a': [TextEdit(Range(Position(0, 0), Position(0, 0)), 'a')]
      }, null);
      final b = WorkspaceEdit({
        'a': [TextEdit(Range(Position(0, 0), Position(0, 0)), 'a')]
      }, null);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with unions of lists can be checked for equality', () {
      final a = Either2<List<String>, List<int>>.t1(['test']);
      final b = Either2<List<String>, List<int>>.t1(['test']);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with union fields can be checked for equality', () {
      final a =
          SignatureInformation('a', Either2<String, MarkupContent>.t1('a'), []);
      final b =
          SignatureInformation('a', Either2<String, MarkupContent>.t1('a'), []);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('consider subclasses when checking for equality', () {
      final a = TextDocumentRegistrationOptions(
          [DocumentFilter('dart', 'file', null)]);
      final b = TextDocumentSaveRegistrationOptions(
          true, [DocumentFilter('dart', 'file', null)]);

      expect(a, isNot(equals(b)));
      expect(b, isNot(equals(a)));
    });
  });
}
