// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../constants/values.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../js_backend/namer.dart';
import '../js_backend/native_data.dart';
import '../js_emitter/code_emitter_task.dart';
import '../native/native.dart' as native;
import '../types/types.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../world.dart';

/// Interface that translates between Kernel IR nodes and entities.
abstract class KernelToElementMap {
  /// Access to the commonly used elements and types.
  CommonElements get commonElements;

  /// Returns the [DartType] corresponding to [type].
  DartType getDartType(ir.DartType type);

  /// Returns the [InterfaceType] corresponding to [type].
  InterfaceType getInterfaceType(ir.InterfaceType type);

  /// Returns the [FunctionType] of the [node].
  FunctionType getFunctionType(ir.FunctionNode node);

  /// Return the [InterfaceType] corresponding to the [cls] with the given
  /// [typeArguments].
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

  /// Returns the [TypedefType] corresponding to raw type of the typedef [node].
  TypedefType getTypedefType(ir.Typedef node);

  /// Returns the super [MemberEntity] for a super invocation, get or set of
  /// [name] from the member [context].
  ///
  /// The IR doesn't always resolve super accesses to the corresponding
  /// [target]. If not, the target is computed using [name] and [setter] from
  /// the enclosing class of [context].
  MemberEntity getSuperMember(ir.Member context, ir.Name name, ir.Member target,
      {bool setter: false});

  /// Returns the [Name] corresponding to [name].
  Name getName(ir.Name name);

  /// Return `true` if [node] is the `dart:_foreign_helper` library.
  bool isForeignLibrary(ir.Library node);

  /// Computes the [native.NativeBehavior] for a call to the [JS] function.
  native.NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node);

  /// Computes the [native.NativeBehavior] for a call to the [JS_BUILTIN]
  /// function.
  native.NativeBehavior getNativeBehaviorForJsBuiltinCall(
      ir.StaticInvocation node);

  /// Computes the [native.NativeBehavior] for a call to the
  /// [JS_EMBEDDED_GLOBAL] function.
  native.NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node);

  /// Returns the [js.Name] for the `JsGetName` [constant] value.
  js.Name getNameForJsGetName(ConstantValue constant, Namer namer);

  /// Computes the [ConstantValue] for the constant [expression].
  // TODO(johnniwinther): Move to [KernelToElementMapForBuilding]. This is only
  // used in impact builder for symbol constants.
  ConstantValue getConstantValue(ir.Expression expression,
      {bool requireConstant: true, bool implicitNull: false});
}

/// Interface that translates between Kernel IR nodes and entities used for
/// computing the [WorldImpact] for members.
abstract class KernelToElementMapForImpact extends KernelToElementMap {
  NativeBasicData get nativeBasicData;

  /// Adds libraries in [program] to the set of libraries.
  ///
  /// The main method of the first program is used as the main method for the
  /// compilation.
  void addProgram(ir.Program program);

  /// Returns the [ConstructorEntity] corresponding to a super initializer in
  /// [constructor].
  ///
  /// The IR resolves super initializers to a [target] up in the type hierarchy.
  /// Most of the time, the result of this function will be the entity
  /// corresponding to that target. In the presence of unnamed mixins, this
  /// function returns an entity for an intermediate synthetic constructor that
  /// kernel doesn't explicitly represent.
  ///
  /// For example:
  ///     class M {}
  ///     class C extends Object with M {}
  ///
  /// Kernel will say that C()'s super initializer resolves to Object(), but
  /// this function will return an entity representing the unnamed mixin
  /// application "Object+M"'s constructor.
  ConstructorEntity getSuperConstructor(
      ir.Constructor constructor, ir.Member target);

  /// Returns `true` is [node] has a `@Native(...)` annotation.
  bool isNativeClass(ir.Class node);

  /// Computes the native behavior for reading the native [field].
  native.NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field,
      {bool isJsInterop});

  /// Computes the native behavior for writing to the native [field].
  native.NativeBehavior getNativeBehaviorForFieldStore(ir.Field field);

  /// Computes the native behavior for calling the function or constructor
  /// [member].
  native.NativeBehavior getNativeBehaviorForMethod(ir.Member member,
      {bool isJsInterop});

  /// Compute the kind of foreign helper function called by [node], if any.
  ForeignKind getForeignKind(ir.StaticInvocation node);

  /// Computes the [InterfaceType] referenced by a call to the
  /// [JS_INTERCEPTOR_CONSTANT] function, if any.
  InterfaceType getInterfaceTypeForJsInterceptorCall(ir.StaticInvocation node);

  /// Returns the [Local] corresponding to the [node]. The node must be either
  /// a [ir.FunctionDeclaration] or [ir.FunctionExpression].
  Local getLocalFunction(ir.TreeNode node);
}

