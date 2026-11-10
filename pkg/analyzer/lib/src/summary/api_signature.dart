// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/utilities/hash/blake3.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:pub_semver/pub_semver.dart';

/// An instance of [ApiSignature] collects data in the form of primitive types
/// (strings, ints, bools, etc.) from a summary "builder" object, and uses them
/// to generate an MD5 signature of a the non-informative parts of the summary
/// (i.e. those parts representing the API of the code being summarized).
///
/// Note that the data passed to the MD5 signature algorithm is untyped.  So,
/// for instance, an API signature built from a sequence of `false` booleans is
/// likely to match an API signature built from a sequence of zeros.  The caller
/// should take this into account; e.g. if a data structure may be represented
/// either by a boolean or an int, the caller should encode a tag distinguishing
/// the two representations before encoding the data.
class ApiSignature {
  /// Version number of the code in this class.  Any time this class is changed
  /// in a way that affects the data collected in [_data], this version number
  /// should be incremented, so that a summary signed by a newer version of the
  /// signature algorithm won't accidentally have the same signature as a
  /// summary signed by an older version.
  static const int _version = 0;

  /// Data accumulated so far.
  ByteData _data = ByteData(4096);

  /// Offset into [_data] where the next byte should be written.
  int _offset = 0;

  /// Create an [ApiSignature] which is ready to accept data.
  new() {
    addInt(_version);
  }

  /// For testing only: create an [ApiSignature] which doesn't include any
  /// version information.  This makes it easier to unit tests, since the data
  /// is stable even if [_version] is changed.
  new unversioned();

  /// Collect a boolean value.
  void addBool(bool b) {
    _makeRoom(1);
    _data.setUint8(_offset, b ? 1 : 0);
    _offset++;
  }

  /// Collect a sequence of arbitrary bytes.  Note that the length is not
  /// collected, so for example `addBytes([1, 2]);` will have the same effect as
  /// `addBytes([1]); addBytes([2]);`.
  void addBytes(List<int> bytes) {
    int length = bytes.length;
    _makeRoom(length);
    for (int i = 0; i < length; i++) {
      _data.setUint8(_offset + i, bytes[i]);
    }
    _offset += length;
  }

  /// Collect a double-precision floating point value.
  void addDouble(double d) {
    _makeRoom(8);
    _data.setFloat64(_offset, d, Endian.little);
    _offset += 8;
  }

  /// Collect a [FeatureSet].
  void addFeatureSet(FeatureSet featureSet) {
    var knownFeatures = ExperimentStatus.knownFeatures;
    addInt(knownFeatures.length);
    for (var feature in knownFeatures.values) {
      addBool(featureSet.isEnabled(feature));
    }
  }

  /// Collect a 32-bit unsigned integer value.
  void addInt(int i) {
    _makeRoom(4);
    _data.setUint32(_offset, i, Endian.little);
    _offset += 4;
  }

  /// Collect a language version.
  void addLanguageVersion(Version version) {
    addInt(version.major);
    addInt(version.minor);
  }

  void addList<T>(List<T> elements, void Function(T) addElement) {
    addInt(elements.length);
    for (var element in elements) {
      addElement(element);
    }
  }

  void addMapEntryList<K, V>(
    List<MapEntry<K, V>> entries,
    void Function(K, V) addEntry,
  ) {
    addInt(entries.length);
    for (var entry in entries) {
      addEntry(entry.key, entry.value);
    }
  }

