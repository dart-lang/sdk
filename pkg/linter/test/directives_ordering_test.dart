// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules/directives_ordering.dart';
import 'package:test/test.dart';

void main() {
  group(compareDirectives, () {
    void checkImportGroup(List<String> correctlyOrderedImports) {
      for (int i = 0; i < correctlyOrderedImports.length; i++) {
        var a = correctlyOrderedImports[i];
        expect(compareDirectives(a, a), 0,
            reason: '"$a" sorts the same as itself');

        for (int j = i + 1; j < correctlyOrderedImports.length; j++) {
          var b = correctlyOrderedImports[j];
          expect(compareDirectives(a, b), lessThan(0),
              reason: '"$a" sorts before "$b"');
          expect(compareDirectives(b, a), greaterThan(0),
              reason: '"$b" sorts after "$a"');
        }
      }
    }

    test('dart: imports', () {
      checkImportGroup(const [
        'dart:aaa',
        'dart:bbb',
      ]);
    });

    test('package: imports', () {
      checkImportGroup(const [
        'package:aa/bb.dart',
        'package:aaa/aaa.dart',
        'package:aaa/ccc.dart',
        'package:bbb/bbb.dart',
      ]);
    });

    test('relative imports', () {
      checkImportGroup(const [
        '/foo5.dart',
        '../../foo4.dart',
        '../foo2/a.dart',
        '../foo3.dart',
        './foo2.dart',
        'a.dart',
        'aaa/aaa.dart',
        'bbb/bbb.dart',
        'foo1.dart',
      ]);
    });
  });
}
