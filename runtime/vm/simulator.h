// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SIMULATOR_H_
#define VM_SIMULATOR_H_

#include "vm/globals.h"

#if defined(TARGET_ARCH_IA32)
// No simulator used.

#elif defined(TARGET_ARCH_X64)
// No simulator used.

#elif defined(TARGET_ARCH_ARM)
#if defined(HOST_ARCH_ARM)
// No simulator used.
#else
#define USING_SIMULATOR 1
#include "vm/simulator_arm.h"
#endif

#elif defined(TARGET_ARCH_MIPS)
#if defined(HOST_ARCH_MIPS)
// No simulator used.
#else
#define USING_SIMULATOR 1
#include "vm/simulator_mips.h"
#endif

#else
#error Unknown architecture.
#endif

#endif  // VM_SIMULATOR_H_
