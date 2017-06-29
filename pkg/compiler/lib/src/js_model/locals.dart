// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.locals;

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../kernel/element_map.dart';

class GlobalLocalsMap {
  Map<MemberEntity, KernelToLocalsMap> _localsMaps =
      <MemberEntity, KernelToLocalsMap>{};

  KernelToLocalsMap getLocalsMap(MemberEntity member) {
    return _localsMaps.putIfAbsent(
        member, () => new KernelToLocalsMapImpl(member));
  }
}

class KernelToLocalsMapImpl implements KernelToLocalsMap {
  final List<MemberEntity> _members = <MemberEntity>[];
  Map<ir.VariableDeclaration, JLocal> _map = <ir.VariableDeclaration, JLocal>{};
  Map<ir.TreeNode, JJumpTarget> _jumpTargetMap;
  Set<ir.BreakStatement> _breaksAsContinue;

  MemberEntity get currentMember => _members.last;

  // TODO(johnniwinther): Compute this eagerly from the root of the member.
  void _ensureJumpMap(ir.TreeNode node) {
    if (_jumpTargetMap == null) {
      JumpVisitor visitor = new JumpVisitor(currentMember);

      // Find the root node for the current member.
      while (node is! ir.Member) {
        node = node.parent;
      }

      node.accept(visitor);
      _jumpTargetMap = visitor.jumpTargetMap;
      _breaksAsContinue = visitor.breaksAsContinue;
    }
  }

  KernelToLocalsMapImpl(MemberEntity member) {
    _members.add(member);
  }

  @override
  void enterInlinedMember(MemberEntity member) {
    _members.add(member);
  }

  @override
  void leaveInlinedMember(MemberEntity member) {
    assert(member == currentMember);
    _members.removeLast();
  }

  @override
  JumpTarget getJumpTargetForBreak(ir.BreakStatement node) {
    _ensureJumpMap(node.target);
    JumpTarget target = _jumpTargetMap[node];
    assert(target != null, failedAt(currentMember, 'No target for $node.'));
    return target;
  }

  @override
  bool generateContinueForBreak(ir.BreakStatement node) {
    return _breaksAsContinue.contains(node);
  }

  @override
  JumpTarget getJumpTargetForContinueSwitch(ir.ContinueSwitchStatement node) {
    _ensureJumpMap(node.target);
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForContinueSwitch');
  }

  @override
  JumpTarget getJumpTargetForSwitchCase(ir.SwitchCase node) {
    _ensureJumpMap(node);
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForSwitchCase');
  }

  @override
  JumpTarget getJumpTargetForDo(ir.DoStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node.parent];
  }

  @override
  JumpTarget getJumpTargetForLabel(ir.LabeledStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  JumpTarget getJumpTargetForSwitch(ir.SwitchStatement node) {
    _ensureJumpMap(node);
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForSwitch');
  }

  @override
  JumpTarget getJumpTargetForFor(ir.ForStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  JumpTarget getJumpTargetForForIn(ir.ForInStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  JumpTarget getJumpTargetForWhile(ir.WhileStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  Local getLocal(ir.VariableDeclaration node) {
    return _map.putIfAbsent(node, () {
      return new JLocal(node.name, currentMember);
    });
  }

  @override
  LoopClosureScope getLoopClosureScope(
      ClosureDataLookup closureLookup, ir.TreeNode node) {
    return closureLookup.getLoopClosureScope(node);
  }
}

class JumpVisitor extends ir.Visitor {
  int index = 0;
  final MemberEntity member;
  final Map<ir.TreeNode, JJumpTarget> jumpTargetMap =
      <ir.TreeNode, JJumpTarget>{};
  final Set<ir.BreakStatement> breaksAsContinue = new Set<ir.BreakStatement>();

  JumpVisitor(this.member);

  JJumpTarget _getJumpTarget(ir.TreeNode node) {
    return jumpTargetMap.putIfAbsent(node, () {
      return new JJumpTarget(member, index++);
    });
  }

  @override
  defaultNode(ir.Node node) => node.visitChildren(this);

  bool _canBeBreakTarget(ir.TreeNode node) {
    // TODO(johnniwinther): Add more.
    return node is ir.ForStatement ||
        node is ir.ForInStatement ||
        node is ir.WhileStatement;
  }

  bool _canBeContinueTarget(ir.TreeNode node) {
    // TODO(johnniwinther): Add more.
    return node is ir.ForStatement ||
        node is ir.ForInStatement ||
        node is ir.WhileStatement;
  }

  @override
  visitBreakStatement(ir.BreakStatement node) {
    // TODO(johnniwinther): Add labels if the enclosing loop is not the implicit
    // break target.
    JJumpTarget target;
    ir.TreeNode body = node.target.body;
    ir.TreeNode parent = node.target.parent;
    if (_canBeBreakTarget(body)) {
      // We have code like
      //
      //     l1: for (int i = 0; i < 10; i++) {
      //        break l1:
      //     }
      //
      // and can therefore use the for loop as the break target.
      target = _getJumpTarget(body);
      target.isBreakTarget = true;
    } else if (_canBeContinueTarget(parent)) {
      // We have code like
      //
      //     for (int i = 0; i < 10; i++) l1: {
      //        break l1:
      //     }
      //
      // and can therefore use the for loop as a continue target.
      target = _getJumpTarget(parent);
      target.isContinueTarget = true;
      breaksAsContinue.add(node);
    } else {
      target = _getJumpTarget(node.target);
      target.isBreakTarget = true;
    }
    jumpTargetMap[node] = target;
    super.visitBreakStatement(node);
  }
}

class JJumpTarget extends JumpTarget<ir.Node> {
  final MemberEntity memberContext;
  final int nestingLevel;

  JJumpTarget(this.memberContext, this.nestingLevel);

  bool isBreakTarget = false;
  bool isContinueTarget = false;
  bool isSwitch = false;

  @override
  Entity get executableContext => memberContext;

  @override
  LabelDefinition<ir.Node> addLabel(ir.Node label, String labelName,
      {bool isBreakTarget: false}) {
    throw new UnimplementedError('KJumpTarget.addLabel');
  }

  @override
  List<LabelDefinition<ir.Node>> get labels {
    return const <LabelDefinition<ir.Node>>[];
  }

  @override
  ir.Node get statement {
    throw new UnimplementedError('KJumpTarget.statement');
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('KJumpTarget[');
    sb.write('memberContext=');
    sb.write(memberContext);
    sb.write(',nestingLevel=');
    sb.write(nestingLevel);
    sb.write(',isBreakTarget=');
    sb.write(isBreakTarget);
    sb.write(',isContinueTarget=');
    sb.write(isContinueTarget);
    sb.write(']');
    return sb.toString();
  }
}

class JLocal implements Local {
  final String name;
  final MemberEntity memberContext;

  JLocal(this.name, this.memberContext);

  @override
  Entity get executableContext => memberContext;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('local(');
    if (memberContext.enclosingClass != null) {
      sb.write(memberContext.enclosingClass.name);
      sb.write('.');
    }
    sb.write(memberContext.name);
    sb.write('#');
    sb.write(name);
    sb.write(')');
    return sb.toString();
  }
}
