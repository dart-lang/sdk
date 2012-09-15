// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('blob_test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('basic', () {
      var b = new Blob([]);
      expect(b.size, 0);
    });

  test('type1', () {
      var b = new Blob(['Harry'], type: 'text');
      expect(b.size, 5);
      expect(b.type, 'text');
    });

  test('endings1', () {
      var b = new Blob(['A\nB\n'], endings: 'transparent');
      expect(b.size, 4);
    });

  test('endings2', () {
      var b = new Blob(['A\nB\n'], endings: 'native');
      expect(b.size, (x) => x == 4 || x == 6);
    });

  test('twoStrings', () {
      var b = new Blob(['123', 'xyz'], type: 'text/plain;charset=UTF-8');
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
      var a = new Uint8Array(100).buffer; // i.e. new ArrayBuffer(100);
      var b = new Blob([a, a]);
      expect(b.size, 200);
    });
}
