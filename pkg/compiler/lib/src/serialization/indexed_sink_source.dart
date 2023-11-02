// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'serialization.dart';

abstract class IndexedSource<E extends Object> {
  Map<int, E> get cache;

  E? read(DataSourceReader source, E readValue());
}

abstract class IndexedSink<E extends Object> {
  Map<E, int> get cache;

  void write(DataSinkWriter sink, E? value, void writeValue(E value));
}

const int _dataInPlaceIndicator = 0;
const int _nullIndicator = 1;
const int _indicatorOffset = 2;

/// Facilitates indexed reads and writes for [IndexedSource] and [IndexedSink].
///
/// Created and stores shared [IndexedSource] and [IndexedSink] instances for
/// cached types. Copies indices from sources to sinks when a sink is requested
/// so that the indices are shared across data files.
///
/// [DataSourceReader] instances must be registered so that contiguous start
/// offsets can be set on each reader. This allows global offsets to be
/// correctly calculated by the indices. See [UnorderedIndexedSource] for more
/// info.
class SerializationIndices {
  final Map<Type, IndexedSource> _indexedSources = {};
  final Map<Type, IndexedSink> _indexedSinks = {};
  final List<DataSourceReader> _sources = [];
  final bool testMode;

  SerializationIndices({this.testMode = false});

  int registerSource(DataSourceReader source) {
    int startOffset;
    if (_sources.isEmpty) {
      startOffset = 0;
    } else {
      final lastSource = _sources.last;
      startOffset = lastSource.startOffset + lastSource.length;
    }
    _sources.add(source);
    return startOffset;
  }

  IndexedSource<E> getIndexedSource<E extends Object>() {
    final source = (_indexedSources[E] ??= UnorderedIndexedSource<E>(this))
        as IndexedSource<E>;
    if (testMode) {
      /// In test mode we ensure that the values we read out are identical to
      /// the values we write in. When copying the elements we turn the local
      /// offsets to global offsets so that the source cache will hit.
      /// Note: Mapped sinks will not get copied over since the mapped write
      /// type will be different from the read type.
      final sink = _indexedSinks[E] as IndexedSink<E>?;
      sink?.cache.forEach((value, offset) {
        // We convert local offsets to relative offsets because source caching
        // uses the relative address space. We want to ensure objects that are
        // serialized and immediately deserialized during testing share the same
        // cached references.
        source.cache[_localToGlobalForTesting(offset)] = value;
      });
    }
    return source;
  }

  IndexedSink<E> getIndexedSink<E extends Object>({bool identity = false}) {
    return _getIndexedSink<E, E>(null, identity: identity);
  }

  IndexedSink<T> getMappedIndexedSink<E extends Object, T extends Object>(
      T Function(E value) f) {
    return _getIndexedSink<E, T>(f, identity: false);
  }

  IndexedSink<T> _getIndexedSink<E extends Object, T extends Object>(
      T Function(E value)? f,
      {required bool identity}) {
    final sink = (_indexedSinks[T] ??=
        UnorderedIndexedSink<T>(identity: identity)) as IndexedSink<T>;
    final source = _indexedSources[E] as UnorderedIndexedSource<E>?;
    source?.cache.forEach((offset, value) {
      final key = (f != null ? f(value) : value) as T;
      sink.cache[key] = offset;
    });
    return sink;
  }
}

// Real offsets are the offsets into the file the data is written in.
// Local offsets are real offsets with an extra indicator bit set to 1.
// Global offsets are offsets into the address space of all files with an
// extra indicator bit set to 0.
int _realToLocalOffset(int offset) => (offset << 1) | 1;
int _realToGlobalOffset(int offset, DataSourceReader source) =>
    (offset + source.startOffset) << 1;
bool _isLocalOffset(int offset) => (offset & 1) == 1;
int _offsetWithoutIndicator(int offset) => offset >> 1;
int _globalToRealOffset(int offset, DataSourceReader source) =>
    (offset >> 1) - source.startOffset;
int _localToGlobalOffset(int offset, DataSourceReader source) =>
    _realToGlobalOffset(offset >> 1, source);
int _localToGlobalForTesting(int offset) => offset & ~1;

