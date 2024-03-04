// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

/// Whether the current runtime can register kernel blobs and launch kernel
/// isolates.
bool get isKernelRuntime => _isKernelRuntime ??= _checkForKernelRuntime();

bool? _isKernelRuntime;

bool _checkForKernelRuntime() {
  try {
    (Isolate.current as dynamic).createUriForKernelBlob;
    return true;
  } catch (_) {
    return false;
  }
}
