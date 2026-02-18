// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math show min, max;
import 'dart:typed_data';

import 'package:native_compiler/back_end/back_end_state.dart';
import 'package:native_compiler/back_end/constraints.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:cfg/ir/liveness_analysis.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/passes/pass.dart';
import 'package:native_compiler/utils/interval_list.dart';

abstract base class RegisterAllocator extends Pass {
  final BackEndState backEndState;

  RegisterAllocator(this.backEndState) : super('RegisterAllocation');
}

/// Linear scan register allocator.
///
/// Allocates registers on the linearized control flow.
/// Live ranges are represented as a sequence of intervals.
///
/// The original idea of linear scan register allocation is described in
/// Massimiliano Poletto and Vivek Sarkar "Linear scan register allocation" (1999).
///
/// This variant of linear scan is largerly based on
/// "Linear Scan Register Allocation for the Java HotSpot Client Compiler",
/// by Christian Wimmer (2004).
/// http://www.christianwimmer.at/Publications/Wimmer04a/Wimmer04a.pdf
///
final class LinearScanRegisterAllocator extends RegisterAllocator {
  // Step of instruction positions in the linearized control flow.
  // Increment positions by 2 to leave space for ParallelMove instructions
  // which can be inserted later between instructions.
  static const int step = 2;

  static const bool trace = const bool.fromEnvironment('trace.regalloc');

  static const int maxPosition = 0x7fffffff;

  final Constraints constraints;

  /// Instruction id -> instruction position in the
  /// linearized control flow.
  late final Int32List _instructionPos;

  /// Instruction position ~/ step -> instruction id.
  late final Int32List _instructionByPos;

  /// Instruction id -> LiveRange corresponding to the instruction output.
  late final List<LiveRange?> _liveRanges;

  /// Locations of instruction inputs/outputs/temps.
  final Map<OperandId, Location> _operandLocations = {};

  /// Live ranges corresponding to the fixed register locations.
  late final List<LiveRange?> _cpuRegLiveRanges;
  late final List<LiveRange?> _fpuRegLiveRanges;

  /// Register index -> [Location].
  late List<Location?> _registerLocations;

  /// List of live ranges which were not handled yet by [allocate].
  late List<LiveRange> _unhandled;
  int _unhandledIndex = -1;

  /// For each register, list of live ranges allocated to this register,
  /// or null if register is not allocatable.
  late List<List<LiveRange>?> _allocated;

  LinearScanRegisterAllocator(super.backEndState, this.constraints);

  RegisterClass registerClass(Definition instr) =>
      instr.type is DoubleType ? RegisterClass.fpu : RegisterClass.cpu;

  int instructionPos(Instruction instr) => _instructionPos[instr.id];
  int blockStartPos(Block block) => instructionPos(block);
  int blockEndPos(Block block) => instructionPos(block.lastInstruction) + step;

  Instruction instructionByPos(int pos) =>
      graph.instructions[_instructionByPos[pos ~/ step]];

  LiveRange liveRangeFor(Definition instr) {
    assert(instr is! Constant);
    return _liveRanges[instr.id] ??= LiveRange(registerClass(instr));
  }

  LiveRange regLiveRange(PhysicalRegister r) => (r is Register)
      ? (_cpuRegLiveRanges[r.index] ??= LiveRange(
          RegisterClass.cpu,
          isPhysical: true,
        ))
      : (_fpuRegLiveRanges[r.index] ??= LiveRange(
          RegisterClass.fpu,
          isPhysical: true,
        ));

  @override
  void run() {
    numberInstructions();

    final liveness = SSALivenessAnalysis(graph);
    liveness.analyze();

    buildLiveRanges(liveness);

    coalesceLiveRanges();

    allocate(
      RegisterClass.cpu,
      constraints.getNumberOfRegisters(),
      constraints.getAllocatableRegisters(),
      _cpuRegLiveRanges,
    );
    allocate(
      RegisterClass.fpu,
      constraints.getNumberOfFPRegisters(),
      constraints.getAllocatableFPRegisters(),
      _fpuRegLiveRanges,
    );

    resolveDataFlow(liveness);

    backEndState.operandLocations = _operandLocations;
    backEndState.stackFrame.finalize();
  }

