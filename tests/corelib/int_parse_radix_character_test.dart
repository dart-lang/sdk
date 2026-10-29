// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Check every UTF-16 code unit in every supported radix, using both short
// inputs and long inputs that exercise the parser's overflow checks.
// Regression test for https://github.com/dart-lang/sdk/issues/64727.
void main() {
  const digitCharacters = '0123456789abcdefghijklmnopqrstuvwxyz';
  // Exercise parse's exception behavior for all ASCII characters and selected
  // Unicode edge cases. Throwing for every code unit in every radix is too slow
  // in Firefox. tryParse still checks every code unit below.
  const extraParseCodeUnits = {
    0x85, 0xa0, 0xff, 0x100, // Whitespace and one-byte/two-byte boundaries.
    0x130, 0x17f, // Non-ASCII letters with ASCII case mappings.
    0x660, 0x669, 0x6f0, 0x6f9, // Arabic-Indic digits.
    0x1680, 0x2000, 0x200a, 0x2028, 0x2029, 0x202f, 0x205f, 0x3000,
    0xd7ff, 0xd800, 0xdbff, 0xdc00, 0xdfff, 0xe000, // Surrogate boundaries.
    0xfeff, // Byte order mark / whitespace.
    0xff10, 0xff19, 0xff21, 0xff3a, 0xff41, 0xff5a, // Fullwidth digits/letters.
    0xfffe, 0xffff, // Noncharacters.
  };

  for (var radix = 2; radix <= 36; radix++) {
    final longPrefix = makeLongPrefix(radix);
    final validDigits = digitCharacters.substring(0, radix);
    final validCharacters = radix <= 10
        ? validDigits
        : validDigits + validDigits.substring(10).toUpperCase();

    // Accept every digit in this radix, in both letter cases.
    for (final character in validCharacters.split('')) {
      final value = digitCharacters.indexOf(character.toLowerCase());
      final reason = 'radix $radix, digit $character';
      final shortInput = '1${character}0';
      final expected = radix * radix + value * radix;

      Expect.equals(
        expected,
        int.parse(shortInput, radix: radix),
        'short: $reason',
      );
      Expect.equals(
        expected,
        int.tryParse(shortInput, radix: radix),
        'short: $reason',
      );

      // Large integers may be rounded on JavaScript backends. Both APIs must
      // accept the input and agree, without requiring an exact value.
      final longInput = '$longPrefix$character';
      Expect.equals(
        int.parse(longInput, radix: radix),
        int.tryParse(longInput, radix: radix),
        'long: $reason',
      );

      // Also check automatic radix detection for decimal and hexadecimal.
      if (radix == 10) {
        Expect.equals(
          expected,
          int.parse(shortInput),
          'automatic short: $reason',
        );
        Expect.equals(
          expected,
          int.tryParse(shortInput),
          'automatic short: $reason',
        );
        Expect.equals(
          int.parse(longInput),
          int.tryParse(longInput),
          'automatic long: $reason',
        );
      }
      if (radix == 16) {
        for (final prefix in ['0x', '0X']) {
          Expect.equals(
            expected,
            int.parse('$prefix$shortInput'),
            '$prefix short: $reason',
          );
          Expect.equals(
            expected,
            int.tryParse('$prefix$shortInput'),
            '$prefix short: $reason',
          );
          Expect.equals(
            int.parse('$prefix$longInput'),
            int.tryParse('$prefix$longInput'),
            '$prefix long: $reason',
          );
        }
      }
    }

    // Reject every other UTF-16 code unit, including unpaired surrogates.
    for (var codeUnit = 0; codeUnit <= 0xffff; codeUnit++) {
      final character = String.fromCharCode(codeUnit);
      if (validCharacters.contains(character)) continue;

      final checkParse =
          codeUnit <= 0x7f || extraParseCodeUnits.contains(codeUnit);
      final reason = 'radix $radix, U+${codeUnit.toRadixString(16)}';
      final shortInput = '1${character}0';
      if (checkParse) {
        Expect.throwsFormatException(
          () => int.parse(shortInput, radix: radix),
          'short: $reason',
        );
      }
      Expect.isNull(int.tryParse(shortInput, radix: radix), 'short: $reason');

      if (radix == 10) {
        if (checkParse) {
          Expect.throwsFormatException(
            () => int.parse(shortInput),
            'automatic short: $reason',
          );
        }
        Expect.isNull(int.tryParse(shortInput), 'automatic short: $reason');
      }
      if (radix == 16) {
        for (final prefix in ['0x', '0X']) {
          if (checkParse) {
            Expect.throwsFormatException(
              () => int.parse('$prefix$shortInput'),
              '$prefix short: $reason',
            );
          }
          Expect.isNull(
            int.tryParse('$prefix$shortInput'),
            '$prefix short: $reason',
          );
        }
      }

      // Trailing whitespace may be trimmed, so only test it inside a number.
      if (character.trim().isNotEmpty) {
        final longInput = '$longPrefix$character';
        if (checkParse) {
          Expect.throwsFormatException(
            () => int.parse(longInput, radix: radix),
            'long: $reason',
          );
        }
        Expect.isNull(int.tryParse(longInput, radix: radix), 'long: $reason');

        if (radix == 10) {
          if (checkParse) {
            Expect.throwsFormatException(
              () => int.parse(longInput),
              'automatic long: $reason',
            );
          }
          Expect.isNull(int.tryParse(longInput), 'automatic long: $reason');
        }
        if (radix == 16) {
          for (final prefix in ['0x', '0X']) {
            if (checkParse) {
              Expect.throwsFormatException(
                () => int.parse('$prefix$longInput'),
                '$prefix long: $reason',
              );
            }
            Expect.isNull(
              int.tryParse('$prefix$longInput'),
              '$prefix long: $reason',
            );
          }
        }
      }
    }
  }
}

// Return "1" followed by as many zeroes as possible, leaving room for any
// valid final digit without overflowing a signed 64-bit integer. Starting
// with "1" matters: the parser skips leading zeroes before counting digits.
//
// For radix 10, the prefix is "100000000000000000"; appending "9" gives
// "1000000000000000009", which fits in a signed 64-bit integer.
String makeLongPrefix(int radix) {
  final maxInt = (BigInt.one << 63) - BigInt.one;
  final base = BigInt.from(radix);
  final largestDigit = base - BigInt.one;
  final largestPrefixValue = (maxInt - largestDigit) ~/ base;

  var prefixValue = BigInt.one;
  while (prefixValue * base <= largestPrefixValue) {
    prefixValue *= base;
  }
  return prefixValue.toRadixString(radix);
}
