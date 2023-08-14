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
  // Allocate the container in old space to test the remembered set.
  const Array& container = Array::Handle(Array::New(1, Heap::kOld));

  const String& before_obj = String::Handle(String::New("old", before_space));
  const String& after_obj = String::Handle(String::New("new", after_space));
  container.SetAt(0, before_obj);
  EXPECT(before_obj.ptr() != after_obj.ptr());

  Become become;
  become.Add(before_obj, after_obj);
  become.Forward();

  EXPECT(before_obj.ptr() == after_obj.ptr());
  EXPECT(container.At(0) == after_obj.ptr());

  GCTestHelper::CollectAllGarbage();

  EXPECT(before_obj.ptr() == after_obj.ptr());
  EXPECT(container.At(0) == after_obj.ptr());
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardOldToOld) {
  TestBecomeForward(Heap::kOld, Heap::kOld);
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardNewToNew) {
  TestBecomeForward(Heap::kNew, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardOldToNew) {
  TestBecomeForward(Heap::kOld, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardNewToOld) {
  TestBecomeForward(Heap::kNew, Heap::kOld);
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardPeer) {
  Heap* heap = IsolateGroup::Current()->heap();

  const Array& before_obj = Array::Handle(Array::New(0, Heap::kOld));
  const Array& after_obj = Array::Handle(Array::New(0, Heap::kOld));
  EXPECT(before_obj.ptr() != after_obj.ptr());

  void* peer = reinterpret_cast<void*>(42);
  void* no_peer = reinterpret_cast<void*>(0);
  heap->SetPeer(before_obj.ptr(), peer);
  EXPECT_EQ(peer, heap->GetPeer(before_obj.ptr()));
  EXPECT_EQ(no_peer, heap->GetPeer(after_obj.ptr()));

  Become become;
  become.Add(before_obj, after_obj);
  become.Forward();

  EXPECT(before_obj.ptr() == after_obj.ptr());
  EXPECT_EQ(peer, heap->GetPeer(before_obj.ptr()));
  EXPECT_EQ(peer, heap->GetPeer(after_obj.ptr()));
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardObjectId) {
  Heap* heap = IsolateGroup::Current()->heap();

  const Array& before_obj = Array::Handle(Array::New(0, Heap::kOld));
  const Array& after_obj = Array::Handle(Array::New(0, Heap::kOld));
  EXPECT(before_obj.ptr() != after_obj.ptr());

  intptr_t id = 42;
  intptr_t no_id = 0;
  heap->SetObjectId(before_obj.ptr(), id);
  EXPECT_EQ(id, heap->GetObjectId(before_obj.ptr()));
  EXPECT_EQ(no_id, heap->GetObjectId(after_obj.ptr()));

  Become become;
  become.Add(before_obj, after_obj);
  become.Forward();

  EXPECT(before_obj.ptr() == after_obj.ptr());
  EXPECT_EQ(id, heap->GetObjectId(before_obj.ptr()));
  EXPECT_EQ(id, heap->GetObjectId(after_obj.ptr()));
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardMessageId) {
  Isolate* isolate = Isolate::Current();
  isolate->set_forward_table_new(new WeakTable());
  isolate->set_forward_table_old(new WeakTable());

  const Array& before_obj = Array::Handle(Array::New(0, Heap::kOld));
  const Array& after_obj = Array::Handle(Array::New(0, Heap::kOld));
  EXPECT(before_obj.ptr() != after_obj.ptr());

  intptr_t id = 42;
  intptr_t no_id = 0;
  isolate->forward_table_old()->SetValueExclusive(before_obj.ptr(), id);
  EXPECT_EQ(id,
            isolate->forward_table_old()->GetValueExclusive(before_obj.ptr()));
  EXPECT_EQ(no_id,
            isolate->forward_table_old()->GetValueExclusive(after_obj.ptr()));

  Become become;
  become.Add(before_obj, after_obj);
  become.Forward();

  EXPECT(before_obj.ptr() == after_obj.ptr());
  EXPECT_EQ(id,
            isolate->forward_table_old()->GetValueExclusive(before_obj.ptr()));
  EXPECT_EQ(id,
            isolate->forward_table_old()->GetValueExclusive(after_obj.ptr()));

  isolate->set_forward_table_new(nullptr);
  isolate->set_forward_table_old(nullptr);
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardRememberedObject) {
  const String& new_element = String::Handle(String::New("new", Heap::kNew));
  const String& old_element = String::Handle(String::New("old", Heap::kOld));
  const Array& before_obj = Array::Handle(Array::New(1, Heap::kOld));
  const Array& after_obj = Array::Handle(Array::New(1, Heap::kOld));
  before_obj.SetAt(0, new_element);
  after_obj.SetAt(0, old_element);
  EXPECT(before_obj.ptr()->untag()->IsRemembered());
  EXPECT(!after_obj.ptr()->untag()->IsRemembered());

  EXPECT(before_obj.ptr() != after_obj.ptr());

  Become become;
  become.Add(before_obj, after_obj);
  become.Forward();

  EXPECT(before_obj.ptr() == after_obj.ptr());
  EXPECT(!after_obj.ptr()->untag()->IsRemembered());

  GCTestHelper::CollectAllGarbage();

  EXPECT(before_obj.ptr() == after_obj.ptr());
}

ISOLATE_UNIT_TEST_CASE(BecomeForwardRememberedCards) {
  const intptr_t length = kNewAllocatableSize / Array::kBytesPerElement;
  ASSERT(Array::UseCardMarkingForAllocation(length));
  const Array& card_remembered_array = Array::Handle(Array::New(length));
  EXPECT(card_remembered_array.ptr()->untag()->IsCardRemembered());
  EXPECT(!card_remembered_array.ptr()->untag()->IsRemembered());

  const String& old_element = String::Handle(String::New("old", Heap::kOld));
  const String& new_element = String::Handle(String::New("new", Heap::kNew));
  card_remembered_array.SetAt(0, old_element);

  {
    HANDLESCOPE(thread);
    EXPECT_STREQ("old",
                 Object::Handle(card_remembered_array.At(0)).ToCString());
  }

  Become become;
  become.Add(old_element, new_element);
  become.Forward();

  EXPECT(old_element.ptr() == new_element.ptr());
  EXPECT(old_element.ptr()->IsNewObject());
  EXPECT(card_remembered_array.ptr()->untag()->IsCardRemembered());
  EXPECT(!card_remembered_array.ptr()->untag()->IsRemembered());

  {
    HANDLESCOPE(thread);
    EXPECT_STREQ("new",
                 Object::Handle(card_remembered_array.At(0)).ToCString());
  }

  GCTestHelper::CollectAllGarbage();

  EXPECT(old_element.ptr() == new_element.ptr());
  EXPECT(card_remembered_array.ptr()->untag()->IsCardRemembered());
  EXPECT(!card_remembered_array.ptr()->untag()->IsRemembered());

  {
    HANDLESCOPE(thread);
    EXPECT_STREQ("new",
                 Object::Handle(card_remembered_array.At(0)).ToCString());
  }
}

}  // namespace dart
