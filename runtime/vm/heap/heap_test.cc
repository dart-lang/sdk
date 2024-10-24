// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <map>
#include <memory>
#include <set>
#include <string>

#include "platform/globals.h"

#include "platform/assert.h"
#include "platform/no_tsan.h"
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

DECLARE_FLAG(int, early_tenuring_threshold);

TEST_CASE(OldGC) {
  const char* kScriptChars =
      "main() {\n"
      "  return [1, 2, 3];\n"
      "}\n";
  NOT_IN_PRODUCT(FLAG_verbose_gc = true);
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, nullptr);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);

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
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, nullptr);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);

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
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, nullptr);
  Dart_EnterScope();
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);

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
  Dart_Handle h_lib = TestCase::LoadTestScript(kScriptChars, nullptr);
  auto isolate_group = IsolateGroup::Current();
  ClassTable* class_table = isolate_group->class_table();
  {
    // GC before main so allocations during the tests don't cause unexpected GC.
    TransitionNativeToVM transition(thread);
    GCTestHelper::CollectAllGarbage();
  }
  Dart_EnterScope();
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, nullptr);
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
    FinalizablePersistentHandle::New(isolate_group, neu, nullptr, NoopFinalizer,
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
      : msg_(CStringUniquePtr(nullptr)), owner_(owner) {}

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
  CStringUniquePtr msg_;
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
    FinalizablePersistentHandle::New(isolate_group, neu, nullptr, NoopFinalizer,
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

// See https://github.com/dart-lang/sdk/issues/54495
ISOLATE_UNIT_TEST_CASE(ArrayTruncationPadding) {
  GrowableObjectArray& retain =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  Array& array = Array::Handle();

  for (intptr_t big = 0; big < 256; big++) {
    for (intptr_t small = 0; small < big; small++) {
      array = Array::New(big);

      // Fill the alignment gap with invalid pointers.
      uword addr = UntaggedObject::ToAddr(array.ptr());
      for (intptr_t offset = Array::UnroundedSize(big);
           offset < Array::InstanceSize(big); offset += sizeof(uword)) {
        *reinterpret_cast<uword*>(addr + offset) = kHeapObjectTag;
      }

      array.Truncate(small);
      retain.Add(array);
    }
  }

  IsolateGroup::Current()->heap()->Verify("truncation padding");
}

class ConcurrentForceGrowthScopeTask : public ThreadPool::Task {
 public:
  ConcurrentForceGrowthScopeTask(IsolateGroup* isolate_group,
                                 Monitor* monitor,
                                 intptr_t* done_count)
      : isolate_group_(isolate_group),
        monitor_(monitor),
        done_count_(done_count) {}

  virtual void Run() {
    const bool kBypassSafepoint = false;
    Thread::EnterIsolateGroupAsHelper(isolate_group_, Thread::kUnknownTask,
                                      kBypassSafepoint);
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
    Thread::ExitIsolateGroupAsHelper(kBypassSafepoint);
    // Notify the main thread that this thread has exited.
    {
      MonitorLocker ml(monitor_);
      *done_count_ += 1;
      ml.Notify();
    }
  }

 private:
  IsolateGroup* isolate_group_;
  Monitor* monitor_;
  intptr_t* done_count_;
};

ISOLATE_UNIT_TEST_CASE(ConcurrentForceGrowthScope) {
  intptr_t task_count = 8;
  Monitor monitor;
  intptr_t done_count = 0;

  for (intptr_t i = 0; i < task_count; i++) {
    Dart::thread_pool()->Run<ConcurrentForceGrowthScopeTask>(
        thread->isolate_group(), &monitor, &done_count);
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

enum Generation {
  kNew,
  kOld,
  kImm,
};

static void WeakProperty_Generations(Generation property_space,
                                     Generation key_space,
                                     Generation value_space,
                                     bool cleared_after_minor,
                                     bool cleared_after_major,
                                     bool cleared_after_all) {
  WeakProperty& property = WeakProperty::Handle();
  GCTestHelper::CollectAllGarbage();
  {
    HANDLESCOPE(Thread::Current());
    switch (property_space) {
      case kNew:
        property = WeakProperty::New(Heap::kNew);
        break;
      case kOld:
        property = WeakProperty::New(Heap::kOld);
        break;
      case kImm:
        UNREACHABLE();
    }

    Object& key = Object::Handle();
    switch (key_space) {
      case kNew:
        key = OneByteString::New("key", Heap::kNew);
        break;
      case kOld:
        key = OneByteString::New("key", Heap::kOld);
        break;
      case kImm:
        key = Smi::New(42);
        break;
    }

    Object& value = Object::Handle();
    switch (value_space) {
      case kNew:
        value = OneByteString::New("value", Heap::kNew);
        break;
      case kOld:
        value = OneByteString::New("value", Heap::kOld);
        break;
      case kImm:
        value = Smi::New(84);
        break;
    }

    property.set_key(key);
    property.set_value(value);
  }

  OS::PrintErr("%d %d %d\n", property_space, key_space, value_space);

  GCTestHelper::CollectNewSpace();
  if (cleared_after_minor) {
    EXPECT(property.key() == Object::null());
    EXPECT(property.value() == Object::null());
  } else {
    EXPECT(property.key() != Object::null());
    EXPECT(property.value() != Object::null());
  }

  GCTestHelper::CollectOldSpace();
  if (cleared_after_major) {
    EXPECT(property.key() == Object::null());
    EXPECT(property.value() == Object::null());
  } else {
    EXPECT(property.key() != Object::null());
    EXPECT(property.value() != Object::null());
  }

  GCTestHelper::CollectAllGarbage();
  if (cleared_after_all) {
    EXPECT(property.key() == Object::null());
    EXPECT(property.value() == Object::null());
  } else {
    EXPECT(property.key() != Object::null());
    EXPECT(property.value() != Object::null());
  }
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_Generations) {
  FLAG_early_tenuring_threshold = 100;  // I.e., off.

  WeakProperty_Generations(kNew, kNew, kNew, true, true, true);
  WeakProperty_Generations(kNew, kNew, kOld, true, true, true);
  WeakProperty_Generations(kNew, kNew, kImm, true, true, true);
  WeakProperty_Generations(kNew, kOld, kNew, false, true, true);
  WeakProperty_Generations(kNew, kOld, kOld, false, true, true);
  WeakProperty_Generations(kNew, kOld, kImm, false, true, true);
  WeakProperty_Generations(kNew, kImm, kNew, false, false, false);
  WeakProperty_Generations(kNew, kImm, kOld, false, false, false);
  WeakProperty_Generations(kNew, kImm, kImm, false, false, false);
  WeakProperty_Generations(kOld, kNew, kNew, true, true, true);
  WeakProperty_Generations(kOld, kNew, kOld, true, true, true);
  WeakProperty_Generations(kOld, kNew, kImm, true, true, true);
  WeakProperty_Generations(kOld, kOld, kNew, false, true, true);
  WeakProperty_Generations(kOld, kOld, kOld, false, true, true);
  WeakProperty_Generations(kOld, kOld, kImm, false, true, true);
  WeakProperty_Generations(kOld, kImm, kNew, false, false, false);
  WeakProperty_Generations(kOld, kImm, kOld, false, false, false);
  WeakProperty_Generations(kOld, kImm, kImm, false, false, false);
}

static void WeakReference_Generations(Generation reference_space,
                                      Generation target_space,
                                      bool cleared_after_minor,
                                      bool cleared_after_major,
                                      bool cleared_after_all) {
  WeakReference& reference = WeakReference::Handle();
  GCTestHelper::CollectAllGarbage();
  {
    HANDLESCOPE(Thread::Current());
    switch (reference_space) {
      case kNew:
        reference = WeakReference::New(Heap::kNew);
        break;
      case kOld:
        reference = WeakReference::New(Heap::kOld);
        break;
      case kImm:
        UNREACHABLE();
    }

    Object& target = Object::Handle();
    switch (target_space) {
      case kNew:
        target = OneByteString::New("target", Heap::kNew);
        break;
      case kOld:
        target = OneByteString::New("target", Heap::kOld);
        break;
      case kImm:
        target = Smi::New(42);
        break;
    }

    reference.set_target(target);
  }

  OS::PrintErr("%d %d\n", reference_space, target_space);

  GCTestHelper::CollectNewSpace();
  if (cleared_after_minor) {
    EXPECT(reference.target() == Object::null());
  } else {
    EXPECT(reference.target() != Object::null());
  }

  GCTestHelper::CollectOldSpace();
  if (cleared_after_major) {
    EXPECT(reference.target() == Object::null());
  } else {
    EXPECT(reference.target() != Object::null());
  }

  GCTestHelper::CollectAllGarbage();
  if (cleared_after_all) {
    EXPECT(reference.target() == Object::null());
  } else {
    EXPECT(reference.target() != Object::null());
  }
}

ISOLATE_UNIT_TEST_CASE(WeakReference_Generations) {
  FLAG_early_tenuring_threshold = 100;  // I.e., off.

  WeakReference_Generations(kNew, kNew, true, true, true);
  WeakReference_Generations(kNew, kOld, false, true, true);
  WeakReference_Generations(kNew, kImm, false, false, false);
  WeakReference_Generations(kOld, kNew, true, true, true);
  WeakReference_Generations(kOld, kOld, false, true, true);
  WeakReference_Generations(kOld, kImm, false, false, false);
}

static void WeakArray_Generations(intptr_t length,
                                  Generation array_space,
                                  Generation element_space,
                                  bool cleared_after_minor,
                                  bool cleared_after_major,
                                  bool cleared_after_all) {
  WeakArray& array = WeakArray::Handle();
  GCTestHelper::CollectAllGarbage();
  {
    HANDLESCOPE(Thread::Current());
    switch (array_space) {
      case kNew:
        array = WeakArray::New(length, Heap::kNew);
        break;
      case kOld:
        array = WeakArray::New(length, Heap::kOld);
        break;
      case kImm:
        UNREACHABLE();
    }

    Object& element = Object::Handle();
    switch (element_space) {
      case kNew:
        element = OneByteString::New("element", Heap::kNew);
        break;
      case kOld:
        element = OneByteString::New("element", Heap::kOld);
        break;
      case kImm:
        element = Smi::New(42);
        break;
    }

    array.SetAt(length - 1, element);
  }

  OS::PrintErr("%d %d\n", array_space, element_space);

  GCTestHelper::CollectNewSpace();
  if (cleared_after_minor) {
    EXPECT(array.At(length - 1) == Object::null());
  } else {
    EXPECT(array.At(length - 1) != Object::null());
  }

  GCTestHelper::CollectOldSpace();
  if (cleared_after_major) {
    EXPECT(array.At(length - 1) == Object::null());
  } else {
    EXPECT(array.At(length - 1) != Object::null());
  }

  GCTestHelper::CollectAllGarbage();
  if (cleared_after_all) {
    EXPECT(array.At(length - 1) == Object::null());
  } else {
    EXPECT(array.At(length - 1) != Object::null());
  }
}

ISOLATE_UNIT_TEST_CASE(WeakArray_Generations) {
  FLAG_early_tenuring_threshold = 100;  // I.e., off.

  intptr_t length = 1;
  WeakArray_Generations(length, kNew, kNew, true, true, true);
  WeakArray_Generations(length, kNew, kOld, false, true, true);
  WeakArray_Generations(length, kNew, kImm, false, false, false);
  WeakArray_Generations(length, kOld, kNew, true, true, true);
  WeakArray_Generations(length, kOld, kOld, false, true, true);
  WeakArray_Generations(length, kOld, kImm, false, false, false);
}

ISOLATE_UNIT_TEST_CASE(WeakArray_Large_Generations) {
  FLAG_early_tenuring_threshold = 100;  // I.e., off.

  intptr_t length = kNewAllocatableSize / kCompressedWordSize;
  WeakArray_Generations(length, kNew, kNew, true, true, true);
  WeakArray_Generations(length, kNew, kOld, false, true, true);
  WeakArray_Generations(length, kNew, kImm, false, false, false);
  WeakArray_Generations(length, kOld, kNew, true, true, true);
  WeakArray_Generations(length, kOld, kOld, false, true, true);
  WeakArray_Generations(length, kOld, kImm, false, false, false);
}

static void FinalizerEntry_Generations(Generation entry_space,
                                       Generation value_space,
                                       bool cleared_after_minor,
                                       bool cleared_after_major,
                                       bool cleared_after_all) {
  FinalizerEntry& entry = FinalizerEntry::Handle();
  GCTestHelper::CollectAllGarbage();
  {
    HANDLESCOPE(Thread::Current());
    switch (entry_space) {
      case kNew:
        entry = FinalizerEntry::New(FinalizerBase::Handle(), Heap::kNew);
        break;
      case kOld:
        entry = FinalizerEntry::New(FinalizerBase::Handle(), Heap::kOld);
        break;
      case kImm:
        UNREACHABLE();
    }

    Object& value = Object::Handle();
    switch (value_space) {
      case kNew:
        value = OneByteString::New("value", Heap::kNew);
        break;
      case kOld:
        value = OneByteString::New("value", Heap::kOld);
        break;
      case kImm:
        value = Smi::New(42);
        break;
    }

    entry.set_value(value);
  }

  OS::PrintErr("%d %d\n", entry_space, value_space);

  GCTestHelper::CollectNewSpace();
  if (cleared_after_minor) {
    EXPECT(entry.value() == Object::null());
  } else {
    EXPECT(entry.value() != Object::null());
  }

  GCTestHelper::CollectOldSpace();
  if (cleared_after_major) {
    EXPECT(entry.value() == Object::null());
  } else {
    EXPECT(entry.value() != Object::null());
  }

  GCTestHelper::CollectAllGarbage();
  if (cleared_after_all) {
    EXPECT(entry.value() == Object::null());
  } else {
    EXPECT(entry.value() != Object::null());
  }
}

ISOLATE_UNIT_TEST_CASE(FinalizerEntry_Generations) {
  FLAG_early_tenuring_threshold = 100;  // I.e., off.

  FinalizerEntry_Generations(kNew, kNew, true, true, true);
  FinalizerEntry_Generations(kNew, kOld, false, true, true);
  FinalizerEntry_Generations(kNew, kImm, false, false, false);
  FinalizerEntry_Generations(kOld, kNew, true, true, true);
  FinalizerEntry_Generations(kOld, kOld, false, true, true);
  FinalizerEntry_Generations(kOld, kImm, false, false, false);
}

#if !defined(PRODUCT) && defined(DART_HOST_OS_LINUX)
ISOLATE_UNIT_TEST_CASE(SweepDontNeed) {
  auto gc_with_fragmentation = [&] {
    HANDLESCOPE(thread);

    EXPECT(IsAllocatableViaFreeLists(Array::InstanceSize(128)));
    const intptr_t num_elements = 100 * MB / Array::InstanceSize(128);
    Array& list = Array::Handle();
    {
      HANDLESCOPE(thread);
      list = Array::New(num_elements);
      Array& element = Array::Handle();
      for (intptr_t i = 0; i < num_elements; i++) {
        element = Array::New(128);
        list.SetAt(i, element);
      }
    }

    GCTestHelper::CollectAllGarbage();
    GCTestHelper::WaitForGCTasks();
    Page::ClearCache();
    const intptr_t before = Service::CurrentRSS();
    EXPECT(before > 0);  // Or RSS hook is not installed.

    for (intptr_t i = 0; i < num_elements; i++) {
      // Let there be one survivor every 150 KB. Bigger than the largest virtual
      // memory page size (64 KB on ARM64 Linux).
      intptr_t m = 150 * KB / Array::InstanceSize(128);
      if ((i % m) != 0) {
        list.SetAt(i, Object::null_object());
      }
    }

    GCTestHelper::CollectAllGarbage();
    GCTestHelper::WaitForGCTasks();
    Page::ClearCache();
    const intptr_t after = Service::CurrentRSS();
    EXPECT(after > 0);  // Or RSS hook is not installed.

    const intptr_t delta = after - before;
    OS::PrintErr("%" Pd " -> %" Pd " (%" Pd ")\n", before, after, delta);
    return delta;
  };

  FLAG_dontneed_on_sweep = false;
  const intptr_t delta_normal = gc_with_fragmentation();
  // EXPECT(delta_normal == 0); Roughly, but there may be noise.

  FLAG_dontneed_on_sweep = true;
  const intptr_t delta_dontneed = gc_with_fragmentation();
  // Free at least half. Various with noise and virtual memory page size.
  EXPECT(delta_dontneed < -50 * MB);

  EXPECT(delta_dontneed < delta_normal);  // More negative.
}
#endif  // !defined(PRODUCT) && !defined(DART_HOST_OS_LINUX)

static void TestCardRememberedArray(bool immutable, bool compact) {
  constexpr intptr_t kNumElements = kNewAllocatableSize / kCompressedWordSize;
  Array& array = Array::Handle(Array::New(kNumElements));
  EXPECT(array.ptr()->untag()->IsCardRemembered());
  EXPECT(Page::Of(array.ptr())->is_large());

  {
    HANDLESCOPE(Thread::Current());
    Object& element = Object::Handle();
    for (intptr_t i = 0; i < kNumElements; i++) {
      element = Double::New(i, Heap::kNew);  // Garbage
      element = Double::New(i, Heap::kNew);
      array.SetAt(i, element);
    }
    if (immutable) {
      array.MakeImmutable();
    }
  }

  GCTestHelper::CollectAllGarbage(compact);
  GCTestHelper::WaitForGCTasks();

  {
    HANDLESCOPE(Thread::Current());
    Object& element = Object::Handle();
    for (intptr_t i = 0; i < kNumElements; i++) {
      element = array.At(i);
      EXPECT(element.IsDouble());
      EXPECT(Double::Cast(element).value() == i);
    }
  }
}

static void TestCardRememberedWeakArray(bool compact) {
  constexpr intptr_t kNumElements = kNewAllocatableSize / kCompressedWordSize;
  WeakArray& weak = WeakArray::Handle(WeakArray::New(kNumElements));
  EXPECT(!weak.ptr()->untag()->IsCardRemembered());
  EXPECT(Page::Of(weak.ptr())->is_large());
  Array& strong = Array::Handle(Array::New(kNumElements));

  {
    HANDLESCOPE(Thread::Current());
    Object& element = Object::Handle();
    for (intptr_t i = 0; i < kNumElements; i++) {
      element = Double::New(i, Heap::kNew);  // Garbage
      element = Double::New(i, Heap::kNew);
      weak.SetAt(i, element);
      if ((i % 3) == 0) {
        strong.SetAt(i, element);
      }
    }
  }

  GCTestHelper::CollectAllGarbage(compact);
  GCTestHelper::WaitForGCTasks();

  {
    HANDLESCOPE(Thread::Current());
    Object& element = Object::Handle();
    for (intptr_t i = 0; i < kNumElements; i++) {
      element = weak.At(i);
      if ((i % 3) == 0) {
        EXPECT(element.IsDouble());
        EXPECT(Double::Cast(element).value() == i);
      } else {
        EXPECT(element.IsNull());
      }
    }
  }
}

ISOLATE_UNIT_TEST_CASE(CardRememberedArray) {
  TestCardRememberedArray(true, true);
  TestCardRememberedArray(true, false);
}

ISOLATE_UNIT_TEST_CASE(CardRememberedImmutableArray) {
  TestCardRememberedArray(false, true);
  TestCardRememberedArray(false, false);
}

ISOLATE_UNIT_TEST_CASE(CardRememberedWeakArray) {
  TestCardRememberedWeakArray(true);
  TestCardRememberedWeakArray(false);
}

struct ExistingObject;

static constexpr uword kMarkBit = 1;
static constexpr uword kCidBit = 2;
static constexpr size_t kNewObjectSlotCount = 3;
struct NewObject {
  std::atomic<uword> header;
  std::atomic<ExistingObject*> slots[kNewObjectSlotCount];
};

static constexpr size_t kExistingObjectSlotCount = 64 * KB;
struct ExistingObject {
  std::atomic<NewObject*> slots[kExistingObjectSlotCount];
};

struct NewPage {
  std::atomic<uword> top;
  std::atomic<uword> end;
  NewObject objects[kExistingObjectSlotCount];
};
static constexpr size_t kNewPageAlignment =
    Utils::RoundUpToPowerOfTwo(sizeof(NewPage));
static constexpr size_t kNewPageMask = kNewPageAlignment - 1;

typedef void (*MutatorFunction)(NewPage*, ExistingObject*);
typedef void (*MarkerFunction)(ExistingObject*);

struct MarkerArguments {
  ExistingObject* existing_object;
  MarkerFunction function;
  Monitor* monitor;
  ThreadJoinId join_id;
};

static void MutatorMarkerRace(MutatorFunction mutator, MarkerFunction marker) {
  VirtualMemory* existing_vm = VirtualMemory::Allocate(
      Utils::RoundUp(sizeof(ExistingObject), VirtualMemory::PageSize()), false,
      false, "dart-heap");
  ExistingObject* existing_object =
      reinterpret_cast<ExistingObject*>(existing_vm->address());

  Monitor monitor;
  MarkerArguments arguments;
  arguments.existing_object = existing_object;
  arguments.function = marker;
  arguments.monitor = &monitor;

  for (intptr_t k = 0; k < 1000; k++) {
    for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
      existing_object->slots[i] = nullptr;
    }
    arguments.join_id = OSThread::kInvalidThreadJoinId;

    OSThread::Start(
        "FakeMarker",
        [](uword parameter) {
          MarkerArguments* arguments =
              reinterpret_cast<MarkerArguments*>(parameter);

          arguments->function(arguments->existing_object);

          MonitorLocker ml(arguments->monitor);
          arguments->join_id =
              OSThread::GetCurrentThreadJoinId(OSThread::Current());
          ml.Notify();
        },
        reinterpret_cast<uword>(&arguments));

    VirtualMemory* new_vm = VirtualMemory::AllocateAligned(
        kNewPageAlignment, kNewPageAlignment, false, false, "dart-heap");
    NewPage* new_page = reinterpret_cast<NewPage*>(new_vm->address());
    new_page->end = new_vm->end();
    new_page->top.store(reinterpret_cast<uword>(new_page->objects),
                        std::memory_order_release);

    mutator(new_page, existing_object);

    for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
      NewObject* new_object = &new_page->objects[i];
      uword header = new_object->header.load(std::memory_order_relaxed);
      EXPECT_EQ(kCidBit, header & kCidBit);
    }

    {
      MonitorLocker ml(&monitor);
      while (arguments.join_id == OSThread::kInvalidThreadJoinId) {
        ml.Wait();
      }
    }
    OSThread::Join(arguments.join_id);

    for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
      NewObject* new_object = &new_page->objects[i];
      uword header = new_object->header.load(std::memory_order_relaxed);
      EXPECT_EQ(kCidBit | kMarkBit, header);
    }

    delete new_vm;
  }

  delete existing_vm;
}

// Skip tests with races on weak-memory model architecture to avoid meta-flaking
// the test status.
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)

