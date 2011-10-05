// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_WIN_H_
#define VM_ISOLATE_WIN_H_

#if !defined(VM_ISOLATE_H_)
#error Do not include isolate_win.h directly; use isolate.h instead.
#endif

#include "vm/assert.h"
#include "vm/globals.h"

namespace dart {

extern DWORD isolate_key;


inline Isolate* Isolate::Current() {
  ASSERT(isolate_key != TLS_OUT_OF_INDEXES);
  return reinterpret_cast<Isolate*>(TlsGetValue(isolate_key));
}

}  // namespace dart

#endif  // VM_ISOLATE_WIN_H_