/// Data sink helper that canonicalizes [E?] values using IDs.
///
/// Writes a unique ID in place of previously visited indexable values. This
/// ID is the offset in the data stream at which the serialized value can be
/// read. The read and write order do not need to be the same because no matter
/// what occurrence of the ID we encounter, we can always recover the value.
///
/// We increment all written offsets by an adjustment value in order to
/// distinguish which source file the offset is from on deserialization.
/// See [UnorderedIndexedSource] for more info.
class UnorderedIndexedSink<E extends Object> implements IndexedSink<E> {
  final Map<E, int> _cache;

  UnorderedIndexedSink({bool identity = false})
      : this._cache = identity ? Map.identity() : {};

  @override
  Map<E, int> get cache => _cache;

  /// Write a reference to [value] to the data sink.
  ///
  /// If [value] has not been canonicalized yet, [writeValue] is called to
  /// serialize the [value] itself.
  @override
  void write(DataSinkWriter sink, E? value, void writeValue(E value)) {
    if (value == null) {
      // We reserve 1 as an indicator for `null`.
      sink.writeInt(_nullIndicator);
      return;
    }
    final offset = _cache[value];
    if (offset == null) {
      // We reserve 0 as an indicator that the data is written 'here'.
      sink.writeInt(_dataInPlaceIndicator);
      _cache[value] = _realToLocalOffset(sink.length);
      writeValue(value);
    } else {
      sink.writeInt(offset + _indicatorOffset);
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
/// This effectively treats all the files as a contiguous address space with
/// offsets being global to the start of the first source.
///
/// Offsets are written in one of two forms. Either as a local offset, an offset
/// relative to the start of the same file, or as a global offset, an offset
/// relative to the start of the concatenated address space of all sources. The
/// two forms are indicated via the lowest bit, the former has that bit set,
/// the latter does not. Local offsets are turned into global offsets when they
/// are written into a later file.
///
/// If an offset is encountered outside the block accessible to current source,
/// [SerializationIndices] provides pointers to the previous sources to check
/// (i.e. previous blocks in the address space).
class UnorderedIndexedSource<E extends Object> implements IndexedSource<E> {
  final Map<int, E> _cache = {};
  final SerializationIndices _indices;

  UnorderedIndexedSource(this._indices);

  @override
  Map<int, E> get cache => _cache;

  /// Reads a reference to an [E?] value from the data source.
  ///
  /// If the value hasn't yet been read, [readValue] is called to deserialize
  /// the value itself.
  @override
  E? read(DataSourceReader source, E readValue()) {
    final markerOrOffset = source.readInt();

    if (markerOrOffset == _dataInPlaceIndicator) {
      final globalOffset = _realToGlobalOffset(source.currentOffset, source);
      // We have to read the value regardless of whether or not it's cached to
      // move the reader past it.
      final value = readValue();
      final cachedValue = _cache[globalOffset];
      if (cachedValue != null) return cachedValue;
      _cache[globalOffset] = value;
      return value;
    } else if (markerOrOffset == _nullIndicator) {
      return null;
    } else {
      final offset = markerOrOffset - _indicatorOffset;
      bool isLocal = _isLocalOffset(offset);
      final globalOffset =
          isLocal ? _localToGlobalOffset(offset, source) : offset;
      final cachedValue = _cache[globalOffset];
      if (cachedValue != null) return cachedValue;
      return _readAtOffset(source, readValue, globalOffset, isLocal);
    }
  }

  DataSourceReader findSource(int globalOffset) {
    final offset = _offsetWithoutIndicator(globalOffset);
    final sources = _indices._sources;
    for (int i = sources.length - 1; i >= 0; i--) {
      final source = sources[i];
      if (source.startOffset <= offset) return source;
    }
    throw StateError('Could not find source for $offset.');
  }

  E _readAtOffset(
      DataSourceReader source, E readValue(), int globalOffset, bool isLocal) {
    final realSource = isLocal ? source : findSource(globalOffset);
    final realOffset = _globalToRealOffset(globalOffset, realSource);
    final value = isLocal
        ? source.readWithOffset(realOffset, readValue)
        : source.readWithSource(
            realSource, () => source.readWithOffset(realOffset, readValue));
    _cache[globalOffset] = value;
    return value;
  }
}
