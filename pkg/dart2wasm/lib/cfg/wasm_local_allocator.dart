// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/liveness_analysis.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/utils/bit_vector.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

/// Allocates Wasm locals for SSA [Definition]s in a [FlowGraph], reusing
/// locals of matching type across non-overlapping live ranges.
final class WasmLocalAllocator {
  final FlowGraph graph;
  final w.InstructionsBuilder b;
  final w.ValueType Function(CType) translateType;
  final w.Local? Function(Parameter) functionParameterLocal;

  /// Maps [Instruction.id] to its local index in [b.locals], or `-1` if no
  /// local was allocated.
  late final Int32List _localIndices;

  WasmLocalAllocator(
    this.graph,
    this.b, {
    required this.translateType,
    required this.functionParameterLocal,
  }) {
    _allocateLocals();
  }

  /// Whether a Wasm local was allocated for [def].
  ///
  /// A definition which e.g. has no uses does not get a wasm local allocated.
  bool hasLocal(Definition def) => _localIndices[def.id] >= 0;

  /// Returns the Wasm local allocated for [def].
  w.Local localOf(Definition def) {
    final index = _localIndices[def.id];
    assert(index >= 0, 'No local allocated for $def');
    return b.locals[index];
  }

  /// Whether copying [inputDef] into [phi] is a no-op because both share the
  /// same Wasm local.
  bool isPhiMoveNoOp(Phi phi, Definition inputDef) {
    if (isUndefined(inputDef)) return false;
    final phiLocalIndex = _localIndices[phi.id];
    assert(phiLocalIndex >= 0);
    return _localIndices[inputDef.id] == phiLocalIndex;
  }

  /// Returns the Wasm value type used to represent [def].
  w.ValueType wasmTypeOf(Definition def) {
    if (def is Parameter && def.isFunctionParameter) {
      final paramLocal = functionParameterLocal(def);
      if (paramLocal != null) return paramLocal.type;
    }
    final type = translateType(def.type);
    if (def is Phi) {
      // `Phi` locals must be nullable for two reasons:
      // 1. Predecessors assign them inside nested Wasm `block`s before
      //    branching to the join block, whereas Wasm only treats a
      //    non-nullable local as initialized within the Wasm `block` where it
      //    was `local.set` (not after exiting that `block`).
      // 2. `UndefinedConstant` phi inputs are lowered as `ref.null`.
      return type.withNullability(true);
    }
    return type;
  }

  /// Whether [def] is the undefined constant, i.e. a placeholder for a value
  /// which is never observed on the given path.
  static bool isUndefined(Definition def) =>
      def is Constant && def.value.constant is UndefinedConstant;

  void _allocateLocals() {
    final numInstructions = graph.instructions.length;

    // Compute liveness information of SSA definitions at block in/out boundary.
    final liveness = SSALivenessAnalysis(graph)..analyze();

    // Maps SSA definition to wasm local index (or -1)
    _localIndices = Int32List(numInstructions)
      ..fillRange(0, numInstructions, -1);

    // Scratch state reused across all blocks to avoid per-block O(graph)
    // allocations:
    // - `lastUseInBlock` maps each non-live-out definition to its last using
    //   instruction in the current block (all `-1` between blocks; written
    //   entries are reset in `_freeDeadWasmLocals`).
    // - `pool` tracks all reusable Wasm locals created so far and which ones
    //   are live at the current point in the block.
    final lastUseInBlock = Int32List(numInstructions)
      ..fillRange(0, numInstructions, -1);
    final pool = _WasmLocalPool(b, numInstructions);

    // Visit blocks in RPO so a block's dominators have been visited by the
    // time we visit `block`, so every definition in `liveIn(block)` already
    // has a local.
    for (final block in graph.reversePostorder) {
      _allocateLocalsForBlock(
        block,
        liveness.liveIn(block),
        liveness.liveOut(block),
        lastUseInBlock,
        pool,
      );
    }
  }

