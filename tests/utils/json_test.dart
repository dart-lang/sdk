// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsonTest;

import "package:expect/expect.dart";
import 'dart:json';

main() {
  testEscaping();
  testParse();
  testParseInvalid();
}

void testParse() {
  // Scalars.
  Expect.equals(5, parse(' 5 '));
  Expect.equals(-42, parse(' -42 '));
  Expect.equals(3, parse(' 3e0 '));
  Expect.equals(3.14, parse(' 3.14 '));
  Expect.equals(1.0E-06, parse(' 1.0E-06 '));
  Expect.equals(0, parse("0"));
  Expect.equals(1, parse("1"));
  Expect.equals(0.1, parse("0.1"));
  Expect.equals(1.1, parse("1.1"));
  Expect.equals(1.1, parse("1.100000"));
  Expect.equals(1.111111, parse("1.111111"));
  Expect.equals(-0, parse("-0"));
  Expect.equals(-1, parse("-1"));
  Expect.equals(-0.1, parse("-0.1"));
  Expect.equals(-1.1, parse("-1.1"));
  Expect.equals(-1.1, parse("-1.100000"));
  Expect.equals(-1.111111, parse("-1.111111"));
  Expect.equals(11, parse("1.1e1"));
  Expect.equals(11, parse("1.1e+1"));
  Expect.equals(0.11, parse("1.1e-1"));
  Expect.equals(11, parse("1.1E1"));
  Expect.equals(11, parse("1.1E+1"));
  Expect.equals(0.11, parse("1.1E-1"));
  Expect.equals(1E0, parse(" 1E0"));
  Expect.equals(1E+0, parse(" 1E+0"));
  Expect.equals(1E-0, parse(" 1E-0"));
  Expect.equals(1E00, parse(" 1E00"));
  Expect.equals(1E+00, parse(" 1E+00"));
  Expect.equals(1E-00, parse(" 1E-00"));
  Expect.equals(1E+10, parse(" 1E+10"));
  Expect.equals(1E+010, parse(" 1E+010"));
  Expect.equals(1E+0010, parse(" 1E+0010"));
  Expect.equals(1E10, parse(" 1E10"));
  Expect.equals(1E010, parse(" 1E010"));
  Expect.equals(1E0010, parse(" 1E0010"));
  Expect.equals(1E-10, parse(" 1E-10"));
  Expect.equals(1E-0010, parse(" 1E-0010"));
  Expect.equals(1E0, parse(" 1e0"));
  Expect.equals(1E+0, parse(" 1e+0"));
  Expect.equals(1E-0, parse(" 1e-0"));
  Expect.equals(1E00, parse(" 1e00"));
  Expect.equals(1E+00, parse(" 1e+00"));
  Expect.equals(1E-00, parse(" 1e-00"));
  Expect.equals(1E+10, parse(" 1e+10"));
  Expect.equals(1E+010, parse(" 1e+010"));
  Expect.equals(1E+0010, parse(" 1e+0010"));
  Expect.equals(1E10, parse(" 1e10"));
  Expect.equals(1E010, parse(" 1e010"));
  Expect.equals(1E0010, parse(" 1e0010"));
  Expect.equals(1E-10, parse(" 1e-10"));
  Expect.equals(1E-0010, parse(" 1e-0010"));
  Expect.equals(true, parse(' true '));
  Expect.equals(false, parse(' false'));
  Expect.equals(null, parse(' null '));
  Expect.equals(null, parse('\n\rnull\t'));
  Expect.equals('hi there" bob', parse(' "hi there\\" bob" '));
  Expect.equals('', parse(' "" '));

  // Lists.
  Expect.listEquals([], parse(' [] '));
  Expect.listEquals(["entry"], parse(' ["entry"] '));
  Expect.listEquals([true, false], parse(' [true, false] '));
  Expect.listEquals([1, 2, 3], parse(' [ 1 , 2 , 3 ] '));

  // Maps.
  Expect.mapEquals({}, parse(' {} '));
  Expect.mapEquals({"key": "value"}, parse(' {"key": "value" } '));
  Expect.mapEquals({"key1": 1, "key2": 2},
                   parse(' {"key1": 1, "key2": 2} '));
  Expect.mapEquals({"key1": 1},
                   parse(' { "key1" : 1 } '));
}

