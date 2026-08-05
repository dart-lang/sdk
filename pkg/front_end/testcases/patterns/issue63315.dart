// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type JsonMap1<T>(Map<String, Object?> _)
    implements Map<String, Object?> {
  T operator [](String key) => _[key] as T;
}

void parseJson1(JsonMap1 map) {
  if (map case {"key": "value"}) print("ok");
}

extension type JsonMap2<T>(Map<String, Object?> _)
    implements Map<String, Object?> {
  bool containsKey(String key) => _.containsKey(key);
}

void parseJson2(JsonMap2 map) {
  if (map case {"key": "value"}) print("ok");
}

extension type JsonMap3<T>(Map<String, Object?> _)
    implements Map<String, Object?> {
  int get length => _.length;
}

void parseJson3(JsonMap3 map) {
  if (map case {"key": "value"}) print("ok");
}

extension type JsonList1<T>(List<Object?> _) implements List<Object?> {
  T operator [](int index) => _[index] as T;
}

void parseJson4(JsonList1 list) {
  if (list case ["value"]) print("ok");
}

extension type JsonList2<T>(List<Object?> _) implements List<Object?> {
  int get length => _.length;
}

void parseJson5(JsonList2 list) {
  if (list case ["value"]) print("ok");
}

extension type JsonList3<T>(List<Object?> _) implements List<Object?> {
  List<T> sublist(int start, [int? end]) => _.sublist(start, end).cast<T>();
}

void parseJson6(JsonList3 list) {
  if (list case ["value"]) print("ok");
}
