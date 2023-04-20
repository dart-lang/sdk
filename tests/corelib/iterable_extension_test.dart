// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async" show FutureOr;
import "package:expect/expect.dart";
import "../language/static_type_helper.dart";
// All extensions are exported by `dart:core`.

void main() {
  // Null-related extensions.
  testNonNulls();
  testFirstOrNull();
  testLastOrNull();
  testSingleOrNull();
  testElementAtOrNull();

  // Record-related extensions.
  testIndexed();
}

void testNonNulls() {
  // Static behavior.
  {
    // Removes nullability from element type.
    Iterable<int?> target = [];
    var result = target.nonNulls;
    result.expectStaticType<Exactly<Iterable<int>>>();
  }
  {
    // Works on subtypes of iterable.
    List<int?> target = [];
    var result = target.nonNulls;
    result.expectStaticType<Exactly<Iterable<int>>>();
  }
  {
    // Works on non-nullable types too (wish it didn't).
    Iterable<int> target = [];
    var result = target.nonNulls;
    result.expectStaticType<Exactly<Iterable<int>>>();
  }
  {
    // Removes nullability from `Never?`, giving `Never`.
    // (Cannot remove nullability from `Null`, so doesn't match
    // `Iterable<Null>`.)
    Iterable<Never?> target = [];
    var result = target.nonNulls;
    result.expectStaticType<Exactly<Iterable<Never>>>();
  }

  // Dynamic behavior.

  void test<T extends Object>(
      String name, Iterable<T?> input, List<T> expectedResults) {
    var actualResults = input.nonNulls;
    Expect.type<Iterable<T>>(actualResults, "$name type");
    Expect.listEquals(expectedResults, [...actualResults], "$name result");
  }

  test<int>("empty iterable", Iterable.empty(), []);
  test<int>("empty list", [], []);
  test<int>("all non-null", numbers(5), [1, 2, 3, 4, 5]);
  test<int>("all null", numbers(5, where: none), []);
  test<int>("one non-null", numbers(5, where: only(3)), [3]);
  test<int>("some null", numbers(5, where: even), [2, 4]);
  test<int>("some null, list", [null, 2, null, 4, null], [2, 4]);

  // Is lazy.
  var nonNulls = numbers(5, where: even, throwAt: 3).nonNulls;
  var it = nonNulls.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.throws<UnimplementedError>(it.moveNext);
}

void testFirstOrNull() {
  // Static behavior.
  // (Tested to ensure extension captures the correct type,
  // and the correct extension member is applied).
  {
    Iterable<int> target = [];
    var result = target.firstOrNull;
    result.expectStaticType<Exactly<int?>>();
  }
  {
    Iterable<int?> target = [];
    var result = target.firstOrNull;
    result.expectStaticType<Exactly<int?>>();
  }
  {
    Iterable<Never> target = [];
    var result = target.firstOrNull;
    result.expectStaticType<Exactly<Null>>();
  }
  // Dynamic behavior.
  void test<T extends Object>(
      String name, Iterable<T?> source, T? expectedResult) {
    var actualResult = source.firstOrNull;
    Expect.equals(expectedResult, actualResult, "firstOrNull $name");
  }

  test<int>("Empty iterable", Iterable.empty(), null);
  test<Never>("Empty iterable", Iterable.empty(), null);
  test<int>("Empty list", [], null);
  test<int>("Single value", numbers(1), 1);
  test<int>("Multiple values", numbers(3), 1);
  test<int>("Nullable values", numbers(3, where: even), null);
  test<int>("Stops after first", numbers(3, throwAt: 2), 1);
  Expect.throws<UnimplementedError>(() => numbers(3, throwAt: 1).firstOrNull,
      null, "firstOrNull first throws");
}

void testLastOrNull() {
  // Static behavior.
  {
    Iterable<int> target = [];
    var result = target.lastOrNull;
    result.expectStaticType<Exactly<int?>>();
  }
  {
    Iterable<int?> target = [];
    var result = target.lastOrNull;
    result.expectStaticType<Exactly<int?>>();
  }
  {
    Iterable<Never> target = [];
    var result = target.lastOrNull;
    result.expectStaticType<Exactly<Null>>();
  }
  // Dynamic behavior.
  void test<T>(String name, Iterable<T> source, T? expectedResult) {
    var actualResult = source.lastOrNull;
    Expect.equals(expectedResult, actualResult, "lastOrNull $name");
  }

  test<int>("Empty iterable", Iterable.empty(), null);
  test<Never>("Empty iterable", Iterable.empty(), null);
  test<int>("Empty list", [], null);
  test<int?>("Single value", numbers(1), 1);
  test<int?>("Multiple values", numbers(3), 3);
  test<int?>("Nullable values", numbers(3, where: even), null);
  Expect.throws<UnimplementedError>(
      () => numbers(3, throwAt: 1).lastOrNull, null, "lastOrNull first throws");
  Expect.throws<UnimplementedError>(
      () => numbers(3, throwAt: 3).lastOrNull, null, "lastOrNull last throws");
  Expect.throws<UnimplementedError>(
      () => CurrentThrowIterable<int?>(numbers(3), 2).lastOrNull,
      null,
      "lastOrNull throw on current");
}

