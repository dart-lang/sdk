// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/elements.dart' show JCommonElements, JElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../ir/closure.dart';
import '../ir/static_type_provider.dart';
import '../ir/util.dart';
import '../js_model/class_type_variable_access.dart';
import '../js_model/elements.dart' show JGeneratorBody;
import '../js_model/js_world.dart' show JClosedWorld;
import '../native/behavior.dart';
import '../serialization/deferrable.dart';
import '../serialization/serialization.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import 'closure.dart';

/// Interface that translates between Kernel IR nodes and entities used for
/// global type inference and building the SSA graph for members.
abstract class JsToElementMap {
  /// Access to the commonly used elements and types.
  JCommonElements get commonElements;

  /// Access to the [DartTypes] object.
  DartTypes get types;

  /// Returns the [DartType] corresponding to [type].
  DartType getDartType(ir.DartType type);

  /// Returns the [InterfaceType] corresponding to [type].
  InterfaceType getInterfaceType(ir.InterfaceType type);

  Iterable<InterfaceType> getInterfaces(ClassEntity cls);

  /// Returns the [TypeVariableType] corresponding to [type].
  TypeVariableType getTypeVariableType(ir.TypeParameterType type);

  /// Returns the [FunctionType] of the [node].
  FunctionType getFunctionType(ir.FunctionNode node);

  /// Return the [InterfaceType] corresponding to the [cls] with the given
  /// [typeArguments] and [nullability].
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments);

  /// Returns the [CallStructure] corresponding to the [arguments].
  CallStructure getCallStructure(ir.Arguments arguments);

  /// Returns the [Selector] corresponding to the invocation or getter/setter
  /// access of [node].
  Selector getSelector(ir.Expression node);

  /// Returns the [MemberEntity] corresponding to the member [node].
  MemberEntity getMember(ir.Member node);

  /// Returns the [FunctionEntity] corresponding to the procedure [node].
  FunctionEntity getMethod(ir.Procedure node);

  /// Returns `true` if [node] has been included into this map.
  bool containsMethod(ir.Procedure node);

  /// Returns the [ConstructorEntity] corresponding to the generative or factory
  /// constructor [node].
  ConstructorEntity getConstructor(ir.Member node);

  /// Returns the [FieldEntity] corresponding to the field [node].
  FieldEntity getField(ir.Field node);

  /// Returns the [ClassEntity] corresponding to the class [node].
  ClassEntity getClass(ir.Class node);

  /// Returns the `noSuchMethod` [FunctionEntity] call from a
  /// `super.noSuchMethod` invocation within [cls].
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls);

  /// Returns the [Name] corresponding to [name].
  Name getName(ir.Name name);

  /// Computes the [native.NativeBehavior] for a call to the [JS] function.
  NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node);

  /// Computes the [native.NativeBehavior] for a call to the [JS_BUILTIN]
  /// function.
  NativeBehavior getNativeBehaviorForJsBuiltinCall(ir.StaticInvocation node);

  /// Computes the [native.NativeBehavior] for a call to the
  /// [JS_EMBEDDED_GLOBAL] function.
  NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node);

  /// Computes the [ConstantValue] for the constant [expression].
  // TODO(johnniwinther,sigmund): Remove the need for [memberContext]. This is
  //  only needed because effectively constant expressions are not replaced by
  //  constant expressions during resolution.
  ConstantValue? getConstantValue(
      ir.Member? memberContext, ir.Expression? expression,
      {bool requireConstant = true, bool implicitNull = false});

  /// Returns the [ConstantValue] for the sentinel used to indicate that a
  /// parameter is required.
  ///
  /// These should only appear within the defaultValues object attached to
  /// closures and tearoffs when emitting Function.apply.
  ConstantValue getRequiredSentinelConstantValue();

  /// Return the [ImportEntity] corresponding to [node].
  ImportEntity getImport(ir.LibraryDependency node);

  /// Returns the definition information for [cls].
  ClassDefinition getClassDefinition(covariant ClassEntity cls);

  /// [ElementEnvironment] for library, class and member lookup.
  JElementEnvironment get elementEnvironment;

  /// Returns the list of [DartType]s corresponding to [types].
  List<DartType> getDartTypes(List<ir.DartType> types);

  /// Returns the definition information for [member].
  MemberDefinition getMemberDefinition(MemberEntity member);

  /// Returns the [ir.Member] containing the definition of [member], if any.
  ir.Member? getMemberContextNode(MemberEntity member);

  /// Returns the type of `this` in [member], or `null` if member is defined in
  /// a static context.
  InterfaceType? getMemberThisType(MemberEntity member);

  /// Returns how [member] has access to type variables of the this type
  /// returned by [getMemberThisType].
  ClassTypeVariableAccess getClassTypeVariableAccessForMember(
      MemberEntity member);

  /// Returns the [LibraryEntity] corresponding to the library [node].
  LibraryEntity getLibrary(ir.Library node);

  /// Returns a [Spannable] for a message pointing to the IR [node] in the
  /// context of [member].
  Spannable getSpannable(MemberEntity member, ir.Node node);

  /// Returns the constructor body entity corresponding to [constructor].
  FunctionEntity getConstructorBody(ir.Constructor node);

  /// Returns the constructor body entity corresponding to [function].
  JGeneratorBody getGeneratorBody(FunctionEntity function);

  /// Make a mapping from closed-over variables to the context fields where they
  /// are stored.
  Map<ir.VariableDeclaration, JContextField> makeContextContainer(
      KernelScopeInfo info, MemberEntity member);

  /// Returns a provider for static types for [member].
  StaticTypeProvider getStaticTypeProvider(MemberEntity member);
}