  /// Number instructions in the linearized control flow.
  void numberInstructions() {
    _instructionPos = Int32List(graph.instructions.length);
    _instructionByPos = Int32List(graph.instructions.length + 1);
    // Reserve 0 for uninitialized value, use even positions
    // for the instructions.
    int pos = step;
    for (final block in backEndState.codeGenBlockOrder) {
      _instructionPos[block.id] = pos;
      _instructionByPos[pos ~/ step] = block.id;
      pos += step;
      for (final instr in block) {
        if (instr is Phi) {
          // All Phis have the same position as their Block.
          _instructionPos[instr.id] = blockStartPos(block);
        } else {
          _instructionPos[instr.id] = pos;
          _instructionByPos[pos ~/ step] = instr.id;
          pos += step;
        }
      }
      assert(pos == blockEndPos(block));
    }

    errorContext.annotator = (Instruction instr) =>
        '[${instructionPos(instr)}]';
  }

  void buildLiveRanges(SSALivenessAnalysis liveness) {
    _liveRanges = List.filled(graph.instructions.length, null, growable: true);
    _cpuRegLiveRanges = List.filled(constraints.getNumberOfRegisters(), null);
    _fpuRegLiveRanges = List.filled(constraints.getNumberOfFPRegisters(), null);

    for (final block in backEndState.codeGenBlockOrder.reversed) {
      final blockStart = blockStartPos(block);
      final blockEnd = blockEndPos(block);

      // Add intervals for values which are live-out.
      for (final instrId in liveness.liveOut(block).elements) {
        final instr = graph.instructions[instrId] as Definition;
        if (instr is! Constant) {
          final liveRange = liveRangeFor(instr);
          liveRange.addInterval(blockStart, blockEnd);
        }
      }

      // Add uses in the Phis in the successor block.
      if (block.successors.length == 1) {
        final succ = block.successors.single;
        if (succ is JoinBlock) {
          final int predIndex = succ.predecessors.indexOf(block);
          assert(predIndex >= 0);
          for (final phi in succ.phis) {
            final input = phi.inputDefAt(predIndex);
            if (input is! Constant) {
              final inputConstr = constraints
                  .getConstraints(phi)!
                  .inputs[predIndex]!;
              final operandId = OperandId.input(phi.id, predIndex);
              final liveRange = liveRangeFor(input);
              _processInput(phi, liveRange, blockEnd, inputConstr, operandId);
            }
          }
        }
      }

      for (final instr in block.reversed) {
        if (instr is CallInstruction) {
          backEndState.stackFrame.allocateArgumentsSlots(instr);
        }
        final pos = instructionPos(instr);
        final constr = constraints.getConstraints(instr);
        if (constr == null) {
          continue;
        }
        // Ignore Phis as they are processed in the predecessor blocks.
        if (instr is! Phi) {
          // Process inputs.
          for (int i = 0, n = instr.inputCount; i < n; ++i) {
            final input = instr.inputDefAt(i);
            final inputConstr = constr.inputs[i];
            final operandId = OperandId.input(instr.id, i);
            if (input is Constant) {
              if (inputConstr != null) {
                _processConstantInput(
                  instr,
                  input.value,
                  pos,
                  inputConstr,
                  operandId,
                );
              }
            } else {
              final liveRange = liveRangeFor(input);
              // Extend range up to block start position.
              // It will be truncated by the definition if needed.
              liveRange.addInterval(blockStart, pos);
              if (inputConstr != null) {
                _processInput(instr, liveRange, pos, inputConstr, operandId);
              }
            }
          }
        }
        // Process temps.
        for (int i = 0, n = constr.temps.length; i < n; ++i) {
          final operandId = OperandId.temp(instr.id, i);
          _processTemp(pos, constr.temps[i], operandId);
        }
        // Process output.
        if (instr is Definition && instr is! Constant) {
          final operandId = OperandId.result(instr.id);
          final liveRange = liveRangeFor(instr);
          final resultConstr = constr.result;
          liveRange.defineAt(
            instructionPos(instr) +
                ((resultConstr is PhysicalRegister ||
                        resultConstr is ParameterStackLocation)
                    ? 1
                    : 0),
          );
          if (resultConstr != null) {
            _processOutput(instr, liveRange, pos, resultConstr, operandId);
          }
        }
      }
    }

    errorContext.annotator = (Instruction instr) {
      if (instr is ParallelMove) return null;
      return '[${instructionPos(instr)}]' +
          ((instr is Definition && instr is! Constant)
              ? ' ${liveRangeFor(instr)}'
              : '');
    };

    if (trace) {
      print(
        IrToText(
          graph,
          printDominators: true,
          printLoops: true,
          annotator: errorContext.annotator,
        ).toString(),
      );
    }
  }

