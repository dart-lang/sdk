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

    test('returns correct output for types unions', () {
      final message = new RequestMessage(new Either2.t1(1), "test", "test");
      String output = json.encode(message.toJson());
      expect(output, equals('{"id":1,"method":"test","jsonrpc":"test"}'));
    });

    test('returns correct output for types with lists', () {
      final start = new Position(1, 1);
      final end = new Position(2, 2);
      // TODO(dantup): Fix that constructor args are the wrong way around
      // (due to our field sorting).
      final range = new Range(end, start);
      final location = new Location(range, 'y-uri');
      final codeAction = new Diagnostic(
          new Either2.t2('test_err'),
          'err!!',
          range,
          [new DiagnosticRelatedInformation(location, 'message')],
          DiagnosticSeverity.Error,
          '/tmp/source.dart');
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
                  "uri":"y-uri"
              },
              "message":"message"
            }
        ],
        "severity":1,
        "source":"/tmp/source.dart"
      }'''
          .replaceAll(new RegExp('[ \n]'), '');
      expect(output, equals(expected));
    });
  });
}
