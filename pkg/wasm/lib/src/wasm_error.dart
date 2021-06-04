// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Error specific to unexpected behavior or incorrect usage of this package.
class WasmError extends Error {
  /// Describes the nature of the error.
  final String message;

  WasmError(this.message) : assert(message.trim() == message);

  @override
  String toString() => 'WasmError:$message';
}
