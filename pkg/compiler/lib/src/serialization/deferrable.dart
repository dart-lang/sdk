// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:compiler/src/serialization/serialization.dart';

/// Interface for data that may be deserialized lazily.
///
/// This interface should be used to wrap data objects that aren't needed in
/// later phases of the compiler. Usage of this class should follow a set
/// pattern. Given a class `C` with a field `m0` of type `E` that we wish to
/// make deferrable:
///
/// 1) `m0` should be replaced with an internal field, `_m1`, of type
///  `Deferrable<E>`.
/// 2) An internal constructor should be added to `C` that takes a `d` of type
///  `Deferrable<E>` to initialize `_m1`. This internal constructor should be
///  called from the readFromSource method/factory to create the instance
///  of `C`. `d` should be obtained using [DataSourceReader.readDeferrable].
///  Note: [DataSourceReader.readDeferrable] passes the correct
///  [DataSourceReader] to the reader function so that the [DataSourceReader]
///  does not have to be closed over. If necessary a static tear-off should be
///  used as the argument so a closure isn't created for every read.
/// 3) Any existing constructors of `C` should maintain the same signature
///  and initialize `_m1` passing `m` to [Deferrable.eager] where m is the value
///  previously used to initialize `m0`.
/// 4) If there are external references to `m0` then `C`s interface should be
///  maintained. A getter `m0` should be added: `E get m0 => _m1.loaded()`
/// 5) If all references to `m0` were internal, they can simply be replaced
///  with calls to `_m1.loaded()`.
///
/// Example class before:
///
/// class Foo {
///   final Bar bar;
///   final String name;
///
///   Foo(this.bar, this.name);
///
///   factory Foo.readFromSource(DataSourceReader reader) {
///     final bar = Bar.readFromSource(reader);
///     final name = reader.readString();
///     return Foo(bar, name);
///   }
/// }
///
/// After:
///
/// class Foo {
///   Bar get bar => _bar.loaded();
///   final Deferrable<Bar> _bar;
///
///   String get name => _name.loaded();
///   final Deferrable<String> _name;
///
///   Foo(Bar bar, String name) :
///       _bar = Deferrable.eager(bar), _name = Deferrable.eager(name);
///   Foo._deserialized(this._bar, this._name);
///
///   static String readName(DataSourceReader reader) => reader.readString();
///
///   factory Foo.readFromSource(DataSourceReader reader) {
///     final bar = reader.readDeferrable(Bar.readFromSource);
///     final name = reader.readDeferrable(readName);
///     return Foo._deserialized(bar, name);
///   }
/// }
abstract class Deferrable<E> {
  E loaded();

  factory Deferrable.deferred(
          DataSourceReader reader, E f(DataSourceReader source), int offset,
          {bool cacheData = true}) =>
      cacheData
          ? _DeferredCache(reader, f, offset)
          : _Deferred(reader, f, offset);
  static Deferrable<E> deferredWithArg<E, A>(DataSourceReader reader,
          E f(DataSourceReader source, A arg), A arg, int offset,
          {bool cacheData = true}) =>
      cacheData
          ? _DeferredCacheWithArg(reader, f, arg, offset)
          : _DeferredWithArg(reader, f, arg, offset);
  const factory Deferrable.eager(E data) = _Eager;

  const Deferrable();
}

class _Eager<E> extends Deferrable<E> {
  final E _data;
  @override
  E loaded() => _data;
  const _Eager(this._data);
}

class _DeferredWithArg<E, A> extends Deferrable<E> {
  final DataSourceReader _reader;
  final E Function(DataSourceReader source, A arg) _dataLoader;
  final A _arg;
  final int _dataOffset;
  @override
  E loaded() =>
      _reader.readWithOffset(_dataOffset, () => _dataLoader(_reader, _arg));
  _DeferredWithArg(this._reader, this._dataLoader, this._arg, this._dataOffset);
}

class _DeferredCacheWithArg<E, A> extends Deferrable<E> {
  final int _dataOffset;
  // Below fields are nullable so they can be cleared after loading.
  DataSourceReader? _reader;
  E Function(DataSourceReader source, A arg)? _dataLoader;
  A? _arg;
  late final E _data = _loadData();

  @override
  E loaded() => _data;

  E _loadData() {
    final reader = _reader!;
    final dataLoader = _dataLoader!;
    final arg = _arg!;
    _reader = null;
    _dataLoader = null;
    _arg = null;
    return reader.readWithOffset(_dataOffset, () => dataLoader(reader, arg));
  }

  _DeferredCacheWithArg(
      this._reader, this._dataLoader, this._arg, this._dataOffset);
}

class _Deferred<E> extends Deferrable<E> {
  final DataSourceReader _reader;
  final E Function(DataSourceReader source) _dataLoader;
  final int _dataOffset;
  @override
  E loaded() => _reader.readWithOffset(_dataOffset, () => _dataLoader(_reader));
  _Deferred(this._reader, this._dataLoader, this._dataOffset);
}

class _DeferredCache<E> extends Deferrable<E> {
  final int _dataOffset;
  // Below fields are nullable so they can be cleared after loading.
  DataSourceReader? _reader;
  E Function(DataSourceReader source)? _dataLoader;
  late final E _data = _loadData();

  @override
  E loaded() => _data;

  E _loadData() {
    final reader = _reader!;
    final dataLoader = _dataLoader!;
    _reader = null;
    _dataLoader = null;
    return reader.readWithOffset(_dataOffset, () => dataLoader(reader));
  }

  _DeferredCache(this._reader, this._dataLoader, this._dataOffset);
}

/// Implementation of [Map] in which each value of type [V] is internally
/// [Deferrable].
///
/// This map should be used when values of type [V] are expensive to
/// deserialize. This abstracts away the laziness allowing the deferred map to
/// be used as if the values were not deferred.
///
/// The provided map can have a mix of eager and lazy [Deferrable]s if
/// there are a mix of expensive and cheap values.
class DeferrableValueMap<K, V> with MapMixin<K, V> {
  DeferrableValueMap(this._map);
  final Map<K, Deferrable<V>> _map;
  @override
  V? operator [](Object? key) {
    return _map[key]?.loaded();
  }

  @override
  void operator []=(K key, V value) {
    _map[key] = Deferrable.eager(value);
  }

  @override
  void clear() {
    _map.clear();
  }

  @override
  Iterable<K> get keys => _map.keys;

  @override
  V? remove(Object? key) {
    return _map.remove(key)?.loaded();
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    return _map.putIfAbsent(key, () => Deferrable.eager(ifAbsent())).loaded();
  }
}