  void _processInput(
    Instruction instr,
    LiveRange liveRange,
    int pos,
    Constraint constr,
    OperandId operandId,
  ) {
    if (constr is PhysicalRegister) {
      regLiveRange(constr).addInterval(pos, pos + 1);
      final loc = liveRange.addUse(pos - 1, constr);
      _insertMoveBefore(instr, ParallelMoveStage.input, loc, constr);
      _operandLocations[operandId] = constr;
    } else {
      final loc = liveRange.addUse(pos - 1, constr);
      _operandLocations[operandId] = loc;
    }
  }

  // TODO: allocate constants to registers.
  void _processConstantInput(
    Instruction instr,
    ConstantValue value,
    int pos,
    Constraint constr,
    OperandId operandId,
  ) {
    if (constr is PhysicalRegister) {
      _insertMoveBefore(instr, ParallelMoveStage.input, null, constr, value);
      regLiveRange(constr).addInterval(pos, pos + 1);
      _operandLocations[operandId] = constr;
    } else {
      final liveRange = LiveRange(constr.registerClass);
      _liveRanges.add(liveRange);
      liveRange.addInterval(pos - 1, pos);
      final loc = liveRange.addUse(pos - 1, constr);
      _insertMoveBefore(instr, ParallelMoveStage.input, null, loc, value);
      _operandLocations[operandId] = loc;
    }
  }

  void _processTemp(int pos, Constraint constr, OperandId operandId) {
    if (constr is PhysicalRegister) {
      regLiveRange(constr).addInterval(pos, pos + 1);
      _operandLocations[operandId] = constr;
    } else {
      final liveRange = LiveRange(constr.registerClass);
      _liveRanges.add(liveRange);
      liveRange.addInterval(pos, pos + 1);
      final loc = liveRange.addUse(pos, constr);
      _operandLocations[operandId] = loc;
    }
  }

  void _processOutput(
    Definition instr,
    LiveRange liveRange,
    int pos,
    Constraint constr,
    OperandId operandId,
  ) {
    assert(instr is! ControlFlowInstruction);
    if (constr is PhysicalRegister) {
      regLiveRange(constr).addInterval(pos, pos + 1);
      _operandLocations[operandId] = constr;
      if (instr.hasUses) {
        final loc = liveRange.addUse(pos + 1, constr);
        _insertMoveBefore(
          _nextInstruction(instr),
          ParallelMoveStage.output,
          constr,
          loc,
        );
      }
    } else if (constr is ParameterStackLocation) {
      assert(liveRange.splitFrom == null);
      liveRange.spillSlot = constr;
      _operandLocations[operandId] = constr;
      if (instr.hasUses) {
        final loc = liveRange.addUse(pos + 1, constr);
        _insertMoveBefore(
          _nextInstruction(instr),
          ParallelMoveStage.output,
          constr,
          loc,
        );
      }
    } else {
      final loc = liveRange.addUse(pos, constr);
      _operandLocations[operandId] = loc;
    }
  }

  ParallelMove _parallelMoveBefore(Instruction instr, ParallelMoveStage stage) {
    assert(instr is! Phi);
    assert(instr is! Constant);
    assert(instr is! ParallelMove);
    for (;;) {
      Instruction? prev = instr.previous;
      if (prev is! ParallelMove || prev.stage.index < stage.index) {
        break;
      }
      if (prev.stage == stage) {
        return prev;
      }
      instr = prev;
    }
    final move = ParallelMove(instr.graph, stage);
    move.insertBefore(instr);
    return move;
  }

  void _insertMoveBefore(
    Instruction instr,
    ParallelMoveStage stage,
    Location? src,
    Location dst, [
    ConstantValue? value,
  ]) {
    ParallelMove move = _parallelMoveBefore(instr, stage);
    MoveOp moveOp;
    if (src == null) {
      moveOp = LoadConstant(value!, dst);
    } else {
      assert(value == null);
      moveOp = Move(src, dst);
    }
    move.moves.add(moveOp);
  }

  /// Returns the instruction after [instr], skipping all [ParallelMove]
  /// instructions in between.
  Instruction _nextInstruction(Instruction instr) {
    instr = instr.next!;
    while (instr is ParallelMove) {
      instr = instr.next!;
    }
    return instr;
  }

