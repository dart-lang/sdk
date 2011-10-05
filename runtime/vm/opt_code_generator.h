// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OPT_CODE_GENERATOR_H_
#define VM_OPT_CODE_GENERATOR_H_

#include "vm/globals.h"


#if defined(TARGET_ARCH_IA32)
#include "vm/opt_code_generator_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/opt_code_generator_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/opt_code_generator_arm.h"
#else
#error Unknown architecture.
#endif


#endif  // VM_OPT_CODE_GENERATOR_H_
