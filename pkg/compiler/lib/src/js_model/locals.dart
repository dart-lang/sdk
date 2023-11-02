// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.locals;

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../elements/entities.dart';
import '../elements/entity_map.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../serialization/deferrable.dart';
import '../serialization/serialization.dart';

import 'element_map.dart';
import 'elements.dart' show JGeneratorBody;

class GlobalLocalsMap {
  /// Tag used for identifying serialized [GlobalLocalsMap] objects in a
  /// debugging data stream.
  static const String tag = 'global-locals-map';

  /// Lookup up the key used to store a LocalsMap for a member.
  ///
  /// While procedures are keyed by their own entity, closures use the
  /// enclosing member as a key. This ensures that the member and all
  /// nested closures share the same local map.
  MemberEntity Function(MemberEntity) _localMapKeyLookup;

  final Map<MemberEntity, KernelToLocalsMap> _localsMaps;

  GlobalLocalsMap(this._localMapKeyLookup) : _localsMaps = {};

  GlobalLocalsMap.internal(this._localMapKeyLookup, this._localsMaps);

  /// Deserializes a [GlobalLocalsMap] object from [source].
  factory GlobalLocalsMap.readFromDataSource(
      MemberEntity Function(MemberEntity) localMapKeyLookup,
      DataSourceReader source) {
    source.begin(tag);
    Map<MemberEntity, Deferrable<KernelToLocalsMap>> _localsMaps = {};
    int mapCount = source.readInt();
    for (int i = 0; i < mapCount; i++) {
      Deferrable<KernelToLocalsMap> localsMap =
          source.readDeferrable(KernelToLocalsMapImpl.readFromDataSource);
      List<MemberEntity> members = source.readMembers();
      for (MemberEntity member in members) {
        _localsMaps[member] = localsMap;
      }
    }
    source.end(tag);
    return GlobalLocalsMap.internal(
        localMapKeyLookup, DeferrableValueMap(_localsMaps));
  }

  /// Serializes this [GlobalLocalsMap] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
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
      sink.writeDeferrable(() => localsMap.writeToDataSink(sink));
      sink.writeMembers(members);
    });
    sink.end(tag);
  }

  /// Returns the [KernelToLocalsMap] for [member].
  KernelToLocalsMap getLocalsMap(MemberEntity member) {
    // If [member] is a closure call method or closure signature method, its
    // localsMap is the same as for the enclosing member since the locals are
    // derived from the same kernel AST.
    MemberEntity key = _localMapKeyLookup(member);
    // If [member] is a ConstructorBodyEntity, its localsMap is the same as for
    // ConstructorEntity, because both of these entities came from the same
    // constructor node. The entities are two separate parts because JS does not
    // have the concept of an initializer list, so the constructor (initializer
    // list) and the constructor body are implemented as two separate
    // constructor steps.
    MemberEntity entity = key;
    if (entity is ConstructorBodyEntity) key = entity.constructor;
    return _localsMaps.putIfAbsent(key, () => KernelToLocalsMapImpl(key));
  }
}

class KernelToLocalsMapImpl implements KernelToLocalsMap {
  /// Tag used for identifying serialized [KernelToLocalsMapImpl] objects in a
  /// debugging data stream.
  static const String tag = 'locals-map';

  late final MemberEntity _currentMember;
  final EntityDataMap<JLocal, LocalData> _locals = EntityDataMap();
  Map<ir.VariableDeclaration, JLocal>? _variableMap;
  Map<ir.TreeNode, JJumpTarget>? _jumpTargetMap;
  Iterable<ir.BreakStatement>? _breaksAsContinue;

  KernelToLocalsMapImpl(this._currentMember);

