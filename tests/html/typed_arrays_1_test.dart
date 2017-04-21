// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TypedArrays1Test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:typed_data';

main() {
  useHtmlIndividualConfiguration();

  var isnumList = predicate((x) => x is List<num>, 'is a List<num>');
  var isStringList = predicate((x) => x is List<String>, 'is a List<String>');
  var expectation = Platform.supportsTypedData ? returnsNormally : throws;

  group('supported', () {
    test('supported', () {
      expect(Platform.supportsTypedData, true);
    });
  });

  group('arrays', () {
    test('createByLengthTest', () {
      expect(() {
        var a = new Float32List(10);
        expect(a.length, 10);
        expect(a.lengthInBytes, 40);
        expect(a[4], 0);
      }, expectation);
    });

    test('aliasTest', () {
      expect(() {
        var a1 = new Uint8List.fromList([0, 0, 1, 0x45]);
        var a2 = new Float32List.view(a1.buffer);

        expect(a1.lengthInBytes, a2.lengthInBytes);

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
      }, expectation);
    });

    // Generic type checking is not available in dart2js, so use this check to
    // see if we should check for it.
    var supportsTypeTest = !(new List<String>() is List<int>);

    if (supportsTypeTest) {
      test('typeTests', () {
        expect(() {
          var a = new Float32List(10);
          expect(a, isList);
          expect(a, isnumList);
          expect(a, isNot(isStringList));
        }, expectation);
      });
    }
  });
}
