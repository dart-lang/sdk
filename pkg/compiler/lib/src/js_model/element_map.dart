// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../constants/values.dart';
import '../common_elements.dart' show JCommonElements, JElementEnvironment;
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../ir/closure.dart';
import '../ir/static_type_provider.dart';
import '../ir/util.dart';
import '../js_model/closure.dart' show JRecordField;
import '../js_model/elements.dart' show JGeneratorBody;
import '../native/behavior.dart';
import '../serialization/serialization.dart';
import '../ssa/type_builder.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../world.dart';
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

  /// Returns the [ConstructorEntity] corresponding to the generative or factory
  /// constructor [node].
  ConstructorEntity getConstructor(ir.Member node);

  /// Returns the [FieldEntity] corresponding to the field [node].
  FieldEntity getField(ir.Field node);

  /// Returns the [ClassEntity] corresponding to the class [node].
  ClassEntity getClass(ir.Class node);

  /// Returns the super [MemberEntity] for a super invocation, get or set of
  /// [name] from the member [context].
  MemberEntity getSuperMember(MemberEntity context, ir.Name name,
      {bool setter: false});

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
  ConstantValue getConstantValue(
      ir.Member memberContext, ir.Expression expression,
      {bool requireConstant: true, bool implicitNull: false});

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
  ir.Member getMemberContextNode(MemberEntity member);

  /// Returns the type of `this` in [member], or `null` if member is defined in
  /// a static context.
  InterfaceType getMemberThisType(MemberEntity member);

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

  /// Make a record to ensure variables that are are declared in one scope and
  /// modified in another get their values updated correctly.
  Map<Local, JRecordField> makeRecordContainer(
      KernelScopeInfo info, MemberEntity member, KernelToLocalsMap localsMap);

  /// Returns a provider for static types for [member].
  StaticTypeProvider getStaticTypeProvider(MemberEntity member);
}

/// Interface for type inference results for kernel IR nodes.
abstract class KernelToTypeInferenceMap {
  /// Returns the inferred return type of [function].
  AbstractValue getReturnTypeOf(FunctionEntity function);

  /// Returns the inferred receiver type of the dynamic [invocation].
  AbstractValue receiverTypeOfInvocation(
      ir.MethodInvocation invocation, AbstractValueDomain abstractValueDomain);

  /// Returns the inferred receiver type of the dynamic [read].
  AbstractValue receiverTypeOfGet(ir.PropertyGet read);

  /// Returns the inferred receiver type of the dynamic [write].
  AbstractValue receiverTypeOfSet(
      ir.PropertySet write, AbstractValueDomain abstractValueDomain);

  /// Returns the inferred type of [listLiteral].
  AbstractValue typeOfListLiteral(
      ir.ListLiteral listLiteral, AbstractValueDomain abstractValueDomain);

  /// Returns the inferred type of iterator in [forInStatement].
  AbstractValue typeOfIterator(ir.ForInStatement forInStatement);

  /// Returns the inferred type of `current` in [forInStatement].
  AbstractValue typeOfIteratorCurrent(ir.ForInStatement forInStatement);

  /// Returns the inferred type of `moveNext` in [forInStatement].
  AbstractValue typeOfIteratorMoveNext(ir.ForInStatement forInStatement);

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

/// Map from kernel IR nodes to local entities.
abstract class KernelToLocalsMap {
  /// The member currently being built.
  MemberEntity get currentMember;

  /// Returns the [Local] for [node].
  Local getLocalVariable(ir.VariableDeclaration node);

  Local getLocalTypeVariable(
      ir.TypeParameterType node, JsToElementMap elementMap);

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
  JumpTarget getJumpTargetForLabel(ir.LabeledStatement node);

  /// Returns the [JumpTarget] defined by the switch statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget getJumpTargetForSwitch(ir.SwitchStatement node);

  /// Returns the [JumpTarget] for the continue switch statement [node].
  JumpTarget getJumpTargetForContinueSwitch(ir.ContinueSwitchStatement node);

  /// Returns the [JumpTarget] defined by the switch case [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget getJumpTargetForSwitchCase(ir.SwitchCase node);

  /// Returns the [JumpTarget] defined the do statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget getJumpTargetForDo(ir.DoStatement node);

  /// Returns the [JumpTarget] defined by the for statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget getJumpTargetForFor(ir.ForStatement node);

  /// Returns the [JumpTarget] defined by the for-in statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget getJumpTargetForForIn(ir.ForInStatement node);

  /// Returns the [JumpTarget] defined by the while statement [node] or `null`
  /// if [node] is not a jump target.
  JumpTarget getJumpTargetForWhile(ir.WhileStatement node);

