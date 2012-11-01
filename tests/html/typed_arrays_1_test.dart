// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TypedArrays1Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isnumList = predicate((x) => x is List<num>, 'is a List<num>');
  var isStringList = predicate((x) => x is List<String>, 'is a List<String>');

  test('createByLengthTest', () {
      var a = new Float32Array(10);
      expect(a.length, 10);
      expect(a[4], 0);
  });

  test('aliasTest', () {
      var a1 = new Uint8Array.fromList([0,0,1,0x45]);
      var a2 = new Float32Array.fromBuffer(a1.buffer);

      expect(a2.length, 1);

      // 0x45010000 = 2048+16
      expect(a2[0], 2048 + 16);

      a1[2] = 0;
      // 0x45000000 = 2048
      expect(a2[0], 2048);

      a1[3]--;
      a1[2] += 128;
      // 0x44800000 = 1024
      expect(a2[0], 1024);

  });

  test('typeTests', () {
      var a = new Float32Array(10);
      expect(a, isList);
      expect(a, isnumList);
      expect(a, isNot(isStringList));
    });
}
