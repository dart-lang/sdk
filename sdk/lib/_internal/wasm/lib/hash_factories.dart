// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_compact_hash";
import "dart:_internal" show patch;
import "dart:_wasm";

import "dart:typed_data" show Uint32List;

@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap(
      {bool equals(K key1, K key2)?,
      int hashCode(K key)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null && equals == null) {
        return WasmDefaultMap<K, V>();
      }
      if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return CompactLinkedIdentityHashMap<K, V>();
      }
    }
    hashCode ??= _defaultHashCode;
    equals ??= _defaultEquals;
    return CompactLinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @pragma("wasm:entry-point")
  static WasmDefaultMap<K, V> _default<K, V>() => WasmDefaultMap<K, V>();

  @patch
  factory LinkedHashMap.identity() => CompactLinkedIdentityHashMap<K, V>();
}

@patch
class LinkedHashSet<E> {
  @patch
  factory LinkedHashSet(
      {bool equals(E e1, E e2)?,
      int hashCode(E e)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null && equals == null) {
        return WasmDefaultSet<E>();
      }
      if (identical(identityHashCode, hashCode) &&
          identical(identical, equals)) {
        return CompactLinkedIdentityHashSet<E>();
      }
    }
    hashCode ??= _defaultHashCode;
    equals ??= _defaultEquals;
    return CompactLinkedCustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @pragma("wasm:entry-point")
  static WasmDefaultSet<E> _default<E>() => WasmDefaultSet<E>();

  @patch
  factory LinkedHashSet.identity() => CompactLinkedIdentityHashSet<E>();
}