  /// Tries to merge live ranges which would benefit from
  /// allocation to the same location.
  ///
  /// TODO: Currently only inputs/outputs of phis are merged, but we
  /// can also merge inputs/outputs of instructions reusing
  /// the same register if/when we add "SameAsFirstInput" constraint.
  void coalesceLiveRanges() {
    for (final block in backEndState.codeGenBlockOrder.reversed) {
      if (block is JoinBlock) {
        for (final phi in block.phis) {
          final liveRange = liveRangeFor(phi).bundle;
          for (int i = 0, n = phi.inputCount; i < n; ++i) {
            final input = phi.inputDefAt(i);
            if (input is! Constant) {
              liveRange.tryMerge(liveRangeFor(input).bundle);
            }
          }
        }
      }
    }
  }

  void allocate(
    RegisterClass registerClass,
    int numberOfRegisters,
    List<PhysicalRegister> allocatableRegisters,
    List<LiveRange?> blockedRegisters,
  ) {
    _unhandled = <LiveRange>[];
    for (final liveRange in _liveRanges) {
      if (liveRange != null &&
          liveRange.registerClass == registerClass &&
          liveRange.mergedTo == null) {
        _unhandled.add(liveRange);
      }
    }
    _unhandled.sort((a, b) => a.start.compareTo(b.start));
    _unhandledIndex = 0;

    if (trace) {
      print('UNHANDLED:');
      print('----------');
      for (final range in _unhandled) {
        print(range);
      }
      print('----------');
    }

    _registerLocations = List<Location?>.filled(numberOfRegisters, null);
    _allocated = List<List<LiveRange>?>.filled(numberOfRegisters, null);
    for (final reg in allocatableRegisters) {
      _registerLocations[reg.index] = reg;
      final blocked = blockedRegisters[reg.index];
      assert(blocked == null || blocked.isPhysical);
      _allocated[reg.index] = <LiveRange>[if (blocked != null) blocked];
    }

    if (trace) {
      print('BLOCKED:');
      print('----------');
      for (var reg = 0; reg < _allocated.length; ++reg) {
        final ranges = _allocated[reg];
        if (ranges != null && ranges.isNotEmpty) {
          print('${_registerLocations[reg]}: ${ranges.single}');
        }
      }
      print('----------');
    }

    for (; _unhandledIndex < _unhandled.length; ++_unhandledIndex) {
      final range = _unhandled[_unhandledIndex];
      if (trace) {
        print('Allocating $range');
      }
      advance(range.start);

      if (!allocateFreeRegister(range)) {
        allocateBlockedRegister(range);
      }
    }

    advance(maxPosition);
  }

  void advance(int pos) {
    if (trace) {
      print('Advance to $pos');
    }
    for (var reg = 0; reg < _allocated.length; ++reg) {
      final ranges = _allocated[reg];
      if (ranges == null) {
        continue;
      }
      var i = 0;
      for (var j = 0; j < ranges.length; ++j) {
        final range = ranges[j];
        if (range.advance(pos)) {
          // Live range ended, set its location and move it to [handled].
          if (range.isPhysical) {
            assert(range.uses.isEmpty);
            if (trace) {
              print('Finished blocked $range');
            }
          } else {
            if (trace) {
              print('Finished $range, allocated to ${_registerLocations[reg]}');
            }
            range.setLocation(_registerLocations[reg]!);
          }
        } else {
          ranges[i++] = range;
        }
      }
      ranges.length = i;
    }
  }

