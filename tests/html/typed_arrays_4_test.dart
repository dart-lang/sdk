// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TypedArrays4Test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

main() {
  useHtmlConfiguration();

  // Only perform tests if ArrayBuffer is supported.
  if (!Platform.supportsTypedData) {
    return;
  }

  test('indexOf_dynamic', () {
    var a1 = new Uint8List(1024);
    for (int i = 0; i < a1.length; i++) {
      a1[i] = i;
    }

    expect(a1.indexOf(50), 50);
    expect(a1.indexOf(50, 50), 50);
    expect(a1.indexOf(50, 51), 256 + 50);

    expect(a1.lastIndexOf(50), 768 + 50);
    expect(a1.lastIndexOf(50, 768 + 50), 768 + 50);
    expect(a1.lastIndexOf(50, 768 + 50 - 1), 512 + 50);
  });

  test('indexOf_typed', () {
    Uint8List a1 = new Uint8List(1024);
    for (int i = 0; i < a1.length; i++) {
      a1[i] = i;
    }

    expect(a1.indexOf(50), 50);
    expect(a1.indexOf(50, 50), 50);
    expect(a1.indexOf(50, 51), 256 + 50);

    expect(a1.lastIndexOf(50), 768 + 50);
    expect(a1.lastIndexOf(50, 768 + 50), 768 + 50);
    expect(a1.lastIndexOf(50, 768 + 50 - 1), 512 + 50);
  });
}
