// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <map>
#include <memory>
#include <set>
#include <string>

#include "platform/globals.h"

#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/dart_api_impl.h"
#include "vm/globals.h"
#include "vm/heap/become.h"
#include "vm/heap/heap.h"
#include "vm/message_handler.h"
#include "vm/message_snapshot.h"
#include "vm/object_graph.h"
#include "vm/port.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(OldGC) {
  const char* kScriptChars =
      "main() {\n"
      "  return [1, 2, 3];\n"
      "}\n";
  NOT_IN_PRODUCT(FLAG_verbose_gc = true);
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);

  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  EXPECT(Dart_IsList(result));
  TransitionNativeToVM transition(thread);
  GCTestHelper::CollectOldSpace();
}

#if !defined(PRODUCT)
TEST_CASE(OldGC_Unsync) {
  // Finalize any GC in progress as it is unsafe to change FLAG_marker_tasks
  // when incremental marking is in progress.
  {
    TransitionNativeToVM transition(thread);
    GCTestHelper::CollectAllGarbage();
  }
  FLAG_marker_tasks = 0;

  const char* kScriptChars =
      "main() {\n"
      "  return [1, 2, 3];\n"
      "}\n";
  FLAG_verbose_gc = true;
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);

  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  EXPECT(Dart_IsList(result));
  TransitionNativeToVM transition(thread);
  GCTestHelper::CollectOldSpace();
}
#endif  // !defined(PRODUCT)

TEST_CASE(LargeSweep) {
  const char* kScriptChars =
      "main() {\n"
      "  return List.filled(8 * 1024 * 1024, null);\n"
      "}\n";
  NOT_IN_PRODUCT(FLAG_verbose_gc = true);
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);

  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  EXPECT(Dart_IsList(result));
  {
    TransitionNativeToVM transition(thread);
    GCTestHelper::CollectOldSpace();
  }
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    GCTestHelper::CollectOldSpace();
  }
}

#ifndef PRODUCT
static ClassPtr GetClass(const Library& lib, const char* name) {
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(Thread::Current(), name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.ptr();
}

TEST_CASE(ClassHeapStats) {
  const char* kScriptChars =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      ""
      "main() {\n"
      "  var x = new A();\n"
      "  return new A();\n"
      "}\n";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScriptChars, NULL);
  auto isolate_group = IsolateGroup::Current();
  ClassTable* class_table = isolate_group->class_table();
  {
    // GC before main so allocations during the tests don't cause unexpected GC.
    TransitionNativeToVM transition(thread);
    GCTestHelper::CollectAllGarbage();
  }
  Dart_EnterScope();
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  intptr_t cid;
  {
    TransitionNativeToVM transition(thread);
    Library& lib = Library::Handle();
    lib ^= Api::UnwrapHandle(h_lib);
    EXPECT(!lib.IsNull());
    const Class& cls = Class::Handle(GetClass(lib, "A"));
    ASSERT(!cls.IsNull());
    cid = cls.id();

    {
      // Verify preconditions: allocated twice in new space.
      CountObjectsVisitor visitor(thread, class_table->NumCids());
      HeapIterationScope iter(thread);
      iter.IterateObjects(&visitor);
      isolate_group->VisitWeakPersistentHandles(&visitor);
      EXPECT_EQ(2, visitor.new_count_[cid]);
      EXPECT_EQ(0, visitor.old_count_[cid]);
    }

    // Perform GC.
    GCTestHelper::CollectNewSpace();

    {
      // Verify postconditions: Only one survived.
      CountObjectsVisitor visitor(thread, class_table->NumCids());
      HeapIterationScope iter(thread);
      iter.IterateObjects(&visitor);
      isolate_group->VisitWeakPersistentHandles(&visitor);
      EXPECT_EQ(1, visitor.new_count_[cid]);
      EXPECT_EQ(0, visitor.old_count_[cid]);
    }

    // Perform GC. The following is heavily dependent on the behaviour
    // of the GC: Retained instance of A will be promoted.
    GCTestHelper::CollectNewSpace();

    {
      // Verify postconditions: One promoted instance.
      CountObjectsVisitor visitor(thread, class_table->NumCids());
      HeapIterationScope iter(thread);
      iter.IterateObjects(&visitor);
      isolate_group->VisitWeakPersistentHandles(&visitor);
      EXPECT_EQ(0, visitor.new_count_[cid]);
      EXPECT_EQ(1, visitor.old_count_[cid]);
    }

    // Perform a GC on new space.
    GCTestHelper::CollectNewSpace();

    {
      // Verify postconditions:
      CountObjectsVisitor visitor(thread, class_table->NumCids());
      HeapIterationScope iter(thread);
      iter.IterateObjects(&visitor);
      isolate_group->VisitWeakPersistentHandles(&visitor);
      EXPECT_EQ(0, visitor.new_count_[cid]);
      EXPECT_EQ(1, visitor.old_count_[cid]);
    }

    GCTestHelper::CollectOldSpace();

    {
      // Verify postconditions:
      CountObjectsVisitor visitor(thread, class_table->NumCids());
      HeapIterationScope iter(thread);
      iter.IterateObjects(&visitor);
      isolate_group->VisitWeakPersistentHandles(&visitor);
      EXPECT_EQ(0, visitor.new_count_[cid]);
      EXPECT_EQ(1, visitor.old_count_[cid]);
    }
  }
  // Exit scope, freeing instance.
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    // Perform GC.
    GCTestHelper::CollectOldSpace();
    {
      // Verify postconditions:
      CountObjectsVisitor visitor(thread, class_table->NumCids());
      HeapIterationScope iter(thread);
      iter.IterateObjects(&visitor);
      isolate_group->VisitWeakPersistentHandles(&visitor);
      EXPECT_EQ(0, visitor.new_count_[cid]);
      EXPECT_EQ(0, visitor.old_count_[cid]);
    }
  }
}
#endif  // !PRODUCT

