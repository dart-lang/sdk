// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.utils_test;

import 'package:dev_compiler/src/utils.dart';
import 'package:test/test.dart';

enum Foo { first, second }

void main() {
  group('getEnumValue', () {
    test('gets simple names', () {
      expect(getEnumName(Foo.first), 'first');
    });
    test('chokes on invalid values', () {
      expect(() => getEnumName(null), throws);
      expect(() => getEnumName(''), throws);
      expect(() => getEnumName('.'), throws);
      expect(() => getEnumName('.a'), throws);
      expect(() => getEnumName('a.'), throws);
    });
  });
  group('parseEnum', () {
    Foo parseFoo(String s) => parseEnum(s, Foo.values);
    test('parses enums', () {
      expect(parseFoo('first'), Foo.first);
      expect(parseFoo('second'), Foo.second);
    });
    test('chokes on unknown enums', () {
      expect(() => parseFoo(''), throws);
      expect(() => parseFoo('what'), throws);
    });
  });
}
