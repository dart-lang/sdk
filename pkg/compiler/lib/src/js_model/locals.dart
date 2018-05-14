// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.locals;

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../kernel/element_map.dart';
import '../kernel/indexed.dart';

import '../js_model/elements.dart' show JGeneratorBody;

class GlobalLocalsMap {
  Map<MemberEntity, KernelToLocalsMap> _localsMaps =
      <MemberEntity, KernelToLocalsMap>{};

  /// Returns the [KernelToLocalsMap] for [member].
  KernelToLocalsMap getLocalsMap(MemberEntity member) {
    // If element is a ConstructorBodyEntity, its localsMap is the same as for
    // ConstructorEntity, because both of these entities came from the same
    // constructor node. The entities are two separate parts because JS does not
    // have the concept of an initializer list, so the constructor (initializer
    // list) and the constructor body are implemented as two separate
    // constructor steps.
    MemberEntity entity = member;
    if (entity is ConstructorBodyEntity) member = entity.constructor;
    return _localsMaps.putIfAbsent(
        member, () => new KernelToLocalsMapImpl(member));
  }

  /// Associates [localsMap] with [member].
  ///
  /// Use this for sharing maps between members that share IR nodes.
  void setLocalsMap(MemberEntity member, KernelToLocalsMap localsMap) {
    assert(member != null, "No member provided.");
    assert(!_localsMaps.containsKey(member),
        "Locals map already created for $member.");
    _localsMaps[member] = localsMap;
  }
}

class KernelToLocalsMapImpl implements KernelToLocalsMap {
  final MemberEntity currentMember;
  final EntityDataMap<JLocal, LocalData> _locals =
      new EntityDataMap<JLocal, LocalData>();
  Map<ir.VariableDeclaration, JLocal> _map = <ir.VariableDeclaration, JLocal>{};
  Map<ir.TreeNode, JJumpTarget> _jumpTargetMap;
  Set<ir.BreakStatement> _breaksAsContinue;

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

