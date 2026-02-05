// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/misc.dart';
import 'package:native_compiler/back_end/locations.dart';

/// Base class for architecture-specific stack frame layout.
abstract base class StackFrame {
  final CFunction function;

  int _usedSpillSlots = 0;
  int _maxArgumentsStackSlots = 0;
  bool _finalized = false;

  StackFrame(this.function);

  bool get isFinalized => _finalized;

  int get usedSpillSlots {
    assert(isFinalized);
    return _usedSpillSlots;
  }

  int get maxArgumentsStackSlots {
    assert(isFinalized);
    return _maxArgumentsStackSlots;
  }

  /// Size of the spill slot with given [registerClass].
  int spillSlotSizeInWords(RegisterClass registerClass);

  /// Alignment of the spill slot with given [registerClass].
  int spillSlotAlignmentInWords(RegisterClass registerClass);

  /// Number of stack slots required for call [instr].
  int argumentsStackSlots(CallInstruction instr);

  /// Offset of [location] relative to the frame pointer, in bytes.
  /// Should be used only after the frame is finalized.
  int offsetFromFP(StackLocation location);

  /// Frame size to allocate, in bytes.
  /// Should be used only after the frame is finalized.
  int get frameSizeToAllocate;

  /// Allocate a new spill slot.
  SpillSlot allocateSpillSlot(RegisterClass registerClass) {
    assert(!_finalized);
    final size = spillSlotSizeInWords(registerClass);
    final alignment = spillSlotAlignmentInWords(registerClass);
    _usedSpillSlots = roundUp(_usedSpillSlots, alignment);
    final slot = SpillSlot(_usedSpillSlots);
    _usedSpillSlots += size;
    return slot;
  }

  /// Allocate outgoing argument slots for [instr].
  void allocateArgumentsSlots(CallInstruction instr) {
    final stackSlots = argumentsStackSlots(instr);
    if (stackSlots > _maxArgumentsStackSlots) {
      _maxArgumentsStackSlots = stackSlots;
    }
  }

  /// Finish stack frame allocation.
  /// No new spill slots can be allocated past this point.
  void finalize() {
    _finalized = true;
  }
}
