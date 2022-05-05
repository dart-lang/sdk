// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'data_sink.dart';
import 'data_source.dart';

/// Data sink helper that canonicalizes [E?] values using indices.
class IndexedSink<E extends Object> {
  final DataSink _sink;
  final Map<E?, int> cache;

  IndexedSink._(this._sink, this.cache);

  factory IndexedSink(DataSink sink, {Map<E?, int>? cache}) {
    // [cache] slot 0 is pre-allocated to `null`.
    cache ??= {null: 0};
    return IndexedSink._(sink, cache);
  }

  /// Write a reference to [value] to the data sink.
  ///
  /// If [value] has not been canonicalized yet, [writeValue] is called to
  /// serialize the [value] itself.
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
class IndexedSource<E extends Object> {
  final DataSource _source;
  final List<E?> cache;

  IndexedSource._(this._source, this.cache);

  factory IndexedSource(DataSource source, {List<E?>? cache}) {
    // [cache] slot 0 is pre-allocated to `null`.
    cache ??= [null];
    return IndexedSource._(source, cache);
  }

  /// Reads a reference to an [E] value from the data source.
  ///
  /// If the value hasn't yet been read, [readValue] is called to deserialize
  /// the value itself.
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
}