// This has a race: the initializing store of the header and the publishing
// store of the new object's pointers might get reordered as seen by the marker.
// Seen in practice on an M1.
VM_UNIT_TEST_CASE(MutatorMarkerRace_Relaxed) {
  MutatorMarkerRace(
      [](NewPage* new_page, ExistingObject* existing_object) {
        // Mutator:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* new_object = &new_page->objects[i];
          new_object->header.store(2u, std::memory_order_relaxed);
          for (size_t j = 0; j < kNewObjectSlotCount; j++) {
            new_object->slots[j].store(existing_object,
                                       std::memory_order_relaxed);
          }
          existing_object->slots[i].store(new_object,
                                          std::memory_order_relaxed);
        }
      },
      [](ExistingObject* existing_object) {
        // Marker:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* target;
          do {
            target = existing_object->slots[i].load(std::memory_order_relaxed);
          } while (target == nullptr);

          uword header = FetchOrRelaxedIgnoreRace(&target->header, kMarkBit);
          EXPECT_EQ(kCidBit, header);
        }
      });
}

// This has a race: the release orders stores before the header initialization
// with the header initialization, but still lets the header initialization and
// publishing store get reordered.
// Seen in practice on Windows ARM64 Snapdragon.
VM_UNIT_TEST_CASE(MutatorMarkerRace_ReleaseHeader) {
  MutatorMarkerRace(
      [](NewPage* new_page, ExistingObject* existing_object) {
        // Mutator:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* new_object = &new_page->objects[i];
          new_object->header.store(2u, std::memory_order_release);
          for (size_t j = 0; j < kNewObjectSlotCount; j++) {
            new_object->slots[j].store(existing_object,
                                       std::memory_order_relaxed);
          }
          existing_object->slots[i].store(new_object,
                                          std::memory_order_relaxed);
        }
      },
      [](ExistingObject* existing_object) {
        // Marker:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* target;
          do {
            target = existing_object->slots[i].load(std::memory_order_relaxed);
          } while (target == nullptr);

          uword header = FetchOrRelaxedIgnoreRace(&target->header, kMarkBit);
          EXPECT_EQ(kCidBit, header);
        }
      });
}

