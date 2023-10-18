// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'c_types.dart';

/// All function types to test.
final functions = [
  ...functionsStructArguments,
  ...functionsStructReturn,
  ...functionsReturnArgument,
];

/// Functions that pass structs as arguments.
final functionsStructArguments = [
  FunctionType(List.filled(10, struct1byteInt), int64, """
Smallest struct with data.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct3bytesInt), int64, """
Not a multiple of word size, not a power of two.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct3bytesInt2), int64, """
Not a multiple of word size, not a power of two.
With alignment rules taken into account size is 4 bytes.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct4bytesInt), int64, """
Exactly word size on 32-bit architectures.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct7bytesInt), int64, """
Sub word size on 64 bit architectures.
10 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct7bytesInt2), int64, """
Sub word size on 64 bit architectures.
With alignment rules taken into account size is 8 bytes.
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
Struct only has 1-byte aligned fields to test struct alignment itself.
Tests upper bytes in the integer registers that are partly filled.
Tests stack alignment of non word size stack arguments."""),
  FunctionType(List.filled(10, struct9bytesInt2), int64, """
Argument is a single byte over a multiple of word size.
With alignment rules taken into account size is 12 or 16 bytes.
10 struct arguments will exhaust available registers.
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
      [
        // Exhaust integer registers on all architectures
        int32,
        int32,
        int32,
        int32,
        int32,
        int32,
        int32,
        int32,
        // Exhaust floating point registers on all architectures.
        double_,
        double_,
        double_,
        double_,
        double_,
        double_,
        double_,
        double_,
        // Pass all kinds of structs to exercise stack placement behavior.
        //
        // For all structs, align stack with int64, then align to 1-byte with
        // int8, then pass struct.
        int64,
        int8,
        struct1byteInt,
        int64,
        int8,
        struct4bytesInt,
        int64,
        int8,
        struct8bytesInt,
        int64,
        int8,
        struct8bytesFloat,
        int64,
        int8,
        struct8BytesMixed,
        int64,
        int8,
        structAlignmentInt16,
        int64,
        int8,
        structAlignmentInt32,
        int64,
        int8,
        structAlignmentInt64,
      ],
      double_,
      """
Test alignment and padding of 16 byte int within struct."""),
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
  FunctionType(List.filled(10, struct8bytesNestedInt), int64, """
Simple nested struct. No alignment gaps on any architectures.
10 arguments exhaust registers on all platforms."""),
  FunctionType(List.filled(10, struct8bytesNestedFloat), float, """
Simple nested struct. No alignment gaps on any architectures.
10 arguments exhaust fpu registers on all platforms."""),
  FunctionType(List.filled(10, struct8bytesNestedFloat2), float, """
Simple nested struct. No alignment gaps on any architectures.
10 arguments exhaust fpu registers on all platforms.
The nesting is irregular, testing homogenous float rules on arm and arm64,
and the fpu register usage on x64."""),
  FunctionType(List.filled(10, struct8bytesNestedMixed), double_, """
Simple nested struct. No alignment gaps on any architectures.
10 arguments exhaust all registers on all platforms."""),
  FunctionType(List.filled(2, struct16bytesNestedInt), int64, """
Deeper nested struct to test recursive member access."""),
  FunctionType(List.filled(2, struct32bytesNestedInt), int64, """
Even deeper nested struct to test recursive member access."""),
  FunctionType(
      [structNestedAlignmentInt16],
      int64,
      """
Test alignment and padding of nested struct with 16 byte int."""),
  FunctionType(
      [structNestedAlignmentInt32],
      int64,
      """
Test alignment and padding of nested struct with 32 byte int."""),
  FunctionType(
      [structNestedAlignmentInt64],
      int64,
      """
Test alignment and padding of nested struct with 64 byte int."""),
  FunctionType(List.filled(4, structNestedEvenBigger), double_, """
Return big irregular struct as smoke test."""),
  FunctionType(List.filled(4, structInlineArray), int32, """
Simple struct with inline array."""),
  FunctionType(List.filled(4, structInlineArrayIrregular), int32, """
Irregular struct with inline array."""),
  FunctionType(
      [structInlineArray100Bytes],
      int32,
      """
Regular larger struct with inline array."""),
  FunctionType(List.filled(5, struct16bytesFloatInlineNested), float, """
Arguments in FPU registers on arm hardfp and arm64.
5 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(5, struct32bytesDoubleInlineNested), double_, """
Arguments in FPU registers on arm64.
5 struct arguments will exhaust available registers."""),
  FunctionType(List.filled(10, struct16bytesMixedInlineNested), float, """
On x64, arguments are split over FP and int registers.
On x64, it will exhaust the integer registers with the 6th argument.
The rest goes on the stack.
On arm, arguments are 4 byte aligned."""),
  FunctionType(
      [
        uint8,
        struct32bytesInlineArrayMultiDimensional,
        uint8,
        struct8bytesInlineArrayMultiDimensional,
        uint8,
        struct8bytesInlineArrayMultiDimensional,
        uint8
      ],
      uint32,
      """
Test multi dimensional inline array struct as argument."""),
  FunctionType(
      [uint8, structMultiDimensionalStruct, uint8],
      uint32,
      """
Test struct in multi dimensional inline array."""),
  FunctionType(List.filled(10, struct3bytesPacked), int64, """
Small struct with mis-aligned member."""),
  FunctionType(List.filled(10, struct8bytesPacked), int64, """
Struct with mis-aligned member."""),
  FunctionType(
      [...List.filled(10, struct9bytesPacked), double_, int32, int32],
      double_,
      """
Struct with mis-aligned member.
Tests backfilling of CPU and FPU registers."""),
  FunctionType(
      [struct5bytesPacked],
      double_,
      """
This packed struct happens to have only aligned members."""),
  FunctionType(
      [struct6bytesPacked],
      double_,
      """
Check alignment of packed struct in non-packed struct."""),
  FunctionType(
      [struct6bytesPacked2],
      double_,
      """
Check alignment of packed struct array in non-packed struct."""),
  FunctionType(
      [struct15bytesPacked],
      double_,
      """
Check alignment of packed struct array in non-packed struct."""),
  FunctionType(List.filled(10, union4bytesMixed), double_, """
Check placement of mixed integer/float union."""),
  FunctionType(List.filled(10, union8bytesFloat), double_, """
Check placement of mixed floats union."""),
  FunctionType(List.filled(10, union12bytesInt), double_, """
Mixed-size union argument."""),
  FunctionType(List.filled(10, union16bytesFloat), double_, """
Union with homogenous floats."""),
  FunctionType(List.filled(10, union16bytesFloat2), double_, """
Union with homogenous floats."""),
  FunctionType(
      [
        uint8,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        struct10bytesBool,
        bool_,
      ],
      int32,
      """
Passing bools and a struct with bools.
Exhausts the registers to test bools and the bool struct alignment on the
stack."""),
  FunctionType(
      [
        uint8,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        bool_,
        structInlineArrayBool,
        bool_,
      ],
      int32,
      """
Passing bools and a struct with bools.
Exhausts the registers to test bools and the bool struct alignment on the
stack."""),
  FunctionType(
      [
        uint8,
        struct1byteBool,
      ],
      bool_,
      """
Returning a bool."""),
  FunctionType(
      [
        wchar,
        structArrayWChar,
        uintptr,
        uintptr,
        long,
        ulong,
      ],
      wchar,
      """
Returning a wchar."""),
  FunctionType(
      [
        int64,
        int64,
        int64,
        int64,
        int64,
        int64,
        int64,
        struct12bytesInt,
      ],
      int64,
      """
Struct stradles last argument register"""),
];

/// Functions that return a struct by value.
final functionsStructReturn = [
  FunctionType(struct1byteInt.memberTypes, struct1byteInt, """
Smallest struct with data."""),
  FunctionType(struct3bytesInt.memberTypes, struct3bytesInt, """
Smaller than word size return value on all architectures."""),
  FunctionType(struct3bytesInt2.memberTypes, struct3bytesInt2, """
Smaller than word size return value on all architectures.
With alignment rules taken into account size is 4 bytes."""),
  FunctionType(struct4bytesInt.memberTypes, struct4bytesInt, """
Word size return value on 32 bit architectures.."""),
  FunctionType(struct7bytesInt.memberTypes, struct7bytesInt, """
Non-wordsize return value."""),
  FunctionType(struct7bytesInt2.memberTypes, struct7bytesInt2, """
Non-wordsize return value.
With alignment rules taken into account size is 8 bytes."""),
  FunctionType(struct8bytesInt.memberTypes, struct8bytesInt, """
Return value in integer registers on many architectures."""),
  FunctionType(struct8bytesFloat.memberTypes, struct8bytesFloat, """
Return value in FP registers on many architectures."""),
  FunctionType(struct8BytesMixed.memberTypes, struct8BytesMixed, """
Return value split over FP and integer register in x64."""),
  FunctionType(struct9bytesInt.memberTypes, struct9bytesInt, """
The minimum alignment of this struct is only 1 byte based on its fields.
Test that the memory backing these structs is the right size and that
dart:ffi trampolines do not write outside this size."""),
  FunctionType(struct9bytesInt2.memberTypes, struct9bytesInt2, """
Return value in two integer registers on x64.
With alignment rules taken into account size is 12 or 16 bytes."""),
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
Return value returned in preallocated space passed by pointer on most ABIs.
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
  FunctionType(struct3bytesPacked.memberTypes, struct3bytesPacked, """
Small struct with mis-aligned member."""),
  FunctionType(struct8bytesPacked.memberTypes, struct8bytesPacked, """
Struct with mis-aligned member."""),
  FunctionType(struct9bytesPacked.memberTypes, struct9bytesPacked, """
Struct with mis-aligned member.
Tests backfilling of CPU and FPU registers."""),
  FunctionType(
      [union4bytesMixed.memberTypes.first],
      union4bytesMixed,
      """
Returning a mixed integer/float union."""),
  FunctionType(
      [union8bytesFloat.memberTypes.first],
      union8bytesFloat,
      """
Returning a floating point only union."""),
  FunctionType(
      [union12bytesInt.memberTypes.first],
      union12bytesInt,
      """
Returning a mixed-size union."""),
  FunctionType(
      [union16bytesFloat2.memberTypes.first],
      union16bytesFloat2,
      """
Returning union with homogenous floats."""),
];

/// Functions that return an argument by value.
final functionsReturnArgument = [
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
  FunctionType(
      [structInlineArray],
      structInlineArray,
      """
Test returning struct with inline array."""),
  FunctionType(
      [struct16bytesFloatInlineNested],
      struct16bytesFloatInlineNested,
      """
Return value in FPU registers on arm hardfp and arm64."""),
  FunctionType(
      [struct32bytesDoubleInlineNested],
      struct32bytesDoubleInlineNested,
      """
Return value in FPU registers on arm64."""),
  FunctionType(
      [struct16bytesMixedInlineNested],
      struct16bytesMixedInlineNested,
      """
On x64 Linux, return value is split over FP and int registers."""),
  FunctionType(structAlignmentInt16.memberTypes, structAlignmentInt16, """
Test alignment and padding of 16 byte int within struct."""),
  FunctionType(structAlignmentInt32.memberTypes, structAlignmentInt32, """
Test alignment and padding of 32 byte int within struct."""),
  FunctionType(structAlignmentInt64.memberTypes, structAlignmentInt64, """
Test alignment and padding of 64 byte int within struct."""),
  FunctionType(struct8bytesNestedInt.memberTypes, struct8bytesNestedInt, """
Simple nested struct."""),
  FunctionType(struct8bytesNestedFloat.memberTypes, struct8bytesNestedFloat, """
Simple nested struct with floats."""),
  FunctionType(
      struct8bytesNestedFloat2.memberTypes, struct8bytesNestedFloat2, """
The nesting is irregular, testing homogenous float rules on arm and arm64,
and the fpu register usage on x64."""),
  FunctionType(struct8bytesNestedMixed.memberTypes, struct8bytesNestedMixed, """
Simple nested struct with mixed members."""),
  FunctionType(struct16bytesNestedInt.memberTypes, struct16bytesNestedInt, """
Deeper nested struct to test recursive member access."""),
  FunctionType(struct32bytesNestedInt.memberTypes, struct32bytesNestedInt, """
Even deeper nested struct to test recursive member access."""),
  FunctionType(
      structNestedAlignmentInt16.memberTypes, structNestedAlignmentInt16, """
Test alignment and padding of nested struct with 16 byte int."""),
  FunctionType(
      structNestedAlignmentInt32.memberTypes, structNestedAlignmentInt32, """
Test alignment and padding of nested struct with 32 byte int."""),
  FunctionType(
      structNestedAlignmentInt64.memberTypes, structNestedAlignmentInt64, """
Test alignment and padding of nested struct with 64 byte int."""),
  FunctionType(structNestedEvenBigger.memberTypes, structNestedEvenBigger, """
Return big irregular struct as smoke test."""),
];

final compounds = [
  struct1byteBool,
  struct1byteInt,
  struct3bytesInt,
  struct3bytesInt2,
  struct4bytesInt,
  struct4bytesFloat,
  struct7bytesInt,
  struct7bytesInt2,
  struct8bytesInt,
  struct8bytesFloat,
  struct8bytesFloat2,
  struct8BytesMixed,
  struct9bytesInt,
  struct9bytesInt2,
  struct10bytesBool,
  struct12bytesFloat,
  struct12bytesInt,
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
  struct8bytesNestedInt,
  struct8bytesNestedFloat,
  struct8bytesNestedFloat2,
  struct8bytesNestedMixed,
  struct16bytesNestedInt,
  struct32bytesNestedInt,
  structNestedAlignmentInt16,
  structNestedAlignmentInt32,
  structNestedAlignmentInt64,
  structNestedBig,
  structNestedBigger,
  structNestedEvenBigger,
  structInlineArray,
  structInlineArrayBool,
  structInlineArrayIrregular,
  structInlineArray100Bytes,
  structInlineArrayBig,
  struct16bytesFloatInlineNested,
  struct32bytesDoubleInlineNested,
  struct16bytesMixedInlineNested,
  struct8bytesInlineArrayMultiDimensional,
  struct32bytesInlineArrayMultiDimensional,
  struct64bytesInlineArrayMultiDimensional,
  structMultiDimensionalStruct,
  struct3bytesPacked,
  struct3bytesPackedMembersAligned,
  struct5bytesPacked,
  struct6bytesPacked,
  struct6bytesPacked2,
  struct8bytesPacked,
  struct9bytesPacked,
  struct15bytesPacked,
  union4bytesMixed,
  union8bytesFloat,
  union12bytesInt,
  union16bytesFloat,
  union16bytesFloat2,
  structArrayWChar,
];

/// Function signatures for variadic argument tests.
final functionsVarArgs = [
  FunctionType(
    varArgsIndex: 1,
    [int64, int64],
    int64,
    "Single variadic argument.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [double_, double_],
    double_,
    "Single variadic argument.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [int64, int64, int64, int64, int64],
    int64,
    "Variadic arguments.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [double_, double_, double_, double_, double_],
    double_,
    "Variadic arguments.",
  ),
  FunctionType(
    varArgsIndex: 1,
    List.filled(20, int64),
    int64,
    "Variadic arguments exhaust registers.",
  ),
  FunctionType(
    varArgsIndex: 1,
    List.filled(20, double_),
    double_,
    "Variadic arguments exhaust registers.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [int64, int64, struct8bytesInt, int64],
    int64,
    "Variadic arguments including struct.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [double_, double_, struct32bytesDouble, double_],
    double_,
    "Variadic arguments including struct.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [double_, struct12bytesFloat, double_],
    double_,
    "Variadic arguments including struct.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [int32, struct20bytesInt, int32],
    int32,
    "Variadic arguments including struct.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [double_, struct20bytesFloat, double_],
    double_,
    "Variadic arguments including struct.",
  ),
  FunctionType(
    varArgsIndex: 2,
    [int32, int64, intptr],
    int32,
    """Regression test for variadic arguments.
https://github.com/dart-lang/sdk/issues/49460""",
  ),
  FunctionType(
    varArgsIndex: 1,
    [double_, int64, int32, double_, int64, int32],
    double_,
    "Variadic arguments mixed.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [
      int64, // Argument passed normally.
      int32, // First argument passed as varargs, misaligning stack.
      struct12bytesFloat, // Homogenous float struct, should be aligned.
    ],
    double_,
    "Variadic arguments homogenous struct stack alignment on macos_arm64.",
  ),
  FunctionType(
    varArgsIndex: 11,
    [
      ...List.filled(8, double_), // Exhaust FPU registers.
      float, // Misalign stack.
      struct12bytesFloat, // Homogenous struct, not aligned to wordsize on stack.
      int64, // Start varargs.
      int32, // Misalign stack again.
      struct12bytesFloat, // Homogenous struct, aligned to wordsize on stack.
    ],
    double_,
    "Variadic arguments homogenous struct stack alignment on macos_arm64.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [
      double_,
      int64,
      int32,
      struct20bytesInt,
      double_,
      int64,
      int32,
      struct12bytesFloat,
      int64,
    ],
    double_,
    "Variadic arguments mixed.",
  ),
  FunctionType(
    varArgsIndex: 5,
    [double_, double_, double_, double_, double_],
    double_,
    "Variadic arguments function definition, but not passing any.",
  ),
  FunctionType(
    varArgsIndex: 1,
    [
      int64,
      int64,
      int64,
      int64,
      int64,
      int64,
      int64,
      struct12bytesInt,
    ],
    int64,
    "Struct stradles last argument register, variadic",
  ),
];

