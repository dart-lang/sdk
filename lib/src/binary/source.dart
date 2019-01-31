// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'dart:convert';

/// Interface for deserialization.
// TODO(sigmund): share this with pkg:compiler/src/serialization/*
abstract class DataSource {
  /// Reads a reference to an [E] value from this data source. If the value has
  /// not yet been deserialized, [f] is called to deserialize the value itself.
  E readCached<E>(E f());

  /// Reads a potentially `null` [E] value from this data source, calling [f] to
  /// read the non-null value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeValueOrNull].
  E readValueOrNull<E>(E f());

  /// Reads a list of [E] values from this data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeList].
  List<E> readList<E>(E f(), {bool emptyAsNull: false});

  /// Reads a boolean value from this data source.
  bool readBool();

  /// Reads a non-negative integer value from this data source.
  int readInt();

  /// Reads a potentially `null` non-negative integer value from this data
  /// source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeIntOrNull].
  int readIntOrNull();

  /// Reads a string value from this data source.
  String readString();

  /// Reads a potentially `null` string value from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeStringOrNull].
  String readStringOrNull();

  /// Reads a list of string values from this data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeStrings].
  List<String> readStrings({bool emptyAsNull: false});

  /// Reads a map from string values to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeStringMap].
  Map<String, V> readStringMap<V>(V f(), {bool emptyAsNull: false});

  /// Reads an enum value from the list of enum [values] from this data source.
  ///
  /// The [values] argument is intended to be the static `.values` field on
  /// enum classes, for instance:
  ///
  ///    enum Foo { bar, baz }
  ///    ...
  ///    Foo foo = source.readEnum(Foo.values);
  ///
  E readEnum<E>(List<E> values);

  /// Reads a URI value from this data source.
  Uri readUri();
}

/// Mixin that implements all convenience methods of [DataSource].
abstract class DataSourceMixin implements DataSource {
  @override
  E readValueOrNull<E>(E f()) {
    bool hasValue = readBool();
    if (hasValue) {
      return f();
    }
    return null;
  }

  @override
  List<E> readList<E>(E f(), {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = new List<E>(count);
    for (int i = 0; i < count; i++) {
      list[i] = f();
    }
    return list;
  }

  @override
  int readIntOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readInt();
    }
    return null;
  }

  @override
  String readStringOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readString();
    }
    return null;
  }

  @override
  List<String> readStrings({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<String> list = new List<String>(count);
    for (int i = 0; i < count; i++) {
      list[i] = readString();
    }
    return list;
  }

  @override
  Map<String, V> readStringMap<V>(V f(), {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<String, V> map = {};
    for (int i = 0; i < count; i++) {
      String key = readString();
      V value = f();
      map[key] = value;
    }
    return map;
  }
}

/// Data source helper reads canonicalized [E] values through indices.
class IndexedSource<E> {
  final int Function() _readInt;
  final List<E> _cache = [];
  final Set<int> _pending = new Set();

  IndexedSource(this._readInt);

  /// Reads a reference to an [E] value from the data source.
  ///
  /// If the value hasn't yet been read, [readValue] is called to deserialize
  /// the value itself.
  E read(E readValue()) {
    int index = _readInt();
    if (_pending.contains(index)) throw "serialization cycles not supported";
    if (index >= _cache.length) {
      _pending.add(index);
      _cache.add(null);
      E value = readValue();
      _pending.remove(index);
      _cache[index] = value;
      return value;
    } else {
      return _cache[index];
    }
  }
}

/// Base implementation of [DataSource] using [DataSourceMixin] to implement
/// convenience methods.
abstract class AbstractDataSource extends DataSourceMixin
    implements DataSource {
  IndexedSource<String> _stringIndex;
  IndexedSource<Uri> _uriIndex;
  Map<Type, IndexedSource> _generalCaches = {};

  AbstractDataSource() {
    _stringIndex = new IndexedSource<String>(_readIntInternal);
    _uriIndex = new IndexedSource<Uri>(_readIntInternal);
  }

  @override
  E readCached<E>(E f()) {
    IndexedSource source =
        _generalCaches[E] ??= new IndexedSource<E>(_readIntInternal);
    return source.read(f);
  }

  @override
  E readEnum<E>(List<E> values) {
    return _readEnumInternal(values);
  }

  @override
  Uri readUri() {
    return _readUri();
  }

  Uri _readUri() {
    return _uriIndex.read(_readUriInternal);
  }

  @override
  bool readBool() {
    int value = _readIntInternal();
    assert(value == 0 || value == 1);
    return value == 1;
  }

  @override
  String readString() {
    return _readString();
  }

  String _readString() {
    return _stringIndex.read(_readStringInternal);
  }

  @override
  int readInt() {
    return _readIntInternal();
  }

  /// Actual deserialization of a string value, implemented by subclasses.
  String _readStringInternal();

  /// Actual deserialization of a non-negative integer value, implemented by
  /// subclasses.
  int _readIntInternal();

  /// Actual deserialization of a URI value, implemented by subclasses.
  Uri _readUriInternal();

  /// Actual deserialization of an enum value in [values], implemented by
  /// subclasses.
  E _readEnumInternal<E>(List<E> values);
}

/// [DataSource] that reads data from a sequence of bytes.
///
/// This data source works together with [BinarySink].
class BinarySource extends AbstractDataSource {
  int _byteOffset = 0;
  final List<int> _bytes;

  BinarySource(this._bytes);
  int _readByte() => _bytes[_byteOffset++];

  @override
  String _readStringInternal() {
    int length = _readIntInternal();
    List<int> bytes = new Uint8List(length);
    bytes.setRange(0, bytes.length, _bytes, _byteOffset);
    _byteOffset += bytes.length;
    return utf8.decode(bytes);
  }

  @override
  int _readIntInternal() {
    var byte = _readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | _readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (_readByte() << 16) |
          (_readByte() << 8) |
          _readByte();
    }
  }

  @override
  Uri _readUriInternal() {
    String text = _readString();
    return Uri.parse(text);
  }

  @override
  E _readEnumInternal<E>(List<E> values) {
    int index = _readIntInternal();
    assert(
        0 <= index && index < values.length,
        "Invalid data kind index. "
        "Expected one of $values, found index $index.");
    return values[index];
  }
}
