// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js_backend/field_analysis.dart' show JFieldAnalysis;
import '../world.dart' show JClosedWorld;
import 'logging.dart';
import 'nodes.dart';
import 'optimize.dart' show OptimizationPhase;

/// Optimization phase that tries to eliminate late field checks and memory
/// loads.
class SsaLateFieldOptimizer extends HBaseVisitor implements OptimizationPhase {
  @override
  final String name = "SsaLateFieldOptimizer";

  final JClosedWorld _closedWorld;
  final OptimizationTestLog /*?*/ _log;

  final AbstractValueDomain _abstractValueDomain;
  final JFieldAnalysis _fieldAnalysis;

  SsaLateFieldOptimizer(this._closedWorld, this._log)
      : _abstractValueDomain = _closedWorld.abstractValueDomain,
        _fieldAnalysis = _closedWorld.fieldAnalysis;

  @override
  void visitGraph(HGraph graph) {
    _log?.instructionHistogram('$name.pre', graph, _summarizeInstruction);

    visitDominatorTree(graph);

    _log?.instructionHistogram('$name.post', graph, _summarizeInstruction);
  }

  static String /*?*/ _summarizeInstruction(HInstruction node) {
    if (node is HLateCheck) return '${node.runtimeType}';
    if (node is HFieldGet) return '${node.runtimeType}';
    return null;
  }

  @override
  bool validPostcondition(HGraph graph) => true;

  @override
  void visitBasicBlock(HBasicBlock block) {
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  @override
  void visitLateReadCheck(HLateReadCheck node) {
    // The getter for a `late` instance field has a check on the backing field
    // to ensure that the sentinel value has been overwritten by an initializing
    // assignment. When the getter is inlined, there is a sequence of loads,
    // each with a check. `h(g(a.f), g(a.f))` looks like the following, where
    // `#f` is the backing field for late field `f`.
    //
    //     t1 = HFieldGet(a, #f)       {T,sentinel}
    //     t2 = HLateReadCheck(t1)     {T}
    //     t9 = g(t2)
    //     t11 = HFieldGet(a, #f)      {T,sentinel}
    //     t12 = HLateReadCheck(t11)   {T}
    //     t19 = g(t12)
    //     t99 = h(t9, t19)
    //
    // The field starts initialized with a sentinel value. HLateReadCheck will
    // throw if the value is a sentinel.  The backing field is never assigned a
    // sentinel, so subsequent read checks will always succeed and can be
    // removed.
    //
    // ## `late` fields
    //
    // The removal is effected by marking the subsequent loaded values with a
    // strengthened type that excludes the sentinel, using HTypeKnown. This
    // makes the sentinel check redundant so it can be removed when it is
    // visited later in the pass.
    //
    // To prevent _uses_ of the loaded values from being moved to before the
    // check, HTypeKnown is witnessed by (has a dependency on) the original
    // check. We know the value is not a sentinel only _after_ the check.
    // (Optimizations preserve the order of loads and stores. It is fine for the
    // second load to move before the first check provided doing so does not
    // change the value seen by the second load.)
    //
    // After inserting the HTypeKnown.witnessed instruction after each
    // subsequent load we have:
    //
    //     t1 = HFieldGet(a, #f)       {T,sentinel}
    //     t2 = HLateReadCheck(t1)     {T}
    //     t9 = g(t2)
    //     t11 = HFieldGet(a, #f)      {T,sentinel}
    //     t12 = HTypeKnown(t11, t2)   {T}
    //     t13 = HLateReadCheck(t12)   {T}
    //     t19 = g(t13)
    //     t99 = h(t9, t19)
    //
    // The subsequent checks are now redundant, and are visited after the
    // initial check, so they are cleaned up when visited.
    //
    //     t1 = HFieldGet(a, #f)       {T,sentinel}
    //     t2 = HLateReadCheck(t1)     {T}
    //     t9 = g(t2)
    //     t11 = HFieldGet(a, #f)      {T,sentinel}
    //     t12 = HTypeKnown(t11, t2)   {T}
    //     t19 = g(t12)
    //     t99 = h(t9, t19)
    //
    // ## `late final` fields
    //
    // `late final` fields change value only once from sentinel to final value.
    // If the read-check passes, the value is the final value, so the subsequent
    // reads can be replaced by the checked value:
    //
    //     t1 = HFieldGet(a, #f)       {T,sentinel}
    //     t2 = HLateReadCheck(t1)     {T}
    //     t9 = g(t2)
    //     t12 = HLateReadCheck(t2)   {T}
    //     t19 = g(t12)
    //     t99 = h(t9, t19)
    //
    // This leads to back-to-back HLateReadCheck instructions, the second of
    // which is redundant and is removed:
    //
    //     t1 = HFieldGet(a, #f)       {T,sentinel}
    //     t2 = HLateReadCheck(t1)     {T}
    //     t9 = g(t2)
    //     t19 = g(t2)
    //     t99 = h(t9, t19)

    HInstruction input = node.checkedInput;

    // Cleanup. Remove redundant checks.
    if (input is HLateReadCheck || node.isRedundant(_closedWorld)) {
      node.block.rewrite(node, input);
      node.block.remove(node);
      return;
    }

    if (input is HFieldGet) {
      HInstruction receiver = input.receiver;
      FieldEntity field = input.element;

      final uses = DominatedUses.of(receiver, node);

      List<HFieldGet> loads = [];
      for (HInstruction use in uses.instructions) {
        if (use is HFieldGet && use.element == field) {
          loads.add(use);
        }
      }

      if (loads.isEmpty) return;

      if (_fieldAnalysis.getFieldData(field).isAssignedOnce) {
        // `late final` backing fields are assigned at most once, so loads can
        // be replaced with the dominating checked load value.
        for (final load in loads) {
          load.block.rewrite(load, node);
          load.block.remove(load);
        }
      } else {
        for (final load in loads) {
          final known = HTypeKnown.witnessed(node.instructionType, load, node)
            ..sourceInformation = node.sourceInformation;
          load.block.rewrite(load, known);
          load.block.addAfter(load, known);
        }
      }
    }
  }

  @override
  void visitFieldSet(HFieldSet node) {
    FieldEntity field = node.element;
    final fieldData = _fieldAnalysis.getFieldData(field);
    if (!fieldData.isLateBackingField) return;

    // [node] is a store to the backing field for a late instance field. The
    // stored value cannot be the sentinel value, so future loads of the field
    // will never be the sentinel value and do not need to be checked.
    final uses = DominatedUses.of(node.receiver, node, excludeDominator: true);

    List<HFieldGet> loads = [];
    for (HInstruction use in uses.instructions) {
      if (use is HFieldGet && use.element == field) {
        loads.add(use);
      }
    }

    if (loads.isEmpty) return;

    if (fieldData.isAssignedOnce) {
      // [field] is a `late final` field so the stored value is the value of
      // every subsequent load. Replace loads with the stored value.
      for (final load in loads) {
        load.block.rewrite(load, node.value);
        load.block.remove(load);
      }
    } else {
      // The subsequent loaded value cannot be the sentinel value. Refine the
      // type of the load which will allow any check on the load to be removed.
      // There is no need for HTypeKnown.witnessed since it would be an invalid
      // transformation to move the read before the write.
      for (final load in loads) {
        load.instructionType =
            _abstractValueDomain.excludeLateSentinel(load.instructionType);
      }
    }
  }
}
