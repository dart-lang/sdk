// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assembler.h"
#include "vm/globals.h"
#include "vm/os.h"
#include "vm/simulator.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

ASSEMBLER_TEST_EXTERN(StoreIntoObject);

ASSEMBLER_TEST_RUN(StoreIntoObject, test) {
#if defined(USING_SIMULATOR)
#define test_code(ctx, value, growable_array)                                  \
  Simulator::Current()->Call(                                                  \
      bit_cast<int32_t, uword>(test->entry()),                                 \
      reinterpret_cast<int32_t>(ctx),                                          \
      reinterpret_cast<int32_t>(value),                                        \
      reinterpret_cast<int32_t>(growable_array),                               \
      0)
#else
  typedef void (*StoreData)(RawContext* ctx,
                            RawObject* value,
                            RawObject* growable_array);
  StoreData test_code = reinterpret_cast<StoreData>(test->entry());
#endif

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
      reinterpret_cast<uword>(grow_old_array.raw())));
  EXPECT(old_array.raw() == grow_new_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_new_array.raw())));

  // Store Smis into the old object.
  for (int i = -128; i < 128; i++) {
    smi = Smi::New(i);
    test_code(ctx.raw(), smi.raw(), grow_old_array.raw());
    EXPECT(reinterpret_cast<RawArray*>(smi.raw()) == grow_old_array.data());
    EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
       reinterpret_cast<uword>(grow_old_array.raw())));
  }

  // Store an old object into the old object.
  test_code(ctx.raw(), old_array.raw(), grow_old_array.raw());
  EXPECT(old_array.raw() == grow_old_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_old_array.raw())));

  // Store a new object into the old object.
  test_code(ctx.raw(), new_array.raw(), grow_old_array.raw());
  EXPECT(new_array.raw() == grow_old_array.data());
  EXPECT(Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_old_array.raw())));

  // Store a new object into the new object.
  test_code(ctx.raw(), new_array.raw(), grow_new_array.raw());
  EXPECT(new_array.raw() == grow_new_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_new_array.raw())));

  // Store an old object into the new object.
  test_code(ctx.raw(), old_array.raw(), grow_new_array.raw());
  EXPECT(old_array.raw() == grow_new_array.data());
  EXPECT(!Isolate::Current()->store_buffer_block()->Contains(
      reinterpret_cast<uword>(grow_new_array.raw())));
}

}  // namespace dart
