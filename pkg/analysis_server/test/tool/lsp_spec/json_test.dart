// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:test/test.dart';

void main() {
  group('toJson', () {
    test('returns correct JSON for a union', () {
      final _num = Either2.t1(1);
      final _string = Either2.t2('Test');
      expect(json.encode(_num.toJson()), equals('1'));
      expect(json.encode(_string.toJson()), equals('"Test"'));
    });

    test('returns correct output for union types', () {
      final message = RequestMessage(
          id: Either2<num, String>.t1(1),
          method: Method.shutdown,
          jsonrpc: 'test');
      final output = json.encode(message.toJson());
      expect(output, equals('{"id":1,"method":"shutdown","jsonrpc":"test"}'));
    });

    test('returns correct output for union types containing interface types',
        () {
      final params = Either2<String, TextDocumentItem>.t2(TextDocumentItem(
          uri: '!uri', languageId: '!language', version: 1, text: '!text'));
      final output = json.encode(params);
      expect(
          output,
          equals(
              '{"uri":"!uri","languageId":"!language","version":1,"text":"!text"}'));
    });

    test('returns correct output for types with lists', () {
      final start = Position(line: 1, character: 1);
      final end = Position(line: 2, character: 2);
      final range = Range(start: start, end: end);
      final location = Location(uri: 'y-uri', range: range);
      final codeAction = Diagnostic(
        range: range,
        severity: DiagnosticSeverity.Error,
        code: 'test_err',
        source: '/tmp/source.dart',
        message: 'err!!',
        relatedInformation: [
          DiagnosticRelatedInformation(location: location, message: 'message')
        ],
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
          .replaceAll(RegExp('[ \n]'), '');
      expect(output, equals(expected));
    });

    test('serialises enums to their underlying values', () {
      final foldingRange = FoldingRange(
          startLine: 1,
          startCharacter: 2,
          endLine: 3,
          endCharacter: 4,
          kind: FoldingRangeKind.Comment);
      final output = json.encode(foldingRange.toJson());
      final expected = '''{
        "startLine":1,
        "startCharacter":2,
        "endLine":3,
        "endCharacter":4,
        "kind":"comment"
      }'''
          .replaceAll(RegExp('[ \n]'), '');
      expect(output, equals(expected));
    });

    test('ResponseMessage does not include an error with a result', () {
      final id = Either2<num, String>.t1(1);
      final result = 'my result';
      final resp =
          ResponseMessage(id: id, result: result, jsonrpc: jsonRpcVersion);
      final jsonMap = resp.toJson();
      expect(jsonMap, contains('result'));
      expect(jsonMap, isNot(contains('error')));
    });

    test('canParse returns false for out-of-spec (restricted) enum values', () {
      expect(
        MarkupKind.canParse('NotAMarkupKind', nullLspJsonReporter),
        isFalse,
      );
    });

    test('canParse returns true for in-spec (restricted) enum values', () {
      expect(
        MarkupKind.canParse('plaintext', nullLspJsonReporter),
        isTrue,
      );
    });

    test('canParse returns true for out-of-spec (unrestricted) enum values',
        () {
      expect(
        SymbolKind.canParse(-1, nullLspJsonReporter),
        isTrue,
      );
    });

    test('canParse allows nulls in nullable and undefinable fields', () {
      // The only required field in InitializeParams is capabilities, and all
      // of the fields on that are optional.
      final canParse = InitializeParams.canParse({
        'processId': null,
        'rootUri': null,
        'capabilities': <String, Object>{}
      }, nullLspJsonReporter);
      expect(canParse, isTrue);
    });

    test('canParse allows matching literal strings', () {
      // The CreateFile type is defined with `{ kind: 'create' }` so the only
      // allowed value for `kind` is "create".
      final canParse = CreateFile.canParse({
        'kind': 'create',
        'uri': 'file:///temp/foo',
      }, nullLspJsonReporter);
      expect(canParse, isTrue);
    });

    test('canParse disallows non-matching literal strings', () {
      // The CreateFile type is defined with `{ kind: 'create' }` so the only
      // allowed value for `kind` is "create".
      final canParse = CreateFile.canParse({
        'kind': 'not-create',
        'uri': 'file:///temp/foo',
      }, nullLspJsonReporter);
      expect(canParse, isFalse);
    });

    test('canParse handles unions of literals', () {
      // Key = value to test
      // Value whether expected to parse
      const testTraceValues = {
        'off': true,
        'message': true,
        'verbose': true,
        null: true,
        'invalid': false,
      };
      for (final testValue in testTraceValues.keys) {
        final expected = testTraceValues[testValue];
        final canParse = InitializeParams.canParse({
          'processId': null,
          'rootUri': null,
          'capabilities': <String, Object>{},
          'trace': testValue,
        }, nullLspJsonReporter);
        expect(canParse, expected,
            reason: 'InitializeParams.canParse returned $canParse with a '
                '"trace" value of "$testValue" but expected $expected');
      }
    });

    test('canParse validates optional fields', () {
      expect(
        RenameFileOptions.canParse(<String, Object>{}, nullLspJsonReporter),
        isTrue,
      );
      expect(
        RenameFileOptions.canParse({'overwrite': true}, nullLspJsonReporter),
        isTrue,
      );
      expect(
        RenameFileOptions.canParse({'overwrite': 1}, nullLspJsonReporter),
        isFalse,
      );
    });

    test('canParse ignores fields not in the spec', () {
      expect(
        RenameFileOptions.canParse(
            {'overwrite': true, 'invalidField': true}, nullLspJsonReporter),
        isTrue,
      );
      expect(
        RenameFileOptions.canParse(
            {'overwrite': 1, 'invalidField': true}, nullLspJsonReporter),
        isFalse,
      );
    });

    test('canParse records undefined fields', () {
      final reporter = LspJsonReporter('params');
      expect(CreateFile.canParse(<String, dynamic>{}, reporter), isFalse);
      expect(reporter.errors, hasLength(1));
      expect(
          reporter.errors.first, equals('params.kind must not be undefined'));
    });

    test('canParse records null fields', () {
      final reporter = LspJsonReporter('params');
      expect(CreateFile.canParse({'kind': null}, reporter), isFalse);
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first, equals('params.kind must not be null'));
    });

    test('canParse records fields of the wrong type', () {
      final reporter = LspJsonReporter('params');
      expect(RenameFileOptions.canParse({'overwrite': 1}, reporter), isFalse);
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first,
          equals('params.overwrite must be of type bool'));
    });

    test('canParse records nested undefined fields', () {
      final reporter = LspJsonReporter('params');
      expect(
          CompletionParams.canParse(
              {'textDocument': <String, dynamic>{}}, reporter),
          isFalse);
      expect(reporter.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(reporter.errors.first,
          equals('params.textDocument.uri must not be undefined'));
    });

    test('canParse records nested null fields', () {
      final reporter = LspJsonReporter('params');
      expect(
          CompletionParams.canParse({
            'textDocument': {'uri': null}
          }, reporter),
          isFalse);
      expect(reporter.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(reporter.errors.first,
          equals('params.textDocument.uri must not be null'));
    });

    test('canParse records nested fields of the wrong type', () {
      final reporter = LspJsonReporter('params');
      expect(
          CompletionParams.canParse({
            'textDocument': {'uri': 1}
          }, reporter),
          isFalse);
      expect(reporter.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(reporter.errors.first,
          equals('params.textDocument.uri must be of type String'));
    });

    test(
        'canParse records errors when the type is not in the set of allowed types',
        () {
      final reporter = LspJsonReporter('params');
      expect(
          WorkspaceEdit.canParse({
            'documentChanges': {'uri': 1}
          }, reporter),
          isFalse);
      expect(reporter.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(
          reporter.errors.first,
          equals(
              'params.documentChanges must be of type Either2<List<TextDocumentEdit>, List<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>>'));
    });

    test('ResponseMessage can include a null result', () {
      final id = Either2<num, String>.t1(1);
      final resp = ResponseMessage(id: id, jsonrpc: jsonRpcVersion);
      final jsonMap = resp.toJson();
      expect(jsonMap, contains('result'));
      expect(jsonMap, isNot(contains('error')));
    });

    test('ResponseMessage does not include a result for an error', () {
      final id = Either2<num, String>.t1(1);
      final error =
          ResponseError(code: ErrorCodes.ParseError, message: 'Error');
      final resp =
          ResponseMessage(id: id, error: error, jsonrpc: jsonRpcVersion);
      final jsonMap = resp.toJson();
      expect(jsonMap, contains('error'));
      expect(jsonMap, isNot(contains('result')));
    });

    test('ResponseMessage throws if both result and error are non-null', () {
      final id = Either2<num, String>.t1(1);
      final result = 'my result';
      final error =
          ResponseError(code: ErrorCodes.ParseError, message: 'Error');
      final resp = ResponseMessage(
          id: id, result: result, error: error, jsonrpc: jsonRpcVersion);
      expect(resp.toJson, throwsA(TypeMatcher<String>()));
    });
  });

  group('fromJson', () {
    test('parses JSON for types with unions (left side)', () {
      final input = '{"id":1,"method":"shutdown","jsonrpc":"test"}';
      final message = RequestMessage.fromJson(jsonDecode(input));
      expect(message.id, equals(Either2<num, String>.t1(1)));
      expect(message.id.valueEquals(1), isTrue);
      expect(message.jsonrpc, 'test');
      expect(message.method, Method.shutdown);
    });

    test('parses JSON for types with unions (right side)', () {
      final input = '{"id":"one","method":"shutdown","jsonrpc":"test"}';
      final message = RequestMessage.fromJson(jsonDecode(input));
      expect(message.id, equals(Either2<num, String>.t2('one')));
      expect(message.id.valueEquals('one'), isTrue);
      expect(message.jsonrpc, 'test');
      expect(message.method, Method.shutdown);
    });

    test('parses JSON with nulls for unions that allow null', () {
      final input = '{"id":null,"jsonrpc":"test"}';
      final message = ResponseMessage.fromJson(jsonDecode(input));
      expect(message.id, isNull);
    });

    test('parses JSON with nulls for unions that allow null', () {
      final input = '{"method":"test","jsonrpc":"test"}';
      final message = NotificationMessage.fromJson(jsonDecode(input));
      expect(message.params, isNull);
    });

    test('deserialises subtypes into the correct class', () {
      // Create some JSON that includes a VersionedTextDocumentIdenfitier but
      // where the class definition only references a TextDocumentIdemntifier.
      final input = jsonEncode(TextDocumentPositionParams(
        textDocument: VersionedTextDocumentIdentifier(
            version: 111, uri: 'file:///foo/bar.dart'),
        position: Position(line: 1, character: 1),
      ).toJson());
      final params = TextDocumentPositionParams.fromJson(jsonDecode(input));
      expect(params.textDocument,
          const TypeMatcher<VersionedTextDocumentIdentifier>());
    });

    test('parses JSON with unknown fields', () {
      final input =
          '{"id":1,"invalidField":true,"method":"foo","jsonrpc":"test"}';
      final message = RequestMessage.fromJson(jsonDecode(input));
      expect(message.id.valueEquals(1), isTrue);
      expect(message.method, equals(Method('foo')));
      expect(message.params, isNull);
      expect(message.jsonrpc, equals('test'));
    });
  });

  test('objects with lists can round-trip through to json and back', () {
    final obj = InitializeParams(
      processId: 1,
      clientInfo:
          InitializeParamsClientInfo(name: 'server name', version: '1.2.3'),
      rootPath: '!root',
      capabilities: ClientCapabilities(),
      trace: 'off',
      workspaceFolders: [
        WorkspaceFolder(uri: '!uri1', name: '!name1'),
        WorkspaceFolder(uri: '!uri2', name: '!name2'),
      ],
    );
    final json = jsonEncode(obj);
    final restoredObj = InitializeParams.fromJson(jsonDecode(json));

    expect(
        restoredObj.workspaceFolders, hasLength(obj.workspaceFolders.length));
    for (var i = 0; i < obj.workspaceFolders.length; i++) {
      expect(restoredObj.workspaceFolders[i].name,
          equals(obj.workspaceFolders[i].name));
      expect(restoredObj.workspaceFolders[i].uri,
          equals(obj.workspaceFolders[i].uri));
    }
  });

  test('objects with enums can round-trip through to json and back', () {
    final obj = FoldingRange(
        startLine: 1,
        startCharacter: 2,
        endLine: 3,
        endCharacter: 4,
        kind: FoldingRangeKind.Comment);
    final json = jsonEncode(obj);
    final restoredObj = FoldingRange.fromJson(jsonDecode(json));

    expect(restoredObj.startLine, equals(obj.startLine));
    expect(restoredObj.startCharacter, equals(obj.startCharacter));
    expect(restoredObj.endLine, equals(obj.endLine));
    expect(restoredObj.endCharacter, equals(obj.endCharacter));
    expect(restoredObj.kind, equals(obj.kind));
  });

  test('objects with maps can round-trip through to json and back', () {
    final start = Position(line: 1, character: 1);
    final end = Position(line: 2, character: 2);
    final range = Range(start: start, end: end);
    final obj = WorkspaceEdit(changes: <String, List<TextEdit>>{
      'fileA': [TextEdit(range: range, newText: 'text A')],
      'fileB': [TextEdit(range: range, newText: 'text B')]
    });
    final json = jsonEncode(obj);
    final restoredObj = WorkspaceEdit.fromJson(jsonDecode(json));

    expect(restoredObj.documentChanges, equals(obj.documentChanges));
    expect(restoredObj.changes, equals(obj.changes));
    expect(restoredObj.changes.keys, equals(obj.changes.keys));
    expect(restoredObj.changes.values, equals(obj.changes.values));
  });
}