void testSingleOrNull() {
  // Static behavior.
  {
    Iterable<int> target = [];
    var result = target.singleOrNull;
    result.expectStaticType<Exactly<int?>>();
  }
  {
    Iterable<int?> target = [];
    var result = target.singleOrNull;
    result.expectStaticType<Exactly<int?>>();
  }
  {
    Iterable<Never> target = [];
    var result = target.singleOrNull;
    result.expectStaticType<Exactly<Null>>();
  }
  // Dynamic behavior.
  void test<T>(String name, Iterable<T> source, T? expectedResult) {
    var actualResult = source.singleOrNull;
    Expect.equals(expectedResult, actualResult, "singleOrNull $name");
  }

  test<int>("Empty iterable", Iterable.empty(), null);
  test<Never>("Empty iterable", Iterable.empty(), null);
  test<int>("Empty list", [], null);
  test<int?>("Single value", numbers(1), 1);
  test<int?>("Multiple values", numbers(3), null);
  test<int?>("Nullable values", numbers(3, where: even), null);
  Expect.throws<UnimplementedError>(() => numbers(3, throwAt: 1).singleOrNull,
      null, "singleOrNull first throws");
  Expect.throws<UnimplementedError>(() => numbers(3, throwAt: 2).singleOrNull,
      null, "singleOrNull second throws");
  test<int?>("Throws after two", numbers(3, throwAt: 3), null);
}

void testElementAtOrNull() {
  // Static behavior.
  {
    Iterable<int> target = [];
    var result = target.elementAtOrNull(0);
    result.expectStaticType<Exactly<int?>>();
  }
  {
    Iterable<int?> target = [];
    var result = target.elementAtOrNull(0);
    result.expectStaticType<Exactly<int?>>();
  }
  {
    Iterable<Never> target = [];
    var result = target.elementAtOrNull(0);
    result.expectStaticType<Exactly<Null>>();
  }
  // Dynamic behavior.
  void test<T>(String name, Iterable<T> source, int index, T? expectedResult) {
    var actualResult = source.elementAtOrNull(index);
    Expect.equals(
        expectedResult, actualResult, "elementAtOrNull($index) $name");
  }

  Expect.throwsArgumentError(() => numbers(3).elementAtOrNull(-1),
      "elementAtOrNull(negative) first throws");

  test<int>("Empty iterable", Iterable<int>.empty(), 0, null);
  test<int>("Empty iterable", Iterable<int>.empty(), 1000000, null);
  test<Never>("Empty iterable", Iterable<Never>.empty(), 0, null);
  test<int>("Empty list", [], 0, null);
  test<int?>("Single value", numbers(1), 0, 1);
  test<int?>("Single value", numbers(1), 1, null);
  test<int?>("Multiple values first", numbers(3), 0, 1);
  test<int?>("Multiple values mid", numbers(3), 1, 2);
  test<int?>("Multiple values last", numbers(3), 2, 3);
  test<int?>("Multiple values overshoot", numbers(3), 3, null);
  test<int?>("Nullable values found", numbers(3, where: even), 2, null);
  test<int?>("Nullable values not found", numbers(3, where: even), 3, null);
  Expect.throws<UnimplementedError>(
      () => numbers(3, throwAt: 1).elementAtOrNull(1),
      null,
      "elementAtOrNull(1) first throws");
  Expect.throws<UnimplementedError>(
      () => numbers(3, throwAt: 2).elementAtOrNull(2),
      null,
      "elementAtOrNull(2) second throws");
  test<int?>("Throws after two", numbers(3, throwAt: 3), 1, 2);

  var currentThrow2 = CurrentThrowIterable<int?>(numbers(3), 2);
  test<int?>("Throws current middle", currentThrow2, 0, 1);
  test<int?>("Throws current middle", currentThrow2, 2, 3);
  Expect.throws<UnimplementedError>(() => currentThrow2.elementAt(1));
}

