// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note that this library violates the formatting provided by `dart format` in
// a few locations, to verify that `"""...""""z"` can be parsed as two
// consecutive strings, `dart format` will insert whitespace before `"z"`.

import 'package:expect/expect.dart';

main() {
  const string = "X";
  const integer = 42;
  const boolean = true;
  const none = null;

  var s00 = new Symbol('');
  var s01 = new Symbol(r'@!#$%^&*(()\\|_-][');
  var s02 = new Symbol('\x00');
  var s03 = new Symbol('a');
  var s04 = new Symbol('ab');
  var s05 = new Symbol('\x80');
  var s06 = new Symbol('\xff');
  var s07 = new Symbol('\u2028');
  var s08 = new Symbol('abcdef\u2028');
  var s09 = new Symbol('\u{10002}');
  var s10 = new Symbol('\ud800');
  var s11 = new Symbol('\udfff');
  var s12 = new Symbol('\u{10FFFF}');
  var s13 = new Symbol('abcdef\u{10002}');
  var s14 = new Symbol('🇺🇸 😊 🇩🇰');
  var s15 = new Symbol('\udc00');

  // The multi-line string below is "abcd\ne:X42truenullz".
  var s16 = new Symbol("""
a${"b" // line break
          "c"}d
e:$string$integer$boolean$none""""z");

  Expect.isTrue(s00 == new Symbol(''));
  Expect.isTrue(s01 == new Symbol(r'@!#$%^&*(()\\|_-]['));
  Expect.isTrue(s02 == new Symbol('\x00'));
  Expect.isTrue(s03 == new Symbol('a'));
  Expect.isTrue(s04 == new Symbol('ab'));
  Expect.isTrue(s05 == new Symbol('\x80'));
  Expect.isTrue(s06 == new Symbol('\xff'));
  Expect.isTrue(s07 == new Symbol('\u2028'));
  Expect.isTrue(s08 == new Symbol('abcdef\u2028'));
  Expect.isTrue(s09 == new Symbol('\u{10002}'));
  Expect.isTrue(s10 == new Symbol('\ud800'));
  Expect.isTrue(s11 == new Symbol('\udfff'));
  Expect.isTrue(s12 == new Symbol('\u{10FFFF}'));
  Expect.isTrue(s13 == new Symbol('abcdef\u{10002}'));
  Expect.isTrue(s14 == new Symbol('🇺🇸 😊 🇩🇰'));
  Expect.isTrue(s15 == new Symbol('\udc00'));

  // The multi-line string below is "abcd\ne:X42truenullz".
  Expect.isTrue(s16 ==
      new Symbol("""
a${"b" // line break
              "c"}d
e:$string$integer$boolean$none""""z"));

  const s00c = const Symbol('');
  const s01c = const Symbol(r'@!#$%^&*(()\\|_-][');
  const s02c = const Symbol('\x00');
  const s03c = const Symbol('a');
  const s04c = const Symbol('ab');
  const s05c = const Symbol('\x80');
  const s06c = const Symbol('\xff');
  const s07c = const Symbol('\u2028');
  const s08c = const Symbol('abcdef\u2028');
  const s09c = const Symbol('\u{10002}');
  const s10c = const Symbol('\ud800');
  const s11c = const Symbol('\udfff');
  const s12c = const Symbol('\u{10FFFF}');
  const s13c = const Symbol('abcdef\u{10002}');
  const s14c = const Symbol('🇺🇸 😊 🇩🇰');
  const s15c = const Symbol('\udc00');

  // The multi-line string below is "abcd\ne:X42truenullz".
  const s16c = const Symbol("""
a${"b" // line break
          "c"}d
e:$string$integer$boolean$none""""z");

  Expect.isTrue(identical(s00c, const Symbol('')));
  Expect.isTrue(identical(s01c, const Symbol(r'@!#$%^&*(()\\|_-][')));
  Expect.isTrue(identical(s02c, const Symbol('\x00')));
  Expect.isTrue(identical(s03c, const Symbol('a')));
  Expect.isTrue(identical(s04c, const Symbol('ab')));
  Expect.isTrue(identical(s05c, const Symbol('\x80')));
  Expect.isTrue(identical(s06c, const Symbol('\xff')));
  Expect.isTrue(identical(s07c, const Symbol('\u2028')));
  Expect.isTrue(identical(s08c, const Symbol('abcdef\u2028')));
  Expect.isTrue(identical(s09c, const Symbol('\u{10002}')));
  Expect.isTrue(identical(s10c, const Symbol('\ud800')));
  Expect.isTrue(identical(s11c, const Symbol('\udfff')));
  Expect.isTrue(identical(s12c, const Symbol('\u{10FFFF}')));
  Expect.isTrue(identical(s13c, const Symbol('abcdef\u{10002}')));
  Expect.isTrue(identical(s14c, const Symbol('🇺🇸 😊 🇩🇰')));
  Expect.isTrue(identical(s15c, const Symbol('\udc00')));

  // The multi-line string below is "abcd\ne:X42truenullz".
  Expect.isTrue(identical(
      s16c,
      const Symbol("""
a${"b" // line break
              "c"}d
e:$string$integer$boolean$none""""z")));
}
