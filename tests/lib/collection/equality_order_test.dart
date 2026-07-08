// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that collections that rely on object equality
// uses the equality of the stored value, not the new/lookup value.

import 'dart:collection';

import "package:expect/expect.dart";

import 'dart:collection';

var counters = Expando<Counters>();

class Counters {
  int hashCodeCalls = 0;
  int equalsCalls = 0;
  int equalsTrueCalls = 0;
  void reset() {
    hashCodeCalls = 0;
    equalsCalls = 0;
    equalsTrueCalls = 0;
  }
}

/// An object which counts when its `==` or `hashCode` is used.
class Box {
  final int id;
  final bool _throwOnEquals;

  // Uses expando to allow object to be const.
  Counters get _counters => counters[this] ??= Counters();

  int get hashCodeCalls => _counters.hashCodeCalls;
  int get equalsCalls => _counters.equalsCalls;
  int get equalsTrueCalls => _counters.equalsTrueCalls;

  void resetCalls() {
    _counters.reset();
  }

  final Object value;

  const Box(this.value, this.id, {bool throwOnEquals = false})
    : _throwOnEquals = throwOnEquals;

  int get hashCode {
    _counters.hashCodeCalls++;
    return value.hashCode;
  }

  bool operator ==(Object other) {
    var counters = _counters;
    counters.equalsCalls++;
    if (_throwOnEquals) Expect.fail('Should not call equals on $this');
    if (other is Box && value == other.value) {
      counters.equalsTrueCalls++;
      return true;
    }
    return false;
  }

  String toString() => "Box#$id($value)";
}