  /// Serializes this [KernelToLocalsMap] to [sink].
  void writeToDataSink(DataSink sink);
}

/// Returns the [ir.FunctionNode] that defines [member] or `null` if [member]
/// is not a constructor, method or local function.
ir.FunctionNode getFunctionNode(
    JsToElementMap elementMap, MemberEntity member) {
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  switch (definition.kind) {
    case MemberKind.regular:
      ir.Member node = definition.node;
      return node.function;
    case MemberKind.constructor:
    case MemberKind.constructorBody:
      ir.Member node = definition.node;
      return node.function;
    case MemberKind.closureCall:
      ir.LocalFunction node = definition.node;
      return node.function;
    default:
  }
  return null;
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
  factory MemberDefinition.readFromDataSource(DataSource source) {
    MemberKind kind = source.readEnum(MemberKind.values);
    switch (kind) {
      case MemberKind.regular:
        return new RegularMemberDefinition.readFromDataSource(source);
      case MemberKind.constructor:
      case MemberKind.constructorBody:
      case MemberKind.signature:
      case MemberKind.generatorBody:
        return new SpecialMemberDefinition.readFromDataSource(source, kind);
      case MemberKind.closureCall:
      case MemberKind.closureField:
        return new ClosureMemberDefinition.readFromDataSource(source, kind);
    }
    throw new UnsupportedError("Unexpected MemberKind $kind");
  }

  /// Serializes this [MemberDefinition] to [sink].
  void writeToDataSink(DataSink sink);
}

enum ClassKind {
  regular,
  closure,
  // TODO(efortuna, johnniwinther): Record is not a class, but is
  // masquerading as one currently for consistency with the old element model.
  record,
}

/// A member directly defined by its [ir.Member] node.
class RegularMemberDefinition implements MemberDefinition {
  /// Tag used for identifying serialized [RegularMemberDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'regular-member-definition';

  @override
  final ir.Member node;

  RegularMemberDefinition(this.node);

  factory RegularMemberDefinition.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    source.end(tag);
    return new RegularMemberDefinition(node);
  }

  @override
  void writeToDataSink(DataSink sink) {
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
  final ir.TreeNode node;
  @override
  final MemberKind kind;

  SpecialMemberDefinition(this.node, this.kind);

  factory SpecialMemberDefinition.readFromDataSource(
      DataSource source, MemberKind kind) {
    source.begin(tag);
    ir.TreeNode node = source.readTreeNode();
    source.end(tag);
    return new SpecialMemberDefinition(node, kind);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(kind);
    sink.begin(tag);
    sink.writeTreeNode(node);
    sink.end(tag);
  }

  @override
  SourceSpan get location => computeSourceSpanFromTreeNode(node);

  @override
  String toString() => 'SpecialMemberDefinition(kind:$kind,'
      'node:$node,location:$location)';
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
  factory ClassDefinition.readFromDataSource(DataSource source) {
    ClassKind kind = source.readEnum(ClassKind.values);
    switch (kind) {
      case ClassKind.regular:
        return new RegularClassDefinition.readFromDataSource(source);
      case ClassKind.closure:
        return new ClosureClassDefinition.readFromDataSource(source);
      case ClassKind.record:
        return new RecordContainerDefinition.readFromDataSource(source);
    }
    throw new UnsupportedError("Unexpected ClassKind $kind");
  }

  /// Serializes this [ClassDefinition] to [sink].
  void writeToDataSink(DataSink sink);
}

/// A class directly defined by its [ir.Class] node.
class RegularClassDefinition implements ClassDefinition {
  /// Tag used for identifying serialized [RegularClassDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'regular-class-definition';

  @override
  final ir.Class node;

  RegularClassDefinition(this.node);

  factory RegularClassDefinition.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Class node = source.readClassNode();
    source.end(tag);
    return new RegularClassDefinition(node);
  }

  @override
  void writeToDataSink(DataSink sink) {
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

/// Returns the initializer for [field].
///
/// If [field] is an instance field with a null literal initializer `null` is
/// returned, otherwise the initializer of the [ir.Field] is returned.
ir.Node getFieldInitializer(JsToElementMap elementMap, FieldEntity field) {
  MemberDefinition definition = elementMap.getMemberDefinition(field);
  ir.Field node = definition.node;
  if (node.isInstanceMember &&
      !node.isFinal &&
      isNullLiteral(node.initializer)) {
    return null;
  }
  return node.initializer;
}

void forEachOrderedParameterByFunctionNode(
    ir.FunctionNode node,
    ParameterStructure parameterStructure,
    void f(ir.VariableDeclaration parameter, {bool isOptional, bool isElided}),
    {bool useNativeOrdering: false}) {
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
    void f(ir.VariableDeclaration parameter, {bool isElided})) {
  ParameterStructure parameterStructure = function.parameterStructure;

  void handleParameter(ir.VariableDeclaration parameter,
      {bool isOptional, bool isElided}) {
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
      ir.LocalFunction node = definition.node;
      forEachOrderedParameterByFunctionNode(
          node.function, parameterStructure, handleParameter);
      return;
    default:
  }
  failedAt(function, "Unexpected function definition $definition.");
}