/// Interface that translates between Kernel IR nodes and entities used for
/// global type inference and building the SSA graph for members.
abstract class KernelToElementMapForBuilding implements KernelToElementMap {
  /// [ElementEnvironment] for library, class and member lookup.
  ElementEnvironment get elementEnvironment;

  /// Returns the list of [DartType]s corresponding to [types].
  List<DartType> getDartTypes(List<ir.DartType> types);

  /// Returns the definition information for [member].
  MemberDefinition getMemberDefinition(covariant MemberEntity member);

  /// Returns the definition information for [cls].
  ClassDefinition getClassDefinition(covariant ClassEntity cls);

  /// Returns the [LibraryEntity] corresponding to the library [node].
  LibraryEntity getLibrary(ir.Library node);

  /// Returns the [js.Template] for the `JsBuiltin` [constant] value.
  js.Template getJsBuiltinTemplate(
      ConstantValue constant, CodeEmitterTask emitter);

  /// Return the [ConstantValue] the initial value of [field] or `null` if
  /// the initializer is not a constant expression.
  ConstantValue getFieldConstantValue(ir.Field field);

  /// Returns the `noSuchMethod` [FunctionEntity] call from a
  /// `super.noSuchMethod` invocation within [cls].
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls);

  /// Returns a [Spannable] for a message pointing to the IR [node] in the
  /// context of [member].
  Spannable getSpannable(MemberEntity member, ir.Node node);

  /// Returns the constructor body entity corresponding to [constructor].
  FunctionEntity getConstructorBody(ir.Constructor node);

  /// Returns the uri for the deferred import [node].
  // TODO(johnniwinther): Avoid this method by deriving the uri directly from
  // the node.
  String getDeferredUri(ir.LibraryDependency node);
}

// TODO(johnniwinther,efortuna): Add more when needed.
// TODO(johnniwinther): Should we split regular into method, field, etc.?
enum MemberKind {
  // A regular member defined by an [ir.Node].
  regular,
  // A constructor whose initializer is defined by an [ir.Constructor] node.
  constructor,
  // A constructor whose body is defined by an [ir.Constructor] node.
  constructorBody,
  // A closure class `call` method whose body is defined by an
  // [ir.FunctionExpression].
  closureCall,
  // A field corresponding to a captured variable in the closure. It does not
  // have a corresponding ir.Node.
  closureField,
}

/// Definition information for a [MemberEntity].
abstract class MemberDefinition {
  /// The defined member.
  MemberEntity get member;

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
}

enum ClassKind {
  regular,
  closure,
}

/// A member directly defined by its [ir.Member] node.
class RegularMemberDefinition implements MemberDefinition {
  final MemberEntity member;
  final ir.Member node;

  RegularMemberDefinition(this.member, this.node);

  SourceSpan get location => computeSourceSpanFromTreeNode(node);

  MemberKind get kind => MemberKind.regular;

  String toString() => 'RegularMemberDefinition(kind:$kind,member:$member,'
      'node:$node,location:$location)';
}

/// The definition of a special kind of member
class SpecialMemberDefinition implements MemberDefinition {
  final MemberEntity member;
  final ir.TreeNode node;
  final MemberKind kind;

  SpecialMemberDefinition(this.member, this.node, this.kind);

  SourceSpan get location => computeSourceSpanFromTreeNode(node);

  String toString() => 'SpecialMemberDefinition(kind:$kind,member:$member,'
      'node:$node,location:$location)';
}

/// Definition information for a [ClassEntity].
abstract class ClassDefinition {
  /// The defined class.
  ClassEntity get cls;

  /// The kind of the defined class. This determines the semantics of [node].
  ClassKind get kind;

  /// The defining [ir.Node] for this class, if supported by its [kind].
  ir.Node get node;

  /// The canonical location of [cls]. This is used for sorting the classes
  /// in the emitted code.
  SourceSpan get location;
}

/// A class directly defined by its [ir.Class] node.
class RegularClassDefinition implements ClassDefinition {
  final ClassEntity cls;
  final ir.Class node;

  RegularClassDefinition(this.cls, this.node);

  SourceSpan get location => computeSourceSpanFromTreeNode(node);

  ClassKind get kind => ClassKind.regular;

  String toString() => 'RegularClassDefinition(kind:$kind,cls:$cls,'
      'node:$node,location:$location)';
}

/// Kinds of foreign functions.
enum ForeignKind {
  JS,
  JS_BUILTIN,
  JS_EMBEDDED_GLOBAL,
  JS_INTERCEPTOR_CONSTANT,
  NONE,
}

/// Interface for type inference results for kernel IR nodes.
abstract class KernelToTypeInferenceMap {
  /// Returns the inferred return type of [function].
  TypeMask getReturnTypeOf(FunctionEntity function);

