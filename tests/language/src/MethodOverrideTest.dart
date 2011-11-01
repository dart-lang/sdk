// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that a method with an instantiated return type can override a method
// with a generic return type.

typedef Collection<K> GetKeysFunctionType<K>();

class MapBase<K, V> implements Map<K, V> {
  Collection<K> getKeys() {
    throw 'Must be implemented';
  }

  void Tests() {
    Expect.isTrue(this is MapBase<int, int>);

    Expect.isTrue(getKeys is GetKeysFunctionType);
    Expect.isTrue(getKeys is GetKeysFunctionType<int>);
    Expect.isTrue(getKeys is !GetKeysFunctionType<String>);
    Expect.isTrue(getKeys is !GetKeysFunctionType<MapBase<int, int>>);
  }
}


class MethodOverrideTest extends MapBase<String, String> {
  Collection<String> getKeys() {
    throw 'Is implemented';
  }

  void Tests() {
    Expect.isTrue(this is MethodOverrideTest);
    Expect.isTrue(this is MapBase<String, String>);

    Expect.isTrue(getKeys is GetKeysFunctionType);
    Expect.isTrue(getKeys is GetKeysFunctionType<String>);
    Expect.isTrue(getKeys is !GetKeysFunctionType<int>);
    Expect.isTrue(super.getKeys is GetKeysFunctionType);
    Expect.isTrue(super.getKeys is GetKeysFunctionType<String>);
    Expect.isTrue(super.getKeys is !GetKeysFunctionType<int>);
  }
}


main() {
  // Since method overriding is only checked statically, explicitly check
  // the subtyping relation using a function type alias.
  var x = new MethodOverrideTest();
  Expect.isTrue(x.getKeys is GetKeysFunctionType<String>);

  // Perform a few more tests.
  x.Tests();

  var m = new MapBase<int, int>();
  Expect.isTrue(m.getKeys is GetKeysFunctionType<int>);

  // Perform a few more tests.
  m.Tests();
}
