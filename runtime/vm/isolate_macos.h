// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_MACOS_H_
#define VM_ISOLATE_MACOS_H_

#if !defined(VM_ISOLATE_H_)
#error Do not include isolate_macos.h directly; use isolate.h instead.
#endif

#include <pthread.h>

namespace dart {

#define PTHREAD_KEY_UNSET static_cast<pthread_key_t>(-1)
extern pthread_key_t isolate_key;


inline Isolate* Isolate::Current() {
  ASSERT(isolate_key != PTHREAD_KEY_UNSET);
  return reinterpret_cast<Isolate*>(pthread_getspecific(isolate_key));
}

}  // namespace dart

#endif  // VM_ISOLATE_MACOS_H_
