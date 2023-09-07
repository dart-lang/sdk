// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../elements/jumps.dart';
import '../io/source_information.dart';

import 'builder.dart';
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
  factory JumpHandler(KernelSsaGraphBuilder builder, JumpTarget target) {
    return TargetJumpHandler(builder, target);
  }

  void generateBreak(SourceInformation? sourceInformation,
      [LabelDefinition? label]);
  void generateContinue(SourceInformation? sourceInformation,
      [LabelDefinition? label]);
  void forEachBreak(void action(HBreak instruction, LocalsHandler locals));
  void forEachContinue(
      void action(HContinue instruction, LocalsHandler locals));
  bool hasAnyContinue();
  bool hasAnyBreak();
  void close();
  JumpTarget? get target;
  List<LabelDefinition> get labels;
}

/// Jump handler used to avoid null checks when a target isn't used as the
/// target of a break, and therefore doesn't need a break handler associated
/// with it.
class NullJumpHandler implements JumpHandler {
  final DiagnosticReporter reporter;

  NullJumpHandler(this.reporter);

  @override
  void generateBreak(SourceInformation? sourceInformation,
      [LabelDefinition? label]) {
    reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
        'NullJumpHandler.generateBreak should not be called.');
  }

  @override
  void generateContinue(SourceInformation? sourceInformation,
      [LabelDefinition? label]) {
    reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
        'NullJumpHandler.generateContinue should not be called.');
  }

  @override
  void forEachBreak(Function ignored) {}
  @override
  void forEachContinue(Function ignored) {}
  @override
  void close() {}
  @override
  bool hasAnyContinue() => false;
  @override
  bool hasAnyBreak() => false;

  @override
  List<LabelDefinition> get labels => const [];
  @override
  JumpTarget? get target => null;
}

/// Jump handler that records breaks until a target block is available.
///
/// Breaks are always forward jumps. Continues in loops are implemented as
/// breaks of the body. Continues in switches is currently not handled.
class TargetJumpHandler implements JumpHandler {
  final KernelSsaGraphBuilder builder;
  @override
  final JumpTarget target;
  final List<_JumpHandlerEntry> jumps = [];

  TargetJumpHandler(this.builder, this.target) {
    assert(builder.jumpTargets[target] == null);
    builder.jumpTargets[target] = this;
  }

  @override
  void generateBreak(SourceInformation? sourceInformation,
      [LabelDefinition? label]) {
    HInstruction breakInstruction;
    if (label == null) {
      breakInstruction = HBreak(target, sourceInformation);
    } else {
      breakInstruction = HBreak.toLabel(label, sourceInformation);
    }
    LocalsHandler locals = LocalsHandler.from(builder.localsHandler);
    builder.close(breakInstruction as HJump);
    jumps.add(_JumpHandlerEntry(breakInstruction, locals));
  }

  @override
  void generateContinue(SourceInformation? sourceInformation,
      [LabelDefinition? label]) {
    HInstruction continueInstruction;
    if (label == null) {
      continueInstruction = HContinue(target, sourceInformation);
    } else {
      continueInstruction = HContinue.toLabel(label, sourceInformation);
      // Switch case continue statements must be handled by the
      // [SwitchCaseJumpHandler].
      assert(!label.target.isSwitchCase);
    }
    LocalsHandler locals = LocalsHandler.from(builder.localsHandler);
    builder.close(continueInstruction as HJump);
    jumps.add(_JumpHandlerEntry(continueInstruction, locals));
  }

  @override
  void forEachBreak(
      void Function(HBreak instruction, LocalsHandler locals) action) {
    for (_JumpHandlerEntry entry in jumps) {
      final jumpInstruction = entry.jumpInstruction;
      if (jumpInstruction is HBreak) action(jumpInstruction, entry.locals);
    }
  }

  @override
  void forEachContinue(
      void Function(HContinue instruction, LocalsHandler locals) action) {
    for (_JumpHandlerEntry entry in jumps) {
      final jumpInstruction = entry.jumpInstruction;
      if (jumpInstruction is HContinue) action(jumpInstruction, entry.locals);
    }
  }

  @override
  bool hasAnyContinue() {
    for (_JumpHandlerEntry entry in jumps) {
      if (entry.isContinue()) return true;
    }
    return false;
  }

  @override
  bool hasAnyBreak() {
    for (_JumpHandlerEntry entry in jumps) {
      if (entry.isBreak()) return true;
    }
    return false;
  }

  @override
  void close() {
    // The mapping from TargetElement to JumpHandler is no longer needed.
    builder.jumpTargets.remove(target);
  }

  @override
  List<LabelDefinition> get labels {
    List<LabelDefinition>? result;
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
  final Map<JumpTarget, int> targetIndexMap = {};

  SwitchCaseJumpHandler(super.builder, super.target);

  @override
  void generateBreak(SourceInformation? sourceInformation,
      [LabelDefinition? label]) {
    if (label == null) {
      // Creates a special break instruction for the synthetic loop generated
      // for a switch statement with continue statements. See
      // [SsaFromAstMixin.buildComplexSwitchStatement] for detail.

      HInstruction breakInstruction =
          HBreak(target, sourceInformation, breakSwitchContinueLoop: true);
      LocalsHandler locals = LocalsHandler.from(builder.localsHandler);
      builder.close(breakInstruction as HJump);
      jumps.add(_JumpHandlerEntry(breakInstruction, locals));
    } else {
      super.generateBreak(sourceInformation, label);
    }
  }

  bool isContinueToSwitchCase(LabelDefinition? label) {
    return label != null && targetIndexMap.containsKey(label.target);
  }

  @override
  void generateContinue(SourceInformation? sourceInformation,
      [LabelDefinition? label]) {
    if (isContinueToSwitchCase(label)) {
      // Creates the special instructions 'label = i; continue l;' used in
      // switch statements with continue statements. See
      // [SsaFromAstMixin.buildComplexSwitchStatement] for detail.

      HInstruction value = builder.graph
          .addConstantInt(targetIndexMap[label!.target]!, builder.closedWorld);
      builder.localsHandler.updateLocal(target, value);

      assert(label.target.labels.contains(label));
      HInstruction continueInstruction = HContinue(target, sourceInformation);
      LocalsHandler locals = LocalsHandler.from(builder.localsHandler);
      builder.close(continueInstruction as HJump);
      jumps.add(_JumpHandlerEntry(continueInstruction, locals));
    } else {
      super.generateContinue(sourceInformation, label);
    }
  }

  @override
  void close() {
    // The mapping from TargetElement to JumpHandler is no longer needed.
    for (JumpTarget target in targetIndexMap.keys) {
      builder.jumpTargets.remove(target);
    }
    super.close();
  }
}
