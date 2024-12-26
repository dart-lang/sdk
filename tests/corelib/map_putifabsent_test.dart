// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that `putIfAbsent(key, ifAbsent)` works like `[key]=ifAbsent()`
// if the key is not in the map, and as `[key]` if the key is in the map.

import "package:expect/expect.dart";
import 'dart:collection';

void main() {
  testMaps<Object?, Object?>();
  testMaps<Object, Object?>();
  testMaps<Object?, Object>();
  testMaps<Object, Object>();
}

void testMaps<K, V>() {
  // Testing `putIfAbsent` of the platform maps.
  test(() => HashMap<K, V>());
  test(() => LinkedHashMap<K, V>());
  test(() => SplayTreeMap<K, V>(), ordered: true);
  test(() => SplayTreeMap<K, V>(compareComparable), ordered: true);
  // The identity version.
  test(() => Map<K, V>.identity(), identity: true);
  test(() => HashMap<K, V>.identity(), identity: true);
  test(() => LinkedHashMap<K, V>.identity(), identity: true);
  // And the configured versions, with equality.
  test(
    () => HashMap<K, V>(equals: (x, y) => x == y, hashCode: (x) => x.hashCode),
  );
  test(
    () => LinkedHashMap<K, V>(
      equals: (x, y) => x == y,
      hashCode: (x) => x.hashCode,
    ),
  );
  // With identity, recognizable as such, and not.
  test(
    () => HashMap<K, V>(equals: identical, hashCode: identityHashCode),
    identity: true,
  );
  test(
    () => LinkedHashMap<K, V>(equals: identical, hashCode: identityHashCode),
    identity: true,
  );
  test(
    () => HashMap<K, V>(
      equals: (x, y) => identical(x, y),
      hashCode: (x) => identityHashCode(x),
    ),
    identity: true,
  );
  test(
    () => LinkedHashMap<K, V>(
      equals: (x, y) => identical(x, y),
      hashCode: (x) => identityHashCode(x),
    ),
    identity: true,
  );

  // Test that [MapView] doesn't break anything.
  test(() => MapView(HashMap<K, V>()));
  test(() => MapView(SplayTreeMap<K, V>()), ordered: true);

  // Test the `putIfAbsent` implementation of `MapBase` and `MapMixin`.
  test(() => MapBaseMap<K, V>());
  test(() => MapMixinMap<K, V>());
}

// Key and value types may be `Object?` or `Object`.
// If [identity] is true, the map uses identical as equality.
// If [ordered] is true, the map uses a `Comparable` as equality
// (and cannot accept `null` as key, even if the key type is `Object?`).
// Otherwise it uses `==` and maybe `hashCode`.
void test<K, V>(
  Map<K, V> Function() map, {
  bool identity = false,
  bool ordered = false,
}) {
  // Different kinds of keys.
  // Every key type implements `Comparable`.

  // Custom key objects overriding `==`.
  var key1 = Key(1) as K;
  var key1B = Key(1) as K; // Equal, not identical to key1.
  var key2 = Key(2) as K; // Different from, but comparable to, key1.
  testKeys<K, V>(
    map(),
    key1,
    key1B,
    key2,
    identity: identity,
    ordered: ordered,
  );

  // Custom key objects not overriding `==`.
  // (Cannot have equal-but-not-identical value.)
  var idKey1 = IdKey(1) as K;
  var idKey2 = IdKey(2) as K;
  testKeys<K, V>(
    map(),
    idKey1,
    idKey1,
    idKey2,
    identity: identity,
    ordered: ordered,
  );

  // Built-in/"native" keys.
  var num1 = 1 as K;
  var num1B = 1.0 as K; // Equal, but sometimes not identical, to num1.
  var num2 = 2 as K; // Different from, but comparable to, key1.
  testKeys<K, V>(
    map(),
    num1,
    num1B,
    num2,
    identity: identity,
    ordered: ordered,
  );

  // String keys (because web treats those specially).
  var str1 = "abc" as K;
  // Obfuscate that it's always "abc". Try to make it not canonicalized.
  var str1B = String.fromCharCodes(("abcmore").codeUnits.take(3)) as K;
  var str2 = "def" as K;
  Expect.equals(str1, str1B, "Something's badly wrong with str1B?");
  testKeys<K, V>(
    map(),
    str1,
    str1B,
    str2,
    identity: identity,
    ordered: ordered,
  );
}

