// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../mini_ast.dart';

main() {
  late Harness h;

  setUp(() {
    h = Harness();
  });

  group('Expressions:', () {
    group('integer literal', () {
      test('double context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: true)
              .checkType('double')
              .checkIr('1.0f')
              .inContext('double'),
        ]);
      });

      test('int context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('int'),
        ]);
      });

      test('num context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('num'),
        ]);
      });

      test('double? context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: true)
              .checkType('double')
              .checkIr('1.0f')
              .inContext('double?'),
        ]);
      });

      test('int? context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('int?'),
        ]);
      });

      test('unknown context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('?'),
        ]);
      });

      test('unrelated context', () {
        // Note: an unrelated context can arise in the case of assigning to a
        // promoted variable, e.g.:
        //
        //   Object x;
        //   if (x is String) {
        //     x = 1;
        //   }
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('String'),
        ]);
      });
    });
  });
}