class FindOnly : public FindObjectVisitor {
 public:
  explicit FindOnly(ObjectPtr target) : target_(target) {
#if defined(DEBUG)
    EXPECT_GT(Thread::Current()->no_safepoint_scope_depth(), 0);
#endif
  }
  virtual ~FindOnly() {}

  virtual bool FindObject(ObjectPtr obj) const { return obj == target_; }

 private:
  ObjectPtr target_;
};

class FindNothing : public FindObjectVisitor {
 public:
  FindNothing() {}
  virtual ~FindNothing() {}
  virtual bool FindObject(ObjectPtr obj) const { return false; }
};

ISOLATE_UNIT_TEST_CASE(FindObject) {
  Heap* heap = IsolateGroup::Current()->heap();
  Heap::Space spaces[2] = {Heap::kOld, Heap::kNew};
  for (size_t space = 0; space < ARRAY_SIZE(spaces); ++space) {
    const String& obj = String::Handle(String::New("x", spaces[space]));
    {
      HeapIterationScope iteration(thread);
      NoSafepointScope no_safepoint;
      FindOnly find_only(obj.ptr());
      EXPECT(obj.ptr() == heap->FindObject(&find_only));
    }
  }
  {
    HeapIterationScope iteration(thread);
    NoSafepointScope no_safepoint;
    FindNothing find_nothing;
    EXPECT(Object::null() == heap->FindObject(&find_nothing));
  }
}

