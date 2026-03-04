// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/misc.dart';
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/stack_frame.dart';

/// Stack frame layout used on arm64.
///
/// Currently stack frame has the following layout (stack grows down):
/// ```
///        [param 1]
///        ...
///        [param N]
///        [saved LR]
/// FP ->  [saved FP]
///        [Code]
///        [saved tagged ObjectPool]
///        [spill slot 0]
///        ...
///        [spill slot M]
///        [outgoing arguments area]
/// ```
/// TODO: add catch block entry parameters area.
final class Arm64StackFrame extends StackFrame {
  /// Number of fixed frame slots; distance between the last parameter
  /// slot and the first spill slot in words.
  static const int numberOfFixedSlots = 4;

  /// Offset of the last parameter slot, relative to FP
  static const int lastParameterOffsetFromFP = 2 * wordSize;

  /// Offset of the saved pool pointer relative to FP.
  static const int poolPointerOffsetFromFP = -2 * wordSize;

  /// Offset of the first spill slot, relative to FP
  static const int firstSpillSlotOffsetFromFP = -3 * wordSize;

  /// Stack frame alignment.
  static const int alignment = 2 * wordSize;

  Arm64StackFrame(super.function);

  @override
  int spillSlotSizeInWords(RegisterClass registerClass) => 1;

  @override
  int spillSlotAlignmentInWords(RegisterClass registerClass) => 1;

  @override
  int argumentsStackSlots(CallInstruction instr) {
    // TODO: pass arguments on registers
    return instr.inputCount;
  }

  @override
  int offsetFromFP(StackLocation location) {
    assert(isFinalized);
    switch (location) {
      case SpillSlot():
        return firstSpillSlotOffsetFromFP - location.index * wordSize;
      case ParameterStackLocation():
        final paramIndex = location.paramIndex;
        final numParams = function.numberOfParameters;
        assert(0 <= paramIndex && paramIndex < numParams);
        return lastParameterOffsetFromFP +
            (numParams - paramIndex - 1) * wordSize;
    }
  }

  @override
  int get frameSizeToAllocate =>
      roundUp((usedSpillSlots + maxArgumentsStackSlots) * wordSize, alignment);
}
