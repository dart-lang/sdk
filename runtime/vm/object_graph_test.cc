// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/object_graph.h"
#include "vm/unit_test.h"

namespace dart {

class Counter : public ObjectGraph::Visitor {
 public:
  // Records the number of objects and total size visited, excluding 'skip'
  // and any objects only reachable through 'skip'.
  Counter(RawObject* skip, RawObject* expected_parent)
      : count_(0), size_(0), skip_(skip), expected_parent_(expected_parent) { }

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


TEST_CASE(ObjectGraph) {
  Isolate* isolate = Isolate::Current();
  // Create a simple object graph with objects a, b, c, d:
  //  a+->b+->c
  //  +   +
  //  |   v
  //  +-->d
  Array& a = Array::Handle(Array::New(2, Heap::kNew));
  Array& b = Array::Handle(Array::New(2, Heap::kOld));
  Array& c = Array::Handle(Array::New(0, Heap::kOld));
  Array& d = Array::Handle(Array::New(0, Heap::kOld));
  a.SetAt(0, b);
  b.SetAt(0, c);
  b.SetAt(1, d);
  a.SetAt(1, d);
  intptr_t b_size = b.raw()->Size();
  intptr_t c_size = c.raw()->Size();
  {
    // No more allocation; raw pointers ahead.
    NoGCScope no_gc_scope;
    RawObject* b_raw = b.raw();
    // Clear handles to cut unintended retained paths.
    b = Array::null();
    c = Array::null();
    d = Array::null();
    ObjectGraph graph(isolate);
    {
      // Compare count and size when 'b' is/isn't skipped.
      Counter with(Object::null(), Object::null());
      graph.IterateObjectsFrom(a, &with);
      Counter without(b_raw, a.raw());
      graph.IterateObjectsFrom(a, &without);
      // Only 'b' and 'c' were cut off.
      EXPECT_EQ(2, with.count() - without.count());
      EXPECT_EQ(b_size + c_size,
                with.size() - without.size());
    }
    {
      // Like above, but iterate over the entire isolate. The counts and sizes
      // are thus larger, but the difference should still be just 'b' and 'c'.
      Counter with(Object::null(), Object::null());
      graph.IterateObjects(&with);
      Counter without(b_raw, a.raw());
      graph.IterateObjects(&without);
      EXPECT_EQ(2, with.count() - without.count());
      EXPECT_EQ(b_size + c_size,
                with.size() - without.size());
    }
  }
}

}  // namespace dart
