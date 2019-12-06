// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// All imports must be in all FFI patch files to not depend on the order
// the patches are applied.
import "dart:_internal" show patch;
import 'dart:typed_data';
import 'dart:isolate';

DynamicLibrary _open(String name) native "Ffi_dl_open";
DynamicLibrary _processLibrary() native "Ffi_dl_processLibrary";
DynamicLibrary _executableLibrary() native "Ffi_dl_executableLibrary";

@patch
@pragma("vm:entry-point")
class DynamicLibrary {
  @patch
  factory DynamicLibrary.open(String name) {
    return _open(name);
  }

  @patch
  factory DynamicLibrary.process() => _processLibrary();

  @patch
  factory DynamicLibrary.executable() => _executableLibrary();

  @patch
  Pointer<T> lookup<T extends NativeType>(String symbolName)
      native "Ffi_dl_lookup";

  // The real implementation of this function lives in FfiUseSiteTransformer
  // for interface calls. Only dynamic calls (which are illegal) reach this
  // implementation.
  @patch
  F lookupFunction<T extends Function, F extends Function>(String symbolName) {
    throw UnsupportedError(
        "Dynamic invocation of lookupFunction is not supported.");
  }

  // TODO(dacoharkes): Expose this to users, or extend Pointer?
  // https://github.com/dart-lang/sdk/issues/35881
  int getHandle() native "Ffi_dl_getHandle";

  @patch
  bool operator ==(other) {
    if (other == null) return false;
    return getHandle() == other.getHandle();
  }

  @patch
  int get hashCode {
    return getHandle().hashCode;
  }

  @patch
  Pointer<Void> get handle => Pointer.fromAddress(getHandle());
}
