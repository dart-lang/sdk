// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/runtime_entry.h"

#include "vm/object.h"
#include "vm/verifier.h"

namespace dart {

// A runtime call for test purposes.
// Arg0: a smi.
// Arg1: a smi.
// Result: a smi representing arg0 - arg1.
DEFINE_RUNTIME_ENTRY(TestSmiSub, 2) {
  ASSERT(arguments.Count() == kTestSmiSubRuntimeEntry.argument_count());
  const Smi& left = Smi::CheckedHandle(arguments.At(0));
  const Smi& right = Smi::CheckedHandle(arguments.At(1));
  // Ignoring overflow in the calculation below.
  intptr_t result = left.Value() - right.Value();
  arguments.SetReturn(Smi::Handle(Smi::New(result)));
}

}  // namespace dart
