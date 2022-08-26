// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests invoking JS BigInt functionality through js_util. This interop
// requires usage of the operator functions exposed through js_util.

@JS()
library js_util_bigint_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS('BigInt')
external Object BigInt(Object value);

main() {
  group('bigint', () {
    test('addition', () {
      final one = BigInt('1');
      final two = BigInt('2');
      final three = BigInt('3');
      expect(js_util.strictEqual(js_util.add(one, two), three), isTrue);
      expect(js_util.strictEqual(js_util.add(one, one), three), isFalse);
    });

    test('subtraction', () {
      final one = BigInt('1');
      final two = BigInt('2');
      final three = BigInt('3');
      expect(js_util.strictEqual(js_util.subtract(three, one), two), isTrue);
      expect(js_util.strictEqual(js_util.subtract(three, two), two), isFalse);
    });

    test('multiplication', () {
      final two = BigInt('2');
      final four = BigInt('4');
      expect(js_util.strictEqual(js_util.multiply(two, two), four), isTrue);
      expect(js_util.strictEqual(js_util.multiply(two, four), four), isFalse);
    });

    test('division', () {
      final two = BigInt('2');
      final four = BigInt('4');
      expect(js_util.strictEqual(js_util.divide(four, two), two), isTrue);
      expect(js_util.strictEqual(js_util.divide(four, four), two), isFalse);
    });

    test('exponentiation', () {
      final two = BigInt('2');
      final three = BigInt('3');
      final nine = BigInt('9');
      expect(
          js_util.strictEqual(js_util.exponentiate(three, two), nine), isTrue);
      expect(js_util.strictEqual(js_util.exponentiate(three, three), nine),
          isFalse);
    });

    test('exponentiation2', () {
      final two = BigInt('2');
      final three = BigInt('3');
      final five = BigInt('5');
      expect(
          js_util.add(
              '', js_util.exponentiate(js_util.exponentiate(five, three), two)),
          '15625');
      expect(
          js_util.add(
              '', js_util.exponentiate(five, js_util.exponentiate(three, two))),
          '1953125');
    });

    test('modulo', () {
      final zero = BigInt('0');
      final three = BigInt('3');
      final nine = BigInt('9');
      expect(js_util.strictEqual(js_util.modulo(nine, three), zero), isTrue);
      expect(js_util.strictEqual(js_util.modulo(nine, three), nine), isFalse);
    });

    test('equality', () {
      final one = BigInt('1');
      expect(js_util.equal(one, 1), isTrue);
      expect(js_util.strictEqual(one, 1), isFalse);
      expect(js_util.notEqual(one, 1), isFalse);
      expect(js_util.strictNotEqual(one, 1), isTrue);
    });

    test('comparisons', () {
      final zero = BigInt('0');
      final one = BigInt('1');
      final otherOne = BigInt('1');
      expect(js_util.greaterThan(one, zero), isTrue);
      expect(js_util.greaterThan(one, 0), isTrue);
      expect(js_util.greaterThan(2, one), isTrue);
      expect(js_util.greaterThanOrEqual(one, otherOne), isTrue);
      expect(js_util.greaterThanOrEqual(one, 1), isTrue);
      expect(js_util.greaterThanOrEqual(one, 2), isFalse);

      expect(js_util.lessThan(one, zero), isFalse);
      expect(js_util.lessThan(zero, one), isTrue);
      expect(js_util.lessThan(one, 2), isTrue);
      expect(js_util.lessThan(one, 0), isFalse);
      expect(js_util.lessThanOrEqual(one, otherOne), isTrue);
      expect(js_util.lessThanOrEqual(one, 1), isTrue);
      expect(js_util.lessThanOrEqual(2, one), isFalse);
    });
  });
}
