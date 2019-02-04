// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "platform/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/globals.h"
#include "vm/heap/become.h"
#include "vm/heap/heap.h"
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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  heap->CollectGarbage(Heap::kOld);
}

#if !defined(PRODUCT)
TEST_CASE(OldGC_Unsync) {
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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  heap->CollectGarbage(Heap::kOld);
}
#endif  // !defined(PRODUCT)

TEST_CASE(LargeSweep) {
  const char* kScriptChars =
      "main() {\n"
      "  return new List(8 * 1024 * 1024);\n"
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
    thread->heap()->CollectGarbage(Heap::kOld);
  }
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    thread->heap()->CollectGarbage(Heap::kOld);
  }
}

#ifndef PRODUCT
class ClassHeapStatsTestHelper {
 public:
  static ClassHeapStats* GetHeapStatsForCid(ClassTable* class_table,
                                            intptr_t cid) {
    return class_table->PreliminaryStatsAt(cid);
  }

  static void DumpClassHeapStats(ClassHeapStats* stats) {
    OS::PrintErr("%" Pd " ", stats->recent.new_count);
    OS::PrintErr("%" Pd " ", stats->post_gc.new_count);
    OS::PrintErr("%" Pd " ", stats->pre_gc.new_count);
    OS::PrintErr("\n");
  }
};

static RawClass* GetClass(const Library& lib, const char* name) {
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
  bool saved_concurrent_sweep_mode = FLAG_concurrent_sweep;
  FLAG_concurrent_sweep = false;
  Dart_Handle h_lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Isolate* isolate = Isolate::Current();
  ClassTable* class_table = isolate->class_table();
  Heap* heap = isolate->heap();
  Dart_EnterScope();
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  ClassHeapStats* class_stats;
  {
    TransitionNativeToVM transition(thread);
    Library& lib = Library::Handle();
    lib ^= Api::UnwrapHandle(h_lib);
    EXPECT(!lib.IsNull());
    const Class& cls = Class::Handle(GetClass(lib, "A"));
    ASSERT(!cls.IsNull());
    intptr_t cid = cls.id();
    class_stats =
        ClassHeapStatsTestHelper::GetHeapStatsForCid(class_table, cid);
    // Verify preconditions:
    EXPECT_EQ(0, class_stats->pre_gc.old_count);
    EXPECT_EQ(0, class_stats->post_gc.old_count);
    EXPECT_EQ(0, class_stats->recent.old_count);
    EXPECT_EQ(0, class_stats->pre_gc.new_count);
    EXPECT_EQ(0, class_stats->post_gc.new_count);
    // Class allocated twice since GC from new space.
    EXPECT_EQ(2, class_stats->recent.new_count);
    // Perform GC.
    heap->CollectGarbage(Heap::kNew);
    // Verify postconditions:
    EXPECT_EQ(0, class_stats->pre_gc.old_count);
    EXPECT_EQ(0, class_stats->post_gc.old_count);
    EXPECT_EQ(0, class_stats->recent.old_count);
    // Total allocations before GC.
    EXPECT_EQ(2, class_stats->pre_gc.new_count);
    // Only one survived.
    EXPECT_EQ(1, class_stats->post_gc.new_count);
    EXPECT_EQ(0, class_stats->recent.new_count);
    // Perform GC. The following is heavily dependent on the behaviour
    // of the GC: Retained instance of A will be promoted.
    heap->CollectGarbage(Heap::kNew);
    // Verify postconditions:
    EXPECT_EQ(0, class_stats->pre_gc.old_count);
    EXPECT_EQ(0, class_stats->post_gc.old_count);
    // One promoted instance.
    EXPECT_EQ(1, class_stats->promoted_count);
    // Promotion counted as an allocation from old space.
    EXPECT_EQ(1, class_stats->recent.old_count);
    // There was one instance allocated before GC.
    EXPECT_EQ(1, class_stats->pre_gc.new_count);
    // There are no instances allocated in new space after GC.
    EXPECT_EQ(0, class_stats->post_gc.new_count);
    // No new allocations.
    EXPECT_EQ(0, class_stats->recent.new_count);
    // Perform a GC on new space.
    heap->CollectGarbage(Heap::kNew);
    // There were no instances allocated before GC.
    EXPECT_EQ(0, class_stats->pre_gc.new_count);
    // There are no instances allocated in new space after GC.
    EXPECT_EQ(0, class_stats->post_gc.new_count);
    // No new allocations.
    EXPECT_EQ(0, class_stats->recent.new_count);
    // Nothing was promoted.
    EXPECT_EQ(0, class_stats->promoted_count);
    heap->CollectGarbage(Heap::kOld);
    // Verify postconditions:
    EXPECT_EQ(1, class_stats->pre_gc.old_count);
    EXPECT_EQ(1, class_stats->post_gc.old_count);
    EXPECT_EQ(0, class_stats->recent.old_count);
  }
  // Exit scope, freeing instance.
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    // Perform GC.
    heap->CollectGarbage(Heap::kOld);
    // Verify postconditions:
    EXPECT_EQ(1, class_stats->pre_gc.old_count);
    EXPECT_EQ(0, class_stats->post_gc.old_count);
    EXPECT_EQ(0, class_stats->recent.old_count);
    // Perform GC.
    heap->CollectGarbage(Heap::kOld);
    EXPECT_EQ(0, class_stats->pre_gc.old_count);
    EXPECT_EQ(0, class_stats->post_gc.old_count);
    EXPECT_EQ(0, class_stats->recent.old_count);
  }
  FLAG_concurrent_sweep = saved_concurrent_sweep_mode;
}