  /// Tries to allocate a free register for [range].
  bool allocateFreeRegister(LiveRange range) {
    // Handle fixed register location first.
    final preferredRegisterUse = range.firstPreferredRegisterUse;
    if (preferredRegisterUse != null) {
      int fixedRegister =
          (preferredRegisterUse.constraint as PhysicalRegister).index;
      int freeUntil = firstIntersectionWithAllocated(range, fixedRegister);
      if (freeUntil > preferredRegisterUse.pos) {
        if (freeUntil < range.end) {
          if (trace) {
            print('Split $range at $freeUntil');
          }
          addToUnhandled(range.splitAt(freeUntil));
        }
        if (trace) {
          print(
            'Allocating $range to preferred ${_registerLocations[fixedRegister]}',
          );
        }
        _allocated[fixedRegister]!.add(range);
        return true;
      }
    }
    // Pick a register which is free the longest span.
    var candidate = -1;
    int freeUntil = range.start;
    for (var reg = 0; reg < _allocated.length; ++reg) {
      if (_allocated[reg] == null) continue;
      int intersection = firstIntersectionWithAllocated(range, reg);
      if (intersection > freeUntil) {
        candidate = reg;
        freeUntil = intersection;
      }
      if (intersection == maxPosition) {
        break;
      }
    }
    if (candidate < 0) {
      if (trace) {
        print('Free register is not found');
      }
      return false;
    }
    if (freeUntil < range.end) {
      if (trace) {
        print('Split $range at $freeUntil');
      }
      addToUnhandled(range.splitAt(freeUntil));
    }
    if (trace) {
      print('Allocating $range to free ${_registerLocations[candidate]}');
    }
    _allocated[candidate]!.add(range);
    return true;
  }

  /// Returns position of the first intersection of [range] with live ranges
  /// allocated to [reg], or [maxPosition] if they do not intersect.
  int firstIntersectionWithAllocated(LiveRange range, int reg) {
    int pos = maxPosition;
    for (final allocated in _allocated[reg]!) {
      final intersection = range.intervals.firstIntersection(
        0,
        allocated.intervals,
        allocated.currentInterval,
      );
      if (intersection >= 0 && intersection < pos) {
        pos = intersection;
      }
    }
    return pos;
  }

  /// Add [tail] to the [_unhandled] list after splitting.
  void addToUnhandled(LiveRange tail) {
    if (trace) {
      print('Add $tail to unhandled');
    }
    final start = tail.start;
    int i = _unhandledIndex + 1;
    for (; i < _unhandled.length; ++i) {
      final range = _unhandled[i];
      if (range.start > start) {
        break;
      }
      _unhandled[i - 1] = range;
    }
    _unhandled[i - 1] = tail;
    --_unhandledIndex;
  }

  void allocateBlockedRegister(LiveRange unallocated) {
    var candidateReg = -1;
    var bestFreeUntil = 0;
    int bestBlockedAt = maxPosition;

    // Select a live range which is not going to be used for the longest time.
    // Spilling this live range would free a register as long as possible.
    void inspectAllocatedRegister(int reg) {
      final ranges = _allocated[reg];
      if (ranges == null) {
        return;
      }
      int freeUntil = maxPosition;
      int blockedAt = maxPosition;
      final start = unallocated.start;
      for (final allocated in ranges) {
        if (allocated.nextIntervalContains(start)) {
          // Active interval.
          if (allocated.isPhysical) {
            return;
          }
          int nextUsePosition = allocated.nextUse?.pos ?? allocated.end;
          if (nextUsePosition < freeUntil) {
            freeUntil = nextUsePosition;
          }
        } else {
          // Inactive interval.
          final intersection = unallocated.intervals.firstIntersection(
            0,
            allocated.intervals,
            allocated.currentInterval,
          );
          if (intersection >= 0) {
            if (intersection < freeUntil) {
              freeUntil = intersection;
            }
            if (allocated.isPhysical && intersection < blockedAt) {
              blockedAt = intersection;
            }
          }
        }

        if (freeUntil <= bestFreeUntil) {
          return;
        }
      }
      assert(freeUntil > bestFreeUntil);
      bestFreeUntil = freeUntil;
      bestBlockedAt = blockedAt;
      candidateReg = reg;
    }

    for (var reg = 0; reg < _allocated.length; ++reg) {
      inspectAllocatedRegister(reg);
    }

    int firstUsePos = unallocated.uses.isEmpty
        ? unallocated.start
        : unallocated.uses.last.pos;
    if (bestFreeUntil < firstUsePos) {
      if (unallocated.start < firstUsePos) {
        if (trace) {
          print('Split $unallocated at $firstUsePos');
        }
        addToUnhandled(unallocated.splitAt(firstUsePos));
      }
      spillLiveRange(unallocated);
      return;
    }

    assert(candidateReg >= 0);
    if (bestBlockedAt < unallocated.end) {
      if (trace) {
        print('Split $unallocated at $bestBlockedAt');
      }
      addToUnhandled(unallocated.splitAt(bestBlockedAt));
    }
    assignNonFreeRegister(unallocated, candidateReg);
  }

