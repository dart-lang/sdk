// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../elements/jumps.dart';
import '../tree/tree.dart' as ast;

import 'graph_builder.dart';
import 'locals_handler.dart';
import 'nodes.dart';

/// A single break/continue instruction.
class _JumpHandlerEntry {
  final HJump jumpInstruction;
  final LocalsHandler locals;
  bool isBreak() => jumpInstruction is HBreak;
  bool isContinue() => jumpInstruction is HContinue;
  _JumpHandlerEntry(this.jumpInstruction, this.locals);
}

abstract class JumpHandler {
  factory JumpHandler(GraphBuilder builder, JumpTarget target) {
    return new TargetJumpHandler(builder, target);
  }
  void generateBreak([LabelDefinition label]);
  void generateContinue([LabelDefinition label]);
  void forEachBreak(void action(HBreak instruction, LocalsHandler locals));
  void forEachContinue(
      void action(HContinue instruction, LocalsHandler locals));
  bool hasAnyContinue();
  bool hasAnyBreak();
  void close();
  final JumpTarget target;
  List<LabelDefinition> get labels;
}

/// Jump handler used to avoid null checks when a target isn't used as the
/// target of a break, and therefore doesn't need a break handler associated
/// with it.
class NullJumpHandler implements JumpHandler {
  final DiagnosticReporter reporter;

  NullJumpHandler(this.reporter);

  void generateBreak([LabelDefinition label]) {
    reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
        'NullJumpHandler.generateBreak should not be called.');
  }

  void generateContinue([LabelDefinition label]) {
    reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
        'NullJumpHandler.generateContinue should not be called.');
  }

  void forEachBreak(Function ignored) {}
  void forEachContinue(Function ignored) {}
  void close() {}
  bool hasAnyContinue() => false;
  bool hasAnyBreak() => false;

  List<LabelDefinition> get labels => const <LabelDefinition>[];
  JumpTarget get target => null;
}

/// Jump handler that records breaks until a target block is available.
///
/// Breaks are always forward jumps. Continues in loops are implemented as
/// breaks of the body. Continues in switches is currently not handled.
class TargetJumpHandler implements JumpHandler {
  final GraphBuilder builder;
  final JumpTarget target;
  final List<_JumpHandlerEntry> jumps;

  TargetJumpHandler(GraphBuilder builder, this.target)
      : this.builder = builder,
        jumps = <_JumpHandlerEntry>[] {
    assert(builder.jumpTargets[target] == null);
    builder.jumpTargets[target] = this;
  }

  void generateBreak([LabelDefinition label]) {
    HInstruction breakInstruction;
    if (label == null) {
      breakInstruction = new HBreak(target);
    } else {
      breakInstruction = new HBreak.toLabel(label);
    }
    LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
    builder.close(breakInstruction);
    jumps.add(new _JumpHandlerEntry(breakInstruction, locals));
  }

  void generateContinue([LabelDefinition label]) {
    HInstruction continueInstruction;
    if (label == null) {
      continueInstruction = new HContinue(target);
    } else {
      continueInstruction = new HContinue.toLabel(label);
      // Switch case continue statements must be handled by the
      // [SwitchCaseJumpHandler].
      assert(label.target.statement is! ast.SwitchCase);
    }
    LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
    builder.close(continueInstruction);
    jumps.add(new _JumpHandlerEntry(continueInstruction, locals));
  }

  void forEachBreak(Function action) {
    for (_JumpHandlerEntry entry in jumps) {
      if (entry.isBreak()) action(entry.jumpInstruction, entry.locals);
    }
  }

  void forEachContinue(Function action) {
    for (_JumpHandlerEntry entry in jumps) {
      if (entry.isContinue()) action(entry.jumpInstruction, entry.locals);
    }
  }

  bool hasAnyContinue() {
    for (_JumpHandlerEntry entry in jumps) {
      if (entry.isContinue()) return true;
    }
    return false;
  }

