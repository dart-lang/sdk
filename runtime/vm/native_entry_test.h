// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_NATIVE_ENTRY_TEST_H_
#define VM_NATIVE_ENTRY_TEST_H_

#include "vm/native_entry.h"

#include "include/dart_api.h"

namespace dart {

// Forward declarations.
class String;


DECLARE_NATIVE_ENTRY(TestSmiSub, 2);
DECLARE_NATIVE_ENTRY(TestSmiSum, 6);
DECLARE_NATIVE_ENTRY(TestStaticCallPatching, 0);

// Helper function for looking up native test functions.
extern Dart_NativeFunction NativeTestEntry_Lookup(const String& name,
                                                  int argument_count);

}  // namespace dart

#endif  // VM_NATIVE_ENTRY_TEST_H_