void testKeys<K, V>(
  Map<K, V> map,
  K k1,
  K k1b,
  K k2, {
  required bool identity,
  required bool ordered,
}) {
  var ifAbsentCalled = 0;

  var v42 = 42 as V;
  var v37 = 37 as V;
  var v87 = 87 as V;
  var vb = "BANANA" as V;

  V Function() add(K key, V value) => () {
    expectNotIn(map, key);
    ifAbsentCalled++;
    return value;
  };

  V? result;

  Expect.mapEquals({}, map);
  result = map.putIfAbsent(k1, add(k1, v42));
  Expect.mapEquals({k1: 42}, map); // Added k1:42
  Expect.equals(1, ifAbsentCalled); // Called add(42).
  Expect.equals(42, result); // Returned 42.

  ifAbsentCalled = 0;

  // Using same key again doesn't change map or call `ifAbsent`.
  result = map.putIfAbsent(k1, add(k1, v87));
  Expect.mapEquals({k1: 42}, map); // Did not change map.
  Expect.equals(0, ifAbsentCalled); // Did not call add(87)
  Expect.equals(42, result); // Returned existing value.

  // Same for equal, but not identical, key.
  if (!identity) {
    result = map.putIfAbsent(k1b, add(k1b, v87));
    Expect.mapEquals({k1: 42}, map); // Did not change map.
    Expect.equals(0, ifAbsentCalled); // Did not call add(87)
    Expect.equals(42, result); // Returned existing value.
  }

  if (map is! Map<Object?, Object>) {
    var vNull = null as V;
    // Allows null value. Check that a null value isn't the same as no key.
    Expect.mapEquals({k1: 42}, map);
    result = map.putIfAbsent(k2, add(k2, vNull));
    Expect.mapEquals({k1: 42, k2: null}, map); // Added k2:null.
    Expect.equals(1, ifAbsentCalled); // Called add(null).
    Expect.equals(null, result); // Returned null.
    ifAbsentCalled = 0;

    result = map.putIfAbsent(k2, add(k2, v87));
    Expect.mapEquals({k1: 42, k2: null}, map); // Did not change map.
    Expect.equals(0, ifAbsentCalled); // Did not call add(87)
    Expect.equals(null, result); // Returned existing value.

    map.remove(k2);
  }

  if (!ordered && map is! Map<Object, Object?>) {
    // Allows null key.
    Expect.mapEquals({k1: 42}, map);
    var kNull = null as K;
    result = map.putIfAbsent(kNull, add(kNull, v37));
    Expect.mapEquals({k1: 42, null: 37}, map); // Added null:37
    Expect.equals(1, ifAbsentCalled); // Called add(37).
    Expect.equals(37, result); // Returned 37.
    ifAbsentCalled = 0;

    result = map.putIfAbsent(kNull, add(kNull, v87));
    Expect.mapEquals({k1: 42, null: 37}, map); // Did not change map.
    Expect.equals(0, ifAbsentCalled); // Did not call add(87)
    Expect.equals(37, result); // Returned existing value.

    map.remove(null);
  }
  Expect.mapEquals({k1: 42}, map);

  // Concurrent modification allowed.
  // If `ifAbsent` modifies map, the returned value is still added.

  // Remove inside ifAbsent.
  result = map.putIfAbsent(k2, () {
    expectNotIn(map, k2);
    ifAbsentCalled++;
    return map.remove(k1) as V; // Remove inside putIfAbsent.
  });
  Expect.mapEquals({k2: 42}, map);
  Expect.equals(1, ifAbsentCalled);
  Expect.equals(42, result);
  ifAbsentCalled = 0;

  // Add other key inside ifAbsent.
  map.clear();
  Expect.mapEquals({}, map);
  result = map.putIfAbsent(k1, () {
    expectNotIn(map, k1);
    map[k2] = v87; // Add other key.
    ifAbsentCalled++;
    return v42;
  });
  Expect.mapEquals({k1: 42, k2: 87}, map);
  Expect.equals(1, ifAbsentCalled);
  Expect.equals(42, result);
  ifAbsentCalled = 0;

  map.remove(k1);
  Expect.mapEquals({k2: 87}, map);

  // Add same key inside ifAbsent.
  result = map.putIfAbsent(k1, () {
    expectNotIn(map, k1);
    map[k1] = vb; // Add value for same key.
    Expect.mapEquals({k1: "BANANA", k2: 87}, map);
    ifAbsentCalled++;
    return v42;
  });
  Expect.mapEquals({k1: 42, k2: 87}, map); // Value was overwritten.
  Expect.equals(1, ifAbsentCalled);
  Expect.equals(42, result);
  ifAbsentCalled = 0;

  map.remove(k1);
  Expect.mapEquals({k2: 87}, map);

  // Add *and* remove same key inside ifAbsent.
  result = map.putIfAbsent(k1, () {
    expectNotIn(map, k1);
    map[k1] = vb; // Add value for same key.
    Expect.mapEquals({k1: "BANANA", k2: 87}, map);
    map.remove(k1);
    Expect.mapEquals({k2: 87}, map);
    ifAbsentCalled++;
    return v42;
  });
  Expect.mapEquals({k1: 42, k2: 87}, map); // Value was overwritten.
  Expect.equals(1, ifAbsentCalled);
  Expect.equals(42, result);
  ifAbsentCalled = 0;

  // Add same key inside ifAbsent using `putIfAbsent`.
  map.remove(k1);
  Expect.mapEquals({k2: 87}, map);
  result = map.putIfAbsent(k1, () {
    expectNotIn(map, k1);
    result = map.putIfAbsent(k1, add(k1, vb)); // Add value for same key.
    Expect.equals(1, ifAbsentCalled);
    Expect.mapEquals({k1: "BANANA", k2: 87}, map);
    ifAbsentCalled++;
    return v42;
  });
  Expect.mapEquals({k1: 42, k2: 87}, map); // Value was overwritten.
  Expect.equals(2, ifAbsentCalled);
  Expect.equals(42, result);
  ifAbsentCalled = 0;

  // Throw inside ifAbsent.
  map.remove(k2);
  Expect.mapEquals({k1: 42}, map);
  try {
    result = map.putIfAbsent(k2, () {
      expectNotIn(map, k2);
      ifAbsentCalled++;
      throw "EXIT";
    });
  } on String catch (e) {
    Expect.equals("EXIT", e);
  }
  expectNotIn(map, k2);
  Expect.mapEquals({k1: 42}, map);

  // Throw inside ifAbsent after doing modification. Modification stays.
  map.remove(k2);
  Expect.mapEquals({k1: 42}, map);
  try {
    result = map.putIfAbsent(k2, () {
      expectNotIn(map, k2);
      result = map.putIfAbsent(k2, add(k2, v87));
      ifAbsentCalled++;
      throw "EXIT";
    });
  } on String catch (e) {
    Expect.equals("EXIT", e);
  }
  Expect.mapEquals({k1: 42, k2: 87}, map);
}

