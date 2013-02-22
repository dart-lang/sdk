// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_test;

import "dart:json";

bool badFormat(e) => e is FormatException;

void testJson(json, expected) {
  var value = parse(json);
  compare(expected, actual, path) {
    if (expected is List) {
      Expect.isTrue(actual is List);
      Expect.equals(expected.length, actual.length, "$path: List length");
      for (int i = 0; i < expected.length; i++) {
        compare(expected[i], actual[i], "$path[$i]");
      }
    } else if (expected is Map) {
      Expect.isTrue(actual is Map);
      Expect.equals(expected.length, actual.length, "$path: Map size");
      expected.forEach((key, value) {
        Expect.isTrue(actual.containsKey(key));
        compare(value, actual[key], "$path[$key]");
      });
    } else if (expected is num) {
      Expect.equals(expected is int, actual is int, "$path: same number type");
      Expect.isTrue(expected.compareTo(actual) == 0,
                    "$path: $expected vs. $actual");
    } else {
      // String, bool, null.
      Expect.equals(expected, actual, path);
    }
  }
  compare(expected, value, "value");
}

void testThrows(json) {
  Expect.throws(() => parse(json), badFormat);
}

testNumbers() {
  // Positive tests for number formats.
  var integerList = ["0","9","9999"];
  var signList = ["", "-"];
  var fractionList = ["", ".0", ".1", ".99999"];
  var exponentList = [""];
  for (var exphead in ["e", "E", "e-", "E-", "e+", "E+"]) {
    for (var expval in ["0", "1", "200"]) {
      exponentList.add("$exphead$expval");
    }
  }

  for (var integer in integerList) {
    for (var sign in signList) {
      for (var fraction in fractionList) {
        for (var exp in exponentList) {
          var literal = "$sign$integer$fraction$exp";
          var parseNumber =
              ((fraction == "" && exp == "") ? (String x) => int.parse(x)
                                             : (String x) => double.parse(x));
          var expectedValue = parseNumber(literal);
          testJson(literal, expectedValue);
        }
      }
    }
  }

  // Negative tests (syntax error).
  // testError thoroughly tests the given parts with a lot of valid
  // values for the other parts.
  testError({signs, integers, fractions, exponents}) {
    def(value, defaultValue) {
      if (value == null) return defaultValue;
      if (value is List) return value;
      return [value];
    }
    signs = def(signs, signList);
    integers = def(integers, integerList);
    fractions = def(fractions, fractionList);
    exponents = def(exponents, exponentList);
    for (var integer in integers) {
      for (var sign in signs) {
        for (var fraction in fractions) {
          for (var exponent in exponents) {
            var literal = "$sign$integer$fraction$exponent";
            testThrows(literal);
          }
        }
      }
    }
  }
  // Doubles overflow to Infinity.
  testJson("1e+400", double.INFINITY);
  // (Integers do not, but we don't have those on dart2js).

  // Integer part cannot be omitted:
  testError(integers: "");
  // Initial zero only allowed for zero integer part.
  testError(integers: ["00", "01"]);
  // Only minus allowed as sign.
  testError(signs: "+");
  // Requires digits after decimal point.
  testError(fractions: ".");
  // Requires exponent digts, and only digits.
  testError(exponents: ["e", "e+", "e-", "e.0"]);

  // No whitespace inside numbers.
  testThrows("- 2.2e+2");
  testThrows("-2 .2e+2");
  testThrows("-2. 2e+2");
  testThrows("-2.2 e+2");
  testThrows("-2.2e +2");
  testThrows("-2.2e+ 2");

  testThrows("[2.,2]");
  testThrows("{2.:2}");
}

