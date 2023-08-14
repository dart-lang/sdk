// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// todo(pq): move to collections
extension MapExtension<K, V> on Map<K, List<V>> {
  void add(K key, V value) {
    (this[key] ??= []).add(value);
  }
}
