// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/jumps.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/js_model/locals.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'package:kernel/ast.dart' as ir;

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const JumpDataComputer(),
        options: [stopAfterTypeInference], args: args);
  });
}

class JumpDataComputer extends DataComputer<String> {
  const JumpDataComputer();

  /// Compute closure data mapping for [member] as a kernel based element.
  ///
  /// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
  /// for the data origin.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    GlobalLocalsMap localsMap = closedWorld.globalLocalsMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new JumpsIrChecker(
            compiler.reporter, actualMap, localsMap.getLocalsMap(member))
        .run(definition.node);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class TargetData {
  final int index;
  final NodeId id;
  final SourceSpan sourceSpan;
  final JumpTarget target;

  TargetData(this.index, this.id, this.sourceSpan, this.target);

  @override
  String toString() => 'TargetData(index=$index,id=$id,'
      'sourceSpan=$sourceSpan,target=$target)';
}

class GotoData {
  final NodeId id;
  final SourceSpan sourceSpan;
  final JumpTarget target;

  GotoData(this.id, this.sourceSpan, this.target);

  @override
  String toString() => 'GotoData(id=$id,sourceSpan=$sourceSpan,target=$target)';
}

/// Kernel IR visitor for computing jump data.
class JumpsIrChecker extends IrDataExtractor<String> {
  final KernelToLocalsMap _localsMap;

  int index = 0;
  Map<JumpTarget, TargetData> targets = <JumpTarget, TargetData>{};
  List<GotoData> gotos = <GotoData>[];

  JumpsIrChecker(DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap, this._localsMap)
      : super(reporter, actualMap);

  void processData() {
    targets.forEach((JumpTarget target, TargetData data) {
      StringBuffer sb = new StringBuffer();
      sb.write(data.index);
      sb.write('@');
      bool needsComma = false;
      if (target.isBreakTarget) {
        sb.write('break');
        needsComma = true;
      }
      if (target.isContinueTarget) {
        if (needsComma) {
          sb.write(',');
        }
        sb.write('continue');
        needsComma = true;
      }
      String value = sb.toString();
      registerValue(
          data.sourceSpan.uri, data.sourceSpan.begin, data.id, value, target);
    });
    gotos.forEach((GotoData data) {
      StringBuffer sb = new StringBuffer();
      sb.write('target=');
      TargetData targetData = targets[data.target];
      assert(targetData != null, "No TargetData for ${data.target}");
      sb.write(targetData.index);
      String value = sb.toString();
      registerValue(
          data.sourceSpan.uri, data.sourceSpan.begin, data.id, value, data);
    });
  }

  @override
  void run(ir.Node root) {
    super.run(root);
    processData();
  }

  @override
  String computeNodeValue(Id id, ir.Node node) {
    // Node values are computed post-visit in [processData].
    return null;
  }

  void addTargetData(ir.TreeNode node, NodeId id, JumpTarget target) {
    if (target != null) {
      SourceSpan sourceSpan = computeSourceSpan(node);
      targets[target] = new TargetData(index++, id, sourceSpan, target);
    }
  }

  @override
  visitForStatement(ir.ForStatement node) {
    addTargetData(
        node, createLoopId(node), _localsMap.getJumpTargetForFor(node));
    super.visitForStatement(node);
  }

  @override
  visitForInStatement(ir.ForInStatement node) {
    addTargetData(
        node, createLoopId(node), _localsMap.getJumpTargetForForIn(node));
    super.visitForInStatement(node);
  }

  @override
  visitWhileStatement(ir.WhileStatement node) {
    addTargetData(
        node, createLoopId(node), _localsMap.getJumpTargetForWhile(node));
    super.visitWhileStatement(node);
  }

  @override
  visitDoStatement(ir.DoStatement node) {
    addTargetData(
        node, createLoopId(node), _localsMap.getJumpTargetForDo(node));
    super.visitDoStatement(node);
  }

  @override
  visitBreakStatement(ir.BreakStatement node) {
    JumpTarget target = _localsMap.getJumpTargetForBreak(node);
    assert(target != null, 'No target for $node.');
    NodeId id = createGotoId(node);
    SourceSpan sourceSpan = computeSourceSpan(node);
    gotos.add(new GotoData(id, sourceSpan, target));
    super.visitBreakStatement(node);
  }

  @override
  visitLabeledStatement(ir.LabeledStatement node) {
    JumpTarget target = _localsMap.getJumpTargetForLabel(node);
    if (target != null) {
      NodeId id = createLabeledStatementId(node);
      SourceSpan sourceSpan = computeSourceSpan(node);
      targets[target] = new TargetData(index++, id, sourceSpan, target);
    }
    super.visitLabeledStatement(node);
  }

  @override
  visitSwitchStatement(ir.SwitchStatement node) {
    addTargetData(
        node, createSwitchId(node), _localsMap.getJumpTargetForSwitch(node));
    super.visitSwitchStatement(node);
  }

  @override
  visitSwitchCase(ir.SwitchCase node) {
    addTargetData(node, createSwitchCaseId(node),
        _localsMap.getJumpTargetForSwitchCase(node));
    super.visitSwitchCase(node);
  }

  @override
  visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    JumpTarget target = _localsMap.getJumpTargetForContinueSwitch(node);
    assert(target != null, 'No target for $node.');
    NodeId id = createGotoId(node);
    SourceSpan sourceSpan = computeSourceSpan(node);
    gotos.add(new GotoData(id, sourceSpan, target));
    super.visitContinueSwitchStatement(node);
  }
}
