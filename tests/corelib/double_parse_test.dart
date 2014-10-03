// Copyright (c) 2014 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math" show pow;
import "package:expect/expect.dart";

const whiteSpace = const [
  "",
  "\x09",
  "\x0a",
  "\x0b",
  "\x0c",
  "\x0d",
  "\x85",    /// 01: ok
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

void expectNumEquals(double expect, var actual, String message) {
  if (expect.isNaN) {
    Expect.isTrue(actual is double && actual.isNaN, "isNaN: $message");
  } else {
    Expect.identical(expect, actual, message);
  }
}

// Test source surrounded by any combination of whitespace.
void testParseAllWhitespace(String source, double result) {
  for (String ws1 in whiteSpace) {
    for (String ws2 in whiteSpace) {
      String padded = "$ws1$source$ws2";
      // Use Expect.identical because it also handles NaN and 0.0/-0.0.
      // Except on dart2js: http://dartbug.com/11551
      expectNumEquals(result, double.parse(padded), "parse '$padded'");
      padded = "$ws1$ws2$source";
      expectNumEquals(result, double.parse(padded), "parse '$padded'");
      padded = "$source$ws1$ws2";
      expectNumEquals(result, double.parse(padded), "parse '$padded'");
    }
  }
}

// Test source and -source surrounded by any combination of whitespace.
void testParseWhitespace(String source, double result) {
  assert(result >= 0);
  testParseAllWhitespace(source, result);
  testParseAllWhitespace("-$source", -result);
}

// Test parsing source, optionally preceeded and/or followed by whitespace.
void testParse(String source, double result, [name = ""]) {
  expectNumEquals(result, double.parse(source), "parse '$source:$name");
  expectNumEquals(result, double.parse(" $source"),
                  "parse ' $source':$name");
  expectNumEquals(result, double.parse("$source "),
                  "parse '$source ':$name");
  expectNumEquals(result, double.parse(" $source "),
                  "parse ' $source ':$name");

  expectNumEquals(result, double.parse("+$source"),
                  "parse '+$source:$name");
  expectNumEquals(result, double.parse(" +$source"),
                  "parse ' +$source':$name");
  expectNumEquals(result, double.parse("+$source "),
                  "parse '+$source ':$name");
  expectNumEquals(result, double.parse(" +$source "),
                  "parse ' +$source ':$name");

  expectNumEquals(-result, double.parse("-$source"),
                  "parse '-$source:$name");
  expectNumEquals(-result, double.parse(" -$source"),
                  "parse ' -$source':$name");
  expectNumEquals(-result, double.parse("-$source "),
                  "parse '-$source ':$name");
  expectNumEquals(-result, double.parse(" -$source "),
                  "parse ' -$source ':$name");
}

void testDouble(double value) {
  testParse("$value", value);
  if (value.isFinite) {
    String exp = value.toStringAsExponential();
    String lcexp = exp.toLowerCase();
    testParse(lcexp, value);
    String ucexp = exp.toUpperCase();
    testParse(ucexp, value);
  }
}

void testFail(String source) {
  var object = new Object();
  Expect.throws(() {
    double.parse(source, (s) {
      Expect.equals(source, s);
      throw object;
    });
  }, (e) => identical(object, e), "Fail: '$source'");
}

void main() {
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
  testDouble(double.NAN);

  // Strings that cannot occur from toString of a number.
  testParse("000000000000", 0.0);
  testParse("000000000001", 1.0);
  testParse("000000000000.0000000000000", 0.0);
  testParse("000000000001.0000000000000", 1.0);
  testParse("0e0", 0.0);
  testParse("0e+0", 0.0);
  testParse("0e-0", 0.0);
  testParse("1e0", 1.0);
  testParse("1e+0", 1.0);
  testParse("1e-0", 1.0);
  testParse("1.", 1.0);
  testParse(".1", 0.1);
  testParse("1.e1", 10.0);
  testParse(".1e1", 1.0);
  testParse("Infinity", double.INFINITY);
  testParse("NaN", double.NAN);

  // Cases where mantissa and 10^exponent are representable as a double.
  for (int i = -22; i <= 22; i++) {
    for (double j in [1.0, 9007199254740991.0, 9007199254740992.0]) {
      var value = (i >= 0) ? j * pow(10.0, i) : j / pow(10.0, -i);
      testParse("${j}e$i", value, "$i/$j");
      testParse("${j}E$i", value, "$i/$j");
      if (i >= 0) {
        testParse("${j}e+$i", value, "$i/$j");
        testParse("${j}E+$i", value, "$i/$j");
      }
    }
  }
  for (int i = 0; i <= 22; i++) {
    var digits = "9007199254740991";
    for (int i = 0; i < digits.length; i++) {
      int dotIndex = digits.length - i;
      var string = "${digits.substring(0, dotIndex)}."
                   "${digits.substring(dotIndex)}e$i";
      testParse(string, 9007199254740991.0);
    }
  }

  testParse("9007199254740993", 9007199254740992.0);
  testParse("9.007199254740993e15", 9007199254740992.0);
  testParse("0.00000009007199254740991e23", 9007199254740991.0);

  testParse("0.000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000004940656458412465441765687"
            "92868221372365059802614324764425585682500675507270"
            "20875186529983636163599237979656469544571773092665"
            "67103559397963987747960107818781263007131903114045"
            "27845817167848982103688718636056998730723050006387"
            "40915356498438731247339727316961514003171538539807"
            "41262385655911710266585566867681870395603106249319"
            "45271591492455329305456544401127480129709999541931"
            "98940908041656332452475714786901472678015935523861"
            "15501348035264934720193790268107107491703332226844"
            "75333572083243193609238289345836806010601150616980"
            "97530783422773183292479049825247307763759272478746"
            "56084778203734469699533647017972677717585125660551"
            "19913150489110145103786273816725095583738973359899"
            "36648099411642057026370902792427675445652290875386"
            "82506419718265533447265625", 5e-324);

  testParse("0.000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000002470328229206232720882843"
            "96434110686182529901307162382212792841250337753635"
            "10437593264991818081799618989828234772285886546332"
            "83551779698981993873980053909390631503565951557022"
            "63922908583924491051844359318028499365361525003193"
            "70457678249219365623669863658480757001585769269903"
            "70631192827955855133292783433840935197801553124659"
            "72635795746227664652728272200563740064854999770965"
            "99470454020828166226237857393450736339007967761930"
            "57750674017632467360096895134053553745851666113422"
            "37666786041621596804619144672918403005300575308490"
            "48765391711386591646239524912623653881879636239373"
            "28042389101867234849766823508986338858792562830275"
            "59956575244555072551893136908362547791869486679949"
            "68324049705821028513185451396213837722826145437693"
            "412532098591327667236328126", 5e-324);

  testParse("0.000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000000000000000000000000000000"
            "00000000000000000000000002470328229206232720882843"
            "96434110686182529901307162382212792841250337753635"
            "10437593264991818081799618989828234772285886546332"
            "83551779698981993873980053909390631503565951557022"
            "63922908583924491051844359318028499365361525003193"
            "70457678249219365623669863658480757001585769269903"
            "70631192827955855133292783433840935197801553124659"
            "72635795746227664652728272200563740064854999770965"
            "99470454020828166226237857393450736339007967761930"
            "57750674017632467360096895134053553745851666113422"
            "37666786041621596804619144672918403005300575308490"
            "48765391711386591646239524912623653881879636239373"
            "28042389101867234849766823508986338858792562830275"
            "59956575244555072551893136908362547791869486679949"
            "68324049705821028513185451396213837722826145437693"
            "412532098591327667236328125", 0.0);

  testParse("0.0000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "00022250738585072011", 2.225073858507201e-308);

  testParse("0.0000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000"
            "00022250738585072012", 2.2250738585072014e-308);

  testParse("0.49999999999999994", 0.49999999999999994);
  testParse("0.49999999999999997219", 0.49999999999999994);
  testParse("0.49999999999999999", 0.5);

  // Edge cases of algorithm (e+-22/23).
  testParse("1e22", 1e22);
  testParse("1e23", 1e23);
  testParse("1e-22", 1e-22);
  testParse("1e-23", 1e-23);

  testParseWhitespace("1", 1.0);
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
  testFail("1 .");
  testFail(". 1");
  testFail("1e 2");
  testFail("1 e2");
  // Invalid characters.
  testFail("0x0");
  testFail("0x1H");
  testFail("12H");
  testFail("1x2");
  testFail("00x2");
  testFail("0x2.2");
  // Double exponent without value.
  testFail(".e1");
  testFail("e1");
  testFail("e+1");
  testFail("e-1");
  testFail("-e1");
  testFail("-e+1");
  testFail("-e-1");
  // Too many signs.
  testFail("--1");
  testFail("-+1");
  testFail("+-1");
  testFail("++1");
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
