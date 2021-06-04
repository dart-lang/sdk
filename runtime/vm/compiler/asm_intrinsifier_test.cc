// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/globals.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

static intptr_t GetHash(Isolate* isolate, const ObjectPtr obj) {
#if defined(HASH_IN_OBJECT_HEADER)
  return Object::GetCachedHash(obj);
#else
  Heap* heap = isolate->group()->heap();
  ASSERT(obj->IsDartInstance());
  return heap->GetHash(obj);
#endif
}

ISOLATE_UNIT_TEST_CASE(AsmIntrinsifier_SetHashIfNotSetYet) {
  auto I = Isolate::Current();
  const auto& corelib = Library::Handle(Library::CoreLibrary());
  const auto& name = String::Handle(String::New("_setHashIfNotSetYet"));
  const auto& symbol = String::Handle(Symbols::New(thread, name));

  const auto& function =
      Function::Handle(corelib.LookupFunctionAllowPrivate(symbol));
  const auto& object_class =
      Class::Handle(corelib.LookupClass(Symbols::Object()));

  auto& smi0 = Smi::Handle(Smi::New(0));
  auto& smi21 = Smi::Handle(Smi::New(21));
  auto& smi42 = Smi::Handle(Smi::New(42));
  const auto& obj = Object::Handle(Instance::New(object_class));
  const auto& args = Array::Handle(Array::New(2));

  const auto& args_descriptor_array =
      Array::Handle(ArgumentsDescriptor::NewBoxed(0, 2, Array::empty_array()));

  // Initialized to 0
  EXPECT_EQ(smi0.ptr(), Smi::New(GetHash(I, obj.ptr())));

  // Lazily set to 42 on first call.
  args.SetAt(0, obj);
  args.SetAt(1, smi42);
  EXPECT_EQ(smi42.ptr(),
            DartEntry::InvokeFunction(function, args, args_descriptor_array));
  EXPECT_EQ(smi42.ptr(), Smi::New(GetHash(I, obj.ptr())));

  // Stays at 42 on subsequent calls.
  args.SetAt(0, obj);
  args.SetAt(1, smi21);
  EXPECT_EQ(smi42.ptr(),
            DartEntry::InvokeFunction(function, args, args_descriptor_array));
  EXPECT_EQ(smi42.ptr(), Smi::New(GetHash(I, obj.ptr())));

  // We test setting the maximum value our core libraries would use when
  // installing an identity hash code (see
  // sdk/lib/_internal/vm/lib/object_patch.dart:Object._objectHashCode)
  //
  // This value is representable as a positive Smi on all architectures (even
  // compressed pointers).
  const auto& smiMax = Smi::Handle(Smi::New(0x40000000 - 1));
  const auto& obj2 = Object::Handle(Instance::New(object_class));

  // Initialized to 0
  EXPECT_EQ(smi0.ptr(), Smi::New(GetHash(I, obj2.ptr())));

  // Lazily set to smiMax first call.
  args.SetAt(0, obj2);
  args.SetAt(1, smiMax);
  EXPECT_EQ(smiMax.ptr(),
            DartEntry::InvokeFunction(function, args, args_descriptor_array));
  EXPECT_EQ(smiMax.ptr(), Smi::New(GetHash(I, obj2.ptr())));

  // Stays at smiMax on subsequent calls.
  args.SetAt(0, obj2);
  args.SetAt(1, smi21);
  EXPECT_EQ(smiMax.ptr(),
            DartEntry::InvokeFunction(function, args, args_descriptor_array));
  EXPECT_EQ(smiMax.ptr(), Smi::New(GetHash(I, obj2.ptr())));
}

}  // namespace dart
