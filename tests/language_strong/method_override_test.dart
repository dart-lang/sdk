// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Checks that a method with an instantiated return type can override a method
// with a generic return type.

typedef V RemoveFunctionType<K, V>(K key);

class MapBase<K, V> implements Map<K, V> {
  K remove(K key) {
    throw 'Must be implemented';
  }

  void Tests() {
    Expect.isTrue(this is MapBase<int, int>);

    Expect.isTrue(remove is RemoveFunctionType);
    Expect.isTrue(remove is RemoveFunctionType<int, int>);
    Expect.isTrue(remove is! RemoveFunctionType<String, int>);
    Expect.isTrue(remove is! RemoveFunctionType<MapBase<int, int>, int>);
  }
}

class MethodOverrideTest extends MapBase<String, String> {
  String remove(String key) {
    throw 'Must be implemented';
  }

  void Tests() {
    Expect.isTrue(this is MethodOverrideTest);
    Expect.isTrue(this is MapBase<String, String>);

    Expect.isTrue(remove is RemoveFunctionType);
    Expect.isTrue(remove is RemoveFunctionType<String, String>);
    Expect.isTrue(remove is! RemoveFunctionType<int, int>);
    Expect.isTrue(super.remove is RemoveFunctionType);
    Expect.isTrue(super.remove is RemoveFunctionType<String, String>);
    Expect.isTrue(super.remove is! RemoveFunctionType<int, int>);
  }
}

main() {
  // Since method overriding is only checked statically, explicitly check
  // the subtyping relation using a function type alias.
  var x = new MethodOverrideTest();
  Expect.isTrue(x.remove is RemoveFunctionType<String, String>);

  // Perform a few more tests.
  x.Tests();

  var m = new MapBase<int, int>();
  Expect.isTrue(m.remove is RemoveFunctionType<int, int>);

  // Perform a few more tests.
  m.Tests();
}
