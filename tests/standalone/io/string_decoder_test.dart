// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

void test() {
  // Code point U+10FFFF is the largest code point supported by Dart.
  var controller = new StreamController();
  controller.add([0xf0, 0x90, 0x80, 0x80]);  // U+10000
  controller.add([0xf4, 0x8f, 0xbf, 0xbf]);  // U+10FFFF
  controller.add([0xf4, 0x90, 0x80, 0x80]);  // U+110000
  controller.add([0xfa, 0x80, 0x80, 0x80, 0x80]);  //  U+2000000
  controller.add([0xfd, 0x80, 0x80, 0x80, 0x80, 0x80]);  // U+40000000
  controller.close();

  var decoder = new StringDecoder(Encoding.UTF_8, '?'.codeUnitAt(0));
  var stream = controller.stream.transform(decoder);
  stream.fold(
      new StringBuffer(),
      (b, e) {
        b.write(e);
        return b;
      })
      .then((b) => b.toString())
      .then((decoded) {
        Expect.equals(7, decoded.length);

        var replacementChar = '?'.codeUnitAt(0);
        Expect.equals(0xd800, decoded.codeUnitAt(0));
        Expect.equals(0xdc00, decoded.codeUnitAt(1));
        Expect.equals(0xdbff, decoded.codeUnitAt(2));
        Expect.equals(0xdfff, decoded.codeUnitAt(3));
        Expect.equals(replacementChar, decoded.codeUnitAt(4));
        Expect.equals(replacementChar, decoded.codeUnitAt(5));
        Expect.equals(replacementChar, decoded.codeUnitAt(6));
      });
}

void testInvalid() {
  void invalid(var bytes, var outputLength) {
    var controller = new StreamController();
    controller.add(bytes);
    controller.close();
    controller.stream.transform(new StringDecoder()).listen((string) {
      Expect.equals(outputLength, string.length);
      for (var i = 0; i < outputLength; i++) {
        Expect.equals(0xFFFD, string.codeUnitAt(i));
      }
    });
  }

  invalid([0x80], 1);
  invalid([0xff], 1);
  invalid([0xf0, 0xc0], 1);
  invalid([0xc0, 0x80], 1);
  invalid([0xfd, 0x80, 0x80], 3); // Unfinished encoding.
}

void main() {
  test();
  testInvalid();
}
