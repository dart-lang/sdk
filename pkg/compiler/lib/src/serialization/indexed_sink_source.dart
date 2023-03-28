// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'serialization.dart';

abstract class IndexedSource<E> {
  E? read(E readValue());

  /// Reshapes the cache to a [Map<E, int>] using [_getValue] if provided or
  /// leaving the cache entry as is otherwise.
  Map<T?, int> reshapeCacheAsMap<T>([T Function(E? value)? getValue]);
}

abstract class IndexedSink<E> {
  void write(E value, void writeValue(E value));
}

/// Data sink helper that canonicalizes [E?] values using IDs.
///
/// Writes a unique ID in place of previously visited indexable values. This
/// ID is the offset in the data stream at which the serialized value can be
/// read. The read and write order do not need to be the same because no matter
/// what occurrence of the ID we encounter, we can always recover the value.
///
/// We increment all written offsets by [_startOffset] in order to distinguish
/// which source file the offset is from on deserialization.
/// See [UnorderedIndexedSource] for more info.
class UnorderedIndexedSink<E> implements IndexedSink<E> {
  final DataSinkWriter _sinkWriter;
  final Map<E?, int> _cache;
  final int _startOffset;

  UnorderedIndexedSink(this._sinkWriter,
      {Map<E?, int>? cache, int? startOffset})
      : // [cache] slot 1 is pre-allocated to `null`.
        this._cache = cache ?? {null: 1},
        this._startOffset = startOffset ?? 0;

  /// Write a reference to [value] to the data sink.
  ///
  /// If [value] has not been canonicalized yet, [writeValue] is called to
  /// serialize the [value] itself.
  @override
  void write(E? value, void writeValue(E value)) {
    final offset = _cache[value];
    if (offset == null) {
      // We reserve 0 as an indicator that the data is written 'here'.
      _sinkWriter.writeInt(0);
      final adjustedOffset = _sinkWriter.length + _startOffset;
      _sinkWriter.writeInt(adjustedOffset);
      _cache[value] = adjustedOffset;
      writeValue(value!); // null would have been found in slot 1
    } else {
      _sinkWriter.writeInt(offset);
    }
  }
}

/// Data source helper reads canonicalized [E?] values through IDs.
///
/// Reads indexable elements via their unique ID. Each ID is the offset in
/// the data stream at which the serialized value can be read. The first time an
/// ID is discovered we jump to the value's offset, deserialize it, and
/// then jump back to the 'current' offset.
///
/// In order to read cached offsets across files, we map offset ranges to a
/// specific source:
///
///   offset 0  .. K1    --- source S1
///   offset K1 .. K2    --- source S2
///   offset K2 .. K3    --- source S3
///
/// This effectively treats all the file as a contiguous address space with
/// offsets being relative to the start of the first source.
///
/// If an offset is encountered outside the block accessible to current source,
/// [previousSource] provides a pointer to the next source to check (i.e. the
/// previous block in the address space).
class UnorderedIndexedSource<E> implements IndexedSource<E> {
  final DataSourceReader _sourceReader;
  final Map<int, E?> _cache;
  final UnorderedIndexedSource<E>? previousSource;

  UnorderedIndexedSource(this._sourceReader, {this.previousSource})
      // [cache] slot 1 is pre-allocated to `null`.
      : _cache =
            previousSource != null ? {...previousSource._cache} : {1: null};

  /// Reads a reference to an [E?] value from the data source.
  ///
  /// If the value hasn't yet been read, [readValue] is called to deserialize
  /// the value itself.
  @override
  E? read(E readValue()) {
    final markerOrOffset = _sourceReader.readInt();

    // We reserve 0 as an indicator that the data is written 'here'.
    if (markerOrOffset == 0) {
      final offset = _sourceReader.readInt();
      // We have to read the value regardless of whether or not it's cached to
      // move the reader passed it.
      final value = readValue();
      final cachedValue = _cache[offset];
      if (cachedValue != null) return cachedValue;
      _cache[offset] = value;
      return value;
    }
    if (markerOrOffset == 1) return null;
    final cachedValue = _cache[markerOrOffset];
    if (cachedValue != null) return cachedValue;
    return _readAtOffset(readValue, markerOrOffset);
  }

  UnorderedIndexedSource<E> _findSource(int offset) {
    return offset >= _sourceReader.startOffset
        ? this
        : previousSource!._findSource(offset);
  }

  E? _readAtOffset(E readValue(), int offset) {
    final realSource = _findSource(offset);
    var adjustedOffset = offset - realSource._sourceReader.startOffset;
    final reader = () {
      _sourceReader.readInt();
      return readValue();
    };

    final value = realSource == this
        ? _sourceReader.readWithOffset(adjustedOffset, reader)
        : _sourceReader.readWithSource(realSource._sourceReader,
            () => _sourceReader.readWithOffset(adjustedOffset, reader));
    _cache[offset] = value;
    return value;
  }

  @override
  Map<T?, int> reshapeCacheAsMap<T>([T Function(E? value)? getValue]) {
    return _cache.map((key, value) =>
        MapEntry(getValue == null ? value as T? : getValue(value), key));
  }
}

/// Data sink helper that canonicalizes [E?] values using indices.
///
/// Writes a list index in place of already indexed values. This list index
/// is the order in which we discover the indexable elements. On deserialization
/// the indexable elements but be visited in the same order they were seen here
/// so that the indices are maintained. Since the read order is assumed to be
/// consistent, the actual data is written at the first occurrence of the
/// indexable element.
class OrderedIndexedSink<E> implements IndexedSink<E> {
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
class OrderedIndexedSource<E> implements IndexedSource<E> {
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
  Map<T?, int> reshapeCacheAsMap<T>([T Function(E? value)? getValue]) {
    var newCache = <T?, int>{};
    for (int i = 0; i < cache.length; i++) {
      final newKey = getValue == null ? cache[i] as T? : getValue(cache[i]);
      newCache[newKey] = i;
    }
    return newCache;
  }
}
