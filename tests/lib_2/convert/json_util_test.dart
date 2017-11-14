// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsonTest;

import "package:expect/expect.dart";
import 'dart:convert';

main() {
  testEscaping();
  testParse();
  testParseInvalid();
}

void testParse() {
  // Scalars.
  Expect.equals(5, JSON.decode(' 5 '));
  Expect.equals(-42, JSON.decode(' -42 '));
  Expect.equals(3, JSON.decode(' 3e0 '));
  Expect.equals(3.14, JSON.decode(' 3.14 '));
  Expect.equals(1.0E-06, JSON.decode(' 1.0E-06 '));
  Expect.equals(0, JSON.decode("0"));
  Expect.equals(1, JSON.decode("1"));
  Expect.equals(0.1, JSON.decode("0.1"));
  Expect.equals(1.1, JSON.decode("1.1"));
  Expect.equals(1.1, JSON.decode("1.100000"));
  Expect.equals(1.111111, JSON.decode("1.111111"));
  Expect.equals(-0, JSON.decode("-0"));
  Expect.equals(-1, JSON.decode("-1"));
  Expect.equals(-0.1, JSON.decode("-0.1"));
  Expect.equals(-1.1, JSON.decode("-1.1"));
  Expect.equals(-1.1, JSON.decode("-1.100000"));
  Expect.equals(-1.111111, JSON.decode("-1.111111"));
  Expect.equals(11, JSON.decode("1.1e1"));
  Expect.equals(11, JSON.decode("1.1e+1"));
  Expect.equals(0.11, JSON.decode("1.1e-1"));
  Expect.equals(11, JSON.decode("1.1E1"));
  Expect.equals(11, JSON.decode("1.1E+1"));
  Expect.equals(0.11, JSON.decode("1.1E-1"));
  Expect.equals(1E0, JSON.decode(" 1E0"));
  Expect.equals(1E+0, JSON.decode(" 1E+0"));
  Expect.equals(1E-0, JSON.decode(" 1E-0"));
  Expect.equals(1E00, JSON.decode(" 1E00"));
  Expect.equals(1E+00, JSON.decode(" 1E+00"));
  Expect.equals(1E-00, JSON.decode(" 1E-00"));
  Expect.equals(1E+10, JSON.decode(" 1E+10"));
  Expect.equals(1E+010, JSON.decode(" 1E+010"));
  Expect.equals(1E+0010, JSON.decode(" 1E+0010"));
  Expect.equals(1E10, JSON.decode(" 1E10"));
  Expect.equals(1E010, JSON.decode(" 1E010"));
  Expect.equals(1E0010, JSON.decode(" 1E0010"));
  Expect.equals(1E-10, JSON.decode(" 1E-10"));
  Expect.equals(1E-0010, JSON.decode(" 1E-0010"));
  Expect.equals(1E0, JSON.decode(" 1e0"));
  Expect.equals(1E+0, JSON.decode(" 1e+0"));
  Expect.equals(1E-0, JSON.decode(" 1e-0"));
  Expect.equals(1E00, JSON.decode(" 1e00"));
  Expect.equals(1E+00, JSON.decode(" 1e+00"));
  Expect.equals(1E-00, JSON.decode(" 1e-00"));
  Expect.equals(1E+10, JSON.decode(" 1e+10"));
  Expect.equals(1E+010, JSON.decode(" 1e+010"));
  Expect.equals(1E+0010, JSON.decode(" 1e+0010"));
  Expect.equals(1E10, JSON.decode(" 1e10"));
  Expect.equals(1E010, JSON.decode(" 1e010"));
  Expect.equals(1E0010, JSON.decode(" 1e0010"));
  Expect.equals(1E-10, JSON.decode(" 1e-10"));
  Expect.equals(1E-0010, JSON.decode(" 1e-0010"));
  Expect.equals(true, JSON.decode(' true '));
  Expect.equals(false, JSON.decode(' false'));
  Expect.equals(null, JSON.decode(' null '));
  Expect.equals(null, JSON.decode('\n\rnull\t'));
  Expect.equals('hi there" bob', JSON.decode(' "hi there\\" bob" '));
  Expect.equals('', JSON.decode(' "" '));

  // Lists.
  Expect.listEquals([], JSON.decode(' [] '));
  Expect.listEquals(["entry"], JSON.decode(' ["entry"] '));
  Expect.listEquals([true, false], JSON.decode(' [true, false] '));
  Expect.listEquals([1, 2, 3], JSON.decode(' [ 1 , 2 , 3 ] '));

  // Maps.
  Expect.mapEquals({}, JSON.decode(' {} '));
  Expect.mapEquals({"key": "value"}, JSON.decode(' {"key": "value" } '));
  Expect.mapEquals(
      {"key1": 1, "key2": 2}, JSON.decode(' {"key1": 1, "key2": 2} '));
  Expect.mapEquals({"key1": 1}, JSON.decode(' { "key1" : 1 } '));
}

