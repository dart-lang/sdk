// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Mixin to be used by entities that will be keys for either [EntityDataMap]
/// or [EntityDataEnvMap].
mixin class EntityMapKey {
  int? _index;
}

/// Map of entities of type [K] with a corresponding data object of type [V].
class EntityDataMap<K extends EntityMapKey, V extends Object> {
  final List<(K, V)?> _list = [];
  int _length = 0;
  int get length => _length;

  /// Returns the data object stored for [entity].
  V getData(K entity) {
    return _list[entity._index!]!.$2;
  }

  /// Registers a new [entity] with an associated [data] object.
  ///
  /// The index of [entity] is set to match its index in the entity and data
  /// lists in this map.
  K0 register<K0 extends K, V0 extends V>(K0 entity, V0 data) {
    entity._index = _list.length;
    _list.add((entity, data));
    _length++;
    return entity;
  }

  /// Skips an index in the entity map assignments allowing for consistent
  /// indexing across multiple maps where some entities are filtered.
  void skipIndex() {
    _list.add(null);
  }

  void markAsCopy({required K original, required K copy}) {
    copy._index = original._index;
  }

  /// Calls [f] for each non-null entity with its corresponding data object.
  void forEach(void f(K entity, V data)) {
    // Copy the length in case the list is modified during the loop.
    int length = _list.length;
    for (int i = 0; i < length; i++) {
      final entry = _list[i];
      if (entry != null) {
        f(entry.$1, entry.$2);
      }
    }
  }
}

/// Index based of entities of type [K] with a corresponding data object of
/// type [V] and an environment of type [Env].
class EntityDataEnvMap<K extends EntityMapKey, V extends Object,
    Env extends Object> {
  final List<(K, V, Env)?> _list = [];
  int _length = 0;
  int get length => _length;

  /// Returns the environment object stored for the entity.
  Env getEnv(K entity) {
    return _list[entity._index!]!.$3;
  }

  /// Returns the data object stored for [entity].
  V getData(K entity) {
    return _list[entity._index!]!.$2;
  }

  /// Registers a new [entity] with an associated [data] object and environment
  /// [env].
  ///
  /// The index of [entity] is set to match its index in the entity, data and
  /// environment lists in this map.
  K0 register<K0 extends K, V0 extends V, Env0 extends Env>(
      K0 entity, V0 data, Env0 env) {
    entity._index = _list.length;
    _list.add((entity, data, env));
    _length++;
    return entity;
  }

  void skipIndex() {
    _list.add(null);
  }

  void markAsCopy({required K original, required K copy}) {
    copy._index = original._index;
  }

  /// Calls [f] for each non-null entity with its corresponding data object and
  /// environment.
  void forEach(void f(K entity, V data, Env env)) {
    // Copy the length in case the list is modified during the loop.
    int length = _list.length;
    for (int i = 0; i < length; i++) {
      final entry = _list[i];
      if (entry != null) {
        f(entry.$1, entry.$2, entry.$3);
      }
    }
  }
}