  /// Deserializes a [KernelToLocalsMapImpl] object from [source].
  KernelToLocalsMapImpl.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    _currentMember = source.readMember();
    int localsCount = source.readInt();
    if (localsCount > 0) {
      final variableMap = _variableMap = {};
      for (int i = 0; i < localsCount; i++) {
        final local = source.readLocal() as JLocal;
        final node = source.readTreeNode() as ir.VariableDeclaration;
        LocalData data = LocalData(node);
        _locals.register<JLocal, LocalData>(local, data);
        variableMap[node] = local;
      }
    }
    int jumpCount = source.readInt();
    if (jumpCount > 0) {
      final jumpTargetMap = _jumpTargetMap = {};
      for (int i = 0; i < jumpCount; i++) {
        JJumpTarget target = JJumpTarget.readFromDataSource(source);
        List<ir.TreeNode> nodes = source.readTreeNodes();
        for (ir.TreeNode node in nodes) {
          jumpTargetMap[node] = target;
        }
      }
    }
    _breaksAsContinue = source.readTreeNodesOrNull() ?? const [];
    source.end(tag);
  }

  /// Serializes this [KernelToLocalsMapImpl] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMember(currentMember);
    sink.writeInt(_locals.length);
    _locals.forEach((JLocal local, LocalData data) {
      assert(local.memberContext == currentMember);
      sink.writeLocal(local);
      sink.writeTreeNode(data.node);
    });
    if (_jumpTargetMap != null) {
      // [JJumpTarget]s are shared between nodes, so we reverse
      // [_jumpTargetMap] to ensure that [JJumpTarget]s are shared upon
      // deserialization. This sharing is needed for correctness since for
      // instance a label statement containing a for loop both constitutes the
      // same jump target and the SSA graph builder dependents on this property.
      Map<JJumpTarget, List<ir.TreeNode>> reversedMap = {};
      _jumpTargetMap!.forEach((ir.TreeNode node, JJumpTarget target) {
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
      JumpVisitor visitor = JumpVisitor(currentMember);

      // Find the root node for the current member.
      while (node is! ir.Member) {
        node = node.parent!;
      }

      node.accept(visitor);
      _jumpTargetMap = visitor.jumpTargetMap;
      _breaksAsContinue = visitor.breaksAsContinue;
    }
  }

  @override
  MemberEntity get currentMember => _currentMember;

  @override
  JumpTarget getJumpTargetForBreak(ir.BreakStatement node) {
    _ensureJumpMap(node.target);
    return _jumpTargetMap![node] ??
        failedAt(
            currentMember, 'Could not find target for break statement: $node');
  }

  @override
  bool generateContinueForBreak(ir.BreakStatement node) {
    return _breaksAsContinue!.contains(node);
  }

  @override
  JumpTarget getJumpTargetForContinueSwitch(ir.ContinueSwitchStatement node) {
    _ensureJumpMap(node.target);
    return _jumpTargetMap![node] ??
        failedAt(currentMember, 'No target for $node.');
  }

  @override
  JumpTarget? getJumpTargetForSwitchCase(ir.SwitchCase node) {
    _ensureJumpMap(node);
    return _jumpTargetMap![node];
  }

  @override
  JumpTarget? getJumpTargetForDo(ir.DoStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap![node];
  }

  @override
  JumpTarget? getJumpTargetForLabel(ir.LabeledStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap![node];
  }

  @override
  JumpTarget? getJumpTargetForSwitch(ir.SwitchStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap![node];
  }

  @override
  JumpTarget? getJumpTargetForFor(ir.ForStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap![node];
  }

  @override
  JumpTarget? getJumpTargetForForIn(ir.ForInStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap![node];
  }

  @override
  JumpTarget? getJumpTargetForWhile(ir.WhileStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap![node];
  }

  @override
  Local getLocalVariable(ir.VariableDeclaration node) {
    final variableMap = _variableMap ??= {};
    return variableMap.putIfAbsent(node, () {
      JLocal local = JLocal(node.name, currentMember,
          isRegularParameter: node.parent is ir.FunctionNode);
      _locals.register<JLocal, LocalData>(local, LocalData(node));
      return local;
    });
  }

  @override
  Local getLocalTypeVariableEntity(TypeVariableEntity typeVariable) {
    // TODO(efortuna, johnniwinther): We're not registering the type variables
    // like we are for the variable declarations. Is that okay or do we need to
    // make TypeVariableLocal a JLocal?
    return TypeVariableLocal(typeVariable);
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

class JumpVisitor extends ir.VisitorDefault<void> with ir.VisitorVoidMixin {
  int jumpIndex = 0;
  int labelIndex = 0;
  final MemberEntity member;
  final Map<ir.TreeNode, JJumpTarget> jumpTargetMap = {};
  final Set<ir.BreakStatement> breaksAsContinue = {};

  JumpVisitor(this.member);

  JJumpTarget _getJumpTarget(ir.TreeNode node) {
    return jumpTargetMap.putIfAbsent(node, () {
      return JJumpTarget(member, jumpIndex++,
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
        node is ir.DoStatement ||
        node is ir.SwitchStatement && mightBeImplementedAsLoop(node);
  }

  static bool mightBeImplementedAsLoop(ir.SwitchStatement node) {
    // ir.SwitchStatements that contain ir.ContinueSwitchStatements are compiled
    // to a loop surrounding a switch statement. This additional surrounding
    // loop means that a label is needed for a `break` or `continue` to skip the
    // loop.

    // Ideally we would do an analysis of the switch to see if it contains a
    // ContinueSwitchStatement. This is exceedingly rare outside of
    // tests. Simply returning `true` gives a false positive that a label is
    // needed. This causes an unnecessary label to be defined and used when the
    // original code contains (1) a switch in a loop and (2) a switch case uses
    // `continue` to jump to the loop, but is otherwise harmless.  This
    // combination of conditions is uncommon so we see only a few extra labels
    // in the largest code-bases.
    return true;

    // TODO(http://dartbug.com/51777): Avoid this issue by implementing the
    // continue-switch feature entirely in front-end.
  }

  @override
  visitBreakStatement(ir.BreakStatement node) {
    JJumpTarget target;
    ir.TreeNode body = node.target.body;
    ir.TreeNode parent = node.target.parent!;

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
      parent = parent.parent!;
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
        search = search.parent!;
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
        search = search.parent!;
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
  List<JLabelDefinition>? _labels;
  @override
  final bool isSwitch;
  @override
  final bool isSwitchCase;
  @override
  bool isBreakTarget;
  @override
  bool isContinueTarget;

  JJumpTarget(this.memberContext, this.nestingLevel,
      {this.isSwitch = false,
      this.isSwitchCase = false,
      this.isBreakTarget = false,
      this.isContinueTarget = false});

  /// Deserializes a [JJumpTarget] object from [source].
  factory JJumpTarget.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    MemberEntity memberContext = source.readMember();
    int nestingLevel = source.readInt();
    bool isSwitch = source.readBool();
    bool isSwitchCase = source.readBool();
    bool isBreakTarget = source.readBool();
    bool isContinueTarget = source.readBool();
    JJumpTarget target = JJumpTarget(memberContext, nestingLevel,
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
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMember(memberContext);
    sink.writeInt(nestingLevel);
    sink.writeBool(isSwitch);
    sink.writeBool(isSwitchCase);
    sink.writeBool(isBreakTarget);
    sink.writeBool(isContinueTarget);
    final labels = _labels;
    if (labels != null) {
      sink.writeInt(labels.length);
      for (LabelDefinition definition in labels) {
        sink.writeString(definition.name!);
        sink.writeBool(definition.isBreakTarget);
        sink.writeBool(definition.isContinueTarget);
      }
    } else {
      sink.writeInt(0);
    }
    sink.end(tag);
  }

  @override
  JLabelDefinition addLabel(String labelName,
      {bool isBreakTarget = false, bool isContinueTarget = false}) {
    _labels ??= <JLabelDefinition>[];
    final labelDefinition = JLabelDefinition(this, labelName,
        isBreakTarget: isBreakTarget, isContinueTarget: isContinueTarget);
    _labels!.add(labelDefinition);
    return labelDefinition;
  }

  @override
  List<JLabelDefinition> get labels {
    return _labels ?? const <JLabelDefinition>[];
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
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
      {this.isBreakTarget = false, this.isContinueTarget = false});

  @override
  String get name => labelName;
  @override
  String toString() {
    StringBuffer sb = StringBuffer();
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

class JLocal with EntityMapKey implements Local {
  static const String tag = 'jlocal';
  @override
  final String? name;
  final MemberEntity memberContext;

  /// True if this local represents a local parameter.
  final bool isRegularParameter;

  JLocal(this.name, this.memberContext, {this.isRegularParameter = false}) {
    assert(memberContext is! JGeneratorBody);
  }

  factory JLocal.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    final name = source.readStringOrNull();
    final memberContext = source.readMember();
    final isRegularParameter = source.readBool();
    source.end(tag);
    return JLocal(name, memberContext, isRegularParameter: isRegularParameter);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeStringOrNull(name);
    sink.writeMember(memberContext);
    sink.writeBool(isRegularParameter);
    sink.end(tag);
  }

  String get _kind => 'local';

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('$_kind(');
    if (memberContext.enclosingClass != null) {
      sb.write(memberContext.enclosingClass!.name);
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

  DartType? _type;

  LocalData(this.node);

  DartType getDartType(JsToElementMap elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  ir.FunctionNode get functionNode => node.parent as ir.FunctionNode;
}

/// Calls [f] for each parameter in [function] in the canonical order:
/// Positional parameters by index, then named parameters lexicographically.
void forEachOrderedParameterAsLocal(
    GlobalLocalsMap globalLocalsMap,
    JsToElementMap elementMap,
    FunctionEntity function,
    void f(Local parameter, {required bool isElided})) {
  KernelToLocalsMap localsMap = globalLocalsMap.getLocalsMap(function);
  forEachOrderedParameter(elementMap, function,
      (ir.VariableDeclaration variable, {required bool isElided}) {
    f(localsMap.getLocalVariable(variable), isElided: isElided);
  });
}
