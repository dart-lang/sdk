// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/heap/heap.h"
#include "vm/heap/weak_table.h"
#include "vm/unit_test.h"

namespace dart {

ISOLATE_UNIT_TEST_CASE(WeakTables) {
  const Object& old_obj = Object::Handle(String::New("old", Heap::kOld));
  const Object& new_obj = Object::Handle(String::New("new", Heap::kNew));
  const Object& imm_obj = Object::Handle(Smi::New(0));

  // Initially absent.
  Heap* heap = thread->heap();
  const intptr_t kNoValue = WeakTable::kNoValue;
  EXPECT_EQ(kNoValue, heap->GetObjectId(old_obj.raw()));
  EXPECT_EQ(kNoValue, heap->GetObjectId(new_obj.raw()));
  EXPECT_EQ(kNoValue, heap->GetObjectId(imm_obj.raw()));

  // Found after insert.
  heap->SetObjectId(old_obj.raw(), 100);
  heap->SetObjectId(new_obj.raw(), 200);
  heap->SetObjectId(imm_obj.raw(), 300);
  EXPECT_EQ(100, heap->GetObjectId(old_obj.raw()));
  EXPECT_EQ(200, heap->GetObjectId(new_obj.raw()));
  EXPECT_EQ(300, heap->GetObjectId(imm_obj.raw()));

  // Found after update.
  heap->SetObjectId(old_obj.raw(), 400);
  heap->SetObjectId(new_obj.raw(), 500);
  heap->SetObjectId(imm_obj.raw(), 600);
  EXPECT_EQ(400, heap->GetObjectId(old_obj.raw()));
  EXPECT_EQ(500, heap->GetObjectId(new_obj.raw()));
  EXPECT_EQ(600, heap->GetObjectId(imm_obj.raw()));

  // Found after GC.
  GCTestHelper::CollectNewSpace();
  EXPECT_EQ(400, heap->GetObjectId(old_obj.raw()));
  EXPECT_EQ(500, heap->GetObjectId(new_obj.raw()));
  EXPECT_EQ(600, heap->GetObjectId(imm_obj.raw()));

  // Found after GC.
  GCTestHelper::CollectOldSpace();
  EXPECT_EQ(400, heap->GetObjectId(old_obj.raw()));
  EXPECT_EQ(500, heap->GetObjectId(new_obj.raw()));
  EXPECT_EQ(600, heap->GetObjectId(imm_obj.raw()));

  // Absent after reset.
  heap->ResetObjectIdTable();
  EXPECT_EQ(kNoValue, heap->GetObjectId(old_obj.raw()));
  EXPECT_EQ(kNoValue, heap->GetObjectId(new_obj.raw()));
  EXPECT_EQ(kNoValue, heap->GetObjectId(imm_obj.raw()));
}

}  // namespace dart
