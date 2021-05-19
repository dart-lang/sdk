// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_ast.string_escape_test;

import 'package:js_ast/js_ast.dart';
import 'package:js_ast/src/characters.dart';
import 'package:test/test.dart';

const int $LCURLY = $OPEN_CURLY_BRACKET;
const int $RCURLY = $CLOSE_CURLY_BRACKET;

void main() {
  check(input, expected, {ascii: false, utf8: false}) {
    if (input is List) input = new String.fromCharCodes(input);
    String actual = js.escapedString(input, ascii: ascii, utf8: utf8).value;
    if (expected is List) {
      expect(actual.codeUnits, expected);
    } else {
      expect(actual, expected);
    }
  }

  test('simple', () {
    check('', [$DQ, $DQ]);
    check('a', [$DQ, $a, $DQ]);
  });

  test('simple-escapes', () {
    check([$BS], [$DQ, $BACKSLASH, $b, $DQ]);
    check([$BS], [$DQ, $BACKSLASH, $b, $DQ], ascii: true);
    check([$BS], [$DQ, $BACKSLASH, $b, $DQ], utf8: true);

    check([$LF], [$DQ, $BACKSLASH, $n, $DQ]);
    check([$LF], [$DQ, $BACKSLASH, $n, $DQ], ascii: true);
    check([$LF], [$DQ, $BACKSLASH, $n, $DQ], utf8: true);

    check([$FF], [$DQ, $FF, $DQ]);
    check([$FF], [$DQ, $BACKSLASH, $f, $DQ], ascii: true);
    check([$FF], [$DQ, $BACKSLASH, $f, $DQ], utf8: true);

    check([$CR], [$DQ, $BACKSLASH, $r, $DQ]);
    check([$CR], [$DQ, $BACKSLASH, $r, $DQ], ascii: true);
    check([$CR], [$DQ, $BACKSLASH, $r, $DQ], utf8: true);

    check([$TAB], [$DQ, $BACKSLASH, $t, $DQ]);
    check([$TAB], [$DQ, $BACKSLASH, $t, $DQ], ascii: true);
    check([$TAB], [$DQ, $BACKSLASH, $t, $DQ], utf8: true);

    check([$VTAB], [$DQ, $BACKSLASH, $v, $DQ]);
    check([$VTAB], [$DQ, $BACKSLASH, $v, $DQ], ascii: true);
    check([$VTAB], [$DQ, $BACKSLASH, $v, $DQ], utf8: true);
  });

  test('unnamed-control-codes-escapes', () {
    check([0, 1, 2, 3], [$DQ, 0, 1, 2, 3, $DQ]);
    check([0, 1, 2, 3], r'''"\x00\x01\x02\x03"''', ascii: true);
    check([0, 1, 2, 3], [$DQ, 0, 1, 2, 3, $DQ], utf8: true);
  });

  test('line-separator', () {
    // Legacy escaper is broken.
    // check([$LS], [$DQ, $BACKSLASH, $u, $2, $0, $2, $8, $DQ]);
    check([$LS], [$DQ, $BACKSLASH, $u, $2, $0, $2, $8, $DQ], ascii: true);
    check([$LS], [$DQ, $BACKSLASH, $u, $2, $0, $2, $8, $DQ], utf8: true);
  });

  test('page-separator', () {
    // Legacy escaper is broken.
    // check([$PS], [$DQ, $BACKSLASH, $u, $2, $0, $2, $9, $DQ]);
    check([$PS], [$DQ, $BACKSLASH, $u, $2, $0, $2, $9, $DQ], ascii: true);
    check([$PS], [$DQ, $BACKSLASH, $u, $2, $0, $2, $9, $DQ], utf8: true);
  });

  test('legacy-escaper-is-broken', () {
    check([$LS], [$DQ, 0x2028, $DQ]);
    check([$PS], [$DQ, 0x2029, $DQ]);
  });

  test('choose-quotes', () {
    check('\'', [$DQ, $SQ, $DQ]);
    check('"', [$SQ, $DQ, $SQ], ascii: true);
    check("'", [$DQ, $SQ, $DQ], ascii: true);
    // Legacy always double-quotes
    check([$DQ, $DQ, $SQ], [$DQ, $BACKSLASH, $DQ, $BACKSLASH, $DQ, $SQ, $DQ]);
    // Using single quotes saves us one backslash:
    check([$DQ, $DQ, $SQ], [$SQ, $DQ, $DQ, $BACKSLASH, $SQ, $SQ], ascii: true);
    check([$DQ, $SQ, $SQ], [$DQ, $BACKSLASH, $DQ, $SQ, $SQ, $DQ], ascii: true);
  });

  test('u1234', () {
    check('\u1234', [$DQ, 0x1234, $DQ]);
    check('\u1234', [$DQ, $BACKSLASH, $u, $1, $2, $3, $4, $DQ], ascii: true);
    check('\u1234', [$DQ, 0x1234, $DQ], utf8: true);
  });

  test('u12345', () {
    check([0x12345], [$DQ, 55304, 57157, $DQ]);
    // TODO: ES6 option:
    //check([0x12345],
    //      [$DQ, $BACKSLASH, $u, $LCURLY, $1, $2, $3, $4, $5, $RCURLY, $DQ],
    //      ascii: true);
    check([0x12345], r'''"\ud808\udf45"''', ascii: true);
    check([
      0x12345
    ], [
      $DQ,
      $BACKSLASH,
      $u,
      $d,
      $8,
      $0,
      $8,
      $BACKSLASH,
      $u,
      $d,
      $f,
      $4,
      $5,
      $DQ
    ], ascii: true);
    check([0x12345], [$DQ, 55304, 57157, $DQ], utf8: true);
  });

  test('unpaired-surrogate', () {
    // (0xD834, 0xDD1E) = 0x1D11E
    // Strings containing unpaired surrogates must be encoded to prevent
    // problems with the utf8 file-level encoding.
    check([0xD834], [$DQ, 0xD834, $DQ]); // Legacy escapedString broken.
    check([0xD834], [$DQ, $BACKSLASH, $u, $d, $8, $3, $4, $DQ], ascii: true);
    check([0xD834], [$DQ, $BACKSLASH, $u, $d, $8, $3, $4, $DQ], utf8: true);

    check([0xDD1E], [$DQ, 0xDD1E, $DQ]); // Legacy escapedString broken.
    check([0xDD1E], [$DQ, $BACKSLASH, $u, $d, $d, $1, $e, $DQ], ascii: true);
    check([0xDD1E], [$DQ, $BACKSLASH, $u, $d, $d, $1, $e, $DQ], utf8: true);

    check([0xD834, $A], [$DQ, 0xD834, $A, $DQ]); // Legacy escapedString broken.
    check([0xD834, $A], [$DQ, $BACKSLASH, $u, $d, $8, $3, $4, $A, $DQ],
        ascii: true);
    check([0xD834, $A], [$DQ, $BACKSLASH, $u, $d, $8, $3, $4, $A, $DQ],
        utf8: true);

    check([0xD834, 0xDD1E], [$DQ, 0xD834, 0xDD1E, $DQ]); // Legacy ok.
    check([
      0xD834,
      0xDD1E
    ], [
      $DQ,
      $BACKSLASH,
      $u,
      $d,
      $8,
      $3,
      $4,
      $BACKSLASH,
      $u,
      $d,
      $d,
      $1,
      $e,
      $DQ
    ], ascii: true);
    check([0xD834, 0xDD1E], r'''"\ud834\udd1e"''', ascii: true);
    check([0xD834, 0xDD1E], [$DQ, 0xD834, 0xDD1E, $DQ], utf8: true);
  });
}
