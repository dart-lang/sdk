// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/elements.dart' show JCommonElements, JElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../ir/closure.dart';
import '../ir/static_type_provider.dart';
import '../ir/util.dart';
import '../js_model/class_type_variable_access.dart';
import '../js_model/elements.dart' show JGeneratorBody;
import '../native/behavior.dart';
import '../serialization/serialization.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../world.dart';
import 'closure.dart';
import 'element_map_interfaces.dart' as interfaces;
import 'element_map_migrated.dart';

export 'element_map_migrated.dart';

/// Interface that translates between Kernel IR nodes and entities used for
/// global type inference and building the SSA graph for members.
abstract class JsToElementMap implements interfaces.JsToElementMap {
  /// Access to the commonly used elements and types.
  JCommonElements get commonElements;

  /// Access to the [DartTypes] object.
  DartTypes get types;

  /// Returns the [DartType] corresponding to [type].
  @override
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
  @override
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
  Map<ir.VariableDeclaration, JRecordField> makeRecordContainer(
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
  AbstractValue receiverTypeOfInvocation(
      ir.Expression invocation, AbstractValueDomain abstractValueDomain);

  /// Returns the inferred receiver type of the dynamic [read].
  // TODO(johnniwinther): Improve the type of the [invocation] once the new
  // method invocation encoding is fully utilized.
  AbstractValue receiverTypeOfGet(ir.Expression read);

  /// Returns the inferred receiver type of the dynamic [write].
  // TODO(johnniwinther): Improve the type of the [invocation] once the new
  // method invocation encoding is fully utilized.
  AbstractValue receiverTypeOfSet(
      ir.Expression write, AbstractValueDomain abstractValueDomain);

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

enum ClassKind {
  regular,
  closure,
  // TODO(efortuna, johnniwinther): Record is not a class, but is
  // masquerading as one currently for consistency with the old element model.
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
      case ClassKind.record:
        return RecordContainerDefinition.readFromDataSource(source);
    }
    throw UnsupportedError("Unexpected ClassKind $kind");
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
