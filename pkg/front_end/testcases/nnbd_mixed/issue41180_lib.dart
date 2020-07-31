// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<X> {
  C(Map<String, String> Function() f) {
    print(f.runtimeType);
  }
}

void foo(Map<String, String> Function() f) {
  print(f.runtimeType);
}

void set bar(Map<String, String> Function() f) {
  print(f.runtimeType);
}

class Map<K, V> {
  final K key;
  final V value;

  Map(this.key, this.value);

  Iterable<MapEntry<K, V>> get entries =>
      new Iterable<MapEntry<K, V>>(new MapEntry<K, V>(key, value));
}

class Iterable<E> {
  final E element;

  Iterable(this.element);

  E singleWhere(bool test(E element), {E orElse()?}) {
    if (test(element)) {
      return element;
    }
    if (orElse != null) return orElse();
    throw 'error';
  }
}