  void spillLiveRange(LiveRange range) {
    final splitParent = range.splitParent;
    assert(splitParent.registerClass == range.registerClass);
    final spillSlot = (splitParent.spillSlot ??= backEndState.stackFrame
        .allocateSpillSlot(splitParent.registerClass));
    if (trace) {
      print('Spill $range to $spillSlot');
    }
    range.setLocation(spillSlot);
  }

  void assignNonFreeRegister(LiveRange range, int reg) {
    if (trace) {
      print('Assigning non-free ${_registerLocations[reg]} to $range');
    }
    _allocated[reg]!.removeWhere(
      (LiveRange allocated) =>
          !allocated.isPhysical && evictIntersection(allocated, range, reg),
    );
    _allocated[reg]!.add(range);
  }

  bool evictIntersection(LiveRange allocated, LiveRange unallocated, int reg) {
    final intersection = unallocated.intervals.firstIntersection(
      0,
      allocated.intervals,
      allocated.currentInterval,
    );
    if (intersection < 0) {
      if (trace) {
        print(' ... no intersection with $allocated');
      }
      return false;
    }
    final spillPos = unallocated.start;
    final nextUse = allocated.nextUse;
    if (nextUse == null) {
      // No more uses which require registers.
      if (trace) {
        print('Split $allocated at $spillPos');
      }
      spillLiveRange(allocated.splitAt(spillPos));
      if (trace) {
        print('Finish evicted $allocated at ${_registerLocations[reg]}');
      }
      allocated.setLocation(_registerLocations[reg]!);
    } else {
      final usePos = nextUse.pos;
      final restorePos = (spillPos < intersection)
          ? math.min(intersection, usePos)
          : usePos;
      if (spillPos == allocated.start) {
        if (trace) {
          print('Split $allocated at $restorePos');
        }
        addToUnhandled(allocated.splitAt(restorePos));
        spillLiveRange(allocated);
      } else {
        if (trace) {
          print('Split $allocated at $spillPos');
        }
        final rangeToSpill = allocated.splitAt(spillPos);
        if (trace) {
          print('Split $rangeToSpill at $restorePos');
        }
        addToUnhandled(rangeToSpill.splitAt(restorePos));
        spillLiveRange(rangeToSpill);
        if (trace) {
          print('Finish evicted $allocated at ${_registerLocations[reg]}');
        }
        allocated.setLocation(_registerLocations[reg]!);
      }
    }
    return true;
  }