/// Interface for type inference results for kernel IR nodes.
abstract class KernelToTypeInferenceMap {
  /// Returns the inferred return type of [function].
  AbstractValue getReturnTypeOf(FunctionEntity function);

  /// Returns the inferred receiver type of the dynamic [invocation].
  // TODO(johnniwinther): Improve the type of the [invocation] once the new
  // method invocation encoding is fully utilized.
  AbstractValue? receiverTypeOfInvocation(
      ir.Expression invocation, AbstractValueDomain abstractValueDomain);

  /// Returns the inferred receiver type of the dynamic [read].
  // TODO(johnniwinther): Improve the type of the [invocation] once the new
  // method invocation encoding is fully utilized.
  AbstractValue? receiverTypeOfGet(ir.Expression read);

  /// Returns the inferred receiver type of the dynamic [write].
  // TODO(johnniwinther): Improve the type of the [invocation] once the new
  // method invocation encoding is fully utilized.
  AbstractValue? receiverTypeOfSet(
      ir.Expression write, AbstractValueDomain abstractValueDomain);

  /// Returns the inferred type of [listLiteral].
  AbstractValue typeOfListLiteral(
      ir.ListLiteral listLiteral, AbstractValueDomain abstractValueDomain);

  /// Returns the inferred type of [recordLiteral].
  AbstractValue? typeOfRecordLiteral(
      ir.RecordLiteral recordLiteral, AbstractValueDomain abstractValueDomain);

  /// Returns the inferred type of iterator in [forInStatement].
  AbstractValue? typeOfIterator(ir.ForInStatement forInStatement);

  /// Returns the inferred type of `current` in [forInStatement].
  AbstractValue? typeOfIteratorCurrent(ir.ForInStatement forInStatement);

  /// Returns the inferred type of `moveNext` in [forInStatement].
  AbstractValue? typeOfIteratorMoveNext(ir.ForInStatement forInStatement);

  /// Returns `true` if [forInStatement] is inferred to be a JavaScript
  /// indexable iterator.
  bool isJsIndexableIterator(ir.ForInStatement forInStatement,
      AbstractValueDomain abstractValueDomain);

