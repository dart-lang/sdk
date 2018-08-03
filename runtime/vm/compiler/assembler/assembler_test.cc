// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/assembler/assembler.h"
#include "vm/globals.h"
#include "vm/os.h"
#include "vm/simulator.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

ASSEMBLER_TEST_EXTERN(StoreIntoObject);

ASSEMBLER_TEST_RUN(StoreIntoObject, test) {
#define TEST_CODE(value, growable_array, thread)                               \
  test->Invoke<void, RawObject*, RawObject*, Thread*>(value, growable_array,   \
                                                      thread)

  const Array& old_array = Array::Handle(Array::New(3, Heap::kOld));
  const Array& new_array = Array::Handle(Array::New(3, Heap::kNew));
  const GrowableObjectArray& grow_old_array = GrowableObjectArray::Handle(
      GrowableObjectArray::New(old_array, Heap::kOld));
  const GrowableObjectArray& grow_new_array = GrowableObjectArray::Handle(
      GrowableObjectArray::New(old_array, Heap::kNew));
  Smi& smi = Smi::Handle();
  Thread* thread = Thread::Current();

  EXPECT(old_array.raw() == grow_old_array.data());
  EXPECT(!thread->StoreBufferContains(grow_old_array.raw()));
  EXPECT(old_array.raw() == grow_new_array.data());
  EXPECT(!thread->StoreBufferContains(grow_new_array.raw()));

  // Store Smis into the old object.
  for (int i = -128; i < 128; i++) {
    smi = Smi::New(i);
    TEST_CODE(smi.raw(), grow_old_array.raw(), thread);
    EXPECT(reinterpret_cast<RawArray*>(smi.raw()) == grow_old_array.data());
    EXPECT(!thread->StoreBufferContains(grow_old_array.raw()));
  }

  // Store an old object into the old object.
  TEST_CODE(old_array.raw(), grow_old_array.raw(), thread);
  EXPECT(old_array.raw() == grow_old_array.data());
  EXPECT(!thread->StoreBufferContains(grow_old_array.raw()));

  // Store a new object into the old object.
  TEST_CODE(new_array.raw(), grow_old_array.raw(), thread);
  EXPECT(new_array.raw() == grow_old_array.data());
  EXPECT(thread->StoreBufferContains(grow_old_array.raw()));

  // Store a new object into the new object.
  TEST_CODE(new_array.raw(), grow_new_array.raw(), thread);
  EXPECT(new_array.raw() == grow_new_array.data());
  EXPECT(!thread->StoreBufferContains(grow_new_array.raw()));

  // Store an old object into the new object.
  TEST_CODE(old_array.raw(), grow_new_array.raw(), thread);
  EXPECT(old_array.raw() == grow_new_array.data());
  EXPECT(!thread->StoreBufferContains(grow_new_array.raw()));
}

}  // namespace dart