  bool hasAnyBreak() {
    for (_JumpHandlerEntry entry in jumps) {
      if (entry.isBreak()) return true;
    }
    return false;
  }

  void close() {
    // The mapping from TargetElement to JumpHandler is no longer needed.
    builder.jumpTargets.remove(target);
  }

  List<LabelDefinition> get labels {
    List<LabelDefinition> result = null;
    for (LabelDefinition element in target.labels) {
      result ??= <LabelDefinition>[];
      result.add(element);
    }
    return result ?? const <LabelDefinition>[];
  }
}

/// Special [JumpHandler] implementation used to handle continue statements
/// targeting switch cases.
abstract class SwitchCaseJumpHandler extends TargetJumpHandler {
  /// Map from switch case targets to indices used to encode the flow of the
  /// switch case loop.
  final Map<JumpTarget, int> targetIndexMap = new Map<JumpTarget, int>();

  SwitchCaseJumpHandler(GraphBuilder builder, JumpTarget target)
      : super(builder, target);

  void generateBreak([LabelDefinition label]) {
    if (label == null) {
      // Creates a special break instruction for the synthetic loop generated
      // for a switch statement with continue statements. See
      // [SsaFromAstMixin.buildComplexSwitchStatement] for detail.

      HInstruction breakInstruction =
          new HBreak(target, breakSwitchContinueLoop: true);
      LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
      builder.close(breakInstruction);
      jumps.add(new _JumpHandlerEntry(breakInstruction, locals));
    } else {
      super.generateBreak(label);
    }
  }

  bool isContinueToSwitchCase(LabelDefinition label) {
    return label != null && targetIndexMap.containsKey(label.target);
  }

  void generateContinue([LabelDefinition label]) {
    if (isContinueToSwitchCase(label)) {
      // Creates the special instructions 'label = i; continue l;' used in
      // switch statements with continue statements. See
      // [SsaFromAstMixin.buildComplexSwitchStatement] for detail.

      assert(label != null);
      // TODO(het): change the graph 'addConstantXXX' to take a ConstantSystem
      // instead of a Compiler.
      HInstruction value = builder.graph
          .addConstantInt(targetIndexMap[label.target], builder.closedWorld);
      builder.localsHandler.updateLocal(target, value);

      assert(label.target.labels.contains(label));
      HInstruction continueInstruction = new HContinue(target);
      LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
      builder.close(continueInstruction);
      jumps.add(new _JumpHandlerEntry(continueInstruction, locals));
    } else {
      super.generateContinue(label);
    }
  }

  void close() {
    // The mapping from TargetElement to JumpHandler is no longer needed.
    for (JumpTarget target in targetIndexMap.keys) {
      builder.jumpTargets.remove(target);
    }
    super.close();
  }
}

/// Special [JumpHandler] implementation used to handle continue statements
/// targeting switch cases.
class AstSwitchCaseJumpHandler extends SwitchCaseJumpHandler {
  AstSwitchCaseJumpHandler(
      GraphBuilder builder, JumpTarget target, ast.SwitchStatement node)
      : super(builder, target) {
    // The switch case indices must match those computed in
    // [SsaFromAstMixin.buildSwitchCaseConstants].
    // Switch indices are 1-based so we can bypass the synthetic loop when no
    // cases match simply by branching on the index (which defaults to null).
    int switchIndex = 1;
    for (ast.SwitchCase switchCase in node.cases) {
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        ast.Node label = labelOrCase.asLabel();
        if (label != null) {
          LabelDefinition labelElement =
              builder.elements.getLabelDefinition(label);
          if (labelElement != null && labelElement.isContinueTarget) {
            JumpTarget continueTarget = labelElement.target;
            targetIndexMap[continueTarget] = switchIndex;
            assert(builder.jumpTargets[continueTarget] == null);
            builder.jumpTargets[continueTarget] = this;
          }
        }
      }
      switchIndex++;
    }
  }
}