  /// Resolve data flow between blocks and split live ranges.
  void resolveDataFlow(SSALivenessAnalysis liveness) {
    for (var i = 0; i < _liveRanges.length; ++i) {
      LiveRange? liveRange = _liveRanges[i];
      if (liveRange == null) {
        continue;
      }
      currentInstruction = (i < graph.instructions.length)
          ? graph.instructions[i]
          : null;
      // Insert moves between split live ranges at split points.
      if (liveRange.mergedTo == null) {
        for (;;) {
          LiveRange? next = liveRange!.splitNext;
          if (next == null) {
            break;
          }
          if (liveRange.end == next.start &&
              liveRange.allocatedLocation != next.allocatedLocation &&
              next.allocatedLocation is! StackLocation) {
            Instruction instr = instructionByPos(next.start);
            if (instr is JoinBlock && instr.hasPhis) {
              instr = instr.phis.last;
            }
            if (instr is! Goto && next.start.isOdd) {
              instr = _nextInstruction(instr);
            }
            _insertMoveBefore(
              instr,
              ParallelMoveStage.split,
              liveRange.allocatedLocation!,
              next.allocatedLocation!,
            );
          }
          liveRange = next;
        }
      }
      // Fill in spill slots after definitions if needed
      // (so the value is always available in the spill slot).
      liveRange = _liveRanges[i]!.bundle;
      assert(liveRange.splitParent == liveRange);
      final spillSlot = liveRange.spillSlot;
      if (spillSlot != null &&
          spillSlot is! ParameterStackLocation &&
          i < graph.instructions.length) {
        Instruction instr = graph.instructions[i];
        if (instr is Phi) {
          instr = (instr.block as JoinBlock).phis.last;
        }
        liveRange = liveRange.findSplitChildAt(instructionPos(instr) + 1);
        if (liveRange.allocatedLocation is! StackLocation) {
          _insertMoveBefore(
            _nextInstruction(instr),
            ParallelMoveStage.spill,
            liveRange.allocatedLocation!,
            spillSlot,
          );
        }
      }
    }

    for (final block in backEndState.codeGenBlockOrder) {
      final blockStart = blockStartPos(block);

      for (
        int predIndex = 0, n = block.predecessors.length;
        predIndex < n;
        ++predIndex
      ) {
        final pred = block.predecessors[predIndex];
        final insertionPoint = block is JoinBlock
            ? pred.lastInstruction
            : _nextInstruction(block);
        final predEnd = blockEndPos(pred);
        // Insert moves between split live ranges at control flow edges
        // which do not match linearized control flow.
        if (predEnd != blockStart) {
          for (final instrId in liveness.liveIn(block).elements) {
            LiveRange? liveRange = _liveRanges[instrId]?.bundle;
            if (liveRange != null) {
              final from = liveRange.findSplitChildAt(predEnd - 1);
              final to = liveRange.findSplitChildAt(blockStart);
              if (from.allocatedLocation != to.allocatedLocation &&
                  to.allocatedLocation is! StackLocation) {
                _insertMoveBefore(
                  insertionPoint,
                  ParallelMoveStage.control,
                  from.allocatedLocation!,
                  to.allocatedLocation!,
                );
              }
            }
          }
        }
        // Insert moves between phis and their inputs.
        if (block is JoinBlock) {
          for (final phi in block.phis) {
            final to = liveRangeFor(phi).bundle.findSplitChildAt(blockStart);
            final input = phi.inputDefAt(predIndex);
            if (input is Constant) {
              _insertMoveBefore(
                insertionPoint,
                ParallelMoveStage.control,
                null,
                to.allocatedLocation!,
                input.value,
              );
            } else {
              final from = liveRangeFor(
                input,
              ).bundle.findSplitChildAt(predEnd - 1);
              if (from.allocatedLocation != to.allocatedLocation) {
                _insertMoveBefore(
                  insertionPoint,
                  ParallelMoveStage.control,
                  from.allocatedLocation!,
                  to.allocatedLocation!,
                );
              }
            }
          }
        }
      }
    }
  }
}

/// Single use of a [LiveRange].
class UsePosition {
  final int pos;
  final VirtualLocation vloc;
  Constraint constraint;

  UsePosition(this.pos, this.vloc, this.constraint);

  @override
  String toString() => 'Use[$pos, $constraint]';
}

/// A unit of register allocation.
///
/// Combines multiple related non-intersecting live ranges
/// which would benefit from being allocating to the same location.
/// Has a list of live intervals [s1, e1), [s2, e2), ...., [sN, eN).
class LiveRange {
  static const int maxUseIndex = 0xffffffff;

  final RegisterClass registerClass;

  // Whether this live range represents a blocked physical register
  // or an allocatable/splittable/spillable live range.
  final bool isPhysical;

  // List of intervals.
  IntervalList intervals = IntervalList();

  // Uses of this live range in the descending order.
  List<UsePosition> uses = [];

  // Live range where this live range was merged.
  LiveRange? mergedTo;

  // Original live range which was split.
  LiveRange? splitFrom;

  // Next live range which was split from this live range.
  LiveRange? splitNext;

  // Location assigned to this live range.
  Location? allocatedLocation;

  // Spill slot assigned to this live range (and all its split siblings).
  StackLocation? spillSlot;

  // Used for the currently tracked live ranges (both active and inactive).
  // Index in [intervals].
  int currentInterval = 0;
  // uses.length - index in [uses].
  int currentUse = 1;

  LiveRange(this.registerClass, {this.isPhysical = false});

  /// Add interval [start, end) to this live range.
  ///
  /// Intervals should be added in the descending order by the end position.
  /// Intersecting intervals are not allowed except nested intervals with
  /// the same starting position (which are ignored).
  void addInterval(int start, int end) {
    intervals.addInterval(start, end);
  }

  /// Cut the last use interval to start at [pos].
  void defineAt(int pos) {
    if (intervals.isEmpty) {
      // Value is defined but not used.
      // Add synthetic one-point interval.
      intervals.addInterval(pos, pos + 1);
    } else {
      assert(intervals.startAt(0) <= pos && pos < intervals.endAt(0));
      intervals.setStartAt(0, pos);
    }
  }