ISOLATE_UNIT_TEST_CASE(IterateReadOnly) {
  const String& obj = String::Handle(String::New("x", Heap::kOld));

  // It is not safe to make the heap read-only if marking or sweeping is in
  // progress.
  GCTestHelper::WaitForGCTasks();

  Heap* heap = IsolateGroup::Current()->heap();
  EXPECT(heap->Contains(UntaggedObject::ToAddr(obj.ptr())));
  heap->WriteProtect(true);
  EXPECT(heap->Contains(UntaggedObject::ToAddr(obj.ptr())));
  heap->WriteProtect(false);
  EXPECT(heap->Contains(UntaggedObject::ToAddr(obj.ptr())));
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_DeadOldToNew) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  old.SetAt(0, neu);
  old = Array::null();
  neu = Array::null();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT_EQ(size_before, size_after);
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_DeadNewToOld) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  neu.SetAt(0, old);
  old = Array::null();
  neu = Array::null();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT_EQ(size_before, size_after);
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_DeadGenCycle) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  neu.SetAt(0, old);
  old.SetAt(0, neu);
  old = Array::null();
  neu = Array::null();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT_EQ(size_before, size_after);
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_LiveNewToOld) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  neu.SetAt(0, old);
  old = Array::null();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT(size_before < size_after);
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_LiveOldToNew) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  old.SetAt(0, neu);
  neu = Array::null();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT(size_before < size_after);
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_LiveOldDeadNew) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  neu = Array::null();
  old.SetAt(0, old);

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT(size_before < size_after);
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_LiveNewDeadOld) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  old = Array::null();
  neu.SetAt(0, neu);

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT(size_before < size_after);
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_LiveNewToOldChain) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& old2 = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  old.SetAt(0, old2);
  neu.SetAt(0, old);
  old = Array::null();
  old2 = Array::null();

  heap->CollectAllGarbage();

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT(size_before < size_after);
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_LiveOldToNewChain) {
  Heap* heap = IsolateGroup::Current()->heap();

  heap->CollectAllGarbage();
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  Array& old = Array::Handle(Array::New(1, Heap::kOld));
  Array& neu = Array::Handle(Array::New(1, Heap::kNew));
  Array& neu2 = Array::Handle(Array::New(1, Heap::kOld));
  neu.SetAt(0, neu2);
  old.SetAt(0, neu);
  neu = Array::null();
  neu2 = Array::null();

  heap->CollectAllGarbage();

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT(size_before < size_after);
}

static void NoopFinalizer(void* isolate_callback_data, void* peer) {}

ISOLATE_UNIT_TEST_CASE(ExternalPromotion) {
  auto isolate_group = IsolateGroup::Current();
  Heap* heap = isolate_group->heap();

  heap->CollectAllGarbage();
  intptr_t size_before = kWordSize * (heap->new_space()->ExternalInWords() +
                                      heap->old_space()->ExternalInWords());

  Array& old = Array::Handle(Array::New(100, Heap::kOld));
  Array& neu = Array::Handle();
  for (intptr_t i = 0; i < 100; i++) {
    neu = Array::New(1, Heap::kNew);
    FinalizablePersistentHandle::New(isolate_group, neu, NULL, NoopFinalizer,
                                     1 * MB,
                                     /*auto_delete=*/true);
    old.SetAt(i, neu);
  }

  intptr_t size_middle = kWordSize * (heap->new_space()->ExternalInWords() +
                                      heap->old_space()->ExternalInWords());
  EXPECT_EQ(size_before + 100 * MB, size_middle);

  old = Array::null();
  neu = Array::null();

  heap->CollectAllGarbage();

  intptr_t size_after = kWordSize * (heap->new_space()->ExternalInWords() +
                                     heap->old_space()->ExternalInWords());

  EXPECT_EQ(size_before, size_after);
}

#if !defined(PRODUCT)
class HeapTestHelper {
 public:
  static void Scavenge(Thread* thread) {
    thread->heap()->CollectNewSpaceGarbage(thread, GCType::kScavenge,
                                           GCReason::kDebugging);
  }
  static void MarkSweep(Thread* thread) {
    thread->heap()->CollectOldSpaceGarbage(thread, GCType::kMarkSweep,
                                           GCReason::kDebugging);
    thread->heap()->WaitForMarkerTasks(thread);
    thread->heap()->WaitForSweeperTasks(thread);
  }
};

