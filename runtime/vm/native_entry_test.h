// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_NATIVE_ENTRY_TEST_H_
#define VM_NATIVE_ENTRY_TEST_H_

#include "include/dart_api.h"

namespace dart {

void TestSmiSub(Dart_NativeArguments args);
void TestSmiSum(Dart_NativeArguments args);
void TestStaticCallPatching(Dart_NativeArguments args);

}  // namespace dart

#endif  // VM_NATIVE_ENTRY_TEST_H_