  /// Allocates Wasm locals for all definitions in [block].
  ///
  /// Reads [liveIn] and [liveOut] for [block]. Uses [lastUseInBlock] as
  /// per-block scratch storage (expected to be all `-1` on entry, and restored
  /// to all `-1` before returning) and updates [pool] to track currently live
  /// locals while scanning [block].
  void _allocateLocalsForBlock(
    Block block,
    BitVector liveIn,
    BitVector liveOut,
    Int32List lastUseInBlock,
    _WasmLocalPool pool,
  ) {
    pool.reset();

    // If this [block] has live incoming definitions, we mark the corresponding
    // wasm locals as allocated.
    _allocateLiveWasmLocals(liveIn, pool);

    // For definitions that have their last use inside [block] remember the
    // instruction that is the last using one, so we can free the wasm local
    // after the last use.
    _recordLastUsesInBlock(block, liveOut, lastUseInBlock);

    for (final instr in block) {
      // If an input to [instr] is the last use of a definition, we can free
      // up the wasm local used for it, so it can be re-used.
      if (instr is! Phi) {
        // Phi inputs are consumed in predecessors.
        _freeDeadWasmLocals(instr, lastUseInBlock, pool);
      }

      // Now allocate, or re-use, a wasm local for the [instr].
      if (instr is Definition && _needsLocal(instr)) {
        assert(liveOut[instr.id] || lastUseInBlock[instr.id] != -1);
        _localIndices[instr.id] = _allocateWasmLocal(instr, pool);
      }
    }
  }

  /// Marks the Wasm locals of all definitions in [liveIn] as allocated in
  /// [pool].
  void _allocateLiveWasmLocals(BitVector liveIn, _WasmLocalPool pool) {
    for (final id in liveIn.elements) {
      final localIndex = _localIndices[id];
      if (localIndex >= 0) {
        pool.markAllocated(localIndex);
      } else {
        assert(!_needsLocal(graph.instructions[id] as Definition));
      }
    }
  }

  void _recordLastUsesInBlock(
    Block block,
    BitVector liveOut,
    Int32List lastUseInBlock,
  ) {
    for (final instr in block) {
      assert(
        instr.implicitInputs == null,
        'Implicit inputs are not yet handled by liveness analysis',
      );
      if (instr is Phi) {
        // Phi inputs are consumed in predecessor blocks (`assignPhis`), not
        // here.
        continue;
      }
      for (var i = 0, n = instr.inputCount; i < n; ++i) {
        final inputId = instr.inputDefAt(i).id;
        if (!liveOut[inputId]) {
          lastUseInBlock[inputId] = instr.id;
        }
      }
    }
  }

  void _freeDeadWasmLocals(
    Instruction instr,
    Int32List lastUseInBlock,
    _WasmLocalPool pool,
  ) {
    for (var i = 0, n = instr.inputCount; i < n; ++i) {
      final inputId = instr.inputDefAt(i).id;
      if (lastUseInBlock[inputId] == instr.id) {
        lastUseInBlock[inputId] = -1;
        final localIndex = _localIndices[inputId];
        if (localIndex >= 0) {
          pool.free(localIndex);
        }
      }
    }
  }

  int _allocateWasmLocal(Definition def, _WasmLocalPool pool) {
    // Incoming parameter locals are intentionally kept out of `pool` so they
    // are never overwritten as scratch locals.
    if (def is Parameter && def.isFunctionParameter) {
      final paramLocal = functionParameterLocal(def);
      if (paramLocal != null) return paramLocal.index;
    }

    final wasmType = wasmTypeOf(def);
    final coalesced = _tryCoalescePhiLocal(def, wasmType, pool);
    if (coalesced >= 0) return coalesced;
    return pool.allocate(wasmType);
  }

  /// Tries to reuse a free local already assigned to a related [Phi] (or [Phi]
  /// input) so that the edge copy becomes a no-op.
  int _tryCoalescePhiLocal(
    Definition def,
    w.ValueType wasmType,
    _WasmLocalPool pool,
  ) {
    for (final use in def.inputUses) {
      final user = use.getInstruction(graph);
      if (user is Phi) {
        final phiLocalIndex = _localIndices[user.id];
        if (phiLocalIndex >= 0 && pool.tryAllocate(phiLocalIndex, wasmType)) {
          return phiLocalIndex;
        }
      }
    }
    if (def is Phi) {
      for (var i = 0, n = def.inputCount; i < n; ++i) {
        final inputLocalIndex = _localIndices[def.inputDefAt(i).id];
        if (inputLocalIndex >= 0 &&
            pool.tryAllocate(inputLocalIndex, wasmType)) {
          return inputLocalIndex;
        }
      }
    }
    return -1;
  }