#endif  // defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)

VM_UNIT_TEST_CASE(MutatorMarkerRace_ReleasePublish) {
  MutatorMarkerRace(
      [](NewPage* new_page, ExistingObject* existing_object) {
        // Mutator:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* new_object = &new_page->objects[i];
          new_object->header.store(2u, std::memory_order_relaxed);
          for (size_t j = 0; j < kNewObjectSlotCount; j++) {
            new_object->slots[j].store(existing_object,
                                       std::memory_order_relaxed);
          }
          existing_object->slots[i].store(new_object,
                                          std::memory_order_release);
        }
      },
      [](ExistingObject* existing_object) {
        // Marker:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* target;
          do {
            target = existing_object->slots[i].load(std::memory_order_relaxed);
          } while (target == nullptr);

          uword header = FetchOrRelaxedIgnoreRace(&target->header, kMarkBit);
          EXPECT_EQ(kCidBit, header);
        }
      });
}

// TSAN doesn't support std::atomic_thread_fence.
#if !defined(USING_THREAD_SANITIZER)
VM_UNIT_TEST_CASE(MutatorMarkerRace_Fence) {
  MutatorMarkerRace(
      [](NewPage* new_page, ExistingObject* existing_object) {
        // Mutator:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* new_object = &new_page->objects[i];
          new_object->header.store(2u, std::memory_order_relaxed);
          std::atomic_thread_fence(std::memory_order_release);
          for (size_t j = 0; j < kNewObjectSlotCount; j++) {
            new_object->slots[j].store(existing_object,
                                       std::memory_order_relaxed);
          }
          existing_object->slots[i].store(new_object,
                                          std::memory_order_relaxed);
        }
      },
      [](ExistingObject* existing_object) {
        // Marker:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* target;
          do {
            target = existing_object->slots[i].load(std::memory_order_relaxed);
          } while (target == nullptr);

          uword header = FetchOrRelaxedIgnoreRace(&target->header, kMarkBit);
          EXPECT_EQ(kCidBit, header);
        }
      });
}
#endif  // !defined(USING_THREAD_SANITIZER)

