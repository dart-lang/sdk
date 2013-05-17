// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library byte_stream;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'utils.dart';

/// A stream of chunks of bytes representing a single piece of data.
class ByteStream extends StreamView<List<int>> {
  ByteStream(Stream<List<int>> stream)
    : super(stream);

  /// Returns a single-subscription byte stream that will emit the given bytes
  /// in a single chunk.
  factory ByteStream.fromBytes(List<int> bytes) =>
    new ByteStream(streamFromIterable([bytes]));

  /// Collects the data of this stream in a [Uint8List].
  Future<Uint8List> toBytes() {
    /// TODO(nweiz): use BufferList when issue 6409 is fixed.
    return fold(<int>[], (buffer, chunk) {
      buffer.addAll(chunk);
      return buffer;
    }).then(toUint8List);
  }

  /// Collect the data of this stream in a [String], decoded according to
  /// [encoding], which defaults to `Encoding.UTF_8`.
  Future<String> bytesToString([Encoding encoding=Encoding.UTF_8]) =>
      toBytes().then((bytes) => decodeString(bytes, encoding));

  Stream<String> toStringStream([Encoding encoding=Encoding.UTF_8]) =>
    transform(new StringDecoder(encoding));
}
