// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Uri_isWindowsPlatform, 0, 0) {
#if defined(HOST_OS_WINDOWS)
  return Bool::True().raw();
#else
  return Bool::False().raw();
#endif
}

}  // namespace dart
