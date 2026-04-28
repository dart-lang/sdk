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
///        [suspend state (only for async/async*/sync* functions)]
///        [shadow space for optional parameters]
///        [spill slot 0]
///        ...
///        [spill slot M]
///        [outgoing arguments area]
/// ```
/// TODO: add catch block entry parameters area.
final class Arm64StackFrame extends StackFrame {
  /// Stack frame alignment.
  static const int alignment = 2 * wordSize;

  /// Number of fixed frame slots; distance between the last parameter
  /// slot and the first spill slot in words.
  static const int numberOfFixedSlots = 4;

  /// Offset of the last parameter slot, relative to FP
  static const int lastParameterOffsetFromFP = 2 * wordSize;

  /// Offset of the saved pool pointer relative to FP.
  static const int poolPointerOffsetFromFP = -2 * wordSize;

  /// Offset of the suspend state, relative to FP
  static const int _suspendStateOffsetFromFP = -3 * wordSize;

  /// Number of stack slots used by suspend state.
  late final int _suspendStateStackSlots = (function.isSuspendable ? 1 : 0);

  /// Offset of the first shadow parameter, relative to FP
  late final int _shadowParametersOffsetFromFP =
      _suspendStateOffsetFromFP - _suspendStateStackSlots * wordSize;

  /// Number of stack slots reserved for shadow parameters.
  late final int _shadowParametersStackSlots =
      ((function.hasOptionalPositionalParameters ||
              function.hasNamedParameters) &&
          function.numberOfParameters > argumentRegisters.length)
      ? function.numberOfParameters - argumentRegisters.length
      : 0;

  late final int _firstSpillSlotOffsetFromFP =
      _shadowParametersOffsetFromFP - _shadowParametersStackSlots * wordSize;

  Arm64StackFrame(super.function);

  @override
  int spillSlotSizeInWords(RegisterClass registerClass) => 1;

  @override
  int spillSlotAlignmentInWords(RegisterClass registerClass) => 1;

  @override
  int argumentsStackSlots(Instruction instr) {
    // TODO: pass arguments on registers
    switch (instr) {
      case CallInstruction():
        return instr.inputCount;
      case TypeLiteral():
        return 4; // Result + 3 arguments for InstantiateType runtime call.
      case TypeTest():
        return 6; // Result + 5 arguments for Instanceof runtime call.
      case Suspend(:var op) when op == .asyncYield || op == .asyncYieldStar:
        return 2; // 2 arguments for _AsyncStarStreamController.add/addStream call.
      default:
        return 0;
    }
  }

  @override
  int offsetFromFP(StackLocation location) {
    assert(isFinalized);
    switch (location) {
      case SpillSlot():
        return _firstSpillSlotOffsetFromFP - location.index * wordSize;
      case ParameterStackLocation():
        final paramIndex = location.paramIndex;
        final numParams = function.numberOfParameters;
        assert(0 <= paramIndex && paramIndex < numParams);
        if (function.hasOptionalPositionalParameters ||
            function.hasNamedParameters) {
          return shadowParameterOffsetFromFP(paramIndex);
        } else {
          return lastParameterOffsetFromFP +
              (numParams - paramIndex - 1) * wordSize;
        }
    }
  }

  @override
  int get suspendStateOffsetFromFP {
    assert(function.isSuspendable);
    return _suspendStateOffsetFromFP;
  }

  @override
  int shadowParameterOffsetFromFP(int paramIndex) {
    assert(
      function.hasOptionalPositionalParameters || function.hasNamedParameters,
    );
    assert(paramIndex >= argumentRegisters.length);
    assert(paramIndex < function.numberOfParameters);
    return _shadowParametersOffsetFromFP -
        (paramIndex - argumentRegisters.length) * wordSize;
  }

  @override
  int get frameSizeToAllocate => roundUp(
    (_suspendStateStackSlots +
            _shadowParametersStackSlots +
            usedSpillSlots +
            maxArgumentsStackSlots) *
        wordSize,
    alignment,
  );
}
