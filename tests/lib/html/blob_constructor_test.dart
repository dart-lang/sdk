// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:typed_data';

import 'package:expect/minitest.dart';

main() {
  test('basic', () {
    var b = new Blob([]);
    expect(b.size, 0);
  });

  test('type1', () {
    // OPTIONALS var b = new Blob(['Harry'], type: 'text');
    var b = new Blob(['Harry'], 'text');
    expect(b.size, 5);
    expect(b.type, 'text');
  });

  test('endings1', () {
    // OPTIONALS var b = new Blob(['A\nB\n'], endings: 'transparent');
    var b = new Blob(['A\nB\n'], null, 'transparent');
    expect(b.size, 4);
  });

  test('endings2', () {
    // OPTIONALS var b = new Blob(['A\nB\n'], endings: 'native');
    var b = new Blob(['A\nB\n'], null, 'native');
    expect(b.size, predicate((x) => x == 4 || x == 6),
        reason: "b.size should be 4 or 6");
  });

  test('twoStrings', () {
    // OPTIONALS var b = new Blob(['123', 'xyz'], type: 'text/plain;charset=UTF-8');
    var b = new Blob(['123', 'xyz'], 'text/plain;charset=UTF-8');
    expect(b.size, 6);
  });

  test('fromBlob1', () {
    var b1 = new Blob([]);
    var b2 = new Blob([b1]);
    expect(b2.size, 0);
  });

  test('fromBlob2', () {
    var b1 = new Blob(['x']);
    var b2 = new Blob([b1, b1]);
    expect(b1.size, 1);
    expect(b2.size, 2);
  });

  test('fromArrayBuffer', () {
    var a = new Uint8List(100).buffer; // i.e. new ArrayBuffer(100);
    var b = new Blob([a, a]);
    expect(b.size, 200);
  });
}
