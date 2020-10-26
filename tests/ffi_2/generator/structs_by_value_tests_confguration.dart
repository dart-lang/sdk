// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'c_types.dart';

final functions = [
  FunctionType(List.filled(10, struct1byteInt), int64, """
Smallest struct with data.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct3bytesInt), int64, """
Not a multiple of word size, not a power of two.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct4bytesInt), int64, """
Exactly word size on 32-bit architectures.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct7bytesInt), int64, """
Sub word size on 64 bit architectures.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct8bytesInt), int64, """
Exactly word size struct on 64bit architectures.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct8bytesFloat), float, """
Arguments passed in FP registers as long as they fit.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct8BytesMixed), float, """
On x64, arguments go in int registers because it is not only float.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct9bytesInt), int64, """
Argument is a single byte over a multiple of word size.
10 struct arguments will exhaust available registers.
Tests upper bytes in the integer registers that are partly filled.
Tests stack alignment of non word size stack arguments."""),
  FunctionType(List.filled(10, struct9bytesInt2), int64, """
Argument is a single byte over a multiple of word size.
10 struct arguments will exhaust available registers.
Struct only has 1-byte aligned fields to test struct alignment itself.
"""),
  FunctionType(List.filled(6, struct12bytesFloat), float, """
Arguments in FPU registers on arm hardfp and arm64.
Struct arguments will exhaust available registers, and leave some empty.
The last argument is to test whether arguments are backfilled."""),
  FunctionType(List.filled(5, struct16bytesFloat), float, """
