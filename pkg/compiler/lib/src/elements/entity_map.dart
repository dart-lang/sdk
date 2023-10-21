// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Indexed entity interfaces for modeling elements derived from Kernel IR.

/// Map of entities of type [K] with a corresponding data object of type [V].
class EntityDataMap<K extends Object, V extends Object> {
  final Map<K, V> _data = {};
  int get length => _data.length;

  /// Returns the data object stored for [entity].
  V getData(K entity) {
    return _data[entity]!;
  }

  /// Registers a new [entity] with an associated [data] object.
  ///
  /// The index of [entity] is set to match its index in the entity and data
  /// lists in this map.
  K0 register<K0 extends K, V0 extends V>(K0 entity, V0 data) {
    assert(!_data.containsKey(entity),
        "Trying to register $entity when already registered.");
    _data[entity] = data;
    return entity;
  }

  /// Calls [f] for each non-null entity with its corresponding data object.
  void forEach(void f(K entity, V data)) {
    // Use a copy of keys to allow for concurrent modification.
    for (final key in [..._data.keys]) {
      f(key, _data[key]!);
    }
  }
}

/// Index based of entities of type [K] with a corresponding data object of
/// type [V] and an environment of type [Env].
class EntityDataEnvMap<K extends Object, V extends Object, Env extends Object> {
  final Map<K, (V, Env)> _map = {};

  int get length => _map.length;

  /// Returns the environment object stored for the entity.
  Env getEnv(K entity) {
    return _map[entity]!.$2;
  }

  /// Returns the data object stored for [entity].
  V getData(K entity) {
    return _map[entity]!.$1;
  }

  /// Registers a new [entity] with an associated [data] object and environment
  /// [env].
  ///
  /// The index of [entity] is set to match its index in the entity, data and
  /// environment lists in this map.
  K0 register<K0 extends K, V0 extends V, Env0 extends Env>(
      K0 entity, V0 data, Env0 env) {
    assert(!_map.containsKey(entity),
        "Trying to register $entity when already registered.");
    _map[entity] = (data, env);
    return entity;
  }

  /// Calls [f] for each non-null entity with its corresponding data object and
  /// environment.
  void forEach(void f(K entity, V data, Env env)) {
    // Use a copy of keys to allow for concurrent modification.
    for (final key in [..._map.keys]) {
      final data = _map[key]!;
      f(key, data.$1, data.$2);
    }
  }
}