void testIndexed() {
  void test<T>(String name, Iterable<T> elements) {
    var values = elements.toList();
    var indexed = elements.indexed;
    testRec(name, values, indexed, 0, false);
  }

  // Non-efficient-length iterables.
  test<int?>("NELI empty", numbers(0));
  test<int?>("NELI single", numbers(1));
  test<int?>("NELI two", numbers(2));
  test<int?>("NELI more", numbers(10));

  // Efficient-length iterables (a list's `map` has efficient length).
  test<int?>("ELI empty", numbers(0).toList().map((x) => x));
  test<int?>("ELI single", numbers(1).toList().map((x) => x));
  test<int?>("ELI two", numbers(2).toList().map((x) => x));
  test<int?>("ELI more", numbers(10).toList().map((x) => x));
}

// Helper function for `testIndexed`. Top-level because dart2js crashes
// on recursive generic local functions.
//
// If [rec] is true, we're doing a recursive test on skip/take/both,
// and `start` the number of leading elements skipped.
void testRec<T>(String name, List<T> values, Iterable<(int, T)> indexed,
    int start, bool rec) {
  var length = values.length;
  Expect.equals(length, indexed.length, "$values length");
  Expect.equals(values.isEmpty, indexed.isEmpty);
  Expect.equals(values.isNotEmpty, indexed.isNotEmpty);
  Expect.listEquals([for (var i = 0; i < length; i++) (start + i, values[i])],
      indexed.toList());

  int index = 0;
  indexed.forEach((pair) {
    Expect.equals(start + index, pair.$1);
    Expect.equals(values[index], pair.$2);
    index++;
  });
  Expect.equals(length, index);

  Expect.isFalse(indexed.contains(0));
  Expect.isFalse(indexed.contains((start - 1, 0)));
  Expect.isFalse(indexed.contains((start + length, 0)));

  if (values.isNotEmpty) {
    Expect.isFalse(indexed.contains(values.first));
    Expect.equals((start, values.first), indexed.first);
    Expect.equals((start + length - 1, values.last), indexed.last);
    for (var i = 0; i < length; i++) {
      Expect.equals((start + i, values[i]), indexed.elementAt(i));
      Expect.isTrue(indexed.contains((start + i, values[i])));
    }
    Expect.isFalse(indexed.contains((start - 1, values.first)));
    Expect.isFalse(indexed.contains((start + length, values.last)));
    if (length == 1) {
      Expect.equals((start, values.single), indexed.single);
    } else if (!rec) {
      Expect.throws<StateError>(() => indexed.single);
      // More than one element, so test skip/take.
      testRec("$name.skip(1)", values.sublist(1), indexed.skip(1), 1, true);
      testRec("$name.take(l-1)", values.sublist(0, length - 1),
          indexed.take(length - 1), 0, true);
      if (length > 2) {
        testRec("$name.skip(1).take(l-2)", values.sublist(1, length - 1),
            indexed.skip(1).take(length - 2), 1, true);
        testRec("$name.take(l-1).skip(1)", values.sublist(1, length - 1),
            indexed.take(length - 1).skip(1), 1, true);
      }
    }
  }
}

/// Generates an iterable with [length] elements.
///
/// The elements are 1, ..., [length], except that if `isValue` returns
/// `false` for a number, it's replaced by `null`.
/// If [throwAt] is provided, the iterable throws an `UnimplementedError`
/// (which shouldn't conflict with an actual error) instead of emitting
/// a value at the [throwAt] index.
Iterable<int?> numbers(int length,
    {bool Function(int) where = all, int? throwAt}) sync* {
  for (var i = 1; i <= length; i++) {
    if (i == throwAt) throw UnimplementedError("Error");
    yield where(i) ? i : null;
  }
}

/// Iterable which throws only when accessing [current].
///
/// Used to test that operations that don't need the value,
/// also don't read it.
///
/// (Could also be achieved with
/// ```
/// _source.toList().map((x) => x == _throwAt ? throw ... : x));
/// ```
/// but that assumes optimization behavior that is not necessarily tested.)
class CurrentThrowIterable<T> extends Iterable<T> {
  final T _throwAt;
  final Iterable<T> _source;
  CurrentThrowIterable(this._source, this._throwAt);
  Iterator<T> get iterator =>
      CurrentThrowIterator<T>(_source.iterator, _throwAt);
}

class CurrentThrowIterator<T> implements Iterator<T> {
  final T _throwAt;
  Iterator<T> _source;
  CurrentThrowIterator(this._source, this._throwAt);
  bool moveNext() => _source.moveNext();
  T get current {
    var result = _source.current;
    if (result == _throwAt) throw UnimplementedError("Error");
    return result;
  }
}

bool none(_) => false;
bool all(_) => true;
bool even(int n) => n.isEven;
bool Function(int) only(int n1) => (int n2) => n1 == n2;