On Linux x64 argument is transferred on stack because it is over 16 bytes.
Arguments in FPU registers on arm hardfp and arm64.
5 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct16bytesMixed), double_, """
On x64, arguments are split over FP and int registers.
On x64, it will exhaust the integer registers with the 6th argument.
The rest goes on the stack.
On arm, arguments are 8 byte aligned."""),
  FunctionType(List.filled(10, struct16bytesMixed2), float, """
On x64, arguments are split over FP and int registers.
On x64, it will exhaust the integer registers with the 6th argument.
The rest goes on the stack.
On arm, arguments are 4 byte aligned."""),
  FunctionType(List.filled(10, struct17bytesInt), int64, """
Arguments are passed as pointer to copy on arm64.
Tests that the memory allocated for copies are rounded up to word size."""),
  FunctionType(List.filled(10, struct19bytesInt), int64, """
The minimum alignment of this struct is only 1 byte based on its fields.
Test that the memory backing these structs is extended to the right size.
"""),
  FunctionType(List.filled(10, struct20bytesInt), int32, """
Argument too big to go into integer registers on arm64.
The arguments are passed as pointers to copies.
The amount of arguments exhausts the number of integer registers, such that
pointers to copies are also passed on the stack."""),
  FunctionType(
      [struct20bytesFloat],
      float,
      """
Argument too big to go into FPU registers in hardfp and arm64."""),
  FunctionType(List.filled(5, struct32bytesDouble), double_, """
Arguments in FPU registers on arm64.
5 struct arguments will exhaust available registers."""),
  FunctionType(
      [struct40bytesDouble],
      double_,
      """
Argument too big to go into FPU registers in arm64."""),
  FunctionType(
      [struct1024bytesInt],
      uint64,
      """
Test 1kb struct."""),
  FunctionType(
      [
        float,
        struct16bytesFloat,
        float,
        struct16bytesFloat,
        float,
        struct16bytesFloat,
        float,
        struct16bytesFloat,
        float
      ],
      float,
      """
Tests the alignment of structs in FPU registers and backfilling."""),
  FunctionType(
      [
        float,
        struct32bytesDouble,
        float,
        struct32bytesDouble,
        float,
        struct32bytesDouble,
        float,
        struct32bytesDouble,
        float
      ],
      double_,
      """
Tests the alignment of structs in FPU registers and backfilling."""),
  FunctionType(
      [
        int8,
        struct16bytesMixed,
        int8,
        struct16bytesMixed,
        int8,
        struct16bytesMixed,
        int8,
        struct16bytesMixed,
        int8
      ],
      double_,
      """
Tests the alignment of structs in integers registers and on the stack.
Arm32 aligns this struct at 8.
Also, arm32 allocates the second struct partially in registers, partially
on stack.
Test backfilling of integer registers."""),
  FunctionType(
      [
        double_,
        double_,
        double_,
        double_,
        double_,
        double_,
        struct16bytesMixed,
        struct16bytesMixed,
        struct16bytesMixed,
        struct16bytesMixed,
        int32,
      ],
      double_,
      """
On Linux x64, it will exhaust xmm registers first, after 6 doubles and 2
structs. The rest of the structs will go on the stack.
The int will be backfilled into the int register."""),
  FunctionType(
      [
        int32,
        int32,
        int32,
        int32,
        struct16bytesMixed,
        struct16bytesMixed,
        struct16bytesMixed,
        struct16bytesMixed,
        double_,
      ],
      double_,
      """
On Linux x64, it will exhaust int registers first.
The rest of the structs will go on the stack.
The double will be backfilled into the xmm register."""),
  FunctionType(
      [
        struct40bytesDouble,
        struct4bytesInt,
        struct8bytesFloat,
      ],
      double_,
      """
On various architectures, first struct is allocated on stack.
Check that the other two arguments are allocated on registers."""),
  FunctionType(
      [structAlignmentInt16],
      int64,
      """
Test alignment and padding of 16 byte int within struct."""),
  FunctionType(
      [structAlignmentInt32],
      int64,
      """
Test alignment and padding of 32 byte int within struct."""),
  FunctionType(
      [structAlignmentInt64],
      int64,
      """
Test alignment and padding of 64 byte int within struct."""),
  FunctionType(struct1byteInt.memberTypes, struct1byteInt, """
Smallest struct with data."""),
  FunctionType(struct3bytesInt.memberTypes, struct3bytesInt, """
Smaller than word size return value on all architectures."""),
  FunctionType(struct4bytesInt.memberTypes, struct4bytesInt, """
Word size return value on 32 bit architectures.."""),
  FunctionType(struct7bytesInt.memberTypes, struct7bytesInt, """
Non-wordsize return value."""),
  FunctionType(struct8bytesInt.memberTypes, struct8bytesInt, """
Return value in integer registers on many architectures."""),
  FunctionType(struct8bytesFloat.memberTypes, struct8bytesFloat, """
Return value in FP registers on many architectures."""),
  FunctionType(struct8BytesMixed.memberTypes, struct8BytesMixed, """
Return value split over FP and integer register in x64."""),
  FunctionType(struct9bytesInt.memberTypes, struct9bytesInt, """
Return value in two integer registers on x64.
The second register only contains a single byte."""),
  FunctionType(struct9bytesInt2.memberTypes, struct9bytesInt2, """
The minimum alignment of this struct is only 1 byte based on its fields.
Test that the memory backing these structs is the right size and that
dart:ffi trampolines do not write outside this size."""),
  FunctionType(struct12bytesFloat.memberTypes, struct12bytesFloat, """
Return value in FPU registers, but does not use all registers on arm hardfp
and arm64."""),
  FunctionType(struct16bytesFloat.memberTypes, struct16bytesFloat, """
Return value in FPU registers on arm hardfp and arm64."""),
  FunctionType(struct16bytesMixed.memberTypes, struct16bytesMixed, """
Return value split over FP and integer register in x64."""),
  FunctionType(struct16bytesMixed2.memberTypes, struct16bytesMixed2, """
Return value split over FP and integer register in x64.
The integer register contains half float half int."""),
  FunctionType(struct17bytesInt.memberTypes, struct17bytesInt, """
Rerturn value returned in preallocated space passed by pointer on most ABIs.
Is non word size on purpose, to test that structs are rounded up to word size
on all ABIs."""),
  FunctionType(struct19bytesInt.memberTypes, struct19bytesInt, """
The minimum alignment of this struct is only 1 byte based on its fields.
Test that the memory backing these structs is the right size and that
dart:ffi trampolines do not write outside this size."""),
  FunctionType(struct20bytesInt.memberTypes, struct20bytesInt, """
Return value too big to go in cpu registers on arm64."""),
  FunctionType(struct20bytesFloat.memberTypes, struct20bytesFloat, """
Return value too big to go in FPU registers on x64, arm hardfp and arm64."""),
  FunctionType(struct32bytesDouble.memberTypes, struct32bytesDouble, """
Return value in FPU registers on arm64."""),
  FunctionType(struct40bytesDouble.memberTypes, struct40bytesDouble, """
Return value too big to go in FPU registers on arm64."""),
  FunctionType(struct1024bytesInt.memberTypes, struct1024bytesInt, """
Test 1kb struct."""),
  FunctionType(
      [struct1byteInt],
      struct1byteInt,
      """
Test that a struct passed in as argument can be returned.
Especially for ffi callbacks.
Struct is passed in int registers in most ABIs."""),
  FunctionType(
      [int32, int32, int32, int32, int32, int32, int32, int32, struct1byteInt],
      struct1byteInt,
      """
Test that a struct passed in as argument can be returned.
Especially for ffi callbacks.
Struct is passed on stack on all ABIs."""),
  FunctionType(
      [struct8bytesFloat],
      struct8bytesFloat,
      """
Test that a struct passed in as argument can be returned.
Especially for ffi callbacks.
Struct is passed in float registers in most ABIs."""),
  FunctionType(
      [struct20bytesInt],
      struct20bytesInt,
      """
On arm64, both argument and return value are passed in by pointer."""),
  FunctionType(
      [
        int32,
        int32,
        int32,
        int32,
        int32,
        int32,
        int32,
        int32,
        struct20bytesInt
      ],
      struct20bytesInt,
      """
On arm64, both argument and return value are passed in by pointer.
Ints exhaust registers, so that pointer is passed on stack."""),
  FunctionType(structAlignmentInt16.memberTypes, structAlignmentInt16, """
Test alignment and padding of 16 byte int within struct."""),
  FunctionType(structAlignmentInt32.memberTypes, structAlignmentInt32, """
Test alignment and padding of 32 byte int within struct."""),
  FunctionType(structAlignmentInt64.memberTypes, structAlignmentInt64, """
Test alignment and padding of 64 byte int within struct."""),
];

