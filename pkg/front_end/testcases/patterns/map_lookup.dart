// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from co19/LanguageFeatures/Patterns/invocation_keys_A08_t01.dart

import "dart:collection";

bool get hasUnsoundNullSafety => const <Null>[] is List<Object>;

String unsoundResult = "containsKey(key1);"
    "[key1];"
    "containsKey(key2);"
    "[key2];";

String soundResult = "[key1];"
    "[key2];";

class MyMap<K, V> extends MapBase<K, V> {
  Map<K, V> _inner;
  String log = "";

  MyMap(this._inner);

  @override
  operator [](Object? key) {
    log += "[$key];";
    return _inner[key];
  }

  @override
  void operator []=(key, value) {
    log += "[$key]=$value;";
    _inner[key] = value;
  }

  @override
  void clear() {
    log += "clear();";
    _inner.clear();
  }

  @override
  Iterable<K> get keys {
    log += "keys;";
    return _inner.keys;
  }

  @override
  remove(Object? key) {
    log += "remove($key);";
    return _inner.remove(key);
  }

  @override
  int get length {
    log += "length;";
    return _inner.length;
  }

  @override
  bool containsKey(Object? key) {
    log += "containsKey($key);";
    return _inner.containsKey(key);
  }

  void clearLog() {
    log = "";
  }
}

String test1(Object o) {
  switch (o) {
    case <String, int>{"key1": 1, "key2": 3}: // Expect call [key1], [key2]
      return "match-2";
    case <String, int>{"key1": 1, "key2": 2}: // Expect no additional calls
      return "match-3";
    default:
      return "no match";
  }
}

String test2(Object o) => switch (o) {
      <String, int>{"key1": 1, "key2": 3} => "match-2",
      <String, int>{"key1": 1, "key2": 2} => "match-3",
      _ => "no match"
    };

main() {
  final map = MyMap<String, int>({"key1": 1, "key2": 2});
  expect("match-3", test1(map));
  expect(hasUnsoundNullSafety ? unsoundResult : soundResult, map.log);
  map.clearLog();

  expect("match-3", test2(map));
  expect(hasUnsoundNullSafety ? unsoundResult : soundResult, map.log);
  map.clearLog();

  var {"key1": x1, "key2": x2} = map;
  expect(hasUnsoundNullSafety ? unsoundResult : soundResult, map.log);
  map.clearLog();

  final {"key1": y1, "key2": y2} = map;
  expect(hasUnsoundNullSafety ? unsoundResult : soundResult, map.log);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