  /// Returns the inferred index type of [forInStatement].
  AbstractValue inferredIndexType(ir.ForInStatement forInStatement);

  /// Returns the inferred type of [member].
  AbstractValue getInferredTypeOf(MemberEntity member);

  /// Returns the inferred type of the [parameter].
  AbstractValue getInferredTypeOfParameter(Local parameter);

  /// Returns the inferred result type of a dynamic [selector] access on the
  /// [receiver].
  AbstractValue resultTypeOfSelector(Selector selector, AbstractValue receiver);

  /// Returns the returned type annotation in the [nativeBehavior].
  AbstractValue typeFromNativeBehavior(
      NativeBehavior nativeBehavior, JClosedWorld closedWorld);
}

/// Returns the [ir.FunctionNode] that defines [member] or `null` if [member]
/// is not a constructor, method or local function.
ir.FunctionNode? getFunctionNode(
    JsToElementMap elementMap, MemberEntity member) {
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  switch (definition.kind) {
    case MemberKind.regular:
    case MemberKind.constructor:
    case MemberKind.constructorBody:
      ir.Member node = definition.node as ir.Member;
      return node.function;
    case MemberKind.closureCall:
      ir.LocalFunction node = definition.node as ir.LocalFunction;
      return node.function;
    default:
  }
  return null;
}

/// Returns the initializer for [field].
///
/// If [field] is an instance field with a null literal initializer `null` is
/// returned, otherwise the initializer of the [ir.Field] is returned.
ir.Node? getFieldInitializer(JsToElementMap elementMap, FieldEntity field) {
  MemberDefinition definition = elementMap.getMemberDefinition(field);
  ir.Field node = definition.node as ir.Field;
  ir.Expression? initializer = node.initializer;
  if (initializer != null &&
      node.isInstanceMember &&
      !node.isFinal &&
      isNullLiteral(initializer)) {
    return null;
  }
  return initializer;
}

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

  /// A dynamic getter for a field of a record.
  recordGetter,
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
      case MemberKind.recordGetter:
        return RecordGetterDefinition.readFromDataSource(source);
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

  static ir.TreeNode _readNode(DataSourceReader source) =>
      source.readTreeNode();

  factory SpecialMemberDefinition.readFromDataSource(
      DataSourceReader source, MemberKind kind) {
    source.begin(tag);
    Deferrable<ir.TreeNode> node = source.readDeferrable(_readNode);
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

  static ir.TreeNode _readNode(DataSourceReader source) =>
      source.readTreeNode();

  factory ClosureMemberDefinition.readFromDataSource(
      DataSourceReader source, MemberKind kind) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    Deferrable<ir.TreeNode> node = source.readDeferrable(_readNode);
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

/// Definition for a record getter member.
class RecordGetterDefinition implements MemberDefinition {
  /// Tag used for identifying serialized [RecordMemberDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'record-getter-definition';

  @override
  final SourceSpan location;

  final int indexInShape;

  @override
  ir.TreeNode get node => throw UnsupportedError('RecordGetterDefinition.node');

  RecordGetterDefinition(this.location, this.indexInShape);

  factory RecordGetterDefinition.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    int indexInShape = source.readInt();
    source.end(tag);
    return RecordGetterDefinition(location, indexInShape);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(kind);
    sink.begin(tag);
    sink.writeSourceSpan(location);
    sink.writeInt(indexInShape);
    sink.end(tag);
  }

  @override
  MemberKind get kind => MemberKind.recordGetter;

  @override
  String toString() =>
      'RecordGetterDefinition(indexInShape:$indexInShape,location:$location)';
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

enum ClassKind {
  regular,
  closure,
  // TODO(efortuna, johnniwinther): Context is not a class, but is
  // masquerading as one currently for consistency with the old element model.
  context,
  record,
}

/// Definition information for a [ClassEntity].
abstract class ClassDefinition {
  /// The kind of the defined class. This determines the semantics of [node].
  ClassKind get kind;

  /// The defining [ir.Node] for this class, if supported by its [kind].
  ir.Node get node;

  /// The canonical location of [cls]. This is used for sorting the classes
  /// in the emitted code.
  SourceSpan get location;

  /// Deserializes a [ClassDefinition] object from [source].
  factory ClassDefinition.readFromDataSource(DataSourceReader source) {
    ClassKind kind = source.readEnum(ClassKind.values);
    switch (kind) {
      case ClassKind.regular:
        return RegularClassDefinition.readFromDataSource(source);
      case ClassKind.closure:
        return ClosureClassDefinition.readFromDataSource(source);
      case ClassKind.context:
        return ContextContainerDefinition.readFromDataSource(source);
      case ClassKind.record:
        return RecordClassDefinition.readFromDataSource(source);
    }
  }

  /// Serializes this [ClassDefinition] to [sink].
  void writeToDataSink(DataSinkWriter sink);
}

/// A class directly defined by its [ir.Class] node.
class RegularClassDefinition implements ClassDefinition {
  /// Tag used for identifying serialized [RegularClassDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'regular-class-definition';

  @override
  final ir.Class node;

  RegularClassDefinition(this.node);

  factory RegularClassDefinition.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Class node = source.readClassNode();
    source.end(tag);
    return RegularClassDefinition(node);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(kind);
    sink.begin(tag);
    sink.writeClassNode(node);
    sink.end(tag);
  }

  @override
  SourceSpan get location => computeSourceSpanFromTreeNode(node);

  @override
  ClassKind get kind => ClassKind.regular;

  @override
  String toString() => 'RegularClassDefinition(kind:$kind,'
      'node:$node,location:$location)';
}