final struct1byteBool = StructType([bool_]);
final struct1byteInt = StructType([int8]);
final struct3bytesInt = StructType(List.filled(3, uint8));
final struct3bytesInt2 = StructType.disambiguate([int16, int8], "2ByteAligned");
final struct4bytesInt = StructType([int16, int16]);
final struct4bytesFloat = StructType([float]);
final struct7bytesInt = StructType(List.filled(7, uint8));
final struct7bytesInt2 =
    StructType.disambiguate([int32, int16, int8], "4ByteAligned");
final struct8bytesInt = StructType([int16, int16, int32]);
final struct8bytesFloat = StructType([float, float]);
final struct8bytesFloat2 = StructType([double_]);
final struct8BytesMixed = StructType([float, int16, int16]);
final struct9bytesInt = StructType(List.filled(9, uint8));
final struct9bytesInt2 =
    StructType.disambiguate([int64, int8], "4Or8ByteAligned");
final struct10bytesBool = StructType(List.filled(10, bool_));
final struct12bytesFloat = StructType([float, float, float]);
final struct12bytesInt = StructType([int32, int32, int32]);

/// The largest homogenous float that goes into FPU registers on softfp and
/// arm64.
final struct16bytesFloat = StructType([float, float, float, float]);

/// This struct will be 8 byte aligned on arm.
final struct16bytesMixed = StructType([double_, int64]);

