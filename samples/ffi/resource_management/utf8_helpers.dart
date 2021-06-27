// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

extension Utf8InArena on String {
  /// Convert a [String] to a Utf8-encoded null-terminated C string.
  ///
  /// If 'string' contains NULL bytes, the converted string will be truncated
  /// prematurely. See [Utf8Encoder] for details on encoding.
  ///
  /// Returns a [allocator]-allocated pointer to the result.
  Pointer<Utf8> toUtf8(Allocator allocator) {
    final units = utf8.encode(this);
    final Pointer<Uint8> result = allocator<Uint8>(units.length + 1);
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }
}

extension Utf8Helpers on Pointer<Utf8> {
  /// The length of a null-terminated string — the number of (one-byte)
  /// characters before the first null byte.
  int get strlen {
    final Pointer<Uint8> array = this.cast<Uint8>();
    int length = 0;
    while (array[length] != 0) {
      length++;
    }
    return length;
  }

  /// Creates a [String] containing the characters UTF-8 encoded in [this].
  ///
  /// [this] must be a zero-terminated byte sequence of valid UTF-8
  /// encodings of Unicode code points. See [Utf8Decoder] for details on
  /// decoding.
  ///
  /// Returns a Dart string containing the decoded code points.
  String contents() {
    final int length = strlen;
    return utf8.decode(Uint8List.view(
        this.cast<Uint8>().asTypedList(length).buffer, 0, length));
  }
}
