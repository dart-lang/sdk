// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Indexed entity interfaces for modeling elements derived from Kernel IR.

import '../elements/entities.dart';

abstract class _Indexed {
  int _index;
}

abstract class IndexedLibrary extends _Indexed implements LibraryEntity {
  /// Library index used for fast lookup in [KernelToElementMapBase].
  int get libraryIndex => _index;
}

abstract class IndexedClass extends _Indexed implements ClassEntity {
  /// Class index used for fast lookup in [KernelToElementMapBase].
  int get classIndex => _index;
}

abstract class IndexedMember extends _Indexed implements MemberEntity {
  /// Member index used for fast lookup in [KernelToElementMapBase].
  int get memberIndex => _index;
}

abstract class IndexedFunction extends _Indexed
    implements IndexedMember, FunctionEntity {}

abstract class IndexedConstructor
    implements IndexedFunction, ConstructorEntity {}

abstract class IndexedField implements IndexedMember, FieldEntity {}

abstract class IndexedTypeVariable extends _Indexed
    implements TypeVariableEntity {
  /// Type variable index used for fast lookup in [KernelToElementMapBase].
  int get typeVariableIndex => _index;
}

abstract class IndexedTypedef extends _Indexed implements TypedefEntity {
  /// Typedef index used for fast lookup in [KernelToElementMapBase].
  int get typedefIndex => _index;
}

abstract class IndexedLocal extends _Indexed implements Local {
  int get localIndex => _index;
}

/// Base implementation for an index based map of entities of type [E].
abstract class EntityMapBase<E extends _Indexed> {
  List<E> _list = <E>[];

  /// Returns the [index]th entity in the map.
  E getEntity(int index) => _list[index];

  /// Returns the number entities in the map.
  int get length => _list.length;
}

/// Index based map of entities of type [E].
class EntityMap<E extends _Indexed> extends EntityMapBase<E> {
  /// Registers a new [entity].
  ///
  /// The index of [entity] is set to match its index in the entity list in this
  /// map.
  E0 register<E0 extends E>(E0 entity) {
    assert(entity != null);
    assert(entity._index == null);
    entity._index = _list.length;
    _list.add(entity);
    return entity;
  }
}

/// Base implementation of an index based map of entities of type [E] with a
/// corresponding data object of type [D].
abstract class EntityDataMapBase<E extends _Indexed, D>
    extends EntityMapBase<E> {
  List<D> _data = <D>[];

  /// Returns the data object stored for the [index]th entity.
  D getData(E entity) {
    int index = entity._index;
    if (index < length && index >= _data.length) {
      throw new StateError(
          'Data is in the process of being created for ${_list[index]}.');
    }
    return _data[index];
  }
}

/// Index based map of entities of type [E] with a corresponding data object
/// of type [D].
class EntityDataMap<E extends _Indexed, D> extends EntityDataMapBase<E, D> {
  /// Mark entity [index] as missing
  void skipIndex(int index) {
    assert(index == _list.length);
    _list.add(null);
    _data.add(null);
  }

  /// Registers a new [entity] with an associated [data] object.
  ///
  /// The index of [entity] is set to match its index in the entity and data
  /// lists in this map.
  E0 register<E0 extends E, D0 extends D>(E0 entity, D0 data) {
    assert(entity != null);
    assert(entity._index == null);
    entity._index = _list.length;
    _list.add(entity);
    assert(data != null);
    _data.add(data);
    return entity;
  }
}

/// Base implementation for an index based of entities of type [E] with a
/// corresponding data object of type [D] and an environment of type [V].
abstract class EntityDataEnvMapBase<E extends _Indexed, D, V>
    extends EntityDataMapBase<E, D> {
  List<V> _env = <V>[];

  /// Returns the environment object stored for the [index]th entity.
  V getEnv(E entity) {
    int index = entity._index;
    if (index < length && index >= _env.length) {
      throw new StateError(
          'Env is in the process of being created for ${_list[index]}.');
    }
    return _env[index];
  }
}

/// Index based of entities of type [E] with a corresponding data object of
/// type [D] and an environment of type [V].
class EntityDataEnvMap<E extends _Indexed, D, V>
    extends EntityDataEnvMapBase<E, D, V> {
  /// Registers a new [entity] with an associated [data] object and environment
  /// [env].
  ///
  /// The index of [entity] is set to match its index in the entity, data and
  /// environment lists in this map.
  E0 register<E0 extends E, D0 extends D, V0 extends V>(
      E0 entity, D0 data, V0 env) {
    assert(entity != null);
    assert(entity._index == null);
    entity._index = _list.length;
    _list.add(entity);
    assert(data != null);
    _data.add(data);
    assert(env != null);
    _env.add(env);
    return entity;
  }
}
