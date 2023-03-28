// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {}

mixin MixinA<T> {
  T method(Object t);
}

abstract class Class extends Base with MixinA {
  method(t) {}
}

abstract class YamlNode {}

abstract class Map<K, V> {
  V operator [](Object key);
}

mixin MapMixin<K, V> implements Map<K, V> {
  V operator [](Object key);
}

mixin UnmodifiableMapMixin<K, V> implements Map<K, V> {}

class YamlMap extends YamlNode with MapMixin, UnmodifiableMapMixin {
  operator [](key) {}
}

main() {}