  VirtualLocation addUse(int pos, Constraint constr) {
    if (uses.isNotEmpty) {
      final last = uses.last;
      if (last.pos == pos) {
        // Reuse existing use with the same position.
        if (constr is PhysicalRegister &&
            last.constraint is! PhysicalRegister) {
          last.constraint = constr;
        }
        return last.vloc;
      }
    }
    final vloc = VirtualLocation();
    uses.add(UsePosition(pos, vloc, constr));
    return vloc;
  }

  int get start => intervals.start;
  int get end => intervals.end;

  LiveRange get bundle {
    LiveRange? parent = mergedTo;
    if (parent == null) return this;
    while (parent!.mergedTo != null) {
      parent = parent.mergedTo;
    }
    mergedTo = parent;
    return parent;
  }

  bool intersects(LiveRange other) => intervals.intersects(other.intervals);

  void tryMerge(LiveRange other) {
    assert(mergedTo == null && other.mergedTo == null);
    assert(!intervals.isEmpty && !other.intervals.isEmpty);
    if (this == other ||
        this.intersects(other) ||
        registerClass != other.registerClass) {
      return;
    }
    intervals.merge(other.intervals);
    uses = _mergeUsePositions(uses, other.uses);
    other.mergedTo = this;
  }

  List<UsePosition> _mergeUsePositions(
    List<UsePosition> list1,
    List<UsePosition> list2,
  ) {
    final list = <UsePosition>[];
    var i = 0;
    var j = 0;
    while (i < list1.length && j < list2.length) {
      final u1 = list1[i];
      final u2 = list2[j];
      if (u1.pos >= u2.pos) {
        list.add(u1);
        ++i;
      } else {
        list.add(u2);
        ++j;
      }
    }
    while (i < list1.length) {
      list.add(list1[i++]);
    }
    while (j < list2.length) {
      list.add(list2[j++]);
    }
    return list;
  }

  LiveRange get splitParent => splitFrom ?? this;

  // TODO: figure out more optimal split position using loop boundaries.
  LiveRange splitAt(int pos) {
    assert(pos > start);
    assert(!isPhysical);
    assert(mergedTo == null);
    assert(splitNext == null);
    final sibling = LiveRange(registerClass);
    sibling.splitFrom = splitParent;
    sibling.intervals = intervals.splitAt(pos);
    _splitUsePositions(pos, uses, sibling.uses);
    currentUse = math.max(1, currentUse - sibling.uses.length);
    splitNext = sibling;
    return sibling;
  }

  void _splitUsePositions(
    int pos,
    List<UsePosition> src,
    List<UsePosition> dst,
  ) {
    var i = 0;
    for (; i < src.length; ++i) {
      if (src[i].pos < pos) break;
    }
    dst.addAll(src.getRange(0, i));
    src.removeRange(0, i);
  }

  /// Advance [currentInterval] and [currentUse], skipping
  /// intervals and uses which end before [pos].
  /// Returns true if the whole live range ended before [pos].
  bool advance(int pos) {
    if (pos >= end) {
      currentInterval = intervals.length;
      currentUse = uses.length + 1;
      return true;
    }
    while (intervals.endAt(currentInterval) <= pos) {
      ++currentInterval;
    }
    while (currentUse <= uses.length &&
        uses[uses.length - currentUse].pos < pos) {
      ++currentUse;
    }
    return false;
  }

  UsePosition? get nextUse =>
      (currentUse <= uses.length) ? uses[uses.length - currentUse] : null;

  (int, int)? get nextInterval => (currentInterval < intervals.length)
      ? (intervals.startAt(currentInterval), intervals.endAt(currentInterval))
      : null;

  bool nextIntervalContains(int pos) =>
      intervals.startAt(currentInterval) <= pos &&
      pos < intervals.endAt(currentInterval);

  UsePosition? get firstPreferredRegisterUse {
    for (final use in uses.reversed) {
      if (use.constraint is PhysicalRegister) {
        return use;
      }
    }
    return null;
  }

  void setLocation(Location loc) {
    assert(!isPhysical);
    allocatedLocation = loc;
    for (final use in uses) {
      use.vloc.location = loc;
    }
  }

  LiveRange findSplitChildAt(int pos) {
    for (LiveRange? range = this; range != null; range = range.splitNext) {
      if (range.start <= pos && pos < range.end) {
        return range;
      }
    }
    throw 'Unable to find cover for pos $pos in $this';
  }

  @override
  String toString() =>
      'LR $intervals ${uses.reversed} next: $nextInterval $nextUse';
}
