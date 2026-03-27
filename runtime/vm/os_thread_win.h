// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OS_THREAD_WIN_H_
#define RUNTIME_VM_OS_THREAD_WIN_H_

#if !defined(RUNTIME_VM_OS_THREAD_H_)
#error Do not include os_thread_win.h directly; use os_thread.h instead.
#endif

#include "platform/assert.h"
#include "platform/globals.h"

#include "vm/allocation.h"

namespace dart {

typedef HANDLE ThreadJoinId;

}  // namespace dart

#endif  // RUNTIME_VM_OS_THREAD_WIN_H_
