// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/allocation.h"
#include "vm/assert.h"
#include "vm/longjump.h"
#include "vm/unit_test.h"

namespace dart {

class TestValueObject : public ValueObject {
 public:
  explicit TestValueObject(int* ptr) : ptr_(ptr) {
    EXPECT_EQ(1, *ptr_);
    *ptr_ = 2;
  }

  virtual ~TestValueObject() {
    EXPECT_EQ(3, *ptr_);
    *ptr_ = 4;
  }

  int value() const { return *ptr_; }
  virtual int GetId() const { return 3; }

 private:
  int* ptr_;
};


class TestStackResource : public StackResource {
 public:
  explicit TestStackResource(int* ptr)
      : StackResource(Isolate::Current()), ptr_(ptr) {
    EXPECT_EQ(1, *ptr_);
    *ptr_ = 2;
  }

  ~TestStackResource() {
    EXPECT_EQ(6, *ptr_);
    *ptr_ = 7;
  }

  int value() const { return *ptr_; }
  virtual int GetId() const { return 3; }

 private:
  int* ptr_;
};


class TestStackedStackResource : public StackResource {
 public:
  explicit TestStackedStackResource(int* ptr)
      : StackResource(Isolate::Current()), ptr_(ptr) {
    EXPECT_EQ(3, *ptr_);
    *ptr_ = 4;
  }

  ~TestStackedStackResource() {
    EXPECT_EQ(5, *ptr_);
    *ptr_ = 6;
  }

  int value() const { return *ptr_; }

 private:
  int* ptr_;
};


static void StackAllocatedDestructionHelper(int* ptr) {
  TestValueObject stacked(ptr);
  EXPECT_EQ(2, *ptr);
  *ptr = 3;
}


UNIT_TEST_CASE(StackAllocatedDestruction) {
  int data = 1;
  StackAllocatedDestructionHelper(&data);
  EXPECT_EQ(4, data);
}


static void StackAllocatedLongJumpHelper(int* ptr, LongJump* jump) {
  TestValueObject stacked(ptr);
  EXPECT_EQ(2, *ptr);
  *ptr = 3;
  jump->Jump(1, "StackAllocatedLongJump Test");
  UNREACHABLE();
}


TEST_CASE(StackAllocatedLongJump) {
  LongJump jump;
  int data = 1;
  if (setjmp(*jump.Set()) == 0) {
    StackAllocatedLongJumpHelper(&data, &jump);
    UNREACHABLE();
  }
  EXPECT_EQ(3, data);
}


static void StackedStackResourceDestructionHelper(int* ptr) {
  TestStackedStackResource stacked(ptr);
  EXPECT_EQ(4, *ptr);
  *ptr = 5;
}


static void StackResourceDestructionHelper(int* ptr) {
  TestStackResource stacked(ptr);
  EXPECT_EQ(2, *ptr);
  *ptr = 3;
  StackedStackResourceDestructionHelper(ptr);
  EXPECT_EQ(6, *ptr);
  // Do not set data because the LongJump version does not return control here.
}


TEST_CASE(StackResourceDestruction) {
  int data = 1;
  StackResourceDestructionHelper(&data);
  EXPECT_EQ(7, data);
}


static void StackedStackResourceLongJumpHelper(int* ptr, LongJump* jump) {
  TestStackedStackResource stacked(ptr);
  EXPECT_EQ(4, *ptr);
  *ptr = 5;
  jump->Jump(1, "StackResourceLongJump Test");
  UNREACHABLE();
}


static void StackResourceLongJumpHelper(int* ptr, LongJump* jump) {
  TestStackResource stacked(ptr);
  EXPECT_EQ(2, *ptr);
  *ptr = 3;
  StackedStackResourceLongJumpHelper(ptr, jump);
  UNREACHABLE();
}


TEST_CASE(StackResourceLongJump) {
  LongJump jump;
  int data = 1;
  if (setjmp(*jump.Set()) == 0) {
    StackResourceLongJumpHelper(&data, &jump);
    UNREACHABLE();
  }
  EXPECT_EQ(7, data);
}

}  // namespace dart