testStrings() {
  // String parser accepts and understands escapes.
  var input = r'"\u0000\uffff\n\r\f\t\b\/\\\"' '\x20\ufffd\uffff"';
  var expected = "\u0000\uffff\n\r\f\t\b\/\\\"\x20\ufffd\uffff";
  testJson(input, expected);
  // Empty string.
  testJson(r'""', "");
  // Escape first.
  testJson(r'"\"........"', "\"........");
  // Escape last.
  testJson(r'"........\""', "........\"");
  // Escape middle.
  testJson(r'"....\"...."', "....\"....");

  // Does not accept single quotes.
  testThrows(r"''");
  // Throws on unterminated strings.
  testThrows(r'"......\"');
  // Throws on unterminated escapes.
  testThrows(r'"\');  // ' is not escaped.
  testThrows(r'"\a"');
  testThrows(r'"\u"');
  testThrows(r'"\u1"');
  testThrows(r'"\u12"');
  testThrows(r'"\u123"');
  testThrows(r'"\ux"');
  testThrows(r'"\u1x"');
  testThrows(r'"\u12x"');
  testThrows(r'"\u123x"');
  // Throws on bad escapes.
  testThrows(r'"\a"');
  testThrows(r'"\x00"');
  testThrows(r'"\c2"');
  testThrows(r'"\000"');
  testThrows(r'"\u{0}"');
  testThrows(r'"\%"');
  testThrows('"\\\x00"'); // Not raw string!
  // Throws on control characters.
  for (int i = 0; i < 32; i++) {
    var string = new String.fromCharCodes([0x22,i,0x22]); // '"\x00"' etc.
    testThrows(string);
  }
}


testObjects() {
  testJson(r'{}', {});
  testJson(r'{"x":42}', {"x":42});
  testJson(r'{"x":{"x":{"x":42}}}', {"x": {"x": {"x": 42}}});
  testJson(r'{"x":10,"x":42}', {"x": 42});
  testJson(r'{"":42}', {"": 42});

  // Keys must be strings.
  testThrows(r'{x:10}');
  testThrows(r'{true:10}');
  testThrows(r'{false:10}');
  testThrows(r'{null:10}');
  testThrows(r'{42:10}');
  testThrows(r'{42e1:10}');
  testThrows(r'{-42:10}');
  testThrows(r'{["text"]:10}');
  testThrows(r'{:10}');
}

testArrays() {
  testJson(r'[]', []);
  testJson(r'[1.1e1,"string",true,false,null,{}]',
           [1.1e1, "string", true, false, null, {}]);
  testJson(r'[[[[[[]]]],[[[]]],[[]]]]', [[[[[[]]]],[[[]]],[[]]]]);
  testJson(r'[{},[{}],{"x":[]}]', [{},[{}],{"x":[]}]);

  testThrows(r'[1,,2]');
  testThrows(r'[1,2,]');
  testThrows(r'[,2]');
}

testWords() {
  testJson(r'true', true);
  testJson(r'false', false);
  testJson(r'null', null);
  testJson(r'[true]', [true]);
  testJson(r'{"true":true}', {"true": true});

  testThrows(r'truefalse');
  testThrows(r'trues');
  testThrows(r'nulll');
  testThrows(r'full');
  testThrows(r'nul');
  testThrows(r'tru');
  testThrows(r'fals');
  testThrows(r'\null');
  testThrows(r't\rue');
  testThrows(r't\rue');
}

testWhitespace() {
  // Valid white-space characters.
  var v = '\t\r\n\ ';
  // Invalid white-space and non-recognized characters.
  var invalids = ['\x00', '\f', '\x08', '\\', '\xa0','\u2028', '\u2029'];

  // Valid whitespace accepted "everywhere".
  testJson('$v[${v}-2.2e2$v,$v{$v"key"$v:${v}true$v}$v,$v"ab"$v]$v',
           [-2.2e2, {"key": true}, "ab"]);

  for (var i in invalids) {
    testThrows('${i}"s"');
    testThrows('"s"${i}');
    testThrows('42${i}');
    testThrows('$i[]');
    testThrows('[$i]');
    testThrows('[$i"s"]');
    testThrows('["s"$i]');
    testThrows('[]$i');
    testThrows('$i{"k":"v"}');
    testThrows('{$i"k":"v"}');
    testThrows('{"k"$i:"v"}');
    testThrows('{"k":$i"v"}');
    testThrows('{"k":"v"$i}');
    testThrows('{"k":"v"}$i');
  }
}

main() {
  testNumbers();
  testStrings();
  testWords();
  testObjects();
  testArrays();
  testWhitespace();
}
