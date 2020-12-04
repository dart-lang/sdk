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
  return cls.raw();
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
  Isolate* isolate = Isolate::Current();
  ClassTable* class_table = isolate->class_table();
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
      isolate->group()->VisitWeakPersistentHandles(&visitor);
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
      isolate->group()->VisitWeakPersistentHandles(&visitor);
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
      isolate->group()->VisitWeakPersistentHandles(&visitor);
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
      isolate->group()->VisitWeakPersistentHandles(&visitor);
      EXPECT_EQ(0, visitor.new_count_[cid]);
      EXPECT_EQ(1, visitor.old_count_[cid]);
    }

    GCTestHelper::CollectOldSpace();

    {
      // Verify postconditions:
      CountObjectsVisitor visitor(thread, class_table->NumCids());
      HeapIterationScope iter(thread);
      iter.IterateObjects(&visitor);
      isolate->group()->VisitWeakPersistentHandles(&visitor);
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
      isolate->group()->VisitWeakPersistentHandles(&visitor);
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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  Heap::Space spaces[2] = {Heap::kOld, Heap::kNew};
  for (size_t space = 0; space < ARRAY_SIZE(spaces); ++space) {
    const String& obj = String::Handle(String::New("x", spaces[space]));
    {
      HeapIterationScope iteration(thread);
      NoSafepointScope no_safepoint;
      FindOnly find_only(obj.raw());
      EXPECT(obj.raw() == heap->FindObject(&find_only));
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

  Heap* heap = Thread::Current()->isolate()->heap();
  EXPECT(heap->Contains(ObjectLayout::ToAddr(obj.raw())));
  heap->WriteProtect(true);
  EXPECT(heap->Contains(ObjectLayout::ToAddr(obj.raw())));
  heap->WriteProtect(false);
  EXPECT(heap->Contains(ObjectLayout::ToAddr(obj.raw())));
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_DeadOldToNew) {
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  heap->CollectAllGarbage();
  intptr_t size_before = kWordSize * (heap->new_space()->ExternalInWords() +
                                      heap->old_space()->ExternalInWords());

  Array& old = Array::Handle(Array::New(100, Heap::kOld));
  Array& neu = Array::Handle();
  for (intptr_t i = 0; i < 100; i++) {
    neu = Array::New(1, Heap::kNew);
    FinalizablePersistentHandle::New(isolate, neu, NULL, NoopFinalizer, 1 * MB,
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
    thread->heap()->CollectNewSpaceGarbage(thread, Heap::kDebugging);
  }
  static void MarkSweep(Thread* thread) {
    thread->heap()->CollectOldSpaceGarbage(thread, Heap::kMarkSweep,
                                           Heap::kDebugging);
    thread->heap()->WaitForMarkerTasks(thread);
    thread->heap()->WaitForSweeperTasks(thread);
  }
};

class MergeIsolatesHeapsHandler : public MessageHandler {
 public:
  explicit MergeIsolatesHeapsHandler(Isolate* owner)
      : msg_(Utils::CreateCStringUniquePtr(nullptr)), owner_(owner) {}

  const char* name() const { return "merge-isolates-heaps-handler"; }

  ~MergeIsolatesHeapsHandler() { PortMap::ClosePorts(this); }

  MessageStatus HandleMessage(std::unique_ptr<Message> message) {
    // Parse the message.
    Object& response_obj = Object::Handle();
    if (message->IsRaw()) {
      response_obj = message->raw_obj();
    } else if (message->IsBequest()) {
      Bequest* bequest = message->bequest();
      PersistentHandle* handle = bequest->handle();
      // Object in the receiving isolate's heap.
      EXPECT(isolate()->heap()->Contains(ObjectLayout::ToAddr(handle->raw())));
      response_obj = handle->raw();
      isolate()->group()->api_state()->FreePersistentHandle(handle);
    } else {
      Thread* thread = Thread::Current();
      MessageSnapshotReader reader(message.get(), thread);
      response_obj = reader.ReadObject();
    }
    if (response_obj.IsString()) {
      String& response = String::Handle();
      response ^= response_obj.raw();
      msg_.reset(Utils::StrDup(response.ToCString()));
    } else {
      ASSERT(response_obj.IsArray());
      Array& response_array = Array::Handle();
      response_array ^= response_obj.raw();
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
  // This test uses features from isolate groups
  FLAG_enable_isolate_groups = true;

  const char* TEST_MESSAGE = "hello, world";
  Dart_Isolate parent = TestCase::CreateTestIsolate("parent");
  EXPECT_EQ(parent, Dart_CurrentIsolate());
  {
    MergeIsolatesHeapsHandler handler(Isolate::Current());
    Dart_Port port_id = PortMap::CreatePort(&handler);
    EXPECT_EQ(PortMap::GetIsolate(port_id), Isolate::Current());
    Dart_ExitIsolate();

    Dart_Isolate worker = TestCase::CreateTestIsolateInGroup("worker", parent);
    EXPECT_EQ(worker, Dart_CurrentIsolate());
    {
      Thread* thread = Thread::Current();
      TransitionNativeToVM transition(thread);
      StackZone zone(thread);
      HANDLESCOPE(thread);

      String& string = String::Handle(String::New(TEST_MESSAGE));
      PersistentHandle* handle =
          Isolate::Current()->group()->api_state()->AllocatePersistentHandle();
      handle->set_raw(string.raw());

      reinterpret_cast<Isolate*>(worker)->bequeath(
          std::unique_ptr<Bequest>(new Bequest(handle, port_id)));
    }
  }
  Dart_ShutdownIsolate();
  Dart_EnterIsolate(parent);
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(ReceivesSendAndExitMessage) {
  // This test uses features from isolate groups
  FLAG_enable_isolate_groups = true;

  const char* TEST_MESSAGE = "hello, world";
  Dart_Isolate parent = TestCase::CreateTestIsolate("parent");
  EXPECT_EQ(parent, Dart_CurrentIsolate());
  MergeIsolatesHeapsHandler handler(Isolate::Current());
  Dart_Port port_id = PortMap::CreatePort(&handler);
  EXPECT_EQ(PortMap::GetIsolate(port_id), Isolate::Current());
  Dart_ExitIsolate();

  Dart_Isolate worker = TestCase::CreateTestIsolateInGroup("worker", parent);
  EXPECT_EQ(worker, Dart_CurrentIsolate());
  {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    HANDLESCOPE(thread);

    String& string = String::Handle(String::New(TEST_MESSAGE));

    PersistentHandle* handle =
        Isolate::Current()->group()->api_state()->AllocatePersistentHandle();
    handle->set_raw(string.raw());

    reinterpret_cast<Isolate*>(worker)->bequeath(
        std::unique_ptr<Bequest>(new Bequest(handle, port_id)));
  }

  Dart_ShutdownIsolate();
  Dart_EnterIsolate(parent);
  {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    HANDLESCOPE(thread);

    EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  }
  EXPECT_STREQ(handler.msg(), TEST_MESSAGE);
  Dart_ShutdownIsolate();
}

ISOLATE_UNIT_TEST_CASE(ExternalAllocationStats) {
  Isolate* isolate = thread->isolate();
  Heap* heap = thread->heap();

  Array& old = Array::Handle(Array::New(100, Heap::kOld));
  Array& neu = Array::Handle();
  for (intptr_t i = 0; i < 100; i++) {
    neu = Array::New(1, Heap::kNew);
    FinalizablePersistentHandle::New(isolate, neu, NULL, NoopFinalizer, 1 * MB,
                                     /*auto_delete=*/true);
    old.SetAt(i, neu);

    if ((i % 4) == 0) {
      HeapTestHelper::MarkSweep(thread);
    } else {
      HeapTestHelper::Scavenge(thread);
    }

    CountObjectsVisitor visitor(thread, isolate->class_table()->NumCids());
    HeapIterationScope iter(thread);
    iter.IterateObjects(&visitor);
    isolate->group()->VisitWeakPersistentHandles(&visitor);
    EXPECT_LE(visitor.old_external_size_[kArrayCid],
              heap->old_space()->ExternalInWords() * kWordSize);
    EXPECT_LE(visitor.new_external_size_[kArrayCid],
              heap->new_space()->ExternalInWords() * kWordSize);
  }
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

}  // namespace dart
