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

void expectNumEquals(num expect, num actual, String message) {
  if (expect is double && expect.isNaN) {
    Expect.isTrue(actual is double && actual.isNaN, "isNaN: $message");
  } else {
    Expect.identical(expect, actual, message);
  }
}

// Test source surrounded by any combination of whitespace.
void testParseAllWhitespace(String source, num result) {
  for (String ws1 in whiteSpace) {
    for (String ws2 in whiteSpace) {
      String padded = "$ws1$source$ws2";
      // Use Expect.identical because it also handles NaN and 0.0/-0.0.
      // Except on dart2js: http://dartbug.com/11551
      expectNumEquals(result, num.parse(padded), "parse '$padded'");
      padded = "$ws1$ws2$source";
      expectNumEquals(result, num.parse(padded), "parse '$padded'");
      padded = "$source$ws1$ws2";
      expectNumEquals(result, num.parse(padded), "parse '$padded'");
    }
  }
}

// Test source and -source surrounded by any combination of whitespace.
void testParseWhitespace(String source, num result) {
  assert(result >= 0);
  testParseAllWhitespace(source, result);
  testParseAllWhitespace("-$source", -result);
}

// Test parsing source, optionally preceeded and/or followed by whitespace.
void testParse(String source, num result) {
  expectNumEquals(result, num.parse(source), "parse '$source'");
  expectNumEquals(result, num.parse(" $source"), "parse ' $source'");
  expectNumEquals(result, num.parse("$source "), "parse '$source '");
  expectNumEquals(result, num.parse(" $source "), "parse ' $source '");
}

// Test parsing an integer in decimal or hex format, with or without signs.
void testInt(int value) {
  testParse("$value", value);
  testParse("+$value", value);
  testParse("-$value", -value);
  var hex = "0x${value.toRadixString(16)}";
  var lchex = hex.toLowerCase();
  testParse(lchex, value);
  testParse("+$lchex", value);
  testParse("-$lchex", -value);
  var uchex = hex.toUpperCase();
  testParse(uchex, value);
  testParse("+$uchex", value);
  testParse("-$uchex", -value);
}

// Test parsing an integer, and the integers just around it.
void testIntAround(int value) {
  testInt(value - 1);
  testInt(value);
  testInt(value + 1);
}

void testDouble(double value) {
  testParse("$value", value);
  testParse("+$value", value);
  testParse("-$value", -value);
  if (value.isFinite) {
    String exp = value.toStringAsExponential();
    String lcexp = exp.toLowerCase();
    testParse(lcexp, value);
    testParse("+$lcexp", value);
    testParse("-$lcexp", -value);
    String ucexp = exp.toUpperCase();
    testParse(ucexp, value);
    testParse("+$ucexp", value);
    testParse("-$ucexp", -value);
  }
}

void testFail(String source) {
  var object = new Object();
  Expect.throws(() {
    num.parse(source, (s) {
      Expect.equals(source, s);
      throw object;
    });
  }, (e) => identical(object, e), "Fail: '$source'");
}

void main() {
  testInt(0);
  testInt(1);
  testInt(9);
  testInt(10);
  testInt(99);
  testInt(100);
  testIntAround(256);
  testIntAround(0x80000000); // 2^31
  testIntAround(0x100000000); // 2^32
  testIntAround(0x10000000000000); // 2^52
  testIntAround(0x20000000000000); // 2^53
  testIntAround(0x40000000000000); // 2^54
  testIntAround(0x8000000000000000); // 2^63
  testIntAround(0x10000000000000000); // 2^64
  testIntAround(0x100000000000000000000); // 2^80

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
  testDouble(double.infinity);
  testDouble(double.nan); //         //# 01: ok

  // Strings that cannot occur from toString of a number.
  testParse("000000000000", 0);
  testParse("000000000001", 1);
  testParse("000000000000.0000000000000", 0.0);
  testParse("000000000001.0000000000000", 1.0);
  testParse("0x0000000000", 0);
  testParse("0e0", 0.0);
  testParse("0e+0", 0.0);
  testParse("0e-0", 0.0);
  testParse("-0e0", -0.0);
  testParse("-0e+0", -0.0);
  testParse("-0e-0", -0.0);
  testParse("1e0", 1.0);
  testParse("1e+0", 1.0);
  testParse("1e-0", 1.0);
  testParse("-1e0", -1.0);
  testParse("-1e+0", -1.0);
  testParse("-1e-0", -1.0);
  testParse("1.", 1.0);
  testParse(".1", 0.1);
  testParse("1.e1", 10.0);
  testParse(".1e1", 1.0);

  testParseWhitespace("0x1", 1);
  testParseWhitespace("1", 1);
  testParseWhitespace("1.0", 1.0);
  testParseWhitespace("1e1", 10.0);
  testParseWhitespace(".1e1", 1.0);
  testParseWhitespace("1.e1", 10.0);
  testParseWhitespace("1e+1", 10.0);
  testParseWhitespace("1e-1", 0.1);

  // Negative tests - things not to allow.

  // Spaces inside the numeral.
  testFail("- 1");
  testFail("+ 1");
  testFail("2 2");
  testFail("0x 42");
  testFail("1 .");
  testFail(". 1");
  testFail("1e 2");
  testFail("1 e2");
  // Invalid characters.
  testFail("0x1H");
  testFail("12H");
  testFail("1x2");
  testFail("00x2");
  testFail("0x2.2");
  // Empty hex number.
  testFail("0x");
  testFail("-0x");
  testFail("+0x");
  // Double exponent without value.
  testFail(".e1");
  testFail("e1");
  testFail("e+1");
  testFail("e-1");
  testFail("-e1");
  testFail("-e+1");
  testFail("-e-1");
  // Incorrect ways to write NaN/Infinity.
  testFail("infinity");
  testFail("INFINITY");
  testFail("1.#INF");
  testFail("inf");
  testFail("nan");
  testFail("NAN");
  testFail("1.#IND");
  testFail("indef");
  testFail("qnan");
  testFail("snan");
}
