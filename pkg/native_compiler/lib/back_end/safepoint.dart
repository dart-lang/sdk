// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/utils/bit_vector.dart';
import 'package:native_compiler/back_end/locations.dart';

/// A point in the program where execution state is well-defined.
///
/// [Safepoint] records live registers and stack slots.
/// This information is used to save/restore execution state.
/// Also, [Safepoint] records which registers and stack slots contain
/// object pointers, so GC can scan and update them.
/// All Dart calls and non-leaf runtime calls are safepoints.
/// Certain leaf runtime calls are also safepoints if they need to preserve
/// state in a slow path.
class Safepoint {
  static final BitVector _emptyStackMap = BitVector(0);

  /// Spill slots with object pointers at this safepoint.
  BitVector _stackMap = _emptyStackMap;

  /// General-purpose registers with live values.
  RegisterSet _liveRegs = RegisterSet();

  /// Floating-point registers with live values.
  RegisterSet _liveFPRegs = RegisterSet();

  /// General-purpose registers with object pointers.
  RegisterSet _objectRegs = RegisterSet();

  BitVector get stackMap => _stackMap;
  RegisterSet get liveRegs => _liveRegs;
  RegisterSet get liveFPRegs => _liveFPRegs;
  RegisterSet get objectRegs => _objectRegs;

  @pragma("vm:never-inline")
  void _growStackMap(int bit) {
    int size = bit + 1;
    // Exponential growth to avoid quadratic behavior.
    size += size >> 1;
    _stackMap = _stackMap.expand(size);
  }

  /// Record live location [loc] at this safepoint.
  void addLiveLocation(Location loc, {required bool isObjectPointer}) {
    switch (loc) {
      case Register():
        _liveRegs = _liveRegs.add(loc);
        if (isObjectPointer) {
          _objectRegs = _objectRegs.add(loc);
        }
        break;
      case FPRegister():
        assert(!isObjectPointer);
        _liveFPRegs = _liveFPRegs.add(loc);
        break;
      case SpillSlot():
        if (isObjectPointer) {
          final bit = loc.stackSlotIndex;
          if (bit >= _stackMap.capacity) {
            _growStackMap(bit);
          }
          _stackMap.add(bit);
        }
        break;
      default:
        throw 'Unexpected ${loc.runtimeType} $loc';
    }
  }

  /// Record live stack slots in the range [firstStackSlotIndex]..[firstStackSlotIndex]+[numSlots]-1
  /// at this safepoint.
  void addLiveStackSlots(
    int firstStackSlotIndex,
    int numSlots, {
    required bool isObjectPointer,
  }) {
    assert(firstStackSlotIndex >= 0);
    assert(numSlots >= 0);
    if (isObjectPointer && numSlots > 0) {
      if (firstStackSlotIndex + numSlots > _stackMap.capacity) {
        _growStackMap(firstStackSlotIndex + numSlots - 1);
      }
      for (var i = 0; i < numSlots; ++i) {
        _stackMap.add(firstStackSlotIndex + i);
      }
    }
  }
}

extension type const RegisterSet._(int _raw) {
  static const int _maxNumberOfRegisters = 64;

  const RegisterSet() : this._(0);

  @pragma("vm:prefer-inline")
  static int _mask(PhysicalRegister r) {
    final index = r.index;
    assert((0 <= index) && (index < _maxNumberOfRegisters));
    return 1 << index;
  }

  @pragma("vm:prefer-inline")
  bool contains(PhysicalRegister r) => (_raw & _mask(r)) != 0;

  @pragma("vm:prefer-inline")
  RegisterSet add(PhysicalRegister r) => RegisterSet._(_raw | _mask(r));

  @pragma("vm:prefer-inline")
  RegisterSet remove(PhysicalRegister r) => RegisterSet._(_raw & ~_mask(r));

  List<PhysicalRegister> elements(List<PhysicalRegister> regs) => [
    for (final r in regs)
      if (contains(r)) r,
  ];
}