/// This struct will be 4 byte aligned on arm.
final struct16bytesMixed2 =
    StructType.disambiguate([float, float, float, int32], "2");

final struct17bytesInt = StructType([int64, int64, int8]);

/// This struct has only 1 byte field-alignment requirements.
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

final struct8bytesNestedInt = StructType([struct4bytesInt, struct4bytesInt]);
final struct8bytesNestedFloat =
    StructType([struct4bytesFloat, struct4bytesFloat]);
final struct8bytesNestedFloat2 =
    StructType.disambiguate([struct4bytesFloat, float], "2");
final struct8bytesNestedMixed =
    StructType([struct4bytesInt, struct4bytesFloat]);

final struct16bytesNestedInt =
    StructType([struct8bytesNestedInt, struct8bytesNestedInt]);
final struct32bytesNestedInt =
    StructType([struct16bytesNestedInt, struct16bytesNestedInt]);

final structNestedAlignmentInt16 = StructType.disambiguate(
    List.filled(2, structAlignmentInt16), structAlignmentInt16.name);
final structNestedAlignmentInt32 = StructType.disambiguate(
    List.filled(2, structAlignmentInt32), structAlignmentInt32.name);
final structNestedAlignmentInt64 = StructType.disambiguate(
    List.filled(2, structAlignmentInt64), structAlignmentInt64.name);