final structs = [
  struct0bytes,
  struct1byteInt,
  struct3bytesInt,
  struct4bytesInt,
  struct7bytesInt,
  struct8bytesInt,
  struct8bytesFloat,
  struct8BytesMixed,
  struct9bytesInt,
  struct9bytesInt2,
  struct12bytesFloat,
  struct16bytesFloat,
  struct16bytesMixed,
  struct16bytesMixed2,
  struct17bytesInt,
  struct19bytesInt,
  struct20bytesInt,
  struct20bytesFloat,
  struct32bytesDouble,
  struct40bytesDouble,
  struct1024bytesInt,
  structAlignmentInt16,
  structAlignmentInt32,
  structAlignmentInt64,
];

/// Using empty structs is undefined behavior in C.
final struct0bytes = StructType([]);

final struct1byteInt = StructType([int8]);
final struct3bytesInt = StructType([int16, int8]);
final struct4bytesInt = StructType([int16, int16]);
final struct7bytesInt = StructType([int32, int16, int8]);
final struct8bytesInt = StructType([int16, int16, int32]);
final struct8bytesFloat = StructType([float, float]);
final struct8BytesMixed = StructType([float, int16, int16]);
final struct9bytesInt = StructType([int64, int8]);
final struct9bytesInt2 = StructType.disambiguate(List.filled(9, uint8), "2");
final struct12bytesFloat = StructType([float, float, float]);

/// The largest homogenous float that goes into FPU registers on softfp and
/// arm64.
final struct16bytesFloat = StructType([float, float, float, float]);

/// This struct will be 8 byte aligned on arm.
final struct16bytesMixed = StructType([double_, int64]);

/// This struct will be 4 byte aligned on arm.
final struct16bytesMixed2 =
    StructType.disambiguate([float, float, float, int32], "2");

final struct17bytesInt = StructType([int64, int64, int8]);

/// This struct has only 1 byte field-alignmnent requirements.
final struct19bytesInt = StructType(List.filled(19, uint8));

/// The first homogenous integer struct that does not go into registers
/// anymore on arm64.
final struct20bytesInt = StructType([int32, int32, int32, int32, int32]);

/// The first homogenous float that does not go into FPU registers anymore on
/// softfp and arm64.
final struct20bytesFloat = StructType([float, float, float, float, float]);

/// Largest homogenous doubles in arm64 that goes into FPU registers.
final struct32bytesDouble = StructType([double_, double_, double_, double_]);

/// The first homogenous doubles that does not go into FPU registers anymore on
/// arm64.
final struct40bytesDouble =
    StructType([double_, double_, double_, double_, double_]);

final struct1024bytesInt = StructType(List.filled(128, uint64));

final structAlignmentInt16 = StructType([int8, int16, int8]);
final structAlignmentInt32 = StructType([int8, int32, int8]);
final structAlignmentInt64 = StructType([int8, int64, int8]);
