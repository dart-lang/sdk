// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

part 'blake3_internal.dart';
part 'blake3_scalar_compression.dart';
part 'blake3_streaming.dart';

/// Computes unkeyed BLAKE3-256 digests of byte sequences.
///
/// An instance reuses its scratch storage between synchronous [hash] calls.
/// For incremental input, use [ScalarBlake3Sink].
abstract interface class Blake3 {
  /// Returns the 32-byte digest of precisely the bytes in [input].
  ///
  /// Arbitrarily offset views and unmodifiable inputs are supported. Input is
  /// never modified or retained. Every digest has independent, mutable storage.
  Uint8List hash(Uint8List input);
}

/// BLAKE3 using scalar integer arithmetic.
abstract final class ScalarBlake3 implements Blake3 {
  factory() = _ScalarBlake3;
}