final structNestedBig = StructType.override([
  uint16,
  struct8bytesNestedMixed,
  uint16,
  struct8bytesNestedFloat2,
  uint16,
  struct8bytesNestedFloat,
  uint16
], "NestedIrregularBig");
final structNestedBigger = StructType.override(
    [structNestedBig, struct8bytesNestedMixed, float, double_],
    "NestedIrregularBigger");
final structNestedEvenBigger = StructType.override(
    [uint64, structNestedBigger, structNestedBigger, double_],
    "NestedIrregularEvenBigger");

final structInlineArray = StructType([FixedLengthArrayType(uint8, 8)]);

final structInlineArrayBool = StructType([FixedLengthArrayType(bool_, 10)]);

final structInlineArrayIrregular = StructType.override(
    [FixedLengthArrayType(struct3bytesInt2, 2), uint8], "InlineArrayIrregular");

final structInlineArray100Bytes = StructType.override(
    [FixedLengthArrayType(uint8, 100)], "InlineArray100Bytes");

final structInlineArrayBig = StructType.override(
    [uint32, uint32, FixedLengthArrayType(uint8, 4000)], "InlineArrayBig");

/// The largest homogenous float that goes into FPU registers on softfp and
/// arm64. This time with nested structs and inline arrays.
final struct16bytesFloatInlineNested = StructType.override([
  StructType([float]),
  FixedLengthArrayType(StructType([float]), 2),
  float,
], "Struct16BytesHomogeneousFloat2");

