// Copyright (c) 2013 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const whiteSpace = const [
  "",
  "\x09",
  "\x0a",
  "\x0b",
  "\x0c",
  "\x0d",
  "\x85",
  "\xa0",
  "\u1680",
  "\u180e",
  "\u2000",
  "\u2001",
  "\u2002",
  "\u2003",
  "\u2004",
  "\u2005",
  "\u2006",
  "\u2007",
  "\u2008",
  "\u2009",
  "\u200a",
  "\u2028",
  "\u2029",
  "\u202f",
  "\u205f",
  "\u3000",
  "\uFEFF"
];

void testParse(String source, num result) {
  for (String ws1 in whiteSpace) {
    for (String ws2 in whiteSpace) {
      String padded = "$ws1$source$ws2";
      // Use Expect.identical because it also handles NaN and 0.0/-0.0.
      // Except on dart2js: http://dartbug.com/11551
      Expect.identical(result, num.parse(padded), "parse '$padded'");
      padded = "$ws1$ws2$source";
      Expect.identical(result, num.parse(padded), "parse '$padded'");
      padded = "$source$ws1$ws2";
      Expect.identical(result, num.parse(padded), "parse '$padded'");
    }
  }
}

void testInt(int value) {
  testParse("$value", value);
  testParse("+$value", value);
  testParse("-$value", -value);
  testParse("0x${value.toRadixString(16)}", value);
  testParse("+0x${value.toRadixString(16)}", value);
  testParse("-0x${value.toRadixString(16)}", -value);
}

void testIntAround(int value) {
  testInt(value - 1);
  testInt(value);
  testInt(value + 1);
}

void testDouble(double value) {
  testParse("$value", value);
  testParse("+$value", value);
  testParse("-$value", -value);
  testParse("${value.toStringAsExponential()}", value);
  testParse("+${value.toStringAsExponential()}", value);
  testParse("-${value.toStringAsExponential()}", -value);
}

void main() {
  testInt(0);
  testInt(1);
  testInt(9);
  testInt(10);
  testInt(99);
  testInt(100);
  testIntAround(256);
  testIntAround(0x80000000);  // 2^31
  testIntAround(0x100000000);  // 2^32
  testIntAround(0x10000000000000);  // 2^52
  testIntAround(0x20000000000000);  // 2^53
  testIntAround(0x40000000000000);  // 2^54
  testIntAround(0x8000000000000000);  // 2^63
  testIntAround(0x10000000000000000);  // 2^64
  testIntAround(0x100000000000000000000);  // 2^80

  testDouble(0.0);
  testDouble(5e-324);
  testDouble(2.225073858507201e-308);
  testDouble(2.2250738585072014e-308);
  testDouble(0.49999999999999994);
  testDouble(0.5);
  testDouble(0.50000000000000006);
  testDouble(0.9999999999999999);
  testDouble(1.0);
  testDouble(1.0000000000000002);
  testDouble(4294967295.0);
  testDouble(4294967296.0);
  testDouble(4503599627370495.5);
  testDouble(4503599627370497.0);
  testDouble(9007199254740991.0);
  testDouble(9007199254740992.0);
  testDouble(1.7976931348623157e+308);
  testDouble(double.INFINITY);
  testDouble(double.NAN);          /// 01: ok
}