class SendAndExitMessagesHandler : public MessageHandler {
 public:
  explicit SendAndExitMessagesHandler(Isolate* owner)
      : msg_(Utils::CreateCStringUniquePtr(nullptr)), owner_(owner) {}

  const char* name() const { return "merge-isolates-heaps-handler"; }

  ~SendAndExitMessagesHandler() { PortMap::ClosePorts(this); }

  MessageStatus HandleMessage(std::unique_ptr<Message> message) {
    // Parse the message.
    Object& response_obj = Object::Handle();
    if (message->IsRaw()) {
      response_obj = message->raw_obj();
    } else if (message->IsPersistentHandle()) {
      PersistentHandle* handle = message->persistent_handle();
      // Object is in the receiving isolate's heap.
      EXPECT(isolate()->group()->heap()->Contains(
          UntaggedObject::ToAddr(handle->ptr())));
      response_obj = handle->ptr();
      isolate()->group()->api_state()->FreePersistentHandle(handle);
    } else {
      Thread* thread = Thread::Current();
      response_obj = ReadMessage(thread, message.get());
    }
    if (response_obj.IsString()) {
      String& response = String::Handle();
      response ^= response_obj.ptr();
      msg_.reset(Utils::StrDup(response.ToCString()));
    } else {
      ASSERT(response_obj.IsArray());
      Array& response_array = Array::Handle();
      response_array ^= response_obj.ptr();
      ASSERT(response_array.Length() == 1);
      ExternalTypedData& response = ExternalTypedData::Handle();
      response ^= response_array.At(0);
      msg_.reset(Utils::StrDup(reinterpret_cast<char*>(response.DataAddr(0))));
    }

    return kOK;
  }

  const char* msg() const { return msg_.get(); }

  virtual Isolate* isolate() const { return owner_; }

 private:
  Utils::CStringUniquePtr msg_;
  Isolate* owner_;
};

VM_UNIT_TEST_CASE(CleanupBequestNeverReceived) {
  const char* TEST_MESSAGE = "hello, world";
  Dart_Isolate parent = TestCase::CreateTestIsolate("parent");
  EXPECT_EQ(parent, Dart_CurrentIsolate());
  {
    SendAndExitMessagesHandler handler(Isolate::Current());
    Dart_Port port_id = PortMap::CreatePort(&handler);
    EXPECT_EQ(PortMap::GetIsolate(port_id), Isolate::Current());
    Dart_ExitIsolate();

    Dart_Isolate worker = TestCase::CreateTestIsolateInGroup("worker", parent);
    EXPECT_EQ(worker, Dart_CurrentIsolate());
    {
      Thread* thread = Thread::Current();
      TransitionNativeToVM transition(thread);
      StackZone zone(thread);

      String& string = String::Handle(String::New(TEST_MESSAGE));
      PersistentHandle* handle =
          Isolate::Current()->group()->api_state()->AllocatePersistentHandle();
      handle->set_ptr(string.ptr());

      reinterpret_cast<Isolate*>(worker)->bequeath(
          std::unique_ptr<Bequest>(new Bequest(handle, port_id)));
    }
  }
  Dart_ShutdownIsolate();
  Dart_EnterIsolate(parent);
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(ReceivesSendAndExitMessage) {
  const char* TEST_MESSAGE = "hello, world";
  Dart_Isolate parent = TestCase::CreateTestIsolate("parent");
  EXPECT_EQ(parent, Dart_CurrentIsolate());
  SendAndExitMessagesHandler handler(Isolate::Current());
  Dart_Port port_id = PortMap::CreatePort(&handler);
  EXPECT_EQ(PortMap::GetIsolate(port_id), Isolate::Current());
  Dart_ExitIsolate();

  Dart_Isolate worker = TestCase::CreateTestIsolateInGroup("worker", parent);
  EXPECT_EQ(worker, Dart_CurrentIsolate());
  {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);

    String& string = String::Handle(String::New(TEST_MESSAGE));

    PersistentHandle* handle =
        Isolate::Current()->group()->api_state()->AllocatePersistentHandle();
    handle->set_ptr(string.ptr());

    reinterpret_cast<Isolate*>(worker)->bequeath(
        std::unique_ptr<Bequest>(new Bequest(handle, port_id)));
  }

  Dart_ShutdownIsolate();
  Dart_EnterIsolate(parent);
  {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);

    EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  }
  EXPECT_STREQ(handler.msg(), TEST_MESSAGE);
  Dart_ShutdownIsolate();
}