/// The largest homogenous float that goes into FPU registers on arm64.
/// This time with nested structs and inline arrays.
final struct32bytesDoubleInlineNested = StructType.override([
  StructType([double_]),
  FixedLengthArrayType(StructType([double_]), 2),
  double_,
], "Struct32BytesHomogeneousDouble2");

/// This struct is split over a CPU and FPU register in x64 Linux.
/// This time with nested structs and inline arrays.
final struct16bytesMixedInlineNested = StructType.override([
  StructType([float]),
  FixedLengthArrayType(StructType([float, int16, int16]), 1),
  FixedLengthArrayType(int16, 2),
], "Struct16BytesMixed3");

final struct8bytesInlineArrayMultiDimensional = StructType([
  FixedLengthArrayType.multi(uint8, [2, 2, 2])
]);

final struct32bytesInlineArrayMultiDimensional = StructType([
  FixedLengthArrayType.multi(uint8, [2, 2, 2, 2, 2])
]);

final struct64bytesInlineArrayMultiDimensional = StructType([
  FixedLengthArrayType.multi(uint8, [2, 2, 2, 2, 2, 2])
]);

final structMultiDimensionalStruct = StructType([
  FixedLengthArrayType.multi(struct1byteInt, [2, 2])
]);

final struct3bytesPacked = StructType([int8, int16], packing: 1);