// -------------------------------------------------------------------
// Helper classes and functions.

// Key class that does not override `operator==`.
class IdKey implements Comparable<IdKey> {
  final int id;
  const IdKey(this.id);
  int compareTo(IdKey other) => id.compareTo(other.id);
  String toString() => "IdKey($id)";
}

// Key class that does override `operator==`.
class Key extends IdKey {
  const Key(super.id);
  int get hashCode => id.hashCode ^ 0x3a5f731;
  bool operator ==(Object other) => other is Key && id == other.id;
  String toString() => "Key($id)";
}

int compareComparable(Object? v1, Object? v2) =>
    (v1 as Comparable<Object?>).compareTo(v2);

// Slow implementation of Map based on MapBase.
// Taken from `map_test.dart`.
mixin class MapBaseOperations<K, V> {
  final List<K> _keys = <K>[];
  final List<V> _values = <V>[];

  V? operator [](Object? key) {
    if (key is! K) return null;
    int index = _keys.indexOf(key);
    if (index < 0) return null;
    return _values[index];
  }

  // Not testing this, so not caring if it recognizes concurrent modifications.
  Iterable<K> get keys => _keys.skip(0);

  void operator []=(K key, V value) {
    int index = _keys.indexOf(key);
    if (index >= 0) {
      _values[index] = value;
    } else {
      _keys.add(key);
      _values.add(value);
    }
  }

  V? remove(Object? key) {
    if (key is! K) return null;
    int index = _keys.indexOf(key);
    if (index >= 0) {
      var result = _values[index];
      key = _keys.removeLast();
      var value = _values.removeLast();
      if (index != _keys.length) {
        _keys[index] = key;
        _values[index] = value;
      }
      return result;
    }
    return null;
  }

  void clear() {
    // Clear cannot be based on remove, since remove won't remove keys that
    // are not equal to themselves.
    _keys.clear();
    _values.clear();
  }
}

class MapBaseMap<K, V> = MapBase<K, V> with MapBaseOperations<K, V>;
class MapMixinMap<K, V> = MapBaseOperations<K, V> with MapMixin<K, V>;

void expectNotIn(Map<Object?, Object?> map, Object? key) {
  Expect.isFalse(map.containsKey(key));
  Expect.isNull(map[key]);
  Expect.isFalse(map.keys.contains(key));
}