TEST_CASE(ArrayHeapStats) {
  const char* kScriptChars =
      "List f(int len) {\n"
      "  return new List(len);\n"
      "}\n"
      ""
      "main() {\n"
      "  return f(1234);\n"
      "}\n";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Isolate* isolate = Isolate::Current();
  ClassTable* class_table = isolate->class_table();
  intptr_t cid = kArrayCid;
  ClassHeapStats* class_stats =
      ClassHeapStatsTestHelper::GetHeapStatsForCid(class_table, cid);
  Dart_EnterScope();
  // Invoke 'main' twice, since initial compilation might trigger extra array
  // allocations.
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  intptr_t before = class_stats->recent.new_size;
  Dart_Handle result2 = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result2);
  EXPECT(!Dart_IsNull(result2));
  intptr_t after = class_stats->recent.new_size;
  const intptr_t expected_size = Array::InstanceSize(1234);
  // Invoking the method might involve some additional tiny array allocations,
  // so we allow slightly more than expected.
  static const intptr_t kTolerance = 10 * kWordSize;
  EXPECT_LE(expected_size, after - before);
  EXPECT_GT(expected_size + kTolerance, after - before);
  Dart_ExitScope();
}
#endif  // !PRODUCT

class FindOnly : public FindObjectVisitor {
 public:
  explicit FindOnly(RawObject* target) : target_(target) {
#if defined(DEBUG)
    EXPECT_GT(Thread::Current()->no_safepoint_scope_depth(), 0);
#endif
  }
  virtual ~FindOnly() {}

  virtual bool FindObject(RawObject* obj) const { return obj == target_; }

 private:
  RawObject* target_;
};

class FindNothing : public FindObjectVisitor {
 public:
  FindNothing() {}
  virtual ~FindNothing() {}
  virtual bool FindObject(RawObject* obj) const { return false; }
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
  Heap* heap = Thread::Current()->isolate()->heap();
  EXPECT(heap->Contains(RawObject::ToAddr(obj.raw())));
  heap->WriteProtect(true);
  EXPECT(heap->Contains(RawObject::ToAddr(obj.raw())));
  heap->WriteProtect(false);
  EXPECT(heap->Contains(RawObject::ToAddr(obj.raw())));
}

void TestBecomeForward(Heap::Space before_space, Heap::Space after_space) {
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

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

  heap->CollectAllGarbage();

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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  const String& new_element = String::Handle(String::New("new", Heap::kNew));
  const String& old_element = String::Handle(String::New("old", Heap::kOld));
  const Array& before_obj = Array::Handle(Array::New(1, Heap::kOld));
  const Array& after_obj = Array::Handle(Array::New(1, Heap::kOld));
  before_obj.SetAt(0, new_element);
  after_obj.SetAt(0, old_element);
  EXPECT(before_obj.raw()->IsRemembered());
  EXPECT(!after_obj.raw()->IsRemembered());

  EXPECT(before_obj.raw() != after_obj.raw());

  const Array& before = Array::Handle(Array::New(1, Heap::kOld));
  before.SetAt(0, before_obj);
  const Array& after = Array::Handle(Array::New(1, Heap::kOld));
  after.SetAt(0, after_obj);

  Become::ElementsForwardIdentity(before, after);

  EXPECT(before_obj.raw() == after_obj.raw());
  EXPECT(!after_obj.raw()->IsRemembered());

  heap->CollectAllGarbage();

  EXPECT(before_obj.raw() == after_obj.raw());
}

ISOLATE_UNIT_TEST_CASE(CollectAllGarbage_DeadOldToNew) {
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  heap->CollectAllGarbage();
  heap->WaitForMarkerTasks(thread);  // Finalize marking to get live size.
  intptr_t size_before =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    old.SetAt(0, neu);
    old = Array::null();
    neu = Array::null();
    EXPECT(!thread->is_marking());
  }

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

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    neu.SetAt(0, old);
    old = Array::null();
    neu = Array::null();
    EXPECT(!thread->is_marking());
  }

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

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    neu.SetAt(0, old);
    old.SetAt(0, neu);
    old = Array::null();
    neu = Array::null();
    EXPECT(!thread->is_marking());
  }

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

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    neu.SetAt(0, old);
    old = Array::null();
    EXPECT(!thread->is_marking());
  }

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

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    old.SetAt(0, neu);
    neu = Array::null();
    EXPECT(!thread->is_marking());
  }

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

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    neu = Array::null();
    old.SetAt(0, old);
    EXPECT(!thread->is_marking());
  }

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

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    old = Array::null();
    neu.SetAt(0, neu);
    EXPECT(!thread->is_marking());
  }

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

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& old2 = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    old.SetAt(0, old2);
    neu.SetAt(0, old);
    old = Array::null();
    old2 = Array::null();
    EXPECT(!thread->is_marking());
  }

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

  {
    // Prevent allocation from starting marking, otherwise the incremental write
    // barrier will keep these objects live.
    NoHeapGrowthControlScope force_growth;
    EXPECT(!thread->is_marking());
    Array& old = Array::Handle(Array::New(1, Heap::kOld));
    Array& neu = Array::Handle(Array::New(1, Heap::kNew));
    Array& neu2 = Array::Handle(Array::New(1, Heap::kOld));
    neu.SetAt(0, neu2);
    old.SetAt(0, neu);
    neu = Array::null();
    neu2 = Array::null();
    EXPECT(!thread->is_marking());
  }

  heap->CollectAllGarbage();

  intptr_t size_after =
      heap->new_space()->UsedInWords() + heap->old_space()->UsedInWords();

  EXPECT(size_before < size_after);
}

static void NoopFinalizer(void* isolate_callback_data,
                          Dart_WeakPersistentHandle handle,
                          void* peer) {}

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
    FinalizablePersistentHandle::New(isolate, neu, NULL, NoopFinalizer, 1 * MB);
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
