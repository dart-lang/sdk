// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/codegen_dart.dart';

main() {
  group('mapType', () {
    test('handles basic types', () {
      expect(mapType(['string']), equals('String'));
      expect(mapType(['boolean']), equals('bool'));
      expect(mapType(['any']), equals('dynamic'));
      expect(mapType(['object']), equals('dynamic'));
      expect(mapType(['int']), equals('int'));
      expect(mapType(['num']), equals('num'));
    });

    test('handles union types', () {
      expect(mapType(['string', 'int']), equals('Either2<String, int>'));
      expect(mapType(['string | int']), equals('Either2<String, int>'));
    });

    test('handles arrays', () {
      expect(mapType(['string[]']), equals('List<String>'));
      expect(mapType(['Array<string>']), equals('List<String>'));
    });

    test('handles types with args', () {
      expect(mapType(['Class<string[]>']), equals('Class<List<String>>'));
      expect(mapType(['Array<string | num>']),
          equals('List<Either2<String, num>>'));
    });

    test('handles complex nested types', () {
      expect(
          mapType([
            'Array<string>',
            'any[]',
            'Response<A>',
            'Request<Array<string | num>>'
          ]),
          equals(
              'Either4<List<String>, List<dynamic>, Response<A>, Request<List<Either2<String, num>>>>'));
    });
  });
}
