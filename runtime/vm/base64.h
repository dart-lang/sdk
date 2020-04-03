// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BASE64_H_
#define RUNTIME_VM_BASE64_H_

#include "vm/globals.h"

namespace dart {

uint8_t* DecodeBase64(const char* str, intptr_t* out_decoded_len);

}  // namespace dart

#endif  // RUNTIME_VM_BASE64_H_