ISOLATE_UNIT_TEST_CASE(ExternalAllocationStats) {
  auto isolate_group = thread->isolate_group();
  Heap* heap = isolate_group->heap();

  Array& old = Array::Handle(Array::New(100, Heap::kOld));
  Array& neu = Array::Handle();
  for (intptr_t i = 0; i < 100; i++) {
    neu = Array::New(1, Heap::kNew);
    FinalizablePersistentHandle::New(isolate_group, neu, NULL, NoopFinalizer,
                                     1 * MB,
                                     /*auto_delete=*/true);
    old.SetAt(i, neu);

    if ((i % 4) == 0) {
      HeapTestHelper::MarkSweep(thread);
    } else {
      HeapTestHelper::Scavenge(thread);
    }

    CountObjectsVisitor visitor(thread,
                                isolate_group->class_table()->NumCids());
    HeapIterationScope iter(thread);
    iter.IterateObjects(&visitor);
    isolate_group->VisitWeakPersistentHandles(&visitor);
    EXPECT_LE(visitor.old_external_size_[kArrayCid],
              heap->old_space()->ExternalInWords() * kWordSize);
    EXPECT_LE(visitor.new_external_size_[kArrayCid],
              heap->new_space()->ExternalInWords() * kWordSize);
  }
}

ISOLATE_UNIT_TEST_CASE(ExternalSizeLimit) {
  // This test checks that the tracked total size of external data never exceeds
  // the amount of memory on the system. To accomplish this, the test performs
  // five calls to FinalizablePersistentHandle::New(), all supplying a size
  // argument that is barely (16 bytes) less than a quarter of kMaxAddrSpaceMB.
  // So, we expect the first four calls to succeed, and the fifth one to return
  // nullptr.

  auto isolate_group = thread->isolate_group();
  Heap* heap = isolate_group->heap();

  // We declare an array of only length 1 here to get around the limit of
  // ExternalTypedData::MaxElements(kExternalTypedDataUint8ArrayCid). Below, we
  // pretend that the length is longer when calling
  // FinalizablePersistentHandle::New(), which is what updates the external size
  // tracker.
  const intptr_t data_length = 1;
  uint8_t data[data_length] = {0};
  const ExternalTypedData& external_typed_data_1 =
      ExternalTypedData::Handle(ExternalTypedData::New(
          kExternalTypedDataUint8ArrayCid, data, data_length, Heap::kOld));
  const ExternalTypedData& external_typed_data_2 =
      ExternalTypedData::Handle(ExternalTypedData::New(
          kExternalTypedDataUint8ArrayCid, data, data_length, Heap::kOld));
  const ExternalTypedData& external_typed_data_3 =
      ExternalTypedData::Handle(ExternalTypedData::New(
          kExternalTypedDataUint8ArrayCid, data, data_length, Heap::kOld));
  const ExternalTypedData& external_typed_data_4 =
      ExternalTypedData::Handle(ExternalTypedData::New(
          kExternalTypedDataUint8ArrayCid, data, data_length, Heap::kOld));
  const ExternalTypedData& external_typed_data_5 =
      ExternalTypedData::Handle(ExternalTypedData::New(
          kExternalTypedDataUint8ArrayCid, data, data_length, Heap::kOld));

  // A size that is less than a quarter of kMaxAddrSpaceMB is used because it
  // needs to be less than or equal to std::numeric_limits<intptr_t>::max().
  const intptr_t external_allocation_size =
      (intptr_t{kMaxAddrSpaceMB / 4} << MBLog2) - 16;
  EXPECT_NOTNULL(FinalizablePersistentHandle::New(
      isolate_group, external_typed_data_1, nullptr, NoopFinalizer,
      external_allocation_size,
      /*auto_delete=*/true));
  EXPECT_LT(heap->old_space()->ExternalInWords(), kMaxAddrSpaceInWords);

  EXPECT_NOTNULL(FinalizablePersistentHandle::New(
      isolate_group, external_typed_data_2, nullptr, NoopFinalizer,
      external_allocation_size,
      /*auto_delete=*/true));
  EXPECT_LT(heap->old_space()->ExternalInWords(), kMaxAddrSpaceInWords);

  EXPECT_NOTNULL(FinalizablePersistentHandle::New(
      isolate_group, external_typed_data_3, nullptr, NoopFinalizer,
      external_allocation_size,
      /*auto_delete=*/true));
  EXPECT_LT(heap->old_space()->ExternalInWords(), kMaxAddrSpaceInWords);

  EXPECT_NOTNULL(FinalizablePersistentHandle::New(
      isolate_group, external_typed_data_4, nullptr, NoopFinalizer,
      external_allocation_size,
      /*auto_delete=*/true));
  EXPECT_LT(heap->old_space()->ExternalInWords(), kMaxAddrSpaceInWords);

  EXPECT_NULLPTR(FinalizablePersistentHandle::New(
      isolate_group, external_typed_data_5, nullptr, NoopFinalizer,
      external_allocation_size,
      /*auto_delete=*/true));
  // Check that the external size is indeed protected from overflowing.
  EXPECT_LT(heap->old_space()->ExternalInWords(), kMaxAddrSpaceInWords);
}
#endif  // !defined(PRODUCT)

