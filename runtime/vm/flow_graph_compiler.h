// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_COMPILER_H_
#define VM_FLOW_GRAPH_COMPILER_H_

#if defined(TARGET_ARCH_IA32)
#include "vm/flow_graph_compiler_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/flow_graph_compiler_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/flow_graph_compiler_arm.h"
#else
#error Unknown architecture.
#endif

#endif  // VM_FLOW_GRAPH_COMPILER_H_