  bool _needsLocal(Definition def) {
    if (!def.hasUses) return false;
    if (def is Constant) {
      // Materialized directly at their use sites (calls / phi assignments).
      return !def.value.isTypeArgumentsConstant && !isUndefined(def);
    }
    // Type parameters and type arguments don't occupy a single Wasm local
    // (function type parameters map to separate Wasm parameters and
    // `TypeArguments` builds one local per non-constant type argument).
    if (def is Parameter && def.variable.isFunctionTypeParametersVariable) {
      return false;
    }
    if (def is TypeParameters || def is TypeArguments) return false;
    return true;
  }
}

/// Tracks which reusable Wasm locals are currently allocated vs. free during
/// allocation, supporting O(1) amortized acquire/release and O(|allocated|)
/// block resets.
final class _WasmLocalPool {
  final w.InstructionsBuilder _b;

  /// First local index in [_b.locals] managed by this pool.
  ///
  /// Lower indices are pre-existing locals (such as function parameters) that
  /// must never be recycled as scratch locals.
  final int _firstReusableLocalIndex;

  /// Free lists of reusable local indices, grouped by their Wasm [w.ValueType].
  ///
  /// May contain stale entries for locals that were re-acquired via
  /// [markAllocated]; [allocate] discards any entry currently in [_allocated].
  final Map<w.ValueType, List<int>> _freeByType = {};

  /// Set of reusable local indices currently marked as live/allocated.
  final BitVector _allocated;

  /// Log of local indices added to [_allocated] since the last [reset].
  ///
  /// Lets [reset] release only the locals touched in the current block in
  /// `O(|_allocatedList|)` time instead of scanning the entire [_allocated] bit
  /// vector. May contain locals already released by [free], so [reset] checks
  /// [_allocated] before returning each entry to [_freeByType].
  final List<int> _allocatedList = [];

  _WasmLocalPool(this._b, int numInstructions)
    : _firstReusableLocalIndex = _b.locals.length,
      _allocated = BitVector(_b.locals.length + numInstructions);

  void reset() {
    for (final localIndex in _allocatedList) {
      if (_allocated[localIndex]) {
        final type = _b.locals[localIndex].type;
        _allocated.remove(localIndex);
        (_freeByType[type] ??= []).add(localIndex);
      }
    }
    _allocatedList.clear();
  }

  void markAllocated(int localIndex) {
    if (localIndex < _firstReusableLocalIndex) return;
    assert(!_allocated[localIndex]);
    _allocated.add(localIndex);
    _allocatedList.add(localIndex);
    // We avoid an O(N) pass over the free list to find [localIndex] and remove
    // it. Instead, [allocate] will drop the stale entry instead of reusing it.
  }

  /// Allocates [localIndex] if it is a free reusable local of [type].
  bool tryAllocate(int localIndex, w.ValueType type) {
    if (localIndex < _firstReusableLocalIndex) return false;
    if (_allocated[localIndex]) return false;
    if (_b.locals[localIndex].type != type) return false;
    markAllocated(localIndex);
    return true;
  }

  int allocate(w.ValueType type) {
    final free = _freeByType[type];
    if (free != null) {
      while (free.isNotEmpty) {
        final localIndex = free.removeLast();
        if (!_allocated[localIndex]) {
          _allocated.add(localIndex);
          _allocatedList.add(localIndex);
          return localIndex;
        } else {
          // This is a stale free list entry: It was allocated by
          // [markAllocated], which didn't remove it from the free list to avoid
          // O(N) traversal to find it.
        }
      }
    }
    final localIndex = _b.addLocal(type).index;
    _allocated.add(localIndex);
    _allocatedList.add(localIndex);
    return localIndex;
  }

  void free(int localIndex) {
    if (localIndex < _firstReusableLocalIndex) return;
    assert(_allocated[localIndex]);
    _allocated.remove(localIndex);
    (_freeByType[_b.locals[localIndex].type] ??= []).add(localIndex);
  }
}
