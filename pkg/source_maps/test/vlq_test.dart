// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.vlq_test;

import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:source_maps/src/vlq.dart';

main() {
  test('encode and decode - simple values', () {
    expect(encodeVlq(1).join(''), 'C');
    expect(encodeVlq(2).join(''), 'E');
    expect(encodeVlq(3).join(''), 'G');
    expect(encodeVlq(100).join(''), 'oG');
    expect(decodeVlq('C'.split('').iterator), 1);
    expect(decodeVlq('E'.split('').iterator), 2);
    expect(decodeVlq('G'.split('').iterator), 3);
    expect(decodeVlq('oG'.split('').iterator), 100);
  });

  test('encode and decode', () {
    for (int i = -10000; i < 10000; i++) {
      _checkEncodeDecode(i);
    }
  });

  test('only 32-bit ints allowed', () {
    var max_int = pow(2, 31) - 1;
    var min_int = -pow(2, 31);
    _checkEncodeDecode(max_int - 1);
    _checkEncodeDecode(min_int + 1);
    _checkEncodeDecode(max_int);
    _checkEncodeDecode(min_int);

    expect(encodeVlq(min_int).join(''), 'hgggggE');
    expect(decodeVlq('hgggggE'.split('').iterator), min_int);

    expect(() => encodeVlq(max_int + 1), throws);
    expect(() => encodeVlq(max_int + 2), throws);
    expect(() => encodeVlq(min_int - 1), throws);
    expect(() => encodeVlq(min_int - 2), throws);


    // if we allowed more than 32 bits, these would be the expected encodings
    // for the large numbers above.
    expect(() => decodeVlq('ggggggE'.split('').iterator), throws);
    expect(() => decodeVlq('igggggE'.split('').iterator), throws);
    expect(() => decodeVlq('jgggggE'.split('').iterator), throws);
    expect(() => decodeVlq('lgggggE'.split('').iterator), throws);
  });
}

_checkEncodeDecode(int value) {
  var encoded = encodeVlq(value);
  expect(decodeVlq(encoded.iterator), value);
  expect(decodeVlq(encoded.join('').split('').iterator), value);
}
