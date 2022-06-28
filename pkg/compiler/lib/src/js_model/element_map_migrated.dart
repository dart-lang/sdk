// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../ir/util.dart';
import '../serialization/deferrable.dart';
import '../serialization/serialization.dart';
import 'element_map_interfaces.dart';

// TODO(48820): Merge back into element_map.dart when migration is done.

/// Map from kernel IR nodes to local entities.
abstract class KernelToLocalsMap {
  /// The member currently being built.
  MemberEntity get currentMember;

  /// Returns the [Local] for [node].
  Local getLocalVariable(ir.VariableDeclaration node);

  /// Returns the [Local] for the [typeVariable].
  Local getLocalTypeVariableEntity(TypeVariableEntity typeVariable);

  /// Returns the [ir.FunctionNode] that declared [parameter].
  ir.FunctionNode getFunctionNodeForParameter(Local parameter);

  /// Returns the [DartType] of [local].
  DartType getLocalType(JsToElementMap elementMap, Local local);

  /// Returns the [JumpTarget] for the break statement [node].
  JumpTarget getJumpTargetForBreak(ir.BreakStatement node);

  /// Returns `true` if [node] should generate a `continue` to its [JumpTarget].
  bool generateContinueForBreak(ir.BreakStatement node);

  /// Returns the [JumpTarget] defined by the labelled statement [node] or
  /// `null` if [node] is not a jump target.
  JumpTarget? getJumpTargetForLabel(ir.LabeledStatement node);

  /// Returns the [JumpTarget] defined by the switch statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget? getJumpTargetForSwitch(ir.SwitchStatement node);

  /// Returns the [JumpTarget] for the continue switch statement [node].
  JumpTarget getJumpTargetForContinueSwitch(ir.ContinueSwitchStatement node);

  /// Returns the [JumpTarget] defined by the switch case [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget? getJumpTargetForSwitchCase(ir.SwitchCase node);

  /// Returns the [JumpTarget] defined the do statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget? getJumpTargetForDo(ir.DoStatement node);

  /// Returns the [JumpTarget] defined by the for statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget? getJumpTargetForFor(ir.ForStatement node);

  /// Returns the [JumpTarget] defined by the for-in statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget? getJumpTargetForForIn(ir.ForInStatement node);

  /// Returns the [JumpTarget] defined by the while statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget? getJumpTargetForWhile(ir.WhileStatement node);

  /// Serializes this [KernelToLocalsMap] to [sink].
  void writeToDataSink(DataSinkWriter sink);
}

// TODO(johnniwinther,efortuna): Add more when needed.
// TODO(johnniwinther): Should we split regular into method, field, etc.?
enum MemberKind {
  /// A regular member defined by an [ir.Node].
  regular,

  /// A constructor whose initializer is defined by an [ir.Constructor] node.
  constructor,

  /// A constructor whose body is defined by an [ir.Constructor] node.
  constructorBody,

  /// A closure class `call` method whose body is defined by an
  /// [ir.LocalFunction].
  closureCall,

  /// A field corresponding to a captured variable in the closure. It does not
  /// have a corresponding ir.Node.
  closureField,

  /// A method that describes the type of a function (in this case the type of
  /// the closure class. It does not have a corresponding ir.Node or a method
  /// body.
  signature,

  /// A separated body of a generator (sync*/async/async*) function.
  generatorBody,
}

/// Definition information for a [MemberEntity].
abstract class MemberDefinition {
  /// The kind of the defined member. This determines the semantics of [node].
  MemberKind get kind;

  /// The defining [ir.Node] for this member, if supported by its [kind].
  ///
  /// For a regular class this is the [ir.Class] node. For closure classes this
  /// might be an [ir.FunctionExpression] node if needed.
  ir.Node get node;

  /// The canonical location of [member]. This is used for sorting the members
  /// in the emitted code.
  SourceSpan get location;

  /// Deserializes a [MemberDefinition] object from [source].
  factory MemberDefinition.readFromDataSource(DataSourceReader source) {
    MemberKind kind = source.readEnum(MemberKind.values);
    switch (kind) {
      case MemberKind.regular:
        return RegularMemberDefinition.readFromDataSource(source);
      case MemberKind.constructor:
      case MemberKind.constructorBody:
      case MemberKind.signature:
      case MemberKind.generatorBody:
        return SpecialMemberDefinition.readFromDataSource(source, kind);
      case MemberKind.closureCall:
      case MemberKind.closureField:
        return ClosureMemberDefinition.readFromDataSource(source, kind);
    }
  }

  /// Serializes this [MemberDefinition] to [sink].
  void writeToDataSink(DataSinkWriter sink);
}

/// A member directly defined by its [ir.Member] node.
class RegularMemberDefinition implements MemberDefinition {
  /// Tag used for identifying serialized [RegularMemberDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'regular-member-definition';

  @override
  final ir.Member node;

  RegularMemberDefinition(this.node);

  factory RegularMemberDefinition.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    source.end(tag);
    return RegularMemberDefinition(node);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(MemberKind.regular);
    sink.begin(tag);
    sink.writeMemberNode(node);
    sink.end(tag);
  }

  @override
  SourceSpan get location => computeSourceSpanFromTreeNode(node);

  @override
  MemberKind get kind => MemberKind.regular;

  @override
  String toString() => 'RegularMemberDefinition(kind:$kind,'
      'node:$node,location:$location)';
}