void testParseInvalid() {
  void testString(String s) {
    Expect.throwsFormatException(() => JSON.decode(s));
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
  Expect.stringEquals('""', JSON.encode(''));
  Expect.stringEquals('"\\u0000"', JSON.encode('\u0000'));
  Expect.stringEquals('"\\u0001"', JSON.encode('\u0001'));
  Expect.stringEquals('"\\u0002"', JSON.encode('\u0002'));
  Expect.stringEquals('"\\u0003"', JSON.encode('\u0003'));
  Expect.stringEquals('"\\u0004"', JSON.encode('\u0004'));
  Expect.stringEquals('"\\u0005"', JSON.encode('\u0005'));
  Expect.stringEquals('"\\u0006"', JSON.encode('\u0006'));
  Expect.stringEquals('"\\u0007"', JSON.encode('\u0007'));
  Expect.stringEquals('"\\b"', JSON.encode('\u0008'));
  Expect.stringEquals('"\\t"', JSON.encode('\u0009'));
  Expect.stringEquals('"\\n"', JSON.encode('\u000a'));
  Expect.stringEquals('"\\u000b"', JSON.encode('\u000b'));
  Expect.stringEquals('"\\f"', JSON.encode('\u000c'));
  Expect.stringEquals('"\\r"', JSON.encode('\u000d'));
  Expect.stringEquals('"\\u000e"', JSON.encode('\u000e'));
  Expect.stringEquals('"\\u000f"', JSON.encode('\u000f'));
  Expect.stringEquals('"\\u0010"', JSON.encode('\u0010'));
  Expect.stringEquals('"\\u0011"', JSON.encode('\u0011'));
  Expect.stringEquals('"\\u0012"', JSON.encode('\u0012'));
  Expect.stringEquals('"\\u0013"', JSON.encode('\u0013'));
  Expect.stringEquals('"\\u0014"', JSON.encode('\u0014'));
  Expect.stringEquals('"\\u0015"', JSON.encode('\u0015'));
  Expect.stringEquals('"\\u0016"', JSON.encode('\u0016'));
  Expect.stringEquals('"\\u0017"', JSON.encode('\u0017'));
  Expect.stringEquals('"\\u0018"', JSON.encode('\u0018'));
  Expect.stringEquals('"\\u0019"', JSON.encode('\u0019'));
  Expect.stringEquals('"\\u001a"', JSON.encode('\u001a'));
  Expect.stringEquals('"\\u001b"', JSON.encode('\u001b'));
  Expect.stringEquals('"\\u001c"', JSON.encode('\u001c'));
  Expect.stringEquals('"\\u001d"', JSON.encode('\u001d'));
  Expect.stringEquals('"\\u001e"', JSON.encode('\u001e'));
  Expect.stringEquals('"\\u001f"', JSON.encode('\u001f'));
  Expect.stringEquals('"\\\""', JSON.encode('"'));
  Expect.stringEquals('"\\\\"', JSON.encode('\\'));
  Expect.stringEquals('"Got \\b, \\f, \\n, \\r, \\t, \\u0000, \\\\, and \\"."',
      JSON.encode('Got \b, \f, \n, \r, \t, \u0000, \\, and ".'));
  Expect.stringEquals('"Got \\b\\f\\n\\r\\t\\u0000\\\\\\"."',
      JSON.encode('Got \b\f\n\r\t\u0000\\".'));
}
