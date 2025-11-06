// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TSAN_SYMBOLIZE_H_
#define RUNTIME_VM_TSAN_SYMBOLIZE_H_

#include "vm/object.h"

namespace dart {

void RegisterTsanSymbolize(const Code& code);

}  // namespace dart

#endif  // RUNTIME_VM_TSAN_SYMBOLIZE_H_