ISOLATE_UNIT_TEST_CASE(ArrayTruncationRaces) {
  // Alternate between allocating new lists and truncating.
  // For each list, the life cycle is
  // 1) the list is allocated and filled with some elements
  // 2) kNumLists other lists are allocated
  // 3) the list's backing store is truncated; the list becomes unreachable
  // 4) kNumLists other lists are allocated
  // 5) the backing store becomes unreachable
  // The goal is to cause truncation *during* concurrent mark or sweep, by
  // truncating an array that had been alive for a while and will be visited by
  // a GC triggering by the allocations in step 2.

  intptr_t kMaxListLength = 100;
  intptr_t kNumLists = 1000;
  Array& lists = Array::Handle(Array::New(kNumLists));
  Array& arrays = Array::Handle(Array::New(kNumLists));

  GrowableObjectArray& list = GrowableObjectArray::Handle();
  Array& array = Array::Handle();
  Object& element = Object::Handle();

  for (intptr_t i = 0; i < kNumLists; i++) {
    list = GrowableObjectArray::New(Heap::kNew);
    intptr_t length = i % kMaxListLength;
    for (intptr_t j = 0; j < length; j++) {
      list.Add(element, Heap::kNew);
    }
    lists.SetAt(i, list);
  }

  intptr_t kTruncations = 100000;
  for (intptr_t i = 0; i < kTruncations; i++) {
    list ^= lists.At(i % kNumLists);
    array = Array::MakeFixedLength(list);
    arrays.SetAt(i % kNumLists, array);

    list = GrowableObjectArray::New(Heap::kOld);
    intptr_t length = i % kMaxListLength;
    for (intptr_t j = 0; j < length; j++) {
      list.Add(element, Heap::kOld);
    }
    lists.SetAt(i % kNumLists, list);
  }
}

class ConcurrentForceGrowthScopeTask : public ThreadPool::Task {
 public:
  ConcurrentForceGrowthScopeTask(Isolate* isolate,
                                 Monitor* monitor,
                                 intptr_t* done_count)
      : isolate_(isolate), monitor_(monitor), done_count_(done_count) {}

