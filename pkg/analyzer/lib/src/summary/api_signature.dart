// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.api_signature;

import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

/**
 * An instance of [ApiSignature] collects data in the form of primitive types
 * (strings, ints, bools, etc.) from a summary "builder" object, and uses them
 * to generate an MD5 signature of a the non-informative parts of the summary
 * (i.e. those parts representing the API of the code being summarized).
 *
 * Note that the data passed to the MD5 signature algorithm is untyped.  So, for
 * instance, an API signature built from a sequence of `false` booleans is
 * likely to match an API signature built from a sequence of zeros.  The caller
 * should take this into account; e.g. if a data structure may be represented
 * either by a boolean or an int, the caller should encode a tag distinguishing
 * the two representations before encoding the data.
 */
class ApiSignature {
  /**
   * Version number of the code in this class.  Any time this class is changed
   * in a way that affects the data collected in [_data], this version number
   * should be incremented, so that a summary signed by a newer version of the
   * signature algorithm won't accidentally have the same signature as a summary
   * signed by an older version.
   */
  static const int _VERSION = 0;

  /**
   * Data accumulated so far.
   */
  ByteData _data = new ByteData(4096);

  /**
   * Offset into [_data] where the next byte should be written.
   */
  int _offset = 0;

  /**
   * Create an [ApiSignature] which is ready to accept data.
   */
  ApiSignature() {
    addInt(_VERSION);
  }

  /**
   * For testing only: create an [ApiSignature] which doesn't include any
   * version information.  This makes it easier to unit tests, since the data
   * is stable even if [_VERSION] is changed.
   */
  ApiSignature.unversioned();

  /**
   * Collect a boolean value.
   */
  void addBool(bool b) {
    _makeRoom(1);
    _data.setUint8(_offset, b ? 1 : 0);
    _offset++;
  }

  /**
   * Collect a sequence of arbitrary bytes.  Note that the length is not
   * collected, so for example `addBytes([1, 2]);` will have the same effect as
   * `addBytes([1]); addBytes([2]);`.
   */
  void addBytes(List<int> bytes) {
    _makeRoom(bytes.length);
    new Uint8List.view(_data.buffer)
        .setRange(_offset, _offset + bytes.length, bytes);
    _offset += bytes.length;
  }

  /**
   * Collect a double-precision floating point value.
   */
  void addDouble(double d) {
    _makeRoom(8);
    _data.setFloat64(_offset, d, Endianness.LITTLE_ENDIAN);
    _offset += 8;
  }

  /**
   * Collect a 32-bit unsigned integer value.
   */
  void addInt(int i) {
    _makeRoom(4);
    _data.setUint32(_offset, i, Endianness.LITTLE_ENDIAN);
    _offset += 4;
  }

  /**
   * Collect a string.
   */
  void addString(String s) {
    List<int> bytes = UTF8.encode(s);
    addInt(bytes.length);
    addBytes(bytes);
  }

  /**
   * For testing only: retrieve the internal representation of the data that
   * has been collected.
   */
  List<int> getBytes_forDebug() {
    return new Uint8List.view(_data.buffer, 0, _offset).toList();
  }

  /**
   * Return a hex-encoded MD5 signature of the data collected so far.
   */
  String toHex() {
    return hex.encode(
        md5.convert(new Uint8List.view(_data.buffer, 0, _offset)).bytes);
  }

  /**
   * Ensure that [spaceNeeded] bytes can be added to [_data] at [_offset]
   * (copying it to a larger object if necessary).
   */
  void _makeRoom(int spaceNeeded) {
    int oldLength = _data.lengthInBytes;
    if (_offset + spaceNeeded > oldLength) {
      int newLength = 2 * (_offset + spaceNeeded);
      ByteData newData = new ByteData(newLength);
      new Uint8List.view(newData.buffer)
          .setRange(0, oldLength, new Uint8List.view(_data.buffer));
      _data = newData;
    }
  }
}