  /// Collect a string.
  void addString(String s) {
    bool isAscii = true;
    for (int i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) >= 128) {
        isAscii = false;
        break;
      }
    }
    if (isAscii) {
      int length = s.length;
      _makeRoom(length + 4);
      _data.setUint32(_offset, length, Endian.little);
      _offset += 4;
      // Calling addBytes is slow because addBytes will have to be more general.
      for (int i = 0; i < length; i++) {
        _data.setUint8(_offset + i, s.codeUnitAt(i));
      }
      _offset += length;
    } else {
      var bytes = const Utf8Encoder().convert(s);
      addInt(bytes.length);
      addBytes(bytes);
    }
  }

  /// Collect a string list, with the length.
  void addStringList(List<String> values) {
    addInt(values.length);
    for (var value in values) {
      addString(value);
    }
  }

  /// Collect the given [Uint32List].
  void addUint32List(Uint32List data) {
    addBytes(data.buffer.asUint8List());
  }

  /// For testing only: retrieve the internal representation of the data that
  /// has been collected.
  Uint8List getBytes_forDebug() {
    return Uint8List.view(_data.buffer, 0, _offset);
  }

  /// Return the bytes of the MD5 hash of the data collected so far.
  Uint8List toByteList() {
    var data = _data.buffer.asUint8List(0, _offset);
    var bytes = md5.convert(data).bytes;
    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  /// Returns the MD5 hash of the data collected so far.
  Hash toHash() {
    var bytes = toByteList();
    return Hash._(bytes);
  }

  /// Return a hex-encoded MD5 signature of the data collected so far.
  String toHex() {
    return hex.encode(toByteList());
  }

  /// Return the MD5 hash of the data collected so far as [Uint32List].
  Uint32List toUint32List() {
    var hash = toHash();
    return hash._bytes.buffer.asUint32List();
  }

  /// Ensure that [spaceNeeded] bytes can be added to [_data] at [_offset]
  /// (copying it to a larger object if necessary).
  void _makeRoom(int spaceNeeded) {
    int oldLength = _data.lengthInBytes;
    if (_offset + spaceNeeded > oldLength) {
      int newLength = 2 * (_offset + spaceNeeded);
      ByteData newData = ByteData(newLength);
      Uint8List.view(newData.buffer)
          .setRange(0, oldLength, Uint8List.view(_data.buffer));
      _data = newData;
    }
  }
}

/// Collects values and produces a BLAKE3-256 digest.
///
/// Values are encoded in call order. Integers use their low 32 bits, doubles
/// use 64-bit IEEE 754, and both use little-endian byte order. Booleans use
/// one byte, 0 or 1. Strings use UTF-8 with a 32-bit byte-length prefix.
/// Raw bytes are appended without a length prefix. No type tags are added.
///
/// Reading the digest finalizes the signature; further additions throw
/// [StateError]. Repeated reads return the same digest. Returned byte and
/// word lists have independent, mutable storage.
final class Blake3ApiSignature {
  static final ScalarBlake3 _hasher = ScalarBlake3();

  final Uint8List _buffer;
  final ByteData _data;
  final ByteData _doubleBytes = ByteData(8);
  int _offset = 0;
  Uint8List? _digest;

  /// Created on the first flush.
  /// Signatures that fit in [_buffer] use [_hasher] for one-shot hashing.
  ScalarBlake3Sink? _sink;

  new() : this._(Uint8List(4096));

  new _(Uint8List buffer)
    : _buffer = buffer,
      _data = ByteData.sublistView(buffer);

  /// Collects a boolean.
  void addBool(bool value) {
    _checkNotFinished();
    _flushIfNeeded();
    _buffer[_offset++] = value ? 1 : 0;
  }

  /// Collects bytes without a length prefix or padding.
  /// Input is consumed synchronously and is neither modified nor retained.
  void addBytes(Uint8List bytes) {
    _checkNotFinished();

    // If bytes fit the buffer, add there and done.
    var length = bytes.length;
    if (_offset + length <= _buffer.length) {
      _buffer.setRange(_offset, _offset + length, bytes);
      _offset += length;
      return;
    }

    // Flush full buffers as needed, keeping the last batch buffered.
    var start = 0;
    while (start < length) {
      _flushIfNeeded();
      var count = min(length - start, _buffer.length - _offset);
      _buffer.setRange(_offset, _offset + count, bytes, start);
      _offset += count;
      start += count;
    }
  }

  /// Collects a little-endian, double-precision floating point value.
  void addDouble(double value) {
    _checkNotFinished();
    if (_offset + 8 <= _buffer.length) {
      _data.setFloat64(_offset, value, Endian.little);
      _offset += 8;
    } else {
      _doubleBytes.setFloat64(0, value, Endian.little);
      addBytes(_doubleBytes.buffer.asUint8List());
    }
  }

  void addFeatureSet(FeatureSet featureSet) {
    var features = ExperimentStatus.knownFeatures;
    addInt(features.length);
    for (var feature in features.values) {
      addBool(featureSet.isEnabled(feature));
    }
  }

