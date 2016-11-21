// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#define WIN32_LEAN_AND_MEAN
#include <windows.h>  // NOLINT

BOOL APIENTRY DllMain(HMODULE module, DWORD reason, LPVOID reserved) {
  return true;
}

#endif  // defined(TARGET_OS_WINDOWS)
