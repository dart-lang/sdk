// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../io/code_output.dart' show CodeOutputListener;

class Hasher implements CodeOutputListener {
  final _DigestSink _digestSink;
  ByteConversionSink _byteSink;

  Hasher._(this._digestSink)
      : _byteSink = sha1.startChunkedConversion(_digestSink);

  factory Hasher() => Hasher._(_DigestSink());

  @override
  void onDone(int length) {
    // Do nothing.
  }

  @override
  void onText(String text) {
    if (_byteSink != null) {
      _byteSink.add(utf8.encode(text));
    }
  }

  /// Returns the base64-encoded SHA-1 hash of the utf-8 bytes of the output
  /// text.
  String getHash() {
    if (_byteSink != null) {
      _byteSink.close();
      _byteSink = null;
    }
    return base64.encode(_digestSink.value.bytes);
  }
}

/// A sink used to get a digest value out of `Hash.startChunkedConversion`.
class _DigestSink extends Sink<Digest> {
  Digest _value;

  /// The value added to the sink, if any.
  Digest get value {
    assert(_value != null);
    return _value;
  }

  /// Adds [value] to the sink.
  ///
  /// Unlike most sinks, this may only be called once.
  @override
  void add(Digest value) {
    assert(_value == null);
    _value = value;
  }

  @override
  void close() {
    assert(_value != null);
  }
}