  /// Collects the low 32 bits of [value] in little-endian order.
  void addInt(int value) {
    _checkNotFinished();
    if (_offset + 4 <= _buffer.length) {
      _data.setUint32(_offset, value, Endian.little);
      _offset += 4;
    } else {
      for (var shift = 0; shift < 32; shift += 8) {
        _addByte(value >> shift);
      }
    }
  }

  void addLanguageVersion(Version version) {
    addInt(version.major);
    addInt(version.minor);
  }

  void addList<T>(List<T> elements, void Function(T) addElement) {
    addInt(elements.length);
    for (var element in elements) {
      addElement(element);
    }
  }

  void addMapEntryList<K, V>(
    List<MapEntry<K, V>> entries,
    void Function(K, V) addEntry,
  ) {
    addInt(entries.length);
    for (var entry in entries) {
      addEntry(entry.key, entry.value);
    }
  }

  /// Collects the UTF-8 byte length followed by the UTF-8 bytes of [value].
  void addString(String value) {
    _checkNotFinished();

    // Use UTF-8 encoding if any character is non-ASCII.
    var length = value.length;
    for (var i = 0; i < length; i++) {
      if (value.codeUnitAt(i) >= 128) {
        var bytes = utf8.encode(value);
        addInt(bytes.length);
        addBytes(bytes);
        return;
      }
    }

    // Write ASCII bytes directly when the length prefix and string fit.
    if (_offset + 4 + length <= _buffer.length) {
      _data.setUint32(_offset, length, Endian.little);
      _offset += 4;
      for (var i = 0; i < length; i++) {
        _buffer[_offset + i] = value.codeUnitAt(i);
      }
      _offset += length;
      return;
    }

    // Write ASCII bytes across buffer boundaries when they do not fit.
    addInt(length);
    var start = 0;
    while (start < length) {
      _flushIfNeeded();
      var count = length - start;
      var space = _buffer.length - _offset;
      if (count > space) count = space;
      for (var i = 0; i < count; i++) {
        _buffer[_offset + i] = value.codeUnitAt(start + i);
      }
      _offset += count;
      start += count;
    }
  }

  void addStringList(List<String> values) {
    addList(values, addString);
  }

  /// Collects the backing buffer's bytes, matching [ApiSignature.addUint32List].
  void addUint32List(Uint32List data) {
    addBytes(data.buffer.asUint8List());
  }

  /// Finalizes the signature and returns its 32-byte digest.
  Uint8List toByteList() => Uint8List.fromList(_digest ??= _finish());

  /// Finalizes the signature and returns its hash value.
  Hash toHash() => Hash._(_digest ??= _finish());

  /// Finalizes the signature and returns its hex-encoded digest.
  String toHex() => hex.encode(_digest ??= _finish());

  /// Finalizes the signature and returns its digest as eight native-endian words.
  Uint32List toUint32List() => toByteList().buffer.asUint32List();

  void _addByte(int value) {
    _flushIfNeeded();
    _buffer[_offset++] = value;
  }

  void _checkNotFinished() {
    if (_digest != null) {
      throw StateError('The API signature is already finalized.');
    }
  }

  Uint8List _finish() {
    var bytes = Uint8List.sublistView(_buffer, 0, _offset);
    var sink = _sink;
    if (sink == null) return _hasher.hash(bytes);
    sink.add(bytes);
    return sink.finish();
  }

  void _flush() {
    assert(_offset == _buffer.length);
    (_sink ??= ScalarBlake3Sink()).add(_buffer);
    _offset = 0;
  }

  void _flushIfNeeded() {
    if (_offset == _buffer.length) _flush();
  }
}

/// Hash value computed from an API signature.
class Hash {
  static final Hash empty = Hash._(Uint8List(0));

  final Uint8List _bytes;
  late final int _hashCode = const ListEquality<int>().hash(_bytes);

  factory read(BinaryReader reader) {
    return Hash._(reader.readUint8List());
  }

  new _(this._bytes);

  @override
  int get hashCode => _hashCode;

  @override
  bool operator ==(Object other) {
    return other is Hash &&
        const ListEquality<int>().equals(_bytes, other._bytes);
  }

  @override
  String toString() {
    return hex.encode(_bytes);
  }

  void write(BinaryWriter writer) {
    writer.writeUint8List(_bytes);
  }
}
