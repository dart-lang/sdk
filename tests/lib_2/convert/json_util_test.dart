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
  Expect.equals(5, json.decode(' 5 '));
  Expect.equals(-42, json.decode(' -42 '));
  Expect.equals(3, json.decode(' 3e0 '));
  Expect.equals(3.14, json.decode(' 3.14 '));
  Expect.equals(1.0E-06, json.decode(' 1.0E-06 '));
  Expect.equals(0, json.decode("0"));
  Expect.equals(1, json.decode("1"));
  Expect.equals(0.1, json.decode("0.1"));
  Expect.equals(1.1, json.decode("1.1"));
  Expect.equals(1.1, json.decode("1.100000"));
  Expect.equals(1.111111, json.decode("1.111111"));
  Expect.equals(-0, json.decode("-0"));
  Expect.equals(-1, json.decode("-1"));
  Expect.equals(-0.1, json.decode("-0.1"));
  Expect.equals(-1.1, json.decode("-1.1"));
  Expect.equals(-1.1, json.decode("-1.100000"));
  Expect.equals(-1.111111, json.decode("-1.111111"));
  Expect.equals(11, json.decode("1.1e1"));
  Expect.equals(11, json.decode("1.1e+1"));
  Expect.equals(0.11, json.decode("1.1e-1"));
  Expect.equals(11, json.decode("1.1E1"));
  Expect.equals(11, json.decode("1.1E+1"));
  Expect.equals(0.11, json.decode("1.1E-1"));
  Expect.equals(1E0, json.decode(" 1E0"));
  Expect.equals(1E+0, json.decode(" 1E+0"));
  Expect.equals(1E-0, json.decode(" 1E-0"));
  Expect.equals(1E00, json.decode(" 1E00"));
  Expect.equals(1E+00, json.decode(" 1E+00"));
  Expect.equals(1E-00, json.decode(" 1E-00"));
  Expect.equals(1E+10, json.decode(" 1E+10"));
  Expect.equals(1E+010, json.decode(" 1E+010"));
  Expect.equals(1E+0010, json.decode(" 1E+0010"));
  Expect.equals(1E10, json.decode(" 1E10"));
  Expect.equals(1E010, json.decode(" 1E010"));
  Expect.equals(1E0010, json.decode(" 1E0010"));
  Expect.equals(1E-10, json.decode(" 1E-10"));
  Expect.equals(1E-0010, json.decode(" 1E-0010"));
  Expect.equals(1E0, json.decode(" 1e0"));
  Expect.equals(1E+0, json.decode(" 1e+0"));
  Expect.equals(1E-0, json.decode(" 1e-0"));
  Expect.equals(1E00, json.decode(" 1e00"));
  Expect.equals(1E+00, json.decode(" 1e+00"));
  Expect.equals(1E-00, json.decode(" 1e-00"));
  Expect.equals(1E+10, json.decode(" 1e+10"));
  Expect.equals(1E+010, json.decode(" 1e+010"));
  Expect.equals(1E+0010, json.decode(" 1e+0010"));
  Expect.equals(1E10, json.decode(" 1e10"));
  Expect.equals(1E010, json.decode(" 1e010"));
  Expect.equals(1E0010, json.decode(" 1e0010"));
  Expect.equals(1E-10, json.decode(" 1e-10"));
  Expect.equals(1E-0010, json.decode(" 1e-0010"));
  Expect.equals(true, json.decode(' true '));
  Expect.equals(false, json.decode(' false'));
  Expect.equals(null, json.decode(' null '));
  Expect.equals(null, json.decode('\n\rnull\t'));
  Expect.equals('hi there" bob', json.decode(' "hi there\\" bob" '));
  Expect.equals('', json.decode(' "" '));

  // Lists.
  Expect.listEquals([], json.decode(' [] '));
  Expect.listEquals(["entry"], json.decode(' ["entry"] '));
  Expect.listEquals([true, false], json.decode(' [true, false] '));
  Expect.listEquals([1, 2, 3], json.decode(' [ 1 , 2 , 3 ] '));

  // Maps.
  Expect.mapEquals({}, json.decode(' {} '));
  Expect.mapEquals({"key": "value"}, json.decode(' {"key": "value" } '));
  Expect.mapEquals(
      {"key1": 1, "key2": 2}, json.decode(' {"key1": 1, "key2": 2} '));
  Expect.mapEquals({"key1": 1}, json.decode(' { "key1" : 1 } '));
}

void testParseInvalid() {
  void testString(String s) {
    Expect.throwsFormatException(() => json.decode(s));
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
  Expect.stringEquals('""', json.encode(''));
  Expect.stringEquals('"\\u0000"', json.encode('\u0000'));
  Expect.stringEquals('"\\u0001"', json.encode('\u0001'));
  Expect.stringEquals('"\\u0002"', json.encode('\u0002'));
  Expect.stringEquals('"\\u0003"', json.encode('\u0003'));
  Expect.stringEquals('"\\u0004"', json.encode('\u0004'));
  Expect.stringEquals('"\\u0005"', json.encode('\u0005'));
  Expect.stringEquals('"\\u0006"', json.encode('\u0006'));
  Expect.stringEquals('"\\u0007"', json.encode('\u0007'));
  Expect.stringEquals('"\\b"', json.encode('\u0008'));
  Expect.stringEquals('"\\t"', json.encode('\u0009'));
  Expect.stringEquals('"\\n"', json.encode('\u000a'));
  Expect.stringEquals('"\\u000b"', json.encode('\u000b'));
  Expect.stringEquals('"\\f"', json.encode('\u000c'));
  Expect.stringEquals('"\\r"', json.encode('\u000d'));
  Expect.stringEquals('"\\u000e"', json.encode('\u000e'));
  Expect.stringEquals('"\\u000f"', json.encode('\u000f'));
  Expect.stringEquals('"\\u0010"', json.encode('\u0010'));
  Expect.stringEquals('"\\u0011"', json.encode('\u0011'));
  Expect.stringEquals('"\\u0012"', json.encode('\u0012'));
  Expect.stringEquals('"\\u0013"', json.encode('\u0013'));
  Expect.stringEquals('"\\u0014"', json.encode('\u0014'));
  Expect.stringEquals('"\\u0015"', json.encode('\u0015'));
  Expect.stringEquals('"\\u0016"', json.encode('\u0016'));
  Expect.stringEquals('"\\u0017"', json.encode('\u0017'));
  Expect.stringEquals('"\\u0018"', json.encode('\u0018'));
  Expect.stringEquals('"\\u0019"', json.encode('\u0019'));
  Expect.stringEquals('"\\u001a"', json.encode('\u001a'));
  Expect.stringEquals('"\\u001b"', json.encode('\u001b'));
  Expect.stringEquals('"\\u001c"', json.encode('\u001c'));
  Expect.stringEquals('"\\u001d"', json.encode('\u001d'));
  Expect.stringEquals('"\\u001e"', json.encode('\u001e'));
  Expect.stringEquals('"\\u001f"', json.encode('\u001f'));
  Expect.stringEquals('"\\\""', json.encode('"'));
  Expect.stringEquals('"\\\\"', json.encode('\\'));
  Expect.stringEquals('"Got \\b, \\f, \\n, \\r, \\t, \\u0000, \\\\, and \\"."',
      json.encode('Got \b, \f, \n, \r, \t, \u0000, \\, and ".'));
  Expect.stringEquals('"Got \\b\\f\\n\\r\\t\\u0000\\\\\\"."',
      json.encode('Got \b\f\n\r\t\u0000\\".'));
}