void testParseInvalid() {
  void testString(String s) {
    Expect.throws(() => parse(s), (e) => e is FormatException);
  }
  // Scalars
  testString("");
  testString("-");
  testString("-.");
  testString("3.a");
  testString("{ key: value }");
  testString("tru");
  testString("1E--6");
  testString("1E-+6");
  testString("1E+-6");
  testString("1E++6");
  testString("1E6.6");
  testString("1E-6.6");
  testString("1E+6.6");

  // JavaScript number literals not valid in JSON.
  testString('[01]');
  testString('[.1]');
  testString('[1.]');
  testString('[1.e1]');
  testString('[-.1]');
  testString('[-1.]');

  // Plain invalid number literals.
  testString('-');
  testString('--1');
  testString('-1e');
  testString('1e--1]');
  testString('1e+-1');
  testString('1e-+1');
  testString('1e++1');

  // Lists
  testString('[, ]');
  testString('["", ]');
  testString('["", "]');
  testString('["" ""]');

  // Maps
  testString('{"" ""}');
  testString('{"": "",}');
}

void testEscaping() {
  Expect.stringEquals('""', stringify(''));
  Expect.stringEquals('"\\u0000"', stringify('\u0000'));
  Expect.stringEquals('"\\u0001"', stringify('\u0001'));
  Expect.stringEquals('"\\u0002"', stringify('\u0002'));
  Expect.stringEquals('"\\u0003"', stringify('\u0003'));
  Expect.stringEquals('"\\u0004"', stringify('\u0004'));
  Expect.stringEquals('"\\u0005"', stringify('\u0005'));
  Expect.stringEquals('"\\u0006"', stringify('\u0006'));
  Expect.stringEquals('"\\u0007"', stringify('\u0007'));
  Expect.stringEquals('"\\b"', stringify('\u0008'));
  Expect.stringEquals('"\\t"', stringify('\u0009'));
  Expect.stringEquals('"\\n"', stringify('\u000a'));
  Expect.stringEquals('"\\u000b"', stringify('\u000b'));
  Expect.stringEquals('"\\f"', stringify('\u000c'));
  Expect.stringEquals('"\\r"', stringify('\u000d'));
  Expect.stringEquals('"\\u000e"', stringify('\u000e'));
  Expect.stringEquals('"\\u000f"', stringify('\u000f'));
  Expect.stringEquals('"\\u0010"', stringify('\u0010'));
  Expect.stringEquals('"\\u0011"', stringify('\u0011'));
  Expect.stringEquals('"\\u0012"', stringify('\u0012'));
  Expect.stringEquals('"\\u0013"', stringify('\u0013'));
  Expect.stringEquals('"\\u0014"', stringify('\u0014'));
  Expect.stringEquals('"\\u0015"', stringify('\u0015'));
  Expect.stringEquals('"\\u0016"', stringify('\u0016'));
  Expect.stringEquals('"\\u0017"', stringify('\u0017'));
  Expect.stringEquals('"\\u0018"', stringify('\u0018'));
  Expect.stringEquals('"\\u0019"', stringify('\u0019'));
  Expect.stringEquals('"\\u001a"', stringify('\u001a'));
  Expect.stringEquals('"\\u001b"', stringify('\u001b'));
  Expect.stringEquals('"\\u001c"', stringify('\u001c'));
  Expect.stringEquals('"\\u001d"', stringify('\u001d'));
  Expect.stringEquals('"\\u001e"', stringify('\u001e'));
  Expect.stringEquals('"\\u001f"', stringify('\u001f'));
  Expect.stringEquals('"\\\""', stringify('"'));
  Expect.stringEquals('"\\\\"', stringify('\\'));
  Expect.stringEquals('"Got \\b, \\f, \\n, \\r, \\t, \\u0000, \\\\, and \\"."',
      stringify('Got \b, \f, \n, \r, \t, \u0000, \\, and ".'));
  Expect.stringEquals('"Got \\b\\f\\n\\r\\t\\u0000\\\\\\"."',
    stringify('Got \b\f\n\r\t\u0000\\".'));
}
