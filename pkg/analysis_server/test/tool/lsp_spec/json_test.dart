// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:test/test.dart';

void main() {
  group('toJson', () {
    final start = Position(line: 1, character: 1);
    final end = Position(line: 2, character: 2);
    final range = Range(start: start, end: end);

    test('returns correct JSON for a union', () {
      final num = Either2.t1(1);
      final string = Either2.t2('Test');
      expect(json.encode(num.toJson()), equals('1'));
      expect(json.encode(string.toJson()), equals('"Test"'));
    });

    test('returns correct output for union types', () {
      final message = RequestMessage(
          id: Either2<int, String>.t1(1),
          method: Method.shutdown,
          jsonrpc: 'test');
      final output = json.encode(message.toJson());
      expect(output, equals('{"id":1,"jsonrpc":"test","method":"shutdown"}'));
    });

    test('returns correct output for nested union types', () {
      final message = ResponseMessage(
        id: Either2<int, String>.t1(1),
        result:
            Either2<Either2<List<Location>, Location>, List<LocationLink>>.t1(
                Either2<List<Location>, Location>.t1([
          Location(
            range: range,
            uri: Uri.parse('http://example.org/'),
          )
        ])),
        jsonrpc: jsonRpcVersion,
      );
      final output = json.encode(message.toJson());
      expect(
          output,
          equals(
            '{"id":1,"jsonrpc":"2.0",'
            '"result":[{"range":{"end":{"character":2,"line":2},"start":{"character":1,"line":1}},'
            '"uri":"http://example.org/"}]}',
          ));
    });

    test('returns correct output for union types containing interface types',
        () {
      final params = Either2<String, TextDocumentItem>.t2(TextDocumentItem(
          uri: Uri.parse('http://example.org/'),
          languageId: '!language',
          version: 1,
          text: '!text'));
      final output = json.encode(params);
      expect(
          output,
          equals(
              '{"languageId":"!language","text":"!text","uri":"http://example.org/","version":1}'));
    });

    test('returns correct output for types with lists', () {
      final location =
          Location(uri: Uri.parse('http://example.org/'), range: range);
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
        "code":"test_err",
        "message":"err!!",
        "range":{
            "end":{"character":2,"line":2},
            "start":{"character":1,"line":1}
        },
        "relatedInformation":[
            {
              "location":{
                  "range":{
                    "end":{"character":2,"line":2},
                    "start":{"character":1,"line":1}
                  },
                  "uri":"http://example.org/"
              },
              "message":"message"
            }
        ],
        "severity":1,
        "source":"/tmp/source.dart"
      }'''
          .replaceAll(RegExp('[ \n]'), '');
      expect(output, equals(expected));
    });

    test('toJson() converts lists of enums to their underlying values', () {
      final kind = CompletionClientCapabilitiesCompletionItemKind(
        valueSet: [CompletionItemKind.Color],
      );
      final json = kind.toJson();
      expect(
        json['valueSet'],
        // The list should contain the toJson (string/int) representation of
        // the color, and not the CompletionItemKind itself.
        equals([CompletionItemKind.Color.toJson()]),
      );
    });

    test('serializes enums to their underlying values', () {
      final foldingRange = FoldingRange(
          startLine: 1,
          startCharacter: 2,
          endLine: 3,
          endCharacter: 4,
          kind: FoldingRangeKind.Comment);
      final output = json.encode(foldingRange.toJson());
      final expected = '''{
        "endCharacter":4,
        "endLine":3,
        "kind":"comment",
        "startCharacter":2,
        "startLine":1
      }'''
          .replaceAll(RegExp('[ \n]'), '');
      expect(output, equals(expected));
    });

    test('ResponseMessage does not include an error with a result', () {
      final id = Either2<int, String>.t1(1);
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
        MarkupKind.canParse('plaintext', throwingLspJsonReporter),
        isTrue,
      );
    });

    test('canParse returns true for out-of-spec (unrestricted) enum values',
        () {
      expect(
        SymbolKind.canParse(-1, throwingLspJsonReporter),
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
      }, throwingLspJsonReporter);
      expect(canParse, isTrue);
    });

    test('canParse allows matching literal strings', () {
      // The CreateFile type is defined with `{ kind: 'create' }` so the only
      // allowed value for `kind` is "create".
      final canParse = CreateFile.canParse({
        'kind': 'create',
        'uri': 'file:///temp/foo',
      }, throwingLspJsonReporter);
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
        'message': false,
        'messages': true,
        'verbose': true,
        null: true,
        'invalid': false,
      };
      for (final entry in testTraceValues.entries) {
        final testValue = entry.key;
        final expected = entry.value;
        final reporter =
            expected ? throwingLspJsonReporter : nullLspJsonReporter;
        final canParse = InitializeParams.canParse({
          'processId': null,
          'rootUri': null,
          'capabilities': <String, Object>{},
          'trace': testValue,
        }, reporter);
        expect(canParse, expected,
            reason: 'InitializeParams.canParse returned $canParse with a '
                '"trace" value of "$testValue" but expected $expected');
      }
    });

    test('canParse validates optional fields', () {
      expect(
        RenameFileOptions.canParse(<String, Object>{}, throwingLspJsonReporter),
        isTrue,
      );
      expect(
        RenameFileOptions.canParse(
            {'overwrite': true}, throwingLspJsonReporter),
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
            {'overwrite': true, 'invalidField': true}, throwingLspJsonReporter),
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
        CompletionParams.canParse({
          'position': {'line': 1, 'character': 1},
          'textDocument': <String, dynamic>{},
        }, reporter),
        isFalse,
      );
      expect(reporter.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(reporter.errors.first,
          equals('params.textDocument.uri must not be undefined'));
    });

    test('canParse records nested null fields', () {
      final reporter = LspJsonReporter('params');
      expect(
        CompletionParams.canParse({
          'position': {'line': 1, 'character': 1},
          'textDocument': {'uri': null},
        }, reporter),
        isFalse,
      );
      expect(reporter.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(reporter.errors.first,
          equals('params.textDocument.uri must not be null'));
    });

    test('canParse records nested fields of the wrong type', () {
      final reporter = LspJsonReporter('params');
      expect(
        CompletionParams.canParse({
          'position': {'line': 1, 'character': 1},
          'textDocument': {'uri': 1},
        }, reporter),
        isFalse,
      );
      expect(reporter.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(reporter.errors.first,
          equals('params.textDocument.uri must be of type Uri'));
    });

    test(
        'canParse records errors when the type is not in the set of allowed types',
        () {
      final reporter = LspJsonReporter('params');
      expect(
        WorkspaceEdit.canParse({
          'documentChanges': {'uri': 1}
        }, reporter),
        isFalse,
      );
      expect(reporter.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(
          reporter.errors.first,
          equals(
              'params.documentChanges must be of type List<Either4<CreateFile, DeleteFile, RenameFile, TextDocumentEdit>>'));
    });

    test('ResponseMessage can include a null result', () {
      final id = Either2<int, String>.t1(1);
      final resp = ResponseMessage(id: id, jsonrpc: jsonRpcVersion);
      final jsonMap = resp.toJson();
      expect(jsonMap, contains('result'));
      expect(jsonMap, isNot(contains('error')));
    });

    test('ResponseMessage does not include a result for an error', () {
      final id = Either2<int, String>.t1(1);
      final error =
          ResponseError(code: ErrorCodes.ParseError, message: 'Error');
      final resp =
          ResponseMessage(id: id, error: error, jsonrpc: jsonRpcVersion);
      final jsonMap = resp.toJson();
      expect(jsonMap, contains('error'));
      expect(jsonMap, isNot(contains('result')));
    });

    test('ResponseMessage throws if both result and error are non-null', () {
      final id = Either2<int, String>.t1(1);
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
      final message =
          RequestMessage.fromJson(jsonDecode(input) as Map<String, Object?>);
      expect(message.id, equals(Either2<num, String>.t1(1)));
      expect(message.id.valueEquals(1), isTrue);
      expect(message.jsonrpc, 'test');
      expect(message.method, Method.shutdown);
    });

    test('parses JSON for types with unions (right side)', () {
      final input = '{"id":"one","method":"shutdown","jsonrpc":"test"}';
      final message =
          RequestMessage.fromJson(jsonDecode(input) as Map<String, Object?>);
      expect(message.id, equals(Either2<num, String>.t2('one')));
      expect(message.id.valueEquals('one'), isTrue);
      expect(message.jsonrpc, 'test');
      expect(message.method, Method.shutdown);
    });

    test('parses JSON with nulls for unions that allow null', () {
      final input = '{"id":null,"jsonrpc":"test"}';
      final message =
          ResponseMessage.fromJson(jsonDecode(input) as Map<String, Object?>);
      expect(message.id, isNull);
    });

    test('parses JSON with nulls for unions that allow null', () {
      final input = '{"method":"test","jsonrpc":"test"}';
      final message = NotificationMessage.fromJson(
          jsonDecode(input) as Map<String, Object?>);
      expect(message.params, isNull);
    });

    test('deserializes subtypes into the correct class', () {
      // Create some JSON that includes a VersionedTextDocumentIdentifier but
      // where the class definition only references a TextDocumentIdentifier.
      final input = jsonEncode(TextDocumentPositionParams(
        textDocument: VersionedTextDocumentIdentifier(
            version: 111, uri: Uri.file('/foo/bar.dart')),
        position: Position(line: 1, character: 1),
      ).toJson());
      final params = TextDocumentPositionParams.fromJson(
          jsonDecode(input) as Map<String, Object?>);
      expect(params.textDocument,
          const TypeMatcher<VersionedTextDocumentIdentifier>());
    });

    test('parses JSON with unknown fields', () {
      final input =
          '{"id":1,"invalidField":true,"method":"foo","jsonrpc":"test"}';
      final message =
          RequestMessage.fromJson(jsonDecode(input) as Map<String, Object?>);
      expect(message.id.valueEquals(1), isTrue);
      expect(message.method, equals(Method('foo')));
      expect(message.params, isNull);
      expect(message.jsonrpc, equals('test'));
    });

    test('parses JSON with integers in double fields', () {
      final input = '{"alpha":1.0,"blue":0,"green":1,"red":1.5}';
      final message = Color.fromJson(jsonDecode(input) as Map<String, Object?>);
      expect(message.alpha, 1.0);
      expect(message.blue, 0.0);
      expect(message.green, 1.0);
      expect(message.red, 1.5);
    });
  });

  test('objects with lists can round-trip through to json and back', () {
    final workspaceFolders = [
      WorkspaceFolder(uri: Uri.parse('http://example.org/1'), name: '!name1'),
      WorkspaceFolder(uri: Uri.parse('http://example.org/2'), name: '!name2'),
    ];
    final obj = InitializeParams(
      processId: 1,
      clientInfo:
          InitializeParamsClientInfo(name: 'server name', version: '1.2.3'),
      rootPath: '!root',
      capabilities: ClientCapabilities(),
      trace: TraceValues.Off,
      workspaceFolders: workspaceFolders,
    );
    final json = jsonEncode(obj);
    final restoredObj =
        InitializeParams.fromJson(jsonDecode(json) as Map<String, Object?>);
    final restoredWorkspaceFolders = restoredObj.workspaceFolders!;

    expect(restoredWorkspaceFolders, hasLength(workspaceFolders.length));
    for (var i = 0; i < workspaceFolders.length; i++) {
      expect(
          restoredWorkspaceFolders[i].name, equals(workspaceFolders[i].name));
      expect(restoredWorkspaceFolders[i].uri, equals(workspaceFolders[i].uri));
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
    final restoredObj =
        FoldingRange.fromJson(jsonDecode(json) as Map<String, Object?>);

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
    final obj = WorkspaceEdit(changes: <Uri, List<TextEdit>>{
      Uri.file('/fileA'): [TextEdit(range: range, newText: 'text A')],
      Uri.file('/fileB'): [TextEdit(range: range, newText: 'text B')]
    });
    final json = jsonEncode(obj);
    final restoredObj =
        WorkspaceEdit.fromJson(jsonDecode(json) as Map<String, Object?>);

    expect(restoredObj.documentChanges, equals(obj.documentChanges));
    expect(restoredObj.changes, equals(obj.changes));
    expect(restoredObj.changes!.keys, equals(obj.changes!.keys));
    expect(restoredObj.changes!.values, equals(obj.changes!.values));
  });
}
