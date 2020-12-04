// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/datastream.h"

#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

// As a baseline, testing encodings of all numbers with bit size <= 16, as
// that's both a reasonable amount of numbers to iterate over and that way we
// test all 1-byte, all 2-byte, and some 3-byte encodings.
static constexpr intptr_t kUnsignedEnd = kMaxUint16;
static constexpr intptr_t kSignedStart = kMinInt16;
static constexpr intptr_t kSignedEnd = kMaxInt16;

// Testing some numbers with first, second, and/or third MSBs set.
#define DEFINE_LARGE_CONSTANTS(T)                                              \
  using Unsigned = typename std::make_unsigned<T>::type;                       \
  constexpr T all_ones = static_cast<T>(-1); /* 111... */                      \
  constexpr T min =                                                            \
      static_cast<T>(static_cast<Unsigned>(1)                                  \
                     << (kBitsPerByte * sizeof(T) - 1)); /* 100... */          \
  constexpr T max =                                                            \
      static_cast<T>(static_cast<Unsigned>(min) - 1); /* 011... */             \
  constexpr T half_min = min / 2;                     /* 110... */             \
  constexpr T half_max = max / 2;                     /* 001... */

TEST_CASE(BaseWriteStream_Write) {
  MallocWriteStream writer(1 * KB);
  for (intptr_t i = kSignedStart; i < kSignedEnd; i++) {
    writer.Write(i);
  }
  DEFINE_LARGE_CONSTANTS(intptr_t);
  writer.Write(all_ones);
  writer.Write(min);
  writer.Write(max);
  writer.Write(half_min);
  writer.Write(half_max);
  ReadStream reader(writer.buffer(), writer.bytes_written());
  for (intptr_t i = kSignedStart; i < kSignedEnd; i++) {
    const intptr_t r = reader.Read<intptr_t>();
    EXPECT_EQ(i, r);
  }
  const intptr_t read_all_ones = reader.Read<intptr_t>();
  EXPECT_EQ(all_ones, read_all_ones);
  const intptr_t read_min = reader.Read<intptr_t>();
  EXPECT_EQ(min, read_min);
  const intptr_t read_max = reader.Read<intptr_t>();
  EXPECT_EQ(max, read_max);
  const intptr_t read_half_min = reader.Read<intptr_t>();
  EXPECT_EQ(half_min, read_half_min);
  const intptr_t read_half_max = reader.Read<intptr_t>();
  EXPECT_EQ(half_max, read_half_max);
}

TEST_CASE(BaseWriteStream_WriteUnsigned) {
  MallocWriteStream writer(1 * KB);
  for (uintptr_t i = 0; i < kUnsignedEnd; i++) {
    writer.WriteUnsigned(i);
  }
  DEFINE_LARGE_CONSTANTS(uintptr_t);
  writer.WriteUnsigned(all_ones);
  writer.WriteUnsigned(min);
  writer.WriteUnsigned(max);
  writer.WriteUnsigned(half_min);
  writer.WriteUnsigned(half_max);
  ReadStream reader(writer.buffer(), writer.bytes_written());
  for (uintptr_t i = 0; i < kUnsignedEnd; i++) {
    const uintptr_t r = reader.ReadUnsigned<uintptr_t>();
    EXPECT_EQ(i, r);
  }
  const uintptr_t read_all_ones = reader.ReadUnsigned<uintptr_t>();
  EXPECT_EQ(all_ones, read_all_ones);
  const uintptr_t read_min = reader.ReadUnsigned<uintptr_t>();
  EXPECT_EQ(min, read_min);
  const uintptr_t read_max = reader.ReadUnsigned<uintptr_t>();
  EXPECT_EQ(max, read_max);
  const uintptr_t read_half_min = reader.ReadUnsigned<uintptr_t>();
  EXPECT_EQ(half_min, read_half_min);
  const uintptr_t read_half_max = reader.ReadUnsigned<uintptr_t>();
  EXPECT_EQ(half_max, read_half_max);
}

