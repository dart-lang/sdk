// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/regexp/regexp.h"
#include "vm/regexp/small-vector.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

static ObjectPtr Match(const String& pattern, const String& subject) {
  const RegExp& regexp = RegExp::Handle(RegExp::New(pattern, RegExpFlags()));
  return RegExpStatics::Interpret(Thread::Current(), regexp, subject, 0,
                                  /*sticky=*/false);
}

namespace {

struct DestructionTracker {
  int* counter;
  DestructionTracker() : counter(nullptr) {}
  explicit DestructionTracker(int* c) : counter(c) {}
  DestructionTracker(DestructionTracker&& other) noexcept
      : counter(other.counter) {
    other.counter = nullptr;
  }
  DestructionTracker& operator=(DestructionTracker&& other) noexcept {
    if (this != &other) {
      if (counter != nullptr) {
        (*counter)++;
      }
      counter = other.counter;
      other.counter = nullptr;
    }
    return *this;
  }
  ~DestructionTracker() {
    if (counter != nullptr) {
      (*counter)++;
    }
  }
};

}  // namespace

ISOLATE_UNIT_TEST_CASE(SmallVector_ReleaseHeapStorage) {
  // Verify behavior on inline storage (no dynamic allocation).
  base::SmallVector<int, 4> vec;
  vec.push_back(10);
  vec.push_back(20);
  EXPECT_EQ(2u, vec.size());
  EXPECT_EQ(4u, vec.capacity());
  vec.ReleaseHeapStorage();
  EXPECT_EQ(0u, vec.size());
  EXPECT_EQ(4u, vec.capacity());

  // Verify growth past inline capacity to dynamic heap storage.
  for (int i = 0; i < 16; i++) {
    vec.push_back(i);
  }
  EXPECT_EQ(16u, vec.size());
  EXPECT(vec.capacity() >= 16u);

  // Verify ReleaseHeapStorage frees heap allocation and reverts to inline.
  vec.ReleaseHeapStorage();
  EXPECT_EQ(0u, vec.size());
  EXPECT_EQ(4u, vec.capacity());

  // Verify vector remains functional after release and destructs cleanly.
  vec.push_back(42);
  EXPECT_EQ(1u, vec.size());
  EXPECT_EQ(42, vec[0]);

  // Verify elements with nontrivial destructors are destroyed exactly once.
  int dtor_count = 0;
  {
    base::SmallVector<DestructionTracker, 2> tracked;
    for (int i = 0; i < 8; i++) {
      tracked.emplace_back(&dtor_count);
    }
    EXPECT_EQ(8u, tracked.size());
    tracked.ReleaseHeapStorage();
    EXPECT_EQ(8, dtor_count);
    EXPECT_EQ(0u, tracked.size());
    EXPECT_EQ(2u, tracked.capacity());
  }
  EXPECT_EQ(8, dtor_count);
}

ISOLATE_UNIT_TEST_CASE(RegExp_OneByteString) {
  uint8_t chars[] = {'a', 'b', 'c', 'b', 'a'};
  intptr_t len = ARRAY_SIZE(chars);
  const String& str =
      String::Handle(OneByteString::New(chars, len, Heap::kNew));

  const String& pat =
      String::Handle(Symbols::New(thread, String::Handle(String::New("bc"))));
  TypedData& res = TypedData::Handle();
  res ^= Match(pat, str);
  EXPECT_EQ(2, res.Length());
  EXPECT_EQ(1, res.GetInt32(0 * sizeof(int32_t)));
  EXPECT_EQ(3, res.GetInt32(1 * sizeof(int32_t)));
}

ISOLATE_UNIT_TEST_CASE(RegExp_TwoByteString) {
  uint16_t chars[] = {'a', 'b', 'c', 'b', 'a'};
  intptr_t len = ARRAY_SIZE(chars);
  const String& str =
      String::Handle(TwoByteString::New(chars, len, Heap::kNew));

  const String& pat =
      String::Handle(Symbols::New(thread, String::Handle(String::New("bc"))));
  TypedData& res = TypedData::Handle();
  res ^= Match(pat, str);
  EXPECT_EQ(2, res.Length());
  EXPECT_EQ(1, res.GetInt32(0 * sizeof(int32_t)));
  EXPECT_EQ(3, res.GetInt32(1 * sizeof(int32_t)));
}

}  // namespace dart
