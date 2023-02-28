// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import 'package:test/test.dart';

class _AlwaysEqual extends Comparable {
  late final int value;

  @override
  int compareTo(other) {
    return 0;
  }

  _AlwaysEqual(int value) {
    this.value = value;
  }
}

class _ValueContainer extends Comparable<_ValueContainer> {
  late int value;

  _ValueContainer(int value) {
    this.value = value;
  }

  @override
  int compareTo(other) {
    return this.value - other.value;
  }
}

class _UnequalToItself extends _ValueContainer {
  _UnequalToItself(int value) : super(value);

  operator ==(Object value) {
    return false;
  }

  @override
  int get hashCode => super.hashCode;
}

void main() {
  group("Testing whether the Iterable<Comparable> extension .max works", () {
    test("Gives the highest number out of normal numbers", () {
      expect([1, 2, 3].max, (equals(3)));
      expect(
          [_ValueContainer(3), _ValueContainer(2), _ValueContainer(1)]
              .max
              .value,
          (equals(3)));
      expect([-3, 2, 1].max, (equals(2)));
    });

    test("Uses the compare function", () {
      expect([_AlwaysEqual(10), _AlwaysEqual(1)].max.value, (equals(10)));
    });

    test("Treats -0.0 as bigger than 0.0", () {
      expect([-0.0, 0.0].max, (equals(0.0)));
      expect([0.0, -0.0].max, (equals(0.0)));
    });

    test(
        'Treats NaN and other values that are unequal to itself '
        'as lower than other numbers', () {
      expect([double.minPositive, double.maxFinite * -1, double.nan].max.isNaN,
          (equals(true)));
      expect(
          [_ValueContainer(1), _UnequalToItself(0), _UnequalToItself(-1)]
              .max
              .value,
          (equals(0)));
    });
  });

  group("Testing whether the Iterable<Comparable> extension .min works", () {
    test("Returns the lowest number out of normal numbers", () {
      expect([1, 2, 3].min, (equals(1)));
      expect(
          [_ValueContainer(3), _ValueContainer(2), _ValueContainer(1)]
              .min
              .value,
          (equals(1)));
      int value = [-3, 2, 1].min;
      expect(value, (equals(-3)));
    });

    test("Uses the compare function", () {
      expect([_AlwaysEqual(10), _AlwaysEqual(1)].max.value, (equals(10)));
    });

    test("Treats -0.0 as smaller than 0.0", () {
      expect([-0.0, 0.0].min.isNegative, (equals(true)));
      expect([0.0, -0.0].min.isNegative, (equals(true)));
    });

    test(
        'Treats NaN and other values that are unequal to itself '
        'as lower than other numbers', () {
      expect([double.minPositive, double.maxFinite * -1, double.nan].min.isNaN,
          (equals(true)));
      expect(
          [_ValueContainer(1), _UnequalToItself(0), _UnequalToItself(-1)]
              .max
              .value,
          (equals(0)));
    });
  });
}
