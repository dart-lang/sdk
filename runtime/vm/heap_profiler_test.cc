// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap_profiler.h"
#include "vm/growable_array.h"
#include "vm/unit_test.h"

namespace dart {

static void WriteCallback(const void* data, intptr_t length, void* stream) {
  GrowableArray<uint8_t>* array =
      reinterpret_cast<GrowableArray<uint8_t>*>(stream);
  for (intptr_t i = 0; i < length; ++i) {
    array->Add(reinterpret_cast<const uint8_t*>(data)[i]);
  }
}


static uint8_t Read8(GrowableArray<uint8_t>* array, intptr_t* i) {
  EXPECT(array != NULL);
  EXPECT(i != NULL);
  EXPECT_LE(*i + 1, array->length());
  return (*array)[(*i)++];
}


static uint32_t Read32(GrowableArray<uint8_t>* array, intptr_t* i) {
  EXPECT(array != NULL);
  EXPECT(i != NULL);
  EXPECT_LE(*i + 4, array->length());
  uint32_t result = 0;
  result |= ((*array)[(*i)++] <<  0);
  result |= ((*array)[(*i)++] <<  8);
  result |= ((*array)[(*i)++] << 16);
  result |= ((*array)[(*i)++] << 24);
  return ntohl(result);
}


static bool IsTagValid(uint8_t tag) {
  switch (static_cast<HeapProfiler::Tag>(tag)) {
    case HeapProfiler::kStringInUtf8:
    case HeapProfiler::kLoadClass:
    case HeapProfiler::kUnloadClass:
    case HeapProfiler::kStackFrame:
    case HeapProfiler::kStackTrace:
    case HeapProfiler::kAllocSites:
    case HeapProfiler::kHeapSummary:
    case HeapProfiler::kStartThread:
    case HeapProfiler::kEndThread:
    case HeapProfiler::kHeapDump:
    case HeapProfiler::kCpuSamples:
    case HeapProfiler::kControlSettings:
    case HeapProfiler::kHeapDumpSummary:
    case HeapProfiler::kHeapDumpEnd:
      return true;
    default:
      return false;
  }
}


// Write an empty profile.  Validate the presence of a header and a
// minimal set of records.
TEST_CASE(HeapProfileEmpty) {
  uint64_t before = OS::GetCurrentTimeMillis();
  GrowableArray<uint8_t> array;
  {
    HeapProfiler(WriteCallback, &array);
  }
  uint64_t after = OS::GetCurrentTimeMillis();
  intptr_t i = 0;
  EXPECT_LE(i + 19, array.length());
  EXPECT_EQ('J', array[i++]);
  EXPECT_EQ('A', array[i++]);
  EXPECT_EQ('V', array[i++]);
  EXPECT_EQ('A', array[i++]);
  EXPECT_EQ(' ', array[i++]);
  EXPECT_EQ('P', array[i++]);
  EXPECT_EQ('R', array[i++]);
  EXPECT_EQ('O', array[i++]);
  EXPECT_EQ('F', array[i++]);
  EXPECT_EQ('I', array[i++]);
  EXPECT_EQ('L', array[i++]);
  EXPECT_EQ('E', array[i++]);
  EXPECT_EQ(' ', array[i++]);
  EXPECT_EQ('1', array[i++]);
  EXPECT_EQ('.', array[i++]);
  EXPECT_EQ('0', array[i++]);
  EXPECT_EQ('.', array[i++]);
  EXPECT_EQ('1', array[i++]);
  EXPECT_EQ('\0', array[i++]);
  uint32_t size = Read32(&array, &i);
  EXPECT_EQ(8u, size);
  uint64_t hi = Read32(&array, &i);
  uint64_t lo = Read32(&array, &i);
  uint64_t time = (hi << 32) | lo;
  EXPECT_GE(before, time);
  EXPECT_LE(after, time);
  while (i != array.length()) {
    // Check tag
    uint8_t tag = Read8(&array, &i);
    EXPECT(IsTagValid(tag));
    // Check time diff
    uint32_t time_diff = Read32(&array, &i);
    EXPECT_LE(before, time + time_diff);
    EXPECT_GE(after, time + time_diff);
    // Check length diff
    uint32_t length = Read32(&array, &i);
    EXPECT_LE((intptr_t)length + i , array.length());
    // skip body
    i += length;
  }
}

}  // namespace dart
