// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('TypedArrays4Test');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('indexOf_dynamic', () {
      var a1 = new Uint8Array(1024);
      for (int i = 0; i < a1.length; i++) {
        a1[i] = i;
      }

      Expect.equals(50, a1.indexOf(50));
      Expect.equals(50, a1.indexOf(50, 50));
      Expect.equals(256 + 50, a1.indexOf(50, 51));

      Expect.equals(768 + 50, a1.lastIndexOf(50));
      Expect.equals(768 + 50, a1.lastIndexOf(50, 768 + 50));
      Expect.equals(512 + 50, a1.lastIndexOf(50, 768 + 50 - 1));
  });

  test('indexOf_typed', () {
      Uint8Array a1 = new Uint8Array(1024);
      for (int i = 0; i < a1.length; i++) {
        a1[i] = i;
      }

      Expect.equals(50, a1.indexOf(50));
      Expect.equals(50, a1.indexOf(50, 50));
      Expect.equals(256 + 50, a1.indexOf(50, 51));

      Expect.equals(768 + 50, a1.lastIndexOf(50));
      Expect.equals(768 + 50, a1.lastIndexOf(50, 768 + 50));
      Expect.equals(512 + 50, a1.lastIndexOf(50, 768 + 50 - 1));
  });
}