  KernelToLocalsMapImpl(this.currentMember);

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
    JumpTarget target = _jumpTargetMap[node];
    assert(target != null, failedAt(currentMember, 'No target for $node.'));
    return target;
  }

  @override
  JumpTarget getJumpTargetForSwitchCase(ir.SwitchCase node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  JumpTarget getJumpTargetForDo(ir.DoStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  JumpTarget getJumpTargetForLabel(ir.LabeledStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  JumpTarget getJumpTargetForSwitch(ir.SwitchStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
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
  Local getLocalVariable(ir.VariableDeclaration node) {
    return _map.putIfAbsent(node, () {
      JLocal local = new JLocal(node.name, currentMember,
          isRegularParameter: node.parent is ir.FunctionNode);
      _locals.register<JLocal, LocalData>(local, new LocalData(node));
      return local;
    });
  }

  @override
  Local getLocalTypeVariable(
      ir.TypeParameterType node, KernelToElementMap elementMap) {
    // TODO(efortuna, johnniwinther): We're not registering the type variables
    // like we are for the variable declarations. Is that okay or do we need to
    // make TypeVariableLocal a JLocal?
    return new TypeVariableLocal(elementMap.getTypeVariableType(node));
  }

  @override
  ir.FunctionNode getFunctionNodeForParameter(covariant JLocal parameter) {
    return _locals.getData(parameter).functionNode;
  }

  @override
  DartType getLocalType(KernelToElementMap elementMap, covariant JLocal local) {
    return _locals.getData(local).getDartType(elementMap);
  }

  @override
  CapturedLoopScope getCapturedLoopScope(
      ClosureDataLookup closureLookup, ir.TreeNode node) {
    return closureLookup.getCapturedLoopScope(node);
  }

  @override
  ClosureRepresentationInfo getClosureRepresentationInfo(
      ClosureDataLookup closureLookup, ir.TreeNode node) {
    return closureLookup.getClosureInfo(node);
  }
}

class JumpVisitor extends ir.Visitor {
  int jumpIndex = 0;
  int labelIndex = 0;
  final MemberEntity member;
  final Map<ir.TreeNode, JJumpTarget> jumpTargetMap =
      <ir.TreeNode, JJumpTarget>{};
  final Set<ir.BreakStatement> breaksAsContinue = new Set<ir.BreakStatement>();

  JumpVisitor(this.member);

  JJumpTarget _getJumpTarget(ir.TreeNode node) {
    return jumpTargetMap.putIfAbsent(node, () {
      return new JJumpTarget(member, jumpIndex++,
          isSwitch: node is ir.SwitchStatement,
          isSwitchCase: node is ir.SwitchCase);
    });
  }

  JLabelDefinition _getOrCreateLabel(JJumpTarget target, ir.Node node) {
    if (target.labels.isEmpty) {
      return target.addLabel(node, 'label${labelIndex++}');
    } else {
      return target.labels.single;
    }
  }

  @override
  defaultNode(ir.Node node) => node.visitChildren(this);

  static bool canBeBreakTarget(ir.TreeNode node) {
    return node is ir.ForStatement ||
        node is ir.ForInStatement ||
        node is ir.WhileStatement ||
        node is ir.DoStatement ||
        node is ir.SwitchStatement;
  }

  static bool canBeContinueTarget(ir.TreeNode node) {
    return node is ir.ForStatement ||
        node is ir.ForInStatement ||
        node is ir.WhileStatement ||
        node is ir.DoStatement;
  }

  @override
  visitBreakStatement(ir.BreakStatement node) {
    JJumpTarget target;
    ir.TreeNode body = node.target.body;
    ir.TreeNode parent = node.target.parent;

    // TODO(johnniwinther): Coordinate with CFE-team to avoid such arbitrary
    // reverse engineering mismatches:
    if (parent is ir.Block && parent.statements.last == node.target) {
      // In strong mode for code like this:
      //
      //     for (int i in list) {
      //       continue;
      //     }
      //
      // an implicit cast may be inserted before the label statement, resulting
      // in code like this:
      //
      //     for (var i in list) {
      //       var #1 = i as int;
      //       l1: {
      //          break l1:
      //       }
      //     }
      //
      // for which we should still use the for loop as a continue target.
      parent = parent.parent;
    }
    if (canBeBreakTarget(body)) {
      // We have code like
      //
      //     l1: for (int i = 0; i < 10; i++) {
      //        break l1:
      //     }
      //
      // and can therefore use the for loop as the break target.
      target = _getJumpTarget(body);
      target.isBreakTarget = true;
      ir.TreeNode search = node;
      bool needsLabel = false;
      while (search != node.target) {
        if (canBeBreakTarget(search)) {
          needsLabel = search != body;
          break;
        }
        search = search.parent;
      }
      if (needsLabel) {
        JLabelDefinition label = _getOrCreateLabel(target, node.target);
        label.isBreakTarget = true;
      }
    } else if (canBeContinueTarget(parent)) {
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
      ir.TreeNode search = node;
      bool needsLabel = false;
      while (search != node.target) {
        if (canBeContinueTarget(search)) {
          needsLabel = search != body;
          break;
        }
        search = search.parent;
      }
      if (needsLabel) {
        JLabelDefinition label = _getOrCreateLabel(target, node.target);
        label.isContinueTarget = true;
      }
    } else {
      // We have code like
      //
      //     label: if (c) {
      //         if (c < 10) break label;
      //     }
      //
      // and label is therefore always needed.
      target = _getJumpTarget(node.target);
      target.isBreakTarget = true;
      JLabelDefinition label = _getOrCreateLabel(target, node.target);
      label.isBreakTarget = true;
    }
    jumpTargetMap[node] = target;
    super.visitBreakStatement(node);
  }

  @override
  visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    JJumpTarget target = _getJumpTarget(node.target);
    target.isContinueTarget = true;
    jumpTargetMap[node] = target;
    JLabelDefinition label = _getOrCreateLabel(target, node.target);
    label.isContinueTarget = true;
    super.visitContinueSwitchStatement(node);
  }

  @override
  visitSwitchStatement(ir.SwitchStatement node) {
    node.expression.accept(this);
    if (node.cases.isNotEmpty) {
      // Ensure that [node] has a corresponding target. We generate a break if:
      //   - a switch case calls a function that always throws
      //   - there's a missing break on the last case if it isn't a default case
      _getJumpTarget(node);
    }
    super.visitSwitchStatement(node);
  }
}

class JJumpTarget extends JumpTarget<ir.Node> {
  final MemberEntity memberContext;
  final int nestingLevel;
  List<LabelDefinition<ir.Node>> _labels;
  final bool isSwitch;
  final bool isSwitchCase;

  JJumpTarget(this.memberContext, this.nestingLevel,
      {this.isSwitch: false, this.isSwitchCase: false});

  bool isBreakTarget = false;
  bool isContinueTarget = false;

  @override
  LabelDefinition<ir.Node> addLabel(ir.Node label, String labelName,
      {bool isBreakTarget: false, bool isContinueTarget: false}) {
    _labels ??= <LabelDefinition<ir.Node>>[];
    LabelDefinition<ir.Node> labelDefinition = new JLabelDefinition(
        this, labelName,
        isBreakTarget: isBreakTarget, isContinueTarget: isContinueTarget);
    _labels.add(labelDefinition);
    return labelDefinition;
  }

  @override
  List<LabelDefinition<ir.Node>> get labels {
    return _labels ?? const <LabelDefinition<ir.Node>>[];
  }

  @override
  ir.Node get statement {
    throw new UnimplementedError('JJumpTarget.statement');
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('JJumpTarget(');
    sb.write('memberContext=');
    sb.write(memberContext);
    sb.write(',nestingLevel=');
    sb.write(nestingLevel);
    sb.write(',isBreakTarget=');
    sb.write(isBreakTarget);
    sb.write(',isContinueTarget=');
    sb.write(isContinueTarget);
    if (_labels != null) {
      sb.write(',labels=');
      sb.write(_labels);
    }
    sb.write(')');
    return sb.toString();
  }
}

class JLabelDefinition extends LabelDefinition<ir.Node> {
  final JumpTarget<ir.Node> target;
  final String labelName;
  bool isBreakTarget;
  bool isContinueTarget;

  JLabelDefinition(this.target, this.labelName,
      {this.isBreakTarget: false, this.isContinueTarget: false});

  @override
  String get name => labelName;
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('JLabelDefinition(');
    sb.write(',labelName=');
    sb.write(labelName);
    sb.write(',isBreakTarget=');
    sb.write(isBreakTarget);
    sb.write(',isContinueTarget=');
    sb.write(isContinueTarget);
    sb.write(')');
    return sb.toString();
  }
}

class JLocal extends IndexedLocal {
  final String name;
  final MemberEntity memberContext;

  /// True if this local represents a local parameter.
  final bool isRegularParameter;

  JLocal(this.name, this.memberContext, {this.isRegularParameter: false}) {
    assert(memberContext is! JGeneratorBody);
  }

  String get _kind => 'local';

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('$_kind(');
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

class LocalData {
  final ir.VariableDeclaration node;

  DartType _type;

  LocalData(this.node);

  DartType getDartType(KernelToElementMap elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  ir.FunctionNode get functionNode => node.parent;
}

/// Calls [f] for each parameter in [function] in the canonical order:
/// Positional parameters by index, then named parameters lexicographically.
void forEachOrderedParameter(
    GlobalLocalsMap globalLocalsMap,
    KernelToElementMapForBuilding elementMap,
    FunctionEntity function,
    void f(Local parameter)) {
  KernelToLocalsMap localsMap = globalLocalsMap.getLocalsMap(function);

  void processFunctionNode(ir.FunctionNode node) {
    for (ir.VariableDeclaration variable in node.positionalParameters) {
      f(localsMap.getLocalVariable(variable));
    }
    List<ir.VariableDeclaration> namedParameters =
        new List<ir.VariableDeclaration>.from(node.namedParameters);
    namedParameters.sort(namedOrdering);
    for (ir.VariableDeclaration variable in namedParameters) {
      f(localsMap.getLocalVariable(variable));
    }
  }

  MemberDefinition definition = elementMap.getMemberDefinition(function);
  switch (definition.kind) {
    case MemberKind.regular:
      ir.Node node = definition.node;
      if (node is ir.Procedure) {
        processFunctionNode(node.function);
        return;
      }
      break;
    case MemberKind.constructor:
    case MemberKind.constructorBody:
      ir.Node node = definition.node;
      if (node is ir.Procedure) {
        processFunctionNode(node.function);
        return;
      } else if (node is ir.Constructor) {
        processFunctionNode(node.function);
        return;
      }
      break;
    case MemberKind.closureCall:
      ir.Node node = definition.node;
      if (node is ir.FunctionDeclaration) {
        processFunctionNode(node.function);
        return;
      } else if (node is ir.FunctionExpression) {
        processFunctionNode(node.function);
        return;
      }
      break;
    default:
  }
  failedAt(function, "Unexpected function definition $definition.");
}