class ClosureClassDefinition implements ClassDefinition {
  /// Tag used for identifying serialized [ClosureClassDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'closure-class-definition';

  @override
  final SourceSpan location;

  ClosureClassDefinition(this.location);

  factory ClosureClassDefinition.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    source.end(tag);
    return ClosureClassDefinition(location);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(ClassKind.closure);
    sink.begin(tag);
    sink.writeSourceSpan(location);
    sink.end(tag);
  }

  @override
  ClassKind get kind => ClassKind.closure;

  @override
  ir.Node get node =>
      throw UnsupportedError('ClosureClassDefinition.node for $location');

  @override
  String toString() => 'ClosureClassDefinition(kind:$kind,location:$location)';
}

class ContextContainerDefinition implements ClassDefinition {
  /// Tag used for identifying serialized [ContextContainerDefinition] objects in
  /// a debugging data stream.
  static const String tag = 'context-definition';

  @override
  final SourceSpan location;

  ContextContainerDefinition(this.location);

  factory ContextContainerDefinition.readFromDataSource(
      DataSourceReader source) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    source.end(tag);
    return ContextContainerDefinition(location);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(ClassKind.context);
    sink.begin(tag);
    sink.writeSourceSpan(location);
    sink.end(tag);
  }

  @override
  ClassKind get kind => ClassKind.context;

  @override
  ir.Node get node =>
      throw UnsupportedError('ContextContainerDefinition.node for $location');

  @override
  String toString() =>
      'ContextContainerDefinition(kind:$kind,location:$location)';
}

class RecordClassDefinition implements ClassDefinition {
  /// Tag used for identifying serialized [RecordClassDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'record-class-definition';

  @override
  final SourceSpan location;

  RecordClassDefinition(this.location);

  factory RecordClassDefinition.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    source.end(tag);
    return RecordClassDefinition(location);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(ClassKind.record);
    sink.begin(tag);
    sink.writeSourceSpan(location);
    sink.end(tag);
  }

  @override
  ClassKind get kind => ClassKind.record;

  @override
  ir.Node get node =>
      throw UnsupportedError('RecordClassDefinition.node for $location');

  @override
  String toString() => 'RecordClassDefinition(kind:$kind,location:$location)';
}
