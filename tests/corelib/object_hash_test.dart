// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math";
import "dart:typed_data";

import "package:expect/expect.dart";

main() {
  const nan = double.nan;
  const inf = double.infinity;

  int hash1234 = Object.hash(1, 2, 3, 4);
  Expect.type<int>(hash1234);
  Expect.equals(hash1234, Object.hash(1, 2, 3, 4)); // Consistent.
  Expect.equals(hash1234, Object.hashAll([1, 2, 3, 4]));
  Expect.equals(hash1234, Object.hashAll(Uint8List.fromList([1, 2, 3, 4])));

  Expect.notEquals(hash1234, Object.hash(1, 2, 3, 4, null));

  Expect.equals(Object.hash(1, 2, 3, 4, 5, 6, 7, 8, 9),
      Object.hashAll([1, 2, 3, 4, 5, 6, 7, 8, 9]));

  // Check that we can call `hash` with 2-20 arguments,
  // and they all agree with `hashAll`.
  var random = Random();
  for (var i = 2; i <= 20; i++) {
    var arguments = [for (var j = 0; j < i; j++) random.nextInt(256)];
    var hashAll = Object.hashAll(arguments);
    var hash = Function.apply(Object.hash, arguments);
    Expect.equals(
        hashAll,
        hash,
        "hashAll and hash disagrees for $i values:\n"
        "$arguments");
  }

  // Works for all kinds of objects;
  int varHash = Object.hash(
      "string", 3, nan, true, null, Type, #Symbol, const Object(), function);
  Expect.equals(
      varHash,
      Object.hashAll([
        "string",
        3,
        nan,
        true,
        null,
        Type,
        #Symbol,
        const Object(),
        function
      ]));

  // Object doesn't matter, just its hash code.
  Expect.equals(hash1234,
      Object.hash(Hashable(1), Hashable(2), Hashable(3), Hashable(4)));

  // It's potentially possible to get a conflict, but it doesn't happen here.
  Expect.notEquals("str".hashCode, Object.hashAll(["str"]));

  var hash12345 = Object.hashAllUnordered([1, 2, 3, 4, 5]);
  for (var p in permutations([1, 2, 3, 4, 5])) {
    Expect.equals(hash12345, Object.hashAllUnordered(p));
  }
  Expect.notEquals(
      Object.hashAllUnordered(["a", "a"]), Object.hashAllUnordered(["a"]));

  Expect.notEquals(Object.hashAllUnordered(["a", "a"]),
      Object.hashAllUnordered(["a", "a", "a", "a"]));

  Expect.notEquals(Object.hashAllUnordered(["a", "b"]),
      Object.hashAllUnordered(["a", "a", "a", "b"]));

  /// Unordered hashing works for all kinds of objects.
  var unorderHash = Object.hashAllUnordered([
    "string",
    3,
    nan,
    true,
    null,
    Type,
    #Symbol,
    const Object(),
    function,
  ]);

  var unorderHash2 = Object.hashAllUnordered([
    true,
    const Object(),
    3,
    function,
    Type,
    "string",
    null,
    nan,
    #Symbol,
  ]);
  Expect.equals(unorderHash, unorderHash2);
}

/// Lazily emits all permutations of [values].
///
/// Modifes [values] rather than create a new list.
/// The [values] list is guaranteed to end up in its original state
/// after all permutations have been read.
Iterable<List<T>> permutations<T>(List<T> values) {
  Iterable<List<T>> recPermute(int end) sync* {
    if (end == 1) {
      yield values;
      return;
    }
    for (var i = 0; i < end; i++) {
      yield* recPermute(end - 1);
      // Rotate values[i:].
      var tmp = values.first;
      for (var k = 1; k < end; k++) values[k - 1] = values[k];
      values[end - 1] = tmp;
    }
  }

  return recPermute(values.length);
}

// static function, used as constant value.
void function() {}

class Hashable {
  final Object o;
  Hashable(this.o);
  bool operator ==(Object other) => other is Hashable && o == other.o;
  int get hashCode => o.hashCode;
}
