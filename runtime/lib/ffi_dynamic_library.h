// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_LIB_FFI_DYNAMIC_LIBRARY_H_
#define RUNTIME_LIB_FFI_DYNAMIC_LIBRARY_H_

#include "platform/globals.h"
#include "vm/object.h"

namespace dart {

intptr_t FfiResolveInternal(const String& asset,
                            const String& symbol,
                            uintptr_t args_n,
                            char** error);

}  // namespace dart

#endif  // RUNTIME_LIB_FFI_DYNAMIC_LIBRARY_H_
