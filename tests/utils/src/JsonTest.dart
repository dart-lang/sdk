// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('jsonTest');

#import('dart:json');

main() {
  testEscaping();
  testParse();
  testParseInvalid();
}

void testParse() {
  // Scalars.
  Expect.equals(5, JSON.parse(' 5 '));
  Expect.equals(-42, JSON.parse(' -42 '));
  Expect.equals(3, JSON.parse(' 3e0 '));
  Expect.equals(3.14, JSON.parse(' 3.14 '));
  Expect.equals(true, JSON.parse(' true '));
  Expect.equals(false, JSON.parse(' false'));
  Expect.equals(null, JSON.parse(' null '));
  Expect.equals(null, JSON.parse('\n\rnull\t'));
  Expect.equals('hi there" bob', JSON.parse(' "hi there\\" bob" '));
  Expect.equals('', JSON.parse(' "" '));

  // Lists.
  Expect.listEquals([], JSON.parse(' [] '));
  Expect.listEquals(["entry"], JSON.parse(' ["entry"] '));
  Expect.listEquals([true, false], JSON.parse(' [true, false] '));
  Expect.listEquals([1, 2, 3], JSON.parse(' [ 1 , 2 , 3 ] '));

  // Maps.
  Expect.mapEquals({}, JSON.parse(' {} '));
  Expect.mapEquals({"key": "value"}, JSON.parse(' {"key": "value" } '));
  Expect.mapEquals({"key1": 1, "key2": 2},
                   JSON.parse(' {"key1": 1, "key2": 2} '));
  Expect.mapEquals({"key1": 1},
                   JSON.parse(' { "key1" : 1 } '));
}

void testParseInvalid() {
  void testString(String s) {
    Expect.throws(() => JSON.parse(s), (e) => e is JSONParseException);
  }
  testString("");
  testString("3.a");
  testString("{ key: value }");
  testString("tru");

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
  Expect.stringEquals('""', JSON.stringify(''));
  Expect.stringEquals('"\\u0000"', JSON.stringify('\u0000'));
  Expect.stringEquals('"\\u0001"', JSON.stringify('\u0001'));
  Expect.stringEquals('"\\u0002"', JSON.stringify('\u0002'));
  Expect.stringEquals('"\\u0003"', JSON.stringify('\u0003'));
  Expect.stringEquals('"\\u0004"', JSON.stringify('\u0004'));
  Expect.stringEquals('"\\u0005"', JSON.stringify('\u0005'));
  Expect.stringEquals('"\\u0006"', JSON.stringify('\u0006'));
  Expect.stringEquals('"\\u0007"', JSON.stringify('\u0007'));
  Expect.stringEquals('"\\b"', JSON.stringify('\u0008'));
  Expect.stringEquals('"\\t"', JSON.stringify('\u0009'));
  Expect.stringEquals('"\\n"', JSON.stringify('\u000a'));
  Expect.stringEquals('"\\u000b"', JSON.stringify('\u000b'));
  Expect.stringEquals('"\\f"', JSON.stringify('\u000c'));
  Expect.stringEquals('"\\r"', JSON.stringify('\u000d'));
  Expect.stringEquals('"\\u000e"', JSON.stringify('\u000e'));
  Expect.stringEquals('"\\u000f"', JSON.stringify('\u000f'));
  Expect.stringEquals('"\\u0010"', JSON.stringify('\u0010'));
  Expect.stringEquals('"\\u0011"', JSON.stringify('\u0011'));
  Expect.stringEquals('"\\u0012"', JSON.stringify('\u0012'));
  Expect.stringEquals('"\\u0013"', JSON.stringify('\u0013'));
  Expect.stringEquals('"\\u0014"', JSON.stringify('\u0014'));
  Expect.stringEquals('"\\u0015"', JSON.stringify('\u0015'));
  Expect.stringEquals('"\\u0016"', JSON.stringify('\u0016'));
  Expect.stringEquals('"\\u0017"', JSON.stringify('\u0017'));
  Expect.stringEquals('"\\u0018"', JSON.stringify('\u0018'));
  Expect.stringEquals('"\\u0019"', JSON.stringify('\u0019'));
  Expect.stringEquals('"\\u001a"', JSON.stringify('\u001a'));
  Expect.stringEquals('"\\u001b"', JSON.stringify('\u001b'));
  Expect.stringEquals('"\\u001c"', JSON.stringify('\u001c'));
  Expect.stringEquals('"\\u001d"', JSON.stringify('\u001d'));
  Expect.stringEquals('"\\u001e"', JSON.stringify('\u001e'));
  Expect.stringEquals('"\\u001f"', JSON.stringify('\u001f'));
  Expect.stringEquals('"\\\""', JSON.stringify('"'));
  Expect.stringEquals('"\\\\"', JSON.stringify('\\'));
  Expect.stringEquals('"Got \\b, \\f, \\n, \\r, \\t, \\u0000, \\\\, and \\"."',
      JSON.stringify('Got \b, \f, \n, \r, \t, \u0000, \\, and ".'));
  Expect.stringEquals('"Got \\b\\f\\n\\r\\t\\u0000\\\\\\"."',
    JSON.stringify('Got \b\f\n\r\t\u0000\\".'));
}
