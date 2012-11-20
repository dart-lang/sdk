// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SurrogatePairTest {

  static testMain() {
    var monkeyFace = "🐵";
    var aceOfSpades = "🂡";
    var gronthismata = "𝁅";
    var segno = "𝄋";

    Expect.equals(monkeyFace, monkeyFace.toUpperCase());
    Expect.equals(monkeyFace, monkeyFace.toLowerCase());
    Expect.equals(aceOfSpades, aceOfSpades.toUpperCase());
    Expect.equals(aceOfSpades, aceOfSpades.toLowerCase());
    Expect.equals(gronthismata, gronthismata.toUpperCase());
    Expect.equals(gronthismata, gronthismata.toLowerCase());
    Expect.equals(segno, segno.toUpperCase());
    Expect.equals(segno, segno.toLowerCase());

    var mixedMitt = new String.fromCharCodes([0x10423, 0x1042e, 0x1043b]);
    var upperMitt = new String.fromCharCodes([0x10423, 0x10406, 0x10413]);
    var lowerMitt = new String.fromCharCodes([0x1044b, 0x1042e, 0x1043b]);
    Expect.equals(upperMitt, mixedMitt.toUpperCase());
    Expect.equals(lowerMitt, mixedMitt.toLowerCase());
    Expect.equals(upperMitt, upperMitt.toUpperCase());
    Expect.equals(lowerMitt, upperMitt.toLowerCase());
    Expect.equals(upperMitt, lowerMitt.toUpperCase());
    Expect.equals(lowerMitt, lowerMitt.toLowerCase());

    var mixedXMitt = new String.fromCharCodes([0x78, 0x10423, 0x1042e, 0x1043b]);
    var upperXMitt = new String.fromCharCodes([0X58, 0x10423, 0x10406, 0x10413]);
    var lowerXMitt = new String.fromCharCodes([0x78, 0x1044b, 0x1042e, 0x1043b]);
    Expect.equals(upperXMitt, mixedXMitt.toUpperCase());
    Expect.equals(lowerXMitt, mixedXMitt.toLowerCase());
    Expect.equals(upperXMitt, upperXMitt.toUpperCase());
    Expect.equals(lowerXMitt, upperXMitt.toLowerCase());
    Expect.equals(upperXMitt, lowerXMitt.toUpperCase());
    Expect.equals(lowerXMitt, lowerXMitt.toLowerCase());

    var mixedDotMitt = new String.fromCharCodes([0x2e, 0x10423, 0x1042e, 0x1043b]);
    var upperDotMitt = new String.fromCharCodes([0X2e, 0x10423, 0x10406, 0x10413]);
    var lowerDotMitt = new String.fromCharCodes([0x2e, 0x1044b, 0x1042e, 0x1043b]);
    Expect.equals(upperDotMitt, mixedDotMitt.toUpperCase());
    Expect.equals(lowerDotMitt, mixedDotMitt.toLowerCase());
    Expect.equals(upperDotMitt, upperDotMitt.toUpperCase());
    Expect.equals(lowerDotMitt, upperDotMitt.toLowerCase());
    Expect.equals(upperDotMitt, lowerDotMitt.toUpperCase());
    Expect.equals(lowerDotMitt, lowerDotMitt.toLowerCase());

    var lowerOw = new String.fromCharCodes([0x10435]);
    var upperOw = new String.fromCharCodes([0x1040d]);
    Expect.equals(lowerOw.codeUnitAt(1), monkeyFace.codeUnitAt(1));
    Expect.equals(upperOw, lowerOw.toUpperCase());
    Expect.equals(upperOw, upperOw.toUpperCase());
    Expect.equals(lowerOw, lowerOw.toLowerCase());
    Expect.equals(lowerOw, upperOw.toLowerCase());
  }
}

main() {
  SurrogatePairTest.testMain();
}
