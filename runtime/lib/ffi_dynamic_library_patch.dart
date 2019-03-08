// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

DynamicLibrary _open(String name) native "Ffi_dl_open";

@patch
@pragma("vm:entry-point")
class DynamicLibrary {
  @patch
  factory DynamicLibrary.open(String name) {
    return _open(name);
  }

  @patch
  Pointer<T> lookup<T extends NativeType>(String symbolName)
      native "Ffi_dl_lookup";

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
}
