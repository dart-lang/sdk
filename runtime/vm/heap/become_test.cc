// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/globals.h"

#include "vm/globals.h"
#include "vm/heap/become.h"
#include "vm/heap/heap.h"
#include "vm/unit_test.h"

namespace dart {

void TestBecomeForward(Heap::Space before_space, Heap::Space after_space) {
  const String& before_obj = String::Handle(String::New("old", before_space));
  const String& after_obj = String::Handle(String::New("new", after_space));

  EXPECT(before_obj.raw() != after_obj.raw());

  // Allocate the arrays in old space to test the remembered set.
  const Array& before = Array::Handle(Array::New(1, Heap::kOld));
  before.SetAt(0, before_obj);
  const Array& after = Array::Handle(Array::New(1, Heap::kOld));
  after.SetAt(0, after_obj);

  Become::ElementsForwardIdentity(before, after);

  EXPECT(before_obj.raw() == after_obj.raw());

  GCTestHelper::CollectAllGarbage();

  EXPECT(before_obj.raw() == after_obj.raw());
}

ISOLATE_UNIT_TEST_CASE(BecomeFowardOldToOld) {
  TestBecomeForward(Heap::kOld, Heap::kOld);
}

ISOLATE_UNIT_TEST_CASE(BecomeFowardNewToNew) {
  TestBecomeForward(Heap::kNew, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(BecomeFowardOldToNew) {
  TestBecomeForward(Heap::kOld, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(BecomeFowardNewToOld) {
  TestBecomeForward(Heap::kNew, Heap::kOld);
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardPeer) {
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  const Array& before_obj = Array::Handle(Array::New(0, Heap::kOld));
  const Array& after_obj = Array::Handle(Array::New(0, Heap::kOld));
  EXPECT(before_obj.raw() != after_obj.raw());

  void* peer = reinterpret_cast<void*>(42);
  void* no_peer = reinterpret_cast<void*>(0);
  heap->SetPeer(before_obj.raw(), peer);
  EXPECT_EQ(peer, heap->GetPeer(before_obj.raw()));
  EXPECT_EQ(no_peer, heap->GetPeer(after_obj.raw()));

  const Array& before = Array::Handle(Array::New(1, Heap::kOld));
  before.SetAt(0, before_obj);
  const Array& after = Array::Handle(Array::New(1, Heap::kOld));
  after.SetAt(0, after_obj);
  Become::ElementsForwardIdentity(before, after);

  EXPECT(before_obj.raw() == after_obj.raw());
  EXPECT_EQ(peer, heap->GetPeer(before_obj.raw()));
  EXPECT_EQ(peer, heap->GetPeer(after_obj.raw()));
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardRememberedObject) {
  const String& new_element = String::Handle(String::New("new", Heap::kNew));
  const String& old_element = String::Handle(String::New("old", Heap::kOld));
  const Array& before_obj = Array::Handle(Array::New(1, Heap::kOld));
  const Array& after_obj = Array::Handle(Array::New(1, Heap::kOld));
  before_obj.SetAt(0, new_element);
  after_obj.SetAt(0, old_element);
  EXPECT(before_obj.raw()->ptr()->IsRemembered());
  EXPECT(!after_obj.raw()->ptr()->IsRemembered());

  EXPECT(before_obj.raw() != after_obj.raw());

  const Array& before = Array::Handle(Array::New(1, Heap::kOld));
  before.SetAt(0, before_obj);
  const Array& after = Array::Handle(Array::New(1, Heap::kOld));
  after.SetAt(0, after_obj);

  Become::ElementsForwardIdentity(before, after);

  EXPECT(before_obj.raw() == after_obj.raw());
  EXPECT(!after_obj.raw()->ptr()->IsRemembered());

  GCTestHelper::CollectAllGarbage();

  EXPECT(before_obj.raw() == after_obj.raw());
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardRememberedCards) {
  const intptr_t length = Heap::kNewAllocatableSize / kWordSize;
  ASSERT(Array::UseCardMarkingForAllocation(length));
  const Array& card_remembered_array = Array::Handle(Array::New(length));
  EXPECT(card_remembered_array.raw()->ptr()->IsCardRemembered());
  EXPECT(!card_remembered_array.raw()->ptr()->IsRemembered());

  const String& old_element = String::Handle(String::New("old", Heap::kOld));
  const String& new_element = String::Handle(String::New("new", Heap::kNew));
  card_remembered_array.SetAt(0, old_element);

  {
    HANDLESCOPE(thread);
    EXPECT_STREQ("old",
                 Object::Handle(card_remembered_array.At(0)).ToCString());
  }

  const Array& before = Array::Handle(Array::New(1, Heap::kOld));
  before.SetAt(0, old_element);
  const Array& after = Array::Handle(Array::New(1, Heap::kOld));
  after.SetAt(0, new_element);
  Become::ElementsForwardIdentity(before, after);

  EXPECT(old_element.raw() == new_element.raw());
  EXPECT(old_element.raw()->IsNewObject());
  EXPECT(card_remembered_array.raw()->ptr()->IsCardRemembered());
  EXPECT(!card_remembered_array.raw()->ptr()->IsRemembered());

  {
    HANDLESCOPE(thread);
    EXPECT_STREQ("new",
                 Object::Handle(card_remembered_array.At(0)).ToCString());
  }

  GCTestHelper::CollectAllGarbage();

  EXPECT(old_element.raw() == new_element.raw());
  EXPECT(card_remembered_array.raw()->ptr()->IsCardRemembered());
  EXPECT(!card_remembered_array.raw()->ptr()->IsRemembered());

  {
    HANDLESCOPE(thread);
    EXPECT_STREQ("new",
                 Object::Handle(card_remembered_array.At(0)).ToCString());
  }
}

}  // namespace dart
