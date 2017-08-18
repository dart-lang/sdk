// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_graph.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

class CounterVisitor : public ObjectGraph::Visitor {
 public:
  // Records the number of objects and total size visited, excluding 'skip'
  // and any objects only reachable through 'skip'.
  CounterVisitor(RawObject* skip, RawObject* expected_parent)
      : count_(0), size_(0), skip_(skip), expected_parent_(expected_parent) {}

  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    RawObject* obj = it->Get();
    if (obj == skip_) {
      EXPECT(it->MoveToParent());
      EXPECT_EQ(expected_parent_, it->Get());
      return kBacktrack;
    }
    ++count_;
    size_ += obj->Size();
    return kProceed;
  }

  int count() const { return count_; }
  int size() const { return size_; }

 private:
  int count_;
  intptr_t size_;
  RawObject* skip_;
  RawObject* expected_parent_;
};

ISOLATE_UNIT_TEST_CASE(ObjectGraph) {
  Isolate* isolate = thread->isolate();
  // Create a simple object graph with objects a, b, c, d:
  //  a+->b+->c
  //  +   +
  //  |   v
  //  +-->d
  Array& a = Array::Handle(Array::New(12, Heap::kNew));
  Array& b = Array::Handle(Array::New(2, Heap::kOld));
  Array& c = Array::Handle(Array::New(0, Heap::kOld));
  Array& d = Array::Handle(Array::New(0, Heap::kOld));
  a.SetAt(10, b);
  b.SetAt(0, c);
  b.SetAt(1, d);
  a.SetAt(11, d);
  intptr_t a_size = a.raw()->Size();
  intptr_t b_size = b.raw()->Size();
  intptr_t c_size = c.raw()->Size();
  intptr_t d_size = d.raw()->Size();
  {
    // No more allocation; raw pointers ahead.
    SafepointOperationScope safepoint(thread);
    RawObject* b_raw = b.raw();
    // Clear handles to cut unintended retained paths.
    b = Array::null();
    c = Array::null();
    d = Array::null();
    ObjectGraph graph(thread);
    {
      HeapIterationScope iteration_scope(thread, true);
      {
        // Compare count and size when 'b' is/isn't skipped.
        CounterVisitor with(Object::null(), Object::null());
        graph.IterateObjectsFrom(a, &with);
        CounterVisitor without(b_raw, a.raw());
        graph.IterateObjectsFrom(a, &without);
        // Only 'b' and 'c' were cut off.
        EXPECT_EQ(2, with.count() - without.count());
        EXPECT_EQ(b_size + c_size, with.size() - without.size());
      }
      {
        // Like above, but iterate over the entire isolate. The counts and sizes
        // are thus larger, but the difference should still be just 'b' and 'c'.
        CounterVisitor with(Object::null(), Object::null());
        graph.IterateObjects(&with);
        CounterVisitor without(b_raw, a.raw());
        graph.IterateObjects(&without);
        EXPECT_EQ(2, with.count() - without.count());
        EXPECT_EQ(b_size + c_size, with.size() - without.size());
      }
    }
    EXPECT_EQ(a_size + b_size + c_size + d_size,
              graph.SizeRetainedByInstance(a));
  }
  {
    // Get hold of c again.
    b ^= a.At(10);
    c ^= b.At(0);
    b = Array::null();
    ObjectGraph graph(thread);
    // A retaining path should end like this: c <- b <- a <- ...
    {
      HANDLESCOPE(thread);
      // Test null, empty, and length 1 array.
      intptr_t null_length = graph.RetainingPath(&c, Object::null_array());
      intptr_t empty_length = graph.RetainingPath(&c, Object::empty_array());
      Array& path = Array::Handle(Array::New(1, Heap::kNew));
      intptr_t one_length = graph.RetainingPath(&c, path);
      EXPECT_EQ(null_length, empty_length);
      EXPECT_EQ(null_length, one_length);
      EXPECT_LE(3, null_length);
    }
    {
      HANDLESCOPE(thread);
      Array& path = Array::Handle(Array::New(6, Heap::kNew));
      // Trigger a full GC to increase probability of concurrent tasks.
      isolate->heap()->CollectAllGarbage();
      intptr_t length = graph.RetainingPath(&c, path);
      EXPECT_LE(3, length);
      Array& expected_c = Array::Handle();
      expected_c ^= path.At(0);
      // c is the first element in b.
      Smi& offset_from_parent = Smi::Handle();
      offset_from_parent ^= path.At(1);
      EXPECT_EQ(Array::element_offset(0),
                offset_from_parent.Value() * kWordSize);
      Array& expected_b = Array::Handle();
      expected_b ^= path.At(2);
      // b is the element with index 10 in a.
      offset_from_parent ^= path.At(3);
      EXPECT_EQ(Array::element_offset(10),
                offset_from_parent.Value() * kWordSize);
      Array& expected_a = Array::Handle();
      expected_a ^= path.At(4);
      EXPECT(expected_c.raw() == c.raw());
      EXPECT(expected_b.raw() == a.At(10));
      EXPECT(expected_a.raw() == a.raw());
    }
  }
}

}  // namespace dart
