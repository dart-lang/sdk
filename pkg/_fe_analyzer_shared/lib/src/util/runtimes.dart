// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:typed_data';

/// Whether the current runtime can register kernel blobs and launch kernel
/// isolates.
bool get isKernelRuntime => _isKernelRuntime ??= _checkForKernelRuntime();

bool? _isKernelRuntime;

bool _checkForKernelRuntime() {
  // `createUriForKernelBlob` throws `UnsupportedError` if kernel blobs are not
  // supported at all. We don't actually want to register kernel so pass
  // invalid kernel, an empty list, resulting in an `ArgumentError` if kernel
  // blobs are supported.
  try {
    (Isolate.current as dynamic)
        .createUriForKernelBlob(new Uint8List.fromList(const []));
    throw new StateError('Expected failure.');
  } on UnsupportedError {
    return false;
  } on ArgumentError {
    return true;
  }
}
