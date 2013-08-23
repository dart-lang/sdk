// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

const UNICODE_REPLACEMENT_CHARACTER_RUNE = 0xFFFD;

void testTransform() {
  // Code point U+10FFFF is the largest code point supported by Dart.
  var controller = new StreamController(sync: true);
  controller.add([0xf0, 0x90, 0x80, 0x80]);  // U+10000
  controller.add([0xf4, 0x8f, 0xbf, 0xbf]);  // U+10FFFF
  controller.add([0xf4, 0x90, 0x80, 0x80]);  // U+110000
  controller.add([0xfa, 0x80, 0x80, 0x80, 0x80]);  //  U+2000000
  controller.add([0xfd, 0x80, 0x80, 0x80, 0x80, 0x80]);  // U+40000000
  controller.close();

  var decoder = new StringDecoder(Encoding.UTF_8);
  var stream = controller.stream.transform(decoder);
  stream.fold(
      new StringBuffer(),
      (b, e) {
        b.write(e);
        return b;
      })
      .then((b) => b.toString())
      .then((decoded) {
        Expect.equals(16, decoded.length);

        var replacementChar = UNICODE_REPLACEMENT_CHARACTER_RUNE;
        Expect.equals(0xd800, decoded.codeUnitAt(0));
        Expect.equals(0xdc00, decoded.codeUnitAt(1));
        Expect.equals(0xdbff, decoded.codeUnitAt(2));
        Expect.equals(0xdfff, decoded.codeUnitAt(3));
        for (int i = 4; i < 16; i++) {
          Expect.equals(replacementChar, decoded.codeUnitAt(i));
        }
      });
}

void testDecode() {
  // Code point U+10FFFF is the largest code point supported by Dart.
  var controller = new StreamController(sync: true);
  controller.add([0xf0, 0x90, 0x80, 0x80]);  // U+10000
  controller.add([0xf4, 0x8f, 0xbf, 0xbf]);  // U+10FFFF
  controller.add([0xf4, 0x90, 0x80, 0x80]);  // U+110000
  controller.add([0xfa, 0x80, 0x80, 0x80, 0x80]);  //  U+2000000
  controller.add([0xfd, 0x80, 0x80, 0x80, 0x80, 0x80]);  // U+40000000
  controller.close();

  StringDecoder.decode(controller.stream, Encoding.UTF_8)
               .then((decoded) {
    Expect.equals(16, decoded.length);

    var replacementChar = UNICODE_REPLACEMENT_CHARACTER_RUNE;
    Expect.equals(0xd800, decoded.codeUnitAt(0));
    Expect.equals(0xdc00, decoded.codeUnitAt(1));
    Expect.equals(0xdbff, decoded.codeUnitAt(2));
    Expect.equals(0xdfff, decoded.codeUnitAt(3));
    for (int i = 4; i < 16; i++) {
      Expect.equals(replacementChar, decoded.codeUnitAt(i));
     }
  });
}

void testInvalid() {
  void invalid(var bytes, var outputLength) {
    var controller = new StreamController(sync: true);
    controller.add(bytes);
    controller.close();
    controller.stream.transform(new StringDecoder()).listen((string) {
      Expect.equals(outputLength, string.length);
      for (var i = 0; i < outputLength; i++) {
        Expect.equals(UNICODE_REPLACEMENT_CHARACTER_RUNE,
                      string.codeUnitAt(i));
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
  testTransform();
  testDecode();
  testInvalid();
}
