// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assembler.h"
#include "vm/globals.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

ASSEMBLER_TEST_EXTERN(StoreIntoObject);

ASSEMBLER_TEST_RUN(StoreIntoObject, entry) {
  typedef void (*StoreData)(RawContext* ctx,
                            RawObject* value,
                            RawObject* growable_array);
  StoreData test_code = reinterpret_cast<StoreData>(entry);

  const Array& old_array = Array::Handle(Array::New(3, Heap::kOld));
  const Array& new_array = Array::Handle(Array::New(3, Heap::kNew));
  const GrowableObjectArray& grow_old_array = GrowableObjectArray::Handle(
      GrowableObjectArray::New(old_array, Heap::kOld));
  const GrowableObjectArray& grow_new_array = GrowableObjectArray::Handle(
      GrowableObjectArray::New(old_array, Heap::kNew));
  Smi& smi = Smi::Handle();
  const Context& ctx = Context::Handle(Context::New(0));

  EXPECT(old_array.raw() == grow_old_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_old_array.raw()) +
      GrowableObjectArray::data_offset() - kHeapObjectTag));
  EXPECT(old_array.raw() == grow_new_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_new_array.raw()) +
      GrowableObjectArray::data_offset() - kHeapObjectTag));

  // Store Smis into the old object.
  for (int i = -128; i < 128; i++) {
    smi = Smi::New(i);
    test_code(ctx.raw(), smi.raw(), grow_old_array.raw());
    EXPECT(reinterpret_cast<RawArray*>(smi.raw()) == grow_old_array.data());
    EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
       reinterpret_cast<uword>(grow_old_array.raw()) +
       GrowableObjectArray::data_offset() - kHeapObjectTag));
  }

  // Store an old object into the old object.
  test_code(ctx.raw(), old_array.raw(), grow_old_array.raw());
  EXPECT(old_array.raw() == grow_old_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_old_array.raw()) +
      GrowableObjectArray::data_offset() - kHeapObjectTag));

  // Store a new object into the old object.
  test_code(ctx.raw(), new_array.raw(), grow_old_array.raw());
  EXPECT(new_array.raw() == grow_old_array.data());
  EXPECT(Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_old_array.raw()) +
      GrowableObjectArray::data_offset() - kHeapObjectTag));

  // Store a new object into the new object.
  test_code(ctx.raw(), new_array.raw(), grow_new_array.raw());
  EXPECT(new_array.raw() == grow_new_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_new_array.raw()) +
      GrowableObjectArray::data_offset() - kHeapObjectTag));

  // Store an old object into the new object.
  test_code(ctx.raw(), old_array.raw(), grow_new_array.raw());
  EXPECT(old_array.raw() == grow_new_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_new_array.raw()) +
      GrowableObjectArray::data_offset() - kHeapObjectTag));
}

#endif

}  // namespace dart