  virtual void Run() {
    Thread::EnterIsolateAsHelper(isolate_, Thread::kUnknownTask);
    {
      Thread* thread = Thread::Current();
      StackZone stack_zone(thread);

      GrowableObjectArray& accumulate =
          GrowableObjectArray::Handle(GrowableObjectArray::New());
      Object& element = Object::Handle();
      for (intptr_t i = 0; i < 1000; i++) {
        // Lots of entering and leaving ForceGrowth scopes. Previously, this
        // would have been data races on the per-Heap force-growth flag.
        {
          ForceGrowthScope force_growth(thread);
          GrowableObjectArrayPtr unsafe_accumulate = accumulate.ptr();
          element = Array::New(0);
          accumulate = unsafe_accumulate;
        }
        accumulate.Add(element);
      }
    }
    Thread::ExitIsolateAsHelper();
    // Notify the main thread that this thread has exited.
    {
      MonitorLocker ml(monitor_);
      *done_count_ += 1;
      ml.Notify();
    }
  }

 private:
  Isolate* isolate_;
  Monitor* monitor_;
  intptr_t* done_count_;
};

ISOLATE_UNIT_TEST_CASE(ConcurrentForceGrowthScope) {
  intptr_t task_count = 8;
  Monitor monitor;
  intptr_t done_count = 0;

  for (intptr_t i = 0; i < task_count; i++) {
    Dart::thread_pool()->Run<ConcurrentForceGrowthScopeTask>(
        thread->isolate(), &monitor, &done_count);
  }

  {
    MonitorLocker ml(&monitor);
    while (done_count < task_count) {
      ml.WaitWithSafepointCheck(thread);
    }
  }
}

ISOLATE_UNIT_TEST_CASE(WeakSmi) {
  // Weaklings are prevented from referencing Smis by the public Dart library
  // interface, but the VM internally can do this and the implementation should
  // just handle it. Immediate objects are effectively immortal.

  WeakProperty& new_ephemeron =
      WeakProperty::Handle(WeakProperty::New(Heap::kNew));
  WeakProperty& old_ephemeron =
      WeakProperty::Handle(WeakProperty::New(Heap::kOld));
  WeakReference& new_weakref =
      WeakReference::Handle(WeakReference::New(Heap::kNew));
  WeakReference& old_weakref =
      WeakReference::Handle(WeakReference::New(Heap::kOld));
  WeakArray& new_weakarray = WeakArray::Handle(WeakArray::New(1, Heap::kNew));
  WeakArray& old_weakarray = WeakArray::Handle(WeakArray::New(1, Heap::kOld));
  FinalizerEntry& new_finalizer = FinalizerEntry::Handle(
      FinalizerEntry::New(FinalizerBase::Handle(), Heap::kNew));
  FinalizerEntry& old_finalizer = FinalizerEntry::Handle(
      FinalizerEntry::New(FinalizerBase::Handle(), Heap::kOld));

  {
    HANDLESCOPE(thread);
    Smi& smi = Smi::Handle(Smi::New(42));
    new_ephemeron.set_key(smi);
    old_ephemeron.set_key(smi);
    new_weakref.set_target(smi);
    old_weakref.set_target(smi);
    new_weakarray.SetAt(0, smi);
    old_weakarray.SetAt(0, smi);
    new_finalizer.set_value(smi);
    old_finalizer.set_value(smi);
  }

  GCTestHelper::CollectNewSpace();
  GCTestHelper::CollectAllGarbage();

  EXPECT(new_ephemeron.key() == Smi::New(42));
  EXPECT(old_ephemeron.key() == Smi::New(42));
  EXPECT(new_weakref.target() == Smi::New(42));
  EXPECT(old_weakref.target() == Smi::New(42));
  EXPECT(new_weakarray.At(0) == Smi::New(42));
  EXPECT(old_weakarray.At(0) == Smi::New(42));
  EXPECT(new_finalizer.value() == Smi::New(42));
  EXPECT(old_finalizer.value() == Smi::New(42));
}

}  // namespace dart
