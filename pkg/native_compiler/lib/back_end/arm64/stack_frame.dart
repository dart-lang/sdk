// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/misc.dart';
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/safepoint.dart';
import 'package:native_compiler/back_end/stack_frame.dart';

/// Stack frame layout used on arm64.
///
/// Currently stack frame has the following layout (stack grows down):
/// ```
///  (stackSlotIndex)
///  |
///  V     [param 1]
///        ...
/// -5     [param N]
///        -------------------------------------------------------------+
///        [saved LR]                                                   |
/// FP ->  [saved FP]                                                   | Fixed frame
///        [Code]                                                       | (numberOfFixedSlots)
///        [saved tagged ObjectPool]                                    |
///        -------------------------------------------------------------+
///  0     [suspend state (only for async/async*/sync* functions)]      |
///        [shadow space for optional parameters]                       |
///  |     [spill slot 0]                                               | Allocated frame
///  V     ...                                                          | (frameSizeInSlots)
///        [spill slot M]                                               |
/// S-1    [outgoing arguments area]                                    |
///        -------------------------------------------------------------+
///        (callee frame)
/// ```
///
/// Stack slots are numbered in the order of growing stack, starting with the
/// slot immediately following fixed frame. This numbering matches the
/// bit numbering in the stack maps used by safepoints.
///
/// TODO: add catch block entry parameters area.
final class Arm64StackFrame extends StackFrame {
  /// Stack frame alignment in stack slots (words).
  static const int frameSizeAlignmentInSlots = 2;

  /// Number of fixed frame slots; distance between the last parameter
  /// slot and the first spill slot in words.
  static const int numberOfFixedSlots = 4;

  /// Offset of the last parameter slot, relative to FP
  static const int lastParameterOffsetFromFP = 2 * wordSize;

  /// Offset of the saved pool pointer relative to FP.
  static const int poolPointerOffsetFromFP = -2 * wordSize;

  /// Offset of the 0-th allocated stack slot, relative to FP
  static const int _firstSlotOffsetFromFP = -3 * wordSize;

  /// Number of stack slots used by suspend state.
  late final int _suspendStateStackSlots = (function.isSuspendable ? 1 : 0);

  /// Number of stack slots reserved for shadow parameters.
  late final int _shadowParametersStackSlots =
      ((function.hasOptionalPositionalParameters ||
              function.hasNamedParameters) &&
          function.numberOfParameters > argumentRegisters.length)
      ? function.numberOfParameters - argumentRegisters.length
      : 0;

  late final int _reservedStackSlots =
      _suspendStateStackSlots + _shadowParametersStackSlots;

  Arm64StackFrame(super.function) {
    reserveSpillSlots(_reservedStackSlots);
  }

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
      case AllocateClosure():
        return 4; // Result + 3 arguments for AllocateClosure runtime call.
      case AllocateContext():
        return 2; // Result + 1 argument for AllocateContext runtime call.
      case AllocateList():
        return 3; // Result + 2 arguments for AllocateList runtime call.
      case AllocateRecord():
        return 2; // Result + 1 argument for AllocateRecord runtime call.
      case TypeLiteral():
        return 4; // Result + 3 arguments for InstantiateType runtime call.
      case TypeCast():
        return 3; // Result + 2 arguments for TypeError runtime call.
      case TypeTest():
        return 6; // Result + 5 arguments for Instanceof runtime call.
      case Suspend(:var op) when op == .asyncYield || op == .asyncYieldStar:
        return 2; // 2 arguments for _AsyncStarStreamController.add/addStream call.
      case Throw(kind: .exception):
        return 2; // Result + 1 argument for Throw runtime call.
      case Throw(kind: .rethrowException):
        return 4; // Result + 3 argument for ReThrow runtime call.
      case NullCheck():
        return 1; // Result + 0 arguments for NullCastError runtime call.
      default:
        return 0;
    }
  }

  int _slotOffsetFromFP(int stackSlotIndex) =>
      _firstSlotOffsetFromFP - stackSlotIndex * wordSize;

  @override
  int offsetFromFP(StackLocation location) {
    assert(isFinalized);
    return _slotOffsetFromFP(location.stackSlotIndex);
  }

  @override
  int get suspendStateOffsetFromFP {
    assert(function.isSuspendable);
    return _slotOffsetFromFP(0);
  }

  int _parameterSlotIndex(int paramIndex) {
    final numParams = function.numberOfParameters;
    assert(0 <= paramIndex && paramIndex < numParams);
    if (function.hasOptionalPositionalParameters ||
        function.hasNamedParameters) {
      assert(paramIndex >= argumentRegisters.length);
      return _suspendStateStackSlots + (paramIndex - argumentRegisters.length);
    } else {
      return -numberOfFixedSlots - numParams + paramIndex;
    }
  }

  @override
  int shadowParameterOffsetFromFP(int paramIndex) {
    assert(
      function.hasOptionalPositionalParameters || function.hasNamedParameters,
    );
    assert(paramIndex >= argumentRegisters.length);
    assert(paramIndex < function.numberOfParameters);
    return _slotOffsetFromFP(_parameterSlotIndex(paramIndex));
  }

  @override
  ParameterStackLocation getParameterSlot(
    int paramIndex,
    RegisterClass registerClass,
  ) {
    return ParameterStackLocation(
      paramIndex,
      _parameterSlotIndex(paramIndex),
      registerClass,
    );
  }

  @override
  late final int frameSizeInSlots = roundUp(
    usedSpillSlots + maxArgumentsStackSlots,
    frameSizeAlignmentInSlots,
  );

  @override
  void recordReservedLocations(Safepoint safepoint) {
    // TODO: unboxed parameters
    safepoint.addLiveStackSlots(0, _reservedStackSlots, isObjectPointer: true);
  }
}
