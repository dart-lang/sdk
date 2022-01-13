// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'remote_instance.dart';

/// All serialization must be done in a serialization Zone, which tells it
/// whether we are the client or server.
///
/// In [SerializationMode.server], sets up a remote instance cache to use when
/// deserializing remote instances back to their original instance.
T withSerializationMode<T>(SerializationMode mode, T Function() fn) =>
    runZoned(fn, zoneValues: {
      #serializationMode: mode,
      if (mode == SerializationMode.server)
        remoteInstanceZoneKey: <int, RemoteInstance>{}
    });

/// Serializable interface
abstract class Serializable {
  /// Serializes this object using [serializer].
  void serialize(Serializer serializer);
}

/// A push based object serialization interface.
abstract class Serializer {
  /// Serializes a [String].
  void addString(String value);

  /// Serializes a nullable [String].
  void addNullableString(String? value);

  /// Serializes a [num].
  void addNum(num value);

  /// Serializes a nullable [num].
  void addNullableNum(num? value);

  /// Serializes a [bool].
  void addBool(bool value);

  /// Serializes a nullable [bool].
  void addNullableBool(bool? value);

  /// Serializes a `null` literal.
  void addNull();

  /// Used to signal the start of an arbitrary length list of items.
  void startList();

  /// Used to signal the end of an arbitrary length list of items.
  void endList();
}

/// A pull based object deserialization interface.
///
/// You must call [moveNext] before reading any items, and in order to advance
/// to the next item.
abstract class Deserializer {
  /// Checks if the current value is a null, returns `true` if so and `false`
  /// otherwise.
  bool checkNull();

  /// Reads the current value as a non-nullable [String].
  bool expectBool();

  /// Reads the current value as a nullable [bool].
  bool? expectNullableBool();

  /// Reads the current value as a non-nullable [String].
  T expectNum<T extends num>();

  /// Reads the current value as a nullable [num].
  num? expectNullableNum();

  /// Reads the current value as a non-nullable [String].
  String expectString();

  /// Reads the current value as a nullable [String].
  String? expectNullableString();

  /// Asserts that the current item is the start of a list.
  ///
  /// An example for how to read from a list is as follows:
  ///
  /// var json = JsonReader.fromString(source);
  /// I know it's a list of strings.
  ///
  /// ```
  ///   var result = <String>[];
  ///   deserializer.moveNext();
  ///   deserializer.expectList();
  ///   while (json.moveNext()) {
  ///     result.add(json.expectString());
  ///   }
  ///   // Can now read later items, but need to call `moveNext` again to move
  ///   // past the list.
  ///   deserializer.moveNext();
  ///   deserializer.expectBool();
  /// ```
  void expectList();

  /// Moves to the next item, returns `false` if there are no more items to
  /// read.
  ///
  /// If inside of a list, this returns `false` when the end of the list is
  /// reached, and moves back to the parent, but does not advance it, so another
  /// call to `moveNext` is needed. See example in the [expectList] docs.
  bool moveNext();
}

class JsonSerializer implements Serializer {
  /// The full result.
  final _result = <Object?>[];

  /// A path to the current list we are modifying.
  late List<List<Object?>> _path = [_result];

  /// Returns the result as an unmodifiable [Iterable].
  ///
  /// Asserts that all [List] entries have not been closed with [endList].
  Iterable<Object?> get result {
    assert(_path.length == 1);
    return _result;
  }

  @override
  void addBool(bool value) => _path.last.add(value);
  @override
  void addNullableBool(bool? value) => _path.last.add(value);

  @override
  void addNum(num value) => _path.last.add(value);
  @override
  void addNullableNum(num? value) => _path.last.add(value);

  @override
  void addString(String value) => _path.last.add(value);
  @override
  void addNullableString(String? value) => _path.last.add(value);

  @override
  void addNull() => _path.last.add(null);

  @override
  void startList() {
    List<Object?> sublist = [];
    _path.last.add(sublist);
    _path.add(sublist);
  }

  @override
  void endList() {
    _path.removeLast();
  }
}

class JsonDeserializer implements Deserializer {
  /// The root source list to read from.
  final Iterable<Object?> _source;

  /// The path to the current iterator we are reading from.
  late List<Iterator<Object?>> _path = [];

  /// Whether we have received our first [moveNext] call.
  bool _initialized = false;

  /// Initialize this deserializer from `_source`.
  JsonDeserializer(this._source);

  @override
  bool checkNull() => _expectValue<Object?>() == null;

  @override
  void expectList() => _path.add(_expectValue<Iterable<Object?>>().iterator);

  @override
  bool expectBool() => _expectValue();
  @override
  bool? expectNullableBool() => _expectValue();

  @override
  T expectNum<T extends num>() => _expectValue();
  @override
  num? expectNullableNum() => _expectValue();

  @override
  String expectString() => _expectValue();
  @override
  String? expectNullableString() => _expectValue();

  /// Reads the current value and casts it to [T].
  T _expectValue<T>() {
    if (!_initialized) {
      throw new StateError(
          'You must call `moveNext()` before reading any values.');
    }
    return _path.last.current as T;
  }

  @override
  bool moveNext() {
    if (!_initialized) {
      _path.add(_source.iterator);
      _initialized = true;
    }

    // Move the current iterable, if its at the end of its items remove it from
    // the current path and return false.
    if (!_path.last.moveNext()) {
      _path.removeLast();
      return false;
    }

    return true;
  }
}

/// Must be set using `withSerializationMode` before doing any serialization or
/// deserialization.
SerializationMode get serializationMode {
  SerializationMode? mode =
      Zone.current[#serializationMode] as SerializationMode?;
  if (mode == null) {
    throw new StateError('No SerializationMode set, you must do all '
        'serialization inside a call to `withSerializationMode`.');
  }
  return mode;
}

/// Some objects are serialized differently on the client side versus the server
/// side. This indicates the different modes.
enum SerializationMode {
  server,
  client,
}
