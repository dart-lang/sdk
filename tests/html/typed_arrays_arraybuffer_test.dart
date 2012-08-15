// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('typed_arrays_arraybuffer_test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('constructor', () {
      var a = new ArrayBuffer(100);
      expect(a.byteLength, 100);
  });

  test('slice1', () {
      var a = new ArrayBuffer(100);
      var s = a.slice(10, 40);
      expect(s.byteLength, 30);
  });

  test('slice2', () {
      var a = new ArrayBuffer(100);
      var s = a.slice(10, 400);
      expect(s.byteLength, 90);  // indexes clamped to valid range.
  });

  test('slice3', () {
      var a = new ArrayBuffer(100);
      var s = a.slice(50, 10);
      expect(s.byteLength, 0);   // end before start becomes empty range.
  });

  test('slice4', () {
      var a = new ArrayBuffer(100);
      var s = a.slice(-90, -30);
      expect(s.byteLength, 60);  // negative indexes measure from end.
  });
}
