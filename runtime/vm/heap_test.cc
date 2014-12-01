// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "platform/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(OldGC) {
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
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  heap->CollectGarbage(Heap::kOld);
}


TEST_CASE(LargeSweep) {
  const char* kScriptChars =
  "main() {\n"
  "  return new List(8 * 1024 * 1024);\n"
  "}\n";
  FLAG_verbose_gc = true;
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);

  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  EXPECT(Dart_IsList(result));
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  heap->CollectGarbage(Heap::kOld);
  Dart_ExitScope();
  heap->CollectGarbage(Heap::kOld);
}


class ClassHeapStatsTestHelper {
 public:
  static ClassHeapStats* GetHeapStatsForCid(ClassTable* class_table,
                                            intptr_t cid) {
    return class_table->PreliminaryStatsAt(cid);
  }

  static void DumpClassHeapStats(ClassHeapStats* stats) {
    OS::Print("%" Pd " ", stats->recent.new_count);
    OS::Print("%" Pd " ", stats->post_gc.new_count);
    OS::Print("%" Pd " ", stats->pre_gc.new_count);
    OS::Print("\n");
  }
};


static RawClass* GetClass(const Library& lib, const char* name) {
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(name))));
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
  Heap* heap = isolate->heap();
  Dart_EnterScope();
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
  const Class& cls = Class::Handle(GetClass(lib, "A"));
  ASSERT(!cls.IsNull());
  intptr_t cid = cls.id();
  ClassHeapStats* class_stats =
      ClassHeapStatsTestHelper::GetHeapStatsForCid(class_table,
                                                   cid);
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
  // Exit scope, freeing instance.
  Dart_ExitScope();
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
      ClassHeapStatsTestHelper::GetHeapStatsForCid(class_table,
                                                   cid);
  Dart_EnterScope();
  // Invoke 'main' twice, since initial compilation might trigger extra array
  // allocations.
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
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


class FindOnly : public FindObjectVisitor {
 public:
  FindOnly(Isolate* isolate, RawObject* target)
      : FindObjectVisitor(isolate), target_(target) {
    ASSERT(isolate->no_gc_scope_depth() != 0);
  }
  virtual ~FindOnly() { }

  virtual bool FindObject(RawObject* obj) const {
    return obj == target_;
  }
 private:
  RawObject* target_;
};


class FindNothing : public FindObjectVisitor {
 public:
  FindNothing() : FindObjectVisitor(Isolate::Current()) { }
  virtual ~FindNothing() { }
  virtual bool FindObject(RawObject* obj) const { return false; }
};


TEST_CASE(FindObject) {
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  Heap::Space spaces[2] = {Heap::kOld, Heap::kNew};
  for (size_t space = 0; space < ARRAY_SIZE(spaces); ++space) {
    const String& obj = String::Handle(String::New("x", spaces[space]));
    {
      NoGCScope no_gc;
      FindOnly find_only(isolate, obj.raw());
      EXPECT(obj.raw() == heap->FindObject(&find_only));
    }
  }
  {
    NoGCScope no_gc;
    FindNothing find_nothing;
    EXPECT(Object::null() == heap->FindObject(&find_nothing));
  }
}

}  // namespace dart.
