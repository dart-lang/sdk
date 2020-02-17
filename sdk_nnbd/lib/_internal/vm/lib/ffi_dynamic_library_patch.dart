// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  // TODO(dacoharkes): Expose this to users, or extend Pointer?
  // https://github.com/dart-lang/sdk/issues/35881
  int getHandle() native "Ffi_dl_getHandle";

  @patch
  bool operator ==(Object other) {
    if (other is! DynamicLibrary) return false;
    DynamicLibrary otherLib = other;
    return getHandle() == otherLib.getHandle();
  }

  @patch
  int get hashCode {
    return getHandle().hashCode;
  }

  @patch
  Pointer<Void> get handle => Pointer.fromAddress(getHandle());
}

extension DynamicLibraryExtension on DynamicLibrary {
  @patch
  DS lookupFunction<NS extends Function, DS extends Function>(
          String symbolName) =>
      throw UnsupportedError("The body is inlined in the frontend.");
}