final struct3bytesPackedMembersAligned =
    StructType.disambiguate([int8, int16], "MembersAligned", packing: 1);

final struct5bytesPacked = StructType([float, uint8], packing: 1);

/// The float in the nested struct is not aligned.
final struct6bytesPacked = StructType([uint8, struct5bytesPacked]);

/// The second element in the array has a nested misaligned int16.
final struct6bytesPacked2 =
    StructType([FixedLengthArrayType(struct3bytesPackedMembersAligned, 2)]);

final struct8bytesPacked =
    StructType([uint8, uint32, uint8, uint8, uint8], packing: 1);

final struct9bytesPacked = StructType([uint8, double_], packing: 1);

/// The float in the nested struct is aligned in the first element in the
/// inline array, but not in the subsequent ones.
final struct15bytesPacked =
    StructType([FixedLengthArrayType(struct5bytesPacked, 3)]);

/// Mixed integer and float. Tests whether calling conventions put this in
/// integer registers or not.
final union4bytesMixed = UnionType([uint32, float]);

/// Different types of float. Tests whether calling conventions put this in
/// FPU registers or not.
final union8bytesFloat = UnionType([double_, struct8bytesFloat]);

/// This union has a size of 12, because of the 4-byte alignment of the first
/// member.
final union12bytesInt = UnionType([struct8bytesInt, struct9bytesInt]);

/// This union has homogenous floats of the same sizes.
final union16bytesFloat =
    UnionType([FixedLengthArrayType(float, 4), struct16bytesFloat]);

/// This union has homogenous floats of different sizes.
final union16bytesFloat2 =
    UnionType([struct8bytesFloat, struct12bytesFloat, struct16bytesFloat]);

/// This struct contains an AbiSpecificInt type.
final structArrayWChar = StructType([FixedLengthArrayType(wchar, 10)]);
