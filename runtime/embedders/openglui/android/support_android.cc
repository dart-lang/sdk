// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Provide atexit, not part of Android libc or linker.

extern "C" int atexit(void (*function)(void)) {
  // Return error code.
  return 1;
}

// Provide __dso_handle, not part of Android libc or linker.

__attribute__((weak)) void *__dso_handle;