VM_UNIT_TEST_CASE(MutatorMarkerRace_DetectPreviousValue) {
  MutatorMarkerRace(
      [](NewPage* new_page, ExistingObject* existing_object) {
        // Mutator:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* new_object = &new_page->objects[i];
          new_object->header.store(2u, std::memory_order_relaxed);
          for (size_t j = 0; j < kNewObjectSlotCount; j++) {
            new_object->slots[j].store(existing_object,
                                       std::memory_order_relaxed);
          }
          existing_object->slots[i].store(new_object,
                                          std::memory_order_relaxed);
        }
      },
      [](ExistingObject* existing_object) {
        // Marker:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* target;
          do {
            target = existing_object->slots[i].load(std::memory_order_relaxed);
          } while (target == nullptr);

          while (LoadRelaxedIgnoreRace(&target->header) == 0) {
            // Wait.
          }

          uword header = FetchOrRelaxedIgnoreRace(&target->header, kMarkBit);
          EXPECT_EQ(kCidBit, header);
        }
      });
}

VM_UNIT_TEST_CASE(MutatorMarkerRace_DetectInTLAB) {
  MutatorMarkerRace(
      [](NewPage* new_page, ExistingObject* existing_object) {
        // Mutator:
        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* new_object = &new_page->objects[i];
          new_object->header.store(2u, std::memory_order_relaxed);
          for (size_t j = 0; j < kNewObjectSlotCount; j++) {
            new_object->slots[j].store(existing_object,
                                       std::memory_order_relaxed);
          }
          existing_object->slots[i].store(new_object,
                                          std::memory_order_relaxed);

          if ((i % 8) == 0) {
            new_page->top.store(
                reinterpret_cast<uword>(&new_page->objects[i + 1]),
                std::memory_order_release);
          }
        }

        new_page->top.store(
            reinterpret_cast<uword>(
                &new_page->objects[kExistingObjectSlotCount + 1]),
            std::memory_order_release);
      },
      [](ExistingObject* existing_object) {
        // Marker:
        MallocGrowableArray<NewObject*> deferred(kExistingObjectSlotCount);

        for (size_t i = 0; i < kExistingObjectSlotCount; i++) {
          NewObject* target;
          do {
            target = existing_object->slots[i].load(std::memory_order_relaxed);
          } while (target == nullptr);

          uword addr = reinterpret_cast<uword>(target);
          NewPage* new_page = reinterpret_cast<NewPage*>(addr & ~kNewPageMask);
          if (addr < new_page->top.load(std::memory_order_acquire)) {
            uword header =
                target->header.fetch_or(kMarkBit, std::memory_order_relaxed);
            EXPECT_EQ(kCidBit, header);
          } else {
            deferred.Add(target);
          }
        }

        for (intptr_t i = 0; i < deferred.length(); i++) {
          NewObject* target = deferred[i];

          uword addr = reinterpret_cast<uword>(target);
          NewPage* new_page = reinterpret_cast<NewPage*>(addr & ~kNewPageMask);
          while (addr >= new_page->top.load(std::memory_order_acquire)) {
            // Wait. Would be a STW phase in the full thing.
          }
          uword header =
              target->header.fetch_or(kMarkBit, std::memory_order_relaxed);
          EXPECT_EQ(kCidBit, header);
        }
      });
}

}  // namespace dart
