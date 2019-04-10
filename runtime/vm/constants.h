// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_H_
#define RUNTIME_VM_CONSTANTS_H_

#if defined(TARGET_ARCH_IA32)
#include "vm/constants_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/constants_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/constants_arm.h"
#elif defined(TARGET_ARCH_ARM64)
#include "vm/constants_arm64.h"
#elif defined(TARGET_ARCH_DBC)
#include "vm/constants_dbc.h"
#else
#error Unknown architecture.
#endif

#if defined(HOST_ARCH_IA32)
#include "vm/constants_ia32.h"
#elif defined(HOST_ARCH_X64)
#include "vm/constants_x64.h"
#elif defined(HOST_ARCH_ARM)
#include "vm/constants_arm.h"
#elif defined(HOST_ARCH_ARM64)
#include "vm/constants_arm64.h"
#else
#error Unknown host architecture.
#endif

namespace dart {

#if defined(TARGET_ARCH_IA32)
using namespace arch_ia32;  // NOLINT
#elif defined(TARGET_ARCH_X64)
using namespace arch_x64;  // NOLINT
#elif defined(TARGET_ARCH_ARM)
using namespace arch_arm;  // NOLINT
#elif defined(TARGET_ARCH_ARM64)
using namespace arch_arm64;  // NOLINT
#elif defined(TARGET_ARCH_DBC)
// DBC is defined in namespace dart already.
#else
#error Unknown architecture.
#endif

namespace host {

#if defined(HOST_ARCH_IA32)
using namespace arch_ia32;  // NOLINT
#elif defined(HOST_ARCH_X64)
using namespace arch_x64;  // NOLINT
#elif defined(HOST_ARCH_ARM)
using namespace arch_arm;  // NOLINT
#elif defined(HOST_ARCH_ARM64)
using namespace arch_arm64;  // NOLINT
#else
#error Unknown host architecture.
#endif

}  // namespace host

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_H_