  /// Returns the inferred receiver type of the dynamic [invocation].
  TypeMask typeOfInvocation(
      ir.MethodInvocation invocation, ClosedWorld closedWorld);

  /// Returns the inferred receiver type of the dynamic [read].
  TypeMask typeOfGet(ir.PropertyGet read);

  /// Returns the inferred receiver type of the dynamic [write].
  TypeMask typeOfSet(ir.PropertySet write, ClosedWorld closedWorld);

  /// Returns the inferred type of [listLiteral].
  TypeMask typeOfListLiteral(covariant MemberEntity owner,
      ir.ListLiteral listLiteral, ClosedWorld closedWorld);

  /// Returns the inferred type of iterator in [forInStatement].
  TypeMask typeOfIterator(ir.ForInStatement forInStatement);

  /// Returns the inferred type of `current` in [forInStatement].
  TypeMask typeOfIteratorCurrent(ir.ForInStatement forInStatement);

  /// Returns the inferred type of `moveNext` in [forInStatement].
  TypeMask typeOfIteratorMoveNext(ir.ForInStatement forInStatement);

  /// Returns `true` if [forInStatement] is inferred to be a JavaScript
  /// indexable iterator.
  bool isJsIndexableIterator(
      ir.ForInStatement forInStatement, ClosedWorld closedWorld);

  /// Returns `true` if [mask] is inferred to have a JavaScript `length`
  /// property.
  bool isFixedLength(TypeMask mask, ClosedWorld closedWorld);

  /// Returns the inferred index type of [forInStatement].
  TypeMask inferredIndexType(ir.ForInStatement forInStatement);

  /// Returns the inferred type of [member].
  TypeMask getInferredTypeOf(MemberEntity member);

  /// Returns the inferred type of the [parameter].
  TypeMask getInferredTypeOfParameter(Local parameter);

  /// Returns the inferred type of a dynamic [selector] access on a receiver of
  /// type [mask].
  TypeMask selectorTypeOf(Selector selector, TypeMask mask);

  /// Returns the returned type annotation in the [nativeBehavior].
  TypeMask typeFromNativeBehavior(
      native.NativeBehavior nativeBehavior, ClosedWorld closedWorld);
}

/// Map from kernel IR nodes to local entities.
abstract class KernelToLocalsMap {
  /// The member currently being built.
  MemberEntity get currentMember;

  // TODO(johnniwinther): Make these return the [KernelToLocalsMap] to use from
  // now on.
  /// Call to notify that [member] is currently being inlined.
  void enterInlinedMember(covariant MemberEntity member);

  /// Call to notify that [member] is no longer being inlined.
  void leaveInlinedMember(covariant MemberEntity member);

  /// Returns the [Local] for [node]. If [isClosureCallMethod] is true, this
  /// gives the locals map permission to also look one scope higher within the
  /// class for the corresponding local. This can happen in the case of free
  /// variables involved with a closure class.
  // TODO(efortuna, johnniwinther): convey this information without a boolean
  // parameter.
  Local getLocalVariable(ir.VariableDeclaration node);

  /// Returns the [Local] corresponding to the [node]. The node must be either
  /// a [ir.FunctionDeclaration] or [ir.FunctionExpression].
  Local getLocalFunction(ir.TreeNode node);

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

  /// Returns the [CapturedLoopScope] for the loop [node] in
  /// [closureLookup].
  // TODO(johnniwinther): Remove this when [KernelAstAdapter] is deleted.
  CapturedLoopScope getCapturedLoopScope(
      ClosureDataLookup closureLookup, ir.TreeNode node);

  /// Returns the [ClosureRepresentationInfo] for the local function [node] in
  /// [closureLookup].
  // TODO(johnniwinther): Remove this when [KernelAstAdapter] is deleted.
  ClosureRepresentationInfo getClosureRepresentationInfo(
      ClosureDataLookup closureLookup, ir.TreeNode node);
}

/// Comparator for the canonical order or named arguments.
// TODO(johnniwinther): Remove this when named parameters are sorted in dill.
int namedOrdering(ir.VariableDeclaration a, ir.VariableDeclaration b) {
  return a.name.compareTo(b.name);
}

SourceSpan computeSourceSpanFromTreeNode(ir.TreeNode node) {
  // TODO(johnniwinther): Use [ir.Location] directly as a [SourceSpan].
  Uri uri;
  int offset;
  while (node != null) {
    if (node.fileOffset != ir.TreeNode.noOffset) {
      offset = node.fileOffset;
      uri = Uri.parse(node.location.file);
      break;
    }
    node = node.parent;
  }
  if (uri != null) {
    return new SourceSpan(uri, offset, offset + 1);
  }
  return null;
}
