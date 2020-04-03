// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.locals;

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../serialization/serialization.dart';

import 'element_map.dart';
import 'elements.dart' show JGeneratorBody;

class GlobalLocalsMap {
  /// Tag used for identifying serialized [GlobalLocalsMap] objects in a
  /// debugging data stream.
  static const String tag = 'global-locals-map';

  final Map<MemberEntity, KernelToLocalsMap> _localsMaps;

  GlobalLocalsMap() : _localsMaps = {};

  GlobalLocalsMap.internal(this._localsMaps);

  /// Deserializes a [GlobalLocalsMap] object from [source].
  factory GlobalLocalsMap.readFromDataSource(DataSource source) {
    source.begin(tag);
    Map<MemberEntity, KernelToLocalsMap> _localsMaps = {};
    int mapCount = source.readInt();
    for (int i = 0; i < mapCount; i++) {
      KernelToLocalsMap localsMap =
          new KernelToLocalsMapImpl.readFromDataSource(source);
      List<MemberEntity> members = source.readMembers();
      for (MemberEntity member in members) {
        _localsMaps[member] = localsMap;
      }
    }
    source.end(tag);
    return new GlobalLocalsMap.internal(_localsMaps);
  }

  /// Serializes this [GlobalLocalsMap] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    // [KernelToLocalsMap]s are shared between members and their nested
    // closures, so we reverse [_localsMaps] to ensure that [KernelToLocalsMap]s
    // are shared upon deserialization. The sharing is needed for correctness
    // since captured variables will otherwise have distinct locals for their
    // non-captured and captured uses.
    Map<KernelToLocalsMap, List<MemberEntity>> reverseMap = {};
    _localsMaps.forEach((MemberEntity member, KernelToLocalsMap localsMap) {
      reverseMap.putIfAbsent(localsMap, () => []).add(member);
    });
    sink.writeInt(reverseMap.length);
    reverseMap
        .forEach((KernelToLocalsMap localsMap, List<MemberEntity> members) {
      localsMap.writeToDataSink(sink);
      sink.writeMembers(members);
    });
    sink.end(tag);
  }

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
  /// Tag used for identifying serialized [KernelToLocalsMapImpl] objects in a
  /// debugging data stream.
  static const String tag = 'locals-map';

  MemberEntity _currentMember;
  final EntityDataMap<JLocal, LocalData> _locals =
      new EntityDataMap<JLocal, LocalData>();
  Map<ir.VariableDeclaration, JLocal> _variableMap =
      <ir.VariableDeclaration, JLocal>{};
  Map<ir.TreeNode, JJumpTarget> _jumpTargetMap;
  Iterable<ir.BreakStatement> _breaksAsContinue;

  KernelToLocalsMapImpl(this._currentMember);

  /// Deserializes a [KernelToLocalsMapImpl] object from [source].
  KernelToLocalsMapImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    _currentMember = source.readMember();
    int localsCount = source.readInt();
    for (int i = 0; i < localsCount; i++) {
      int index = source.readInt();
      String name = source.readStringOrNull();
      bool isRegularParameter = source.readBool();
      ir.VariableDeclaration node = source.readTreeNode();
      JLocal local = new JLocal(name, currentMember,
          isRegularParameter: isRegularParameter);
      LocalData data = new LocalData(node);
      _locals.registerByIndex(index, local, data);
      _variableMap[node] = local;
    }
    int jumpCount = source.readInt();
    if (jumpCount > 0) {
      _jumpTargetMap = {};
      for (int i = 0; i < jumpCount; i++) {
        JJumpTarget target = new JJumpTarget.readFromDataSource(source);
        List<ir.TreeNode> nodes = source.readTreeNodes();
        for (ir.TreeNode node in nodes) {
          _jumpTargetMap[node] = target;
        }
      }
    }
    _breaksAsContinue = source.readTreeNodes();
    source.end(tag);
  }

  /// Serializes this [KernelToLocalsMapImpl] to [sink].
  @override
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMember(currentMember);
    sink.writeInt(_locals.size);
    _locals.forEach((JLocal local, LocalData data) {
      assert(local.memberContext == currentMember);
      sink.writeInt(local.localIndex);
      sink.writeStringOrNull(local.name);
      sink.writeBool(local.isRegularParameter);
      sink.writeTreeNode(data.node);
    });
    if (_jumpTargetMap != null) {
      // [JJumpTarget]s are shared between nodes, so we reverse
      // [_jumpTargetMap] to ensure that [JJumpTarget]s are shared upon
      // deserialization. This sharing is needed for correctness since for
      // instance a label statement containing a for loop both constitutes the
      // same jump target and the SSA graph builder dependents on this property.
      Map<JJumpTarget, List<ir.TreeNode>> reversedMap = {};
      _jumpTargetMap.forEach((ir.TreeNode node, JJumpTarget target) {
        reversedMap.putIfAbsent(target, () => []).add(node);
      });
      sink.writeInt(reversedMap.length);
      reversedMap.forEach((JJumpTarget target, List<ir.TreeNode> nodes) {
        target.writeToDataSink(sink);
        sink.writeTreeNodes(nodes);
      });
    } else {
      sink.writeInt(0);
    }
    sink.writeTreeNodes(_breaksAsContinue, allowNull: true);
    sink.end(tag);
  }

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

  @override
  MemberEntity get currentMember => _currentMember;

  Local getLocalByIndex(int index) {
    return _locals.getEntity(index);
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
    return _variableMap.putIfAbsent(node, () {
      JLocal local = new JLocal(node.name, currentMember,
          isRegularParameter: node.parent is ir.FunctionNode);
      _locals.register<JLocal, LocalData>(local, new LocalData(node));
      return local;
    });
  }

  @override
  Local getLocalTypeVariable(
      ir.TypeParameterType node, JsToElementMap elementMap) {
    // TODO(efortuna, johnniwinther): We're not registering the type variables
    // like we are for the variable declarations. Is that okay or do we need to
    // make TypeVariableLocal a JLocal?
    return new TypeVariableLocal(elementMap.getTypeVariableType(node).element);
  }

  @override
  ir.FunctionNode getFunctionNodeForParameter(covariant JLocal parameter) {
    return _locals.getData(parameter).functionNode;
  }

  @override
  DartType getLocalType(JsToElementMap elementMap, covariant JLocal local) {
    return _locals.getData(local).getDartType(elementMap);
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

  JLabelDefinition _getOrCreateLabel(JJumpTarget target) {
    if (target.labels.isEmpty) {
      return target.addLabel('label${labelIndex++}');
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
        JLabelDefinition label = _getOrCreateLabel(target);
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
        JLabelDefinition label = _getOrCreateLabel(target);
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
      JLabelDefinition label = _getOrCreateLabel(target);
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
    JLabelDefinition label = _getOrCreateLabel(target);
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

class JJumpTarget extends JumpTarget {
  /// Tag used for identifying serialized [JJumpTarget] objects in a
  /// debugging data stream.
  static const String tag = 'jump-target';

  final MemberEntity memberContext;
  @override
  final int nestingLevel;
  List<LabelDefinition> _labels;
  @override
  final bool isSwitch;
  @override
  final bool isSwitchCase;
  @override
  bool isBreakTarget;
  @override
  bool isContinueTarget;

  JJumpTarget(this.memberContext, this.nestingLevel,
      {this.isSwitch: false,
      this.isSwitchCase: false,
      this.isBreakTarget: false,
      this.isContinueTarget: false});

  /// Deserializes a [JJumpTarget] object from [source].
  factory JJumpTarget.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberEntity memberContext = source.readMember();
    int nestingLevel = source.readInt();
    bool isSwitch = source.readBool();
    bool isSwitchCase = source.readBool();
    bool isBreakTarget = source.readBool();
    bool isContinueTarget = source.readBool();
    JJumpTarget target = new JJumpTarget(memberContext, nestingLevel,
        isSwitch: isSwitch,
        isSwitchCase: isSwitchCase,
        isBreakTarget: isBreakTarget,
        isContinueTarget: isContinueTarget);
    int labelCount = source.readInt();
    for (int i = 0; i < labelCount; i++) {
      String labelName = source.readString();
      bool isBreakTarget = source.readBool();
      bool isContinueTarget = source.readBool();
      target.addLabel(labelName,
          isBreakTarget: isBreakTarget, isContinueTarget: isContinueTarget);
    }
    source.end(tag);
    return target;
  }

  /// Serializes this [JJumpTarget] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMember(memberContext);
    sink.writeInt(nestingLevel);
    sink.writeBool(isSwitch);
    sink.writeBool(isSwitchCase);
    sink.writeBool(isBreakTarget);
    sink.writeBool(isContinueTarget);
    if (_labels != null) {
      sink.writeInt(_labels.length);
      for (LabelDefinition definition in _labels) {
        sink.writeString(definition.name);
        sink.writeBool(definition.isBreakTarget);
        sink.writeBool(definition.isContinueTarget);
      }
    } else {
      sink.writeInt(0);
    }
    sink.end(tag);
  }

  @override
  LabelDefinition addLabel(String labelName,
      {bool isBreakTarget: false, bool isContinueTarget: false}) {
    _labels ??= <LabelDefinition>[];
    LabelDefinition labelDefinition = new JLabelDefinition(this, labelName,
        isBreakTarget: isBreakTarget, isContinueTarget: isContinueTarget);
    _labels.add(labelDefinition);
    return labelDefinition;
  }

  @override
  List<LabelDefinition> get labels {
    return _labels ?? const <LabelDefinition>[];
  }

  @override
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

class JLabelDefinition extends LabelDefinition {
  @override
  final JumpTarget target;
  @override
  final String labelName;
  @override
  bool isBreakTarget;
  @override
  bool isContinueTarget;

  JLabelDefinition(this.target, this.labelName,
      {this.isBreakTarget: false, this.isContinueTarget: false});

  @override
  String get name => labelName;
  @override
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
  @override
  final String name;
  final MemberEntity memberContext;

  /// True if this local represents a local parameter.
  final bool isRegularParameter;

  JLocal(this.name, this.memberContext, {this.isRegularParameter: false}) {
    assert(memberContext is! JGeneratorBody);
  }

  String get _kind => 'local';

  @override
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

  DartType getDartType(JsToElementMap elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  ir.FunctionNode get functionNode => node.parent;
}

/// Calls [f] for each parameter in [function] in the canonical order:
/// Positional parameters by index, then named parameters lexicographically.
void forEachOrderedParameterAsLocal(
    GlobalLocalsMap globalLocalsMap,
    JsToElementMap elementMap,
    FunctionEntity function,
    void f(Local parameter, {bool isElided})) {
  KernelToLocalsMap localsMap = globalLocalsMap.getLocalsMap(function);
  forEachOrderedParameter(elementMap, function,
      (ir.VariableDeclaration variable, {bool isElided}) {
    f(localsMap.getLocalVariable(variable), isElided: isElided);
  });
}
