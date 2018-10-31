// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:test/test.dart';

main() {
  group('toJson', () {
    test('returns correct JSON for a union', () {
      final _num = new Either2.t1(1);
      final _string = new Either2.t2('Test');
      expect(json.encode(_num.toJson()), equals('1'));
      expect(json.encode(_string.toJson()), equals('"Test"'));
    });

    test('returns correct output for union types', () {
      final message =
          new RequestMessage(new Either2.t1(1), "test", null, "test");
      String output = json.encode(message.toJson());
      expect(output, equals('{"id":1,"method":"test","jsonrpc":"test"}'));
    });

    test('returns correct output for union types containing interface types',
        () {
      final params = new Either2<String, WorkspaceClientCapabilities>.t2(
          new WorkspaceClientCapabilities(
        true,
        null,
        null,
        null,
      ));
      String output = json.encode(params);
      expect(output, equals('{"applyEdit":true}'));
    });

    test('returns correct output for types with lists', () {
      final start = new Position(1, 1);
      final end = new Position(2, 2);
      final range = new Range(start, end);
      final location = new Location('y-uri', range);
      final codeAction = new Diagnostic(
        range,
        DiagnosticSeverity.Error,
        new Either2.t2('test_err'),
        '/tmp/source.dart',
        'err!!',
        [new DiagnosticRelatedInformation(location, 'message')],
      );
      final output = json.encode(codeAction.toJson());
      final expected = '''{
        "range":{
            "start":{"line":1,"character":1},
            "end":{"line":2,"character":2}
        },
        "severity":1,
        "code":"test_err",
        "source":"/tmp/source.dart",
        "message":"err!!",
        "relatedInformation":[
            {
              "location":{
                  "uri":"y-uri",
                  "range":{
                    "start":{"line":1,"character":1},
                    "end":{"line":2,"character":2}
                  }
              },
              "message":"message"
            }
        ]
      }'''
          .replaceAll(new RegExp('[ \n]'), '');
      expect(output, equals(expected));
    });

    test('serialises enums to their underlying values', () {
      final foldingRange =
          new FoldingRange(1, 2, 3, 4, FoldingRangeKind.Comment);
      final output = json.encode(foldingRange.toJson());
      final expected = '''{
        "startLine":1,
        "startCharacter":2,
        "endLine":3,
        "endCharacter":4,
        "kind":"comment"
      }'''
          .replaceAll(new RegExp('[ \n]'), '');
      expect(output, equals(expected));
    });
  });

  group('fromJson', () {
    test('parses JSON for types with unions (left side)', () {
      final input = '{"id":1,"method":"test","jsonrpc":"test"}';
      final message = RequestMessage.fromJson(jsonDecode(input));
      expect(message.id, equals(new Either2<num, String>.t1(1)));
      expect(message.id.valueEquals(1), isTrue);
      expect(message.jsonrpc, "test");
      expect(message.method, "test");
    });

    test('parses JSON for types with unions (right side)', () {
      final input = '{"id":"one","method":"test","jsonrpc":"test"}';
      final message = RequestMessage.fromJson(jsonDecode(input));
      expect(message.id, equals(new Either2<num, String>.t2("one")));
      expect(message.id.valueEquals("one"), isTrue);
      expect(message.jsonrpc, "test");
      expect(message.method, "test");
    });
  });

  test('objects with lists and enums can round-trip through to json and back',
      () {
    final obj = new ClientCapabilities(
        new WorkspaceClientCapabilities(
            true,
            false,
            [ResourceOperationKind.Create, ResourceOperationKind.Delete],
            FailureHandlingKind.Undo),
        new TextDocumentClientCapabilities(true, false, true, false),
        null);
    final String json = jsonEncode(obj);
    final restoredObj = ClientCapabilities.fromJson(jsonDecode(json));

    expect(restoredObj.workspace.applyEdit, equals(obj.workspace.applyEdit));
    expect(restoredObj.workspace.documentChanges,
        equals(obj.workspace.documentChanges));
    expect(restoredObj.workspace.resourceOperations,
        equals(obj.workspace.resourceOperations));
    expect(restoredObj.workspace.failureHandling,
        equals(obj.workspace.failureHandling));
    expect(restoredObj.textDocument.didSave, equals(obj.textDocument.didSave));
    expect(restoredObj.textDocument.dynamicRegistration,
        equals(obj.textDocument.dynamicRegistration));
    expect(
        restoredObj.textDocument.willSave, equals(obj.textDocument.willSave));
    expect(restoredObj.textDocument.willSaveWaitUntil,
        equals(obj.textDocument.willSaveWaitUntil));
    expect(restoredObj.experimental, equals(obj.experimental));
  });
}
