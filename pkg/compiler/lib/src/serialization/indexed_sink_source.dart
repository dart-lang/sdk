// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'data_sink.dart';
import 'data_source.dart';

abstract class IndexedSource<E> {
  E? read(E readValue());

  /// Reshapes the cache to a [Map<E, int>] using [_getValue] if provided or
  /// leaving the cache entry as is otherwise.
  Map<T, int> reshape<T>([T Function(E? value)? getValue]);
}

abstract class IndexedSink<E> {
  void write(E value, void writeValue(E value));
}

/// Data sink helper that canonicalizes [E?] values using indices.
///
/// Writes a list index in place of already indexed values. This list index
/// is the order in which we discover the indexable elements. On deserialization
/// the indexable elements but be visited in the same order they were seen here
/// so that the indices are maintained. Since the read order is assumed to be
/// consistent, the actual data is written at the first occurrence of the
/// indexable element.
class OrderedIndexedSink<E extends Object> implements IndexedSink<E> {
  final DataSink _sink;
  final Map<E?, int> cache;

  OrderedIndexedSink._(this._sink, this.cache);

  factory OrderedIndexedSink(DataSink sink, {Map<E?, int>? cache}) {
    // [cache] slot 0 is pre-allocated to `null`.
    cache ??= {null: 0};
    return OrderedIndexedSink._(sink, cache);
  }

  /// Write a reference to [value] to the data sink.
  ///
  /// If [value] has not been canonicalized yet, [writeValue] is called to
  /// serialize the [value] itself.
  @override
  void write(E? value, void writeValue(E value)) {
    const int pending = -1;
    int? index = cache[value];
    if (index == null) {
      index = cache.length;
      _sink.writeInt(index);
      cache[value] = pending; // Increments length to allocate slot.
      writeValue(value!); // `null` would have been found in slot 0.
      cache[value] = index;
    } else if (index == pending) {
      throw ArgumentError("Cyclic dependency on cached value: $value");
    } else {
      _sink.writeInt(index);
    }
  }
}

/// Data source helper reads canonicalized [E?] values through indices.
///
/// Reads indexable elements treating their read order as their index. Since the
/// read order is consistent with the write order, when a new index is
/// discovered we assume the data is written immediately after. Subsequent
/// occurrences of that index then refer to the same value. Indices will appear
/// in ascending order.
class OrderedIndexedSource<E extends Object> implements IndexedSource<E> {
  final DataSource _source;
  final List<E?> cache;

  OrderedIndexedSource._(this._source, this.cache);

  factory OrderedIndexedSource(DataSource source, {List<E?>? cache}) {
    // [cache] slot 0 is pre-allocated to `null`.
    cache ??= [null];
    return OrderedIndexedSource._(source, cache);
  }

  /// Reads a reference to an [E] value from the data source.
  ///
  /// If the value hasn't yet been read, [readValue] is called to deserialize
  /// the value itself.
  @override
  E? read(E readValue()) {
    int index = _source.readInt();
    if (index >= cache.length) {
      assert(index == cache.length);
      cache.add(null); // placeholder.
      E value = readValue();
      cache[index] = value;
      return value;
    } else {
      E? value = cache[index];
      if (value == null && index != 0) {
        throw StateError('Unfilled index $index of $E');
      }
      return value;
    }
  }

  @override
  Map<T, int> reshape<T>([T Function(E? value)? getValue]) {
    var newCache = <T, int>{};
    for (int i = 0; i < cache.length; i++) {
      final newKey = getValue == null ? cache[i] as T : getValue(cache[i]);
      newCache[newKey] = i;
    }
    return newCache;
  }
}
