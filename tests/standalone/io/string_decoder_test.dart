// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void test() {
  // Code point U+10FFFF is the largest code point supported by Dart.
  //var decoder = _StringDecoders.decoder(Encoding.UTF_8);
  ListInputStream lis = new ListInputStream();
  lis.write([0xf0, 0x90, 0x80, 0x80]);  // U+10000
  lis.write([0xf4, 0x8f, 0xbf, 0xbf]);  // U+10FFFF
  lis.write([0xf4, 0x90, 0x80, 0x80]);  // U+110000
  lis.write([0xfa, 0x80, 0x80, 0x80, 0x80]);  //  U+2000000
  lis.write([0xfd, 0x80, 0x80, 0x80, 0x80, 0x80]);  // U+40000000
  lis.markEndOfStream();

  var sis = new StringInputStream(lis);
  sis.onData = () {
    var decoded = sis.read();
    Expect.equals(7, decoded.length);

    var replacementChar = '?'.charCodeAt(0);
    Expect.equals(0xd800, decoded.charCodeAt(0));
    Expect.equals(0xdc00, decoded.charCodeAt(1));
    Expect.equals(0xdbff, decoded.charCodeAt(2));
    Expect.equals(0xdfff, decoded.charCodeAt(3));
    Expect.equals(replacementChar, decoded.charCodeAt(4));
    Expect.equals(replacementChar, decoded.charCodeAt(5));
    Expect.equals(replacementChar, decoded.charCodeAt(6));
  };
}

void testInvalid() {
  void invalid(var bytes) {
    ListInputStream lis = new ListInputStream();
    lis.write(bytes);
    lis.markEndOfStream();
    var sis = new StringInputStream(lis);
    sis.onData = () { throw "onData not expected"; };
    sis.onError = (e) { Expect.isTrue(e is DecoderException); };
    sis.onClosed = () { throw "onClosed not expected"; };
  }

  invalid([0x80]);
  invalid([0xff]);
  invalid([0xf0, 0xc0]);
}

void main() {
  test();
  testInvalid();
}
