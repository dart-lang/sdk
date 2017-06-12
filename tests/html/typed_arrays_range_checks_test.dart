// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TypedArraysRangeCheckTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

const N = 1024;

class _TestList {
  _TestList(int n);

  operator [](int i) => i;
  operator []=(int i, v) {}
}

_obfuscatedList() {
  var a = new Uint8List(N);
  var b = new _TestList(N);
  var k = 0;
  for (int i = 0; i < 10; ++i) {
    k += i;
  }
  return (k == 45) ? a : b;
}

main() {
  useHtmlConfiguration();

  // Only perform tests if ArrayBuffer is supported.
  if (!Platform.supportsTypedData) {
    return;
  }

  test('outOfRangeAccess_dynamic', () {
    var a = _obfuscatedList();

    expect(() => a[a.length], throws);
    expect(() => a[a.length + 1], throws);
    expect(() => a[a.length + N], throws);

    expect(() => a[-1], throws);
    expect(() => a[1.5], throws);
    expect(() => a['length'], throws);

    expect(() => a[a.length] = 0xdeadbeef, throws);
    expect(() => a[a.length + 1] = 0xdeadbeef, throws);
    expect(() => a[a.length + N] = 0xdeadbeef, throws);

    expect(() => a[-1] = 0xdeadbeef, throws);
    expect(() => a[1.5] = 0xdeadbeef, throws);
    expect(() => a['length'] = 1, throws);
  });

  test('outOfRange_typed', () {
    Uint8List a = new Uint8List(N);

    expect(() => a[a.length], throws);
    expect(() => a[a.length + 1], throws);
    expect(() => a[a.length + N], throws);

    expect(() => a[-1], throws);
    expect(() => a[1.5], throws);
    expect(() => a['length'], throws);

    expect(() => a[a.length] = 0xdeadbeef, throws);
    expect(() => a[a.length + 1] = 0xdeadbeef, throws);
    expect(() => a[a.length + N] = 0xdeadbeef, throws);

    expect(() => a[-1] = 0xdeadbeef, throws);
    expect(() => a[1.5] = 0xdeadbeef, throws);
    expect(() => a['length'] = 1, throws);
  });
}
