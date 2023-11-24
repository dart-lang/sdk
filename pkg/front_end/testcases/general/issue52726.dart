// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class WeakMap<K extends Object, V> {
  WeakMap(List<(K, V)> entries) {
    var mapped = entries.map((i) => [i.$1, i.$2]);
    var first = mapped.first;
    first.add(null);
    Object o = first.first; // Error.
  }
}