/// The definition of a special kind of member
class SpecialMemberDefinition implements MemberDefinition {
  /// Tag used for identifying serialized [SpecialMemberDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'special-member-definition';

  @override
  ir.TreeNode get node => _node.loaded();
  final Deferrable<ir.TreeNode> _node;
  @override
  final MemberKind kind;

  SpecialMemberDefinition(ir.TreeNode node, this.kind)
      : _node = Deferrable.eager(node);

  SpecialMemberDefinition.from(MemberDefinition baseMember, this.kind)
      : _node = baseMember is ClosureMemberDefinition
            ? baseMember._node
            : Deferrable.eager(baseMember.node as ir.TreeNode);

  SpecialMemberDefinition._deserialized(this._node, this.kind);

  factory SpecialMemberDefinition.readFromDataSource(
      DataSourceReader source, MemberKind kind) {
    source.begin(tag);
    Deferrable<ir.TreeNode> node =
        source.readDeferrable(() => source.readTreeNode());
    source.end(tag);
    return SpecialMemberDefinition._deserialized(node, kind);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(kind);
    sink.begin(tag);
    sink.writeDeferrable(() => sink.writeTreeNode(node));
    sink.end(tag);
  }

  @override
  SourceSpan get location => computeSourceSpanFromTreeNode(node);

  @override
  String toString() => 'SpecialMemberDefinition(kind:$kind,'
      'node:$node,location:$location)';
}

class ClosureMemberDefinition implements MemberDefinition {
  /// Tag used for identifying serialized [ClosureMemberDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'closure-member-definition';

  @override
  final SourceSpan location;
  @override
  final MemberKind kind;
  @override
  ir.TreeNode get node => _node.loaded();
  final Deferrable<ir.TreeNode> _node;

  ClosureMemberDefinition(this.location, this.kind, ir.TreeNode node)
      : _node = Deferrable.eager(node),
        assert(
            kind == MemberKind.closureCall || kind == MemberKind.closureField);

  ClosureMemberDefinition._deserialized(this.location, this.kind, this._node)
      : assert(
            kind == MemberKind.closureCall || kind == MemberKind.closureField);

  factory ClosureMemberDefinition.readFromDataSource(
      DataSourceReader source, MemberKind kind) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    Deferrable<ir.TreeNode> node =
        source.readDeferrable(() => source.readTreeNode());
    source.end(tag);
    return ClosureMemberDefinition._deserialized(location, kind, node);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(kind);
    sink.begin(tag);
    sink.writeSourceSpan(location);
    sink.writeDeferrable(() => sink.writeTreeNode(node));
    sink.end(tag);
  }

  @override
  String toString() => 'ClosureMemberDefinition(kind:$kind,location:$location)';
}

void forEachOrderedParameterByFunctionNode(
    ir.FunctionNode node,
    ParameterStructure parameterStructure,
    void f(ir.VariableDeclaration parameter,
        {required bool isOptional, required bool isElided}),
    {bool useNativeOrdering = false}) {
  for (int position = 0;
      position < node.positionalParameters.length;
      position++) {
    ir.VariableDeclaration variable = node.positionalParameters[position];
    f(variable,
        isOptional: position >= parameterStructure.requiredPositionalParameters,
        isElided: position >= parameterStructure.positionalParameters);
  }

  if (node.namedParameters.isEmpty) {
    return;
  }

  List<ir.VariableDeclaration> namedParameters = node.namedParameters.toList();
  if (useNativeOrdering) {
    namedParameters.sort(nativeOrdering);
  } else {
    namedParameters.sort(namedOrdering);
  }
  for (ir.VariableDeclaration variable in namedParameters) {
    f(variable,
        isOptional: true,
        isElided: !parameterStructure.namedParameters.contains(variable.name));
  }
}

void forEachOrderedParameter(JsToElementMap elementMap, FunctionEntity function,
    void f(ir.VariableDeclaration parameter, {required bool isElided})) {
  ParameterStructure parameterStructure = function.parameterStructure;

  void handleParameter(ir.VariableDeclaration parameter,
      {required bool isOptional, required bool isElided}) {
    f(parameter, isElided: isElided);
  }

  MemberDefinition definition = elementMap.getMemberDefinition(function);
  switch (definition.kind) {
    case MemberKind.regular:
      ir.Node node = definition.node;
      if (node is ir.Procedure) {
        forEachOrderedParameterByFunctionNode(
            node.function, parameterStructure, handleParameter);
        return;
      }
      break;
    case MemberKind.constructor:
    case MemberKind.constructorBody:
      ir.Node node = definition.node;
      if (node is ir.Procedure) {
        forEachOrderedParameterByFunctionNode(
            node.function, parameterStructure, handleParameter);
        return;
      } else if (node is ir.Constructor) {
        forEachOrderedParameterByFunctionNode(
            node.function, parameterStructure, handleParameter);
        return;
      }
      break;
    case MemberKind.closureCall:
      final node = definition.node as ir.LocalFunction;
      forEachOrderedParameterByFunctionNode(
          node.function, parameterStructure, handleParameter);
      return;
    default:
  }
  failedAt(function, "Unexpected function definition $definition.");
}