void main() {
  // Can increase to check more combinations of wrappers,
  // but this covers the collections themselves.
  const depth = 3;
  const original = Box("original", 1);
  const other = Box("original", 2);
  const notOther = Box("not equal", 3);
  // Can be used instead of fx `notOther` to check where equality is called.
  const fatal = Box("fatal", 4, throwOnEquals: true);

  // Sanity checks.
  assert(original == other);
  assert(original.hashCodeCalls == 0);
  assert(original.equalsCalls == 1);
  assert(original.equalsTrueCalls == 1);
  assert(other.hashCodeCalls == 0);
  assert(other.equalsCalls == 0);
  assert(other.equalsTrueCalls == 0);
  original.resetCalls();

  void expectValueLookup(Box box) {
    var matches = identical(box, original) || identical(box, other);
    var checks = original.equalsCalls;
    if (matches) {
      Expect.equals(
        matches ? checks : 0,
        original.equalsTrueCalls,
        'all checks are true',
      );
    }
    if (!identical(box, original)) {
      Expect.equals(0, box.equalsCalls, 'checks on $box');
      Expect.equals(0, box.equalsTrueCalls, 'true checks on $box');
    }
    original.resetCalls();
    other.resetCalls();
    notOther.resetCalls();
  }

  // Sets
  const constSetOriginal = <Object>{"original"};
  checkSet(
    'constSetOriginal',
    constSetOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  var literalSetOriginal = <Object>{original};
  checkSet(
    mutable: true,
    'literalSetOriginal',
    literalSetOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);
  Expect.equals(literalSetOriginal.length, 1);

  checkSet(
    mutable: true,
    'literalSetOriginal',
    literalSetOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);
  Expect.equals(literalSetOriginal.length, 1);

  checkSet(
    mutable: true,
    'literalSetOriginal',
    literalSetOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);
  Expect.equals(literalSetOriginal.length, 1);

  var hashSetOriginal = HashSet<Object>()..add(original);
  checkSet(
    mutable: true,
    'hashSetOriginal',
    hashSetOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);

  checkSet(
    mutable: true,
    'hashSetOriginal',
    hashSetOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);

  checkSet(
    mutable: true,
    'hashSetOriginal',
    hashSetOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  var linkedHashSetOriginal = LinkedHashSet<Object>()..add(original);
  checkSet(
    mutable: true,
    'linkedHashSetOriginal',
    linkedHashSetOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);

  checkSet(
    mutable: true,
    'linkedHashSetOriginal',
    linkedHashSetOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);

  checkSet(
    mutable: true,
    'linkedHashSetOriginal',
    linkedHashSetOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  // Maps.
  const constMapOriginal = <Object, Object>{"original": "original"};
  checkMap(
    'constMapOriginal',
    constMapOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  var literalMapOriginal = <Object, Object>{original: original};
  checkMap(
    mutable: true,
    'literalMapOriginal',
    literalMapOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);

  checkMap(
    mutable: true,
    'literalMapOriginal',
    literalMapOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);

  checkMap(
    mutable: true,
    'literalMapOriginal',
    literalMapOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  var hashMapOriginal = HashMap<Object, Object>()..[original] = original;
  checkMap(
    mutable: true,
    'hashMapOriginal',
    hashMapOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);

  checkMap(
    mutable: true,
    'hashMapOriginal',
    hashMapOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);

  checkMap(
    mutable: true,
    'hashMapOriginal',
    hashMapOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  var linkedHashMapOriginal = LinkedHashMap<Object, Object>()
    ..[original] = original;
  checkMap(
    mutable: true,
    'linkedHashMapOriginal',
    linkedHashMapOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);

  checkMap(
    mutable: true,
    'linkedHashMapOriginal',
    linkedHashMapOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);

  checkMap(
    mutable: true,
    'linkedHashMapOriginal',
    linkedHashMapOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  // Lists.
  const constListOriginal = <Object>["original"];
  checkList(
    'constListOriginal',
    constListOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  var unmodifiableListOriginal = List<Object>.unmodifiableOf([original]);
  checkList(
    'unmodifiableListOriginal',
    unmodifiableListOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);

  checkList(
    'unmodifiableListOriginal',
    unmodifiableListOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);

  checkList(
    'unmodifiableListOriginal',
    unmodifiableListOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  // Treated as non-mutable, can't remove from it.
  var fixedListOriginal = List<Object>.filled(1, original);
  checkList(
    'fixedListOriginal',
    fixedListOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);

  checkList(
    'fixedListOriginal',
    fixedListOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);

  checkList(
    'fixedListOriginal',
    fixedListOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);

  var growableListOriginal = <Object>[original];
  checkList(
    mutable: true,
    'growableListOriginal',
    growableListOriginal,
    original,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(original);

  checkList(
    mutable: true,
    'growableListOriginal',
    growableListOriginal,
    other,
    isElement: true,
    depth: depth,
  );
  expectValueLookup(other);

  checkList(
    mutable: true,
    'growableListOriginal',
    growableListOriginal,
    notOther,
    isElement: false,
    depth: depth,
  );
  expectValueLookup(notOther);
}

void checkList(
  String name,
  List<Object?> values,
  Object value, {
  required bool isElement,
  int depth = 1,
  bool mutable = false,
}) {
  try {
    var expectIfElement = isElement ? Expect.isTrue : Expect.isFalse;
    var indexOf = values.indexOf(value);
    expectIfElement(indexOf >= 0, '$name.indexOf($value) >= 0');
    expectIfElement(
      values.lastIndexOf(value) >= 0,
      '$name.lastIndexOf($value) >= 0',
    );
    var originalValue = indexOf >= 0 ? values[indexOf] : null;

    if (mutable) {
      var prevLength = values.length;
      expectIfElement(values.remove(value), '$name.remove($value)');
      expectIfElement(
        values.length < prevLength,
        '$name.remove($value).length',
      );
      if (isElement) {
        values.insert(indexOf, originalValue);
      }
      Expect.equals(prevLength, values.length);
    }

    if (depth > 0) {
      checkList(
        '$name.cast()',
        values.cast<Object>(),
        value,
        mutable: mutable,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.reversed',
        values.reversed,
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.getRange()',
        values.getRange(0, values.length),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
    }
    checkIterable(name, values, value, isElement: isElement, depth: depth);
  } on Error {
    print(
      "Failing List $name with ${isElement ? 'element' : 'non-element'} $value in $values",
    );
    rethrow;
  }
}

void checkMap(
  String name,
  Map<Object?, Object?>
  values, // Contains value: value or no key/value == to value.
  Object value, {
  required bool isElement,
  int depth = 1,
  bool mutable = false,
}) {
  try {
    var expectIfElement = isElement ? Expect.isTrue : Expect.isFalse;
    expectIfElement(values.containsKey(value), '$name.containsKey($value)');
    expectIfElement(values.containsValue(value), '$name.containsValue($value)');
    if (mutable) {
      var originalSize = values.length;
      if (isElement) {
        values.putIfAbsent(value, () {
          Expect.fail('Unreachable');
          return 0;
        });

        var wasElement = false;
        values.update(
          value,
          (original) {
            wasElement = true;
            return original!;
          },
          ifAbsent: () {
            Expect.fail('Unreachable');
            return 0;
          },
        );
        Expect.isTrue(wasElement, '$name.update($value) was element');

        var original = values.remove(value);
        Expect.isNotNull(original, '$name.remove($value)');
        Expect.equals(originalSize - 1, values.length);
        // Put values back in.
        values[original] = original;
        Expect.equals(originalSize, values.length);

        values[original] = original;
        Expect.equals(originalSize, values.length);

        values[value] = original;
        Expect.equals(originalSize, values.length);
      } else {
        // Not equal to key.
        Expect.isNull(values.remove(value), '$name.remove($value)');
        Expect.equals(originalSize, values.length);
        Expect.throws<Error>(
          () => values.update(value, (_) {
            Expect.fail('Unreachable');
            return 0;
          }),
        );
        // Don't add the `value`. It works, but there is no good way to
        // remove it again without using its equality.
        // (Some platforms use lookup in `removeWhere`.)
      }
      Expect.equals(originalSize, values.length);
    }
    if (depth > 0) {
      checkIterable(
        '$name.keys',
        values.keys,
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.values',
        values.values,
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkMap(
        '$name.cast(), ',
        values.cast<Object, Object>(),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkMap(
        '$name.map(), ',
        values.map<Object, Object>(
          (a, b) => MapEntry<Object, Object>(a as Object, b as Object),
        ),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
    }
  } on Error {
    print(
      "Failing map $name with ${isElement ? 'element' : 'non-element'} $value in $values",
    );
    rethrow;
  }
}

void checkSet(
  String name,
  Set<Object?> values,
  Object value, {
  required bool isElement,
  int depth = 1,
  bool mutable = false,
}) {
  try {
    checkIterable(name, values, value, isElement: isElement, depth: depth);
    var expectIfElement = isElement ? Expect.isTrue : Expect.isFalse;

    expectIfElement(values.containsAll([value]), '$name.containsAll([$value])');
    var original = values.lookup(value);
    expectIfElement(original != null, '$name.lookup($value)');

    if (mutable) {
      var prevSize = values.length;
      assert(prevSize == 1);
      if (isElement) {
        assert(original != null);
        Expect.isFalse(values.add(value), '$name.add($value)');
        Expect.isTrue(values.remove(value), '$name.remove($value)');
        Expect.equals(prevSize - 1, values.length);
        values.add(original); // Put original back.
        Expect.equals(prevSize, values.length);
        values.removeAll([value]);
        Expect.equals(
          prevSize - 1,
          values.length,
          '$name.removeAll([$value]).length',
        );
        values.add(original); // Put original back.
      } else {
        original = values.first;
        assert(original != null);
        Expect.isFalse(values.remove(value), '$name.remove($value)');
        Expect.equals(prevSize, values.length);
        values.removeAll([value]);
        Expect.equals(prevSize, values.length, '$name.remove($value).length');

        Expect.isTrue(values.add(value), '$name.add($value)');
        Expect.equals(prevSize + 1, values.length, '$name.add($value).length');

        // Reset in a way that won't look up `value`.
        values.clear();
        values.add(original);
      }
      Expect.equals(prevSize, values.length);
    }

    if (depth > 0) {
      checkSet(
        '$name.cast()',
        values.cast<Object>(),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
    }
  } on Error {
    print(
      "Failing set $name with ${isElement ? 'element' : 'non-element'} $value in $values",
    );
    rethrow;
  }
}

void checkIterable(
  String name,
  Iterable<Object?> values,
  Object value, {
  required bool isElement,
  int depth = 1,
}) {
  try {
    var expectIfElement = isElement ? Expect.isTrue : Expect.isFalse;

    expectIfElement(values.contains(value), '$name.contains($value)');

    if (depth > 0) {
      checkIterable(
        '$name.cast()',
        values.cast<Object>(),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.where()',
        values.where((_) => true),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.map()',
        values.map((v) => v),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.expand()',
        values.expand((v) => [v]),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.take()',
        values.take(999),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.skip()',
        values.skip(0),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.skipWhile()',
        values.skipWhile((_) => false),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.takeWhile()',
        values.takeWhile((_) => true),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.followedBy()',
        values.followedBy(values),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.indexed',
        values.indexed,
        (0, value), // Should be first value in iterable!
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.nonNulls',
        values.nonNulls,
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkIterable(
        '$name.whereType()',
        values.whereType<Object>(),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkList(
        '$name.toList()',
        values.toList(growable: false),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkList(
        mutable: true,
        '$name.toList(growable)',
        values.toList(growable: true),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
      checkSet(
        '$name.toSet()',
        values.toSet(),
        value,
        isElement: isElement,
        depth: depth - 1,
      );
    }
  } on Error {
    print(
      "Failing iterable $name with ${isElement ? 'element' : 'non-element'} $value in $values",
    );
    rethrow;
  }
}