template <typename T>
void TestRaw() {
  MallocWriteStream writer(1 * KB);
  for (T i = kSignedStart; i < kSignedEnd; i++) {
    writer.Write(i);
  }
  DEFINE_LARGE_CONSTANTS(T);
  writer.Write(all_ones);
  writer.Write(min);
  writer.Write(max);
  writer.Write(half_min);
  writer.Write(half_max);
  ReadStream reader(writer.buffer(), writer.bytes_written());
  using Raw = ReadStream::Raw<sizeof(T), T>;
  for (T i = kSignedStart; i < kSignedEnd; i++) {
    const T r = Raw::Read(&reader);
    EXPECT_EQ(i, r);
  }
  const T read_all_ones = Raw::Read(&reader);
  EXPECT_EQ(all_ones, read_all_ones);
  const T read_min = Raw::Read(&reader);
  EXPECT_EQ(min, read_min);
  const T read_max = Raw::Read(&reader);
  EXPECT_EQ(max, read_max);
  const T read_half_min = Raw::Read(&reader);
  EXPECT_EQ(half_min, read_half_min);
  const T read_half_max = Raw::Read(&reader);
  EXPECT_EQ(half_max, read_half_max);
}

TEST_CASE(ReadStream_Read16) {
  TestRaw<int16_t>();
}

TEST_CASE(ReadStream_Read32) {
  TestRaw<int32_t>();
}

TEST_CASE(ReadStream_Read64) {
  TestRaw<int64_t>();
}

TEST_CASE(BaseWriteStream_WriteLEB128) {
  MallocWriteStream writer(1 * KB);
  for (uintptr_t i = 0; i < kUnsignedEnd; i++) {
    writer.WriteLEB128(i);
  }
  DEFINE_LARGE_CONSTANTS(uintptr_t);
  writer.WriteLEB128(all_ones);
  writer.WriteLEB128(min);
  writer.WriteLEB128(max);
  writer.WriteLEB128(half_min);
  writer.WriteLEB128(half_max);
  ReadStream reader(writer.buffer(), writer.bytes_written());
  for (uintptr_t i = 0; i < kUnsignedEnd; i++) {
    const uintptr_t r = reader.ReadLEB128();
    EXPECT_EQ(i, r);
  }
  const uintptr_t read_all_ones = reader.ReadLEB128();
  EXPECT_EQ(all_ones, read_all_ones);
  const uintptr_t read_min = reader.ReadLEB128();
  EXPECT_EQ(min, read_min);
  const uintptr_t read_max = reader.ReadLEB128();
  EXPECT_EQ(max, read_max);
  const uintptr_t read_half_min = reader.ReadLEB128();
  EXPECT_EQ(half_min, read_half_min);
  const uintptr_t read_half_max = reader.ReadLEB128();
  EXPECT_EQ(half_max, read_half_max);
}

TEST_CASE(BaseWriteStream_WriteSLEB128) {
  MallocWriteStream writer(1 * KB);
  for (intptr_t i = kSignedStart; i < kSignedEnd; i++) {
    writer.WriteSLEB128(i);
  }
  DEFINE_LARGE_CONSTANTS(intptr_t);
  writer.WriteSLEB128(all_ones);
  writer.WriteSLEB128(min);
  writer.WriteSLEB128(max);
  writer.WriteSLEB128(half_min);
  writer.WriteSLEB128(half_max);
  ReadStream reader(writer.buffer(), writer.bytes_written());
  for (intptr_t i = kSignedStart; i < kSignedEnd; i++) {
    const intptr_t r = reader.ReadSLEB128();
    EXPECT_EQ(i, r);
  }
  const intptr_t read_all_ones = reader.ReadSLEB128();
  EXPECT_EQ(all_ones, read_all_ones);
  const intptr_t read_min = reader.ReadSLEB128();
  EXPECT_EQ(min, read_min);
  const intptr_t read_max = reader.ReadSLEB128();
  EXPECT_EQ(max, read_max);
  const intptr_t read_half_min = reader.ReadSLEB128();
  EXPECT_EQ(half_min, read_half_min);
  const intptr_t read_half_max = reader.ReadSLEB128();
  EXPECT_EQ(half_max, read_half_max);
}

}  // namespace dart
