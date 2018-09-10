// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../constants/values.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../js_backend/namer.dart';
import '../js_backend/native_data.dart';
import '../native/native.dart' as native;
import '../universe/call_structure.dart';
import '../universe/selector.dart';

/// Interface that translates between Kernel IR nodes and entities.
abstract class KernelToElementMap {
  /// Access to the commonly used elements and types.
  CommonElements get commonElements;

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
  MemberEntity getSuperMember(
      MemberEntity context, ir.Name name, ir.Member target,
      {bool setter: false});

  /// Returns the `noSuchMethod` [FunctionEntity] call from a
  /// `super.noSuchMethod` invocation within [cls].
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls);

  /// Returns the [Name] corresponding to [name].
  Name getName(ir.Name name);

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

  /// Return the [ImportEntity] corresponding to [node].
  ImportEntity getImport(ir.LibraryDependency node);

  /// Returns the definition information for [cls].
  ClassDefinition getClassDefinition(covariant ClassEntity cls);

  /// Returns the static type of [node].
  // TODO(johnniwinther): This should be provided directly from kernel.
  DartType getStaticType(ir.Expression node);
}

/// Interface that translates between Kernel IR nodes and entities used for
/// computing the [WorldImpact] for members.
abstract class KernelToElementMapForImpact extends KernelToElementMap {
  ElementEnvironment get elementEnvironment;
  NativeBasicData get nativeBasicData;

  /// Adds libraries in [component] to the set of libraries.
  ///
  /// The main method of the first component is used as the main method for the
  /// compilation.
  void addComponent(ir.Component component);

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

  /// Returns the [ir.Library] corresponding to [library].
  ir.Library getLibraryNode(LibraryEntity library);

  /// Returns the node that defines [typedef].
  ir.Typedef getTypedefNode(covariant TypedefEntity typedef);

  /// Returns the definition information for [member].
  MemberDefinition getMemberDefinition(covariant MemberEntity member);

  /// Returns the element type of a async/sync*/async* function.
  DartType getFunctionAsyncOrSyncStarElementType(ir.FunctionNode functionNode);
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
  // [ir.FunctionExpression] or [ir.FunctionDeclaration].
  closureCall,
  // A field corresponding to a captured variable in the closure. It does not
  // have a corresponding ir.Node.
  closureField,
  // A method that describes the type of a function (in this case the type of
  // the closure class. It does not have a corresponding ir.Node or a method
  // body.
  signature,
  // A separated body of a generator (sync*/async/async*) function.
  generatorBody,
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
  // TODO(efortuna, johnniwinther): Record is not a class, but is
  // masquerading as one currently for consistency with the old element model.
  record,
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
      // @patch annotations have no location.
      uri = node.location?.file;
      break;
    }
    node = node.parent;
  }
  if (uri != null) {
    return new SourceSpan(uri, offset, offset + 1);
  }
  return null;
}

/// Returns the `AsyncMarker` corresponding to `node.asyncMarker`.
AsyncMarker getAsyncMarker(ir.FunctionNode node) {
  switch (node.asyncMarker) {
    case ir.AsyncMarker.Async:
      return AsyncMarker.ASYNC;
    case ir.AsyncMarker.AsyncStar:
      return AsyncMarker.ASYNC_STAR;
    case ir.AsyncMarker.Sync:
      return AsyncMarker.SYNC;
    case ir.AsyncMarker.SyncStar:
      return AsyncMarker.SYNC_STAR;
    case ir.AsyncMarker.SyncYielding:
    default:
      throw new UnsupportedError(
          "Async marker ${node.asyncMarker} is not supported.");
  }
}

/// Kernel encodes a null-aware expression `a?.b` as
///
///     let final #1 = a in #1 == null ? null : #1.b
///
/// [getNullAwareExpression] recognizes such expressions storing the result in
/// a [NullAwareExpression] object.
///
/// [syntheticVariable] holds the synthesized `#1` variable. [expression] holds
/// the `#1.b` expression. [receiver] returns `a` expression. [parent] returns
/// the parent of the let node, i.e. the parent node of the original null-aware
/// expression. [let] returns the let node created for the encoding.
class NullAwareExpression {
  final ir.VariableDeclaration syntheticVariable;
  final ir.Expression expression;

  NullAwareExpression(this.syntheticVariable, this.expression);

  ir.Expression get receiver => syntheticVariable.initializer;

  ir.TreeNode get parent => syntheticVariable.parent.parent;

  ir.Let get let => syntheticVariable.parent;

  String toString() => let.toString();
}

NullAwareExpression getNullAwareExpression(ir.TreeNode node) {
  if (node is ir.Let) {
    ir.Expression body = node.body;
    if (node.variable.name == null &&
        node.variable.isFinal &&
        body is ir.ConditionalExpression &&
        body.condition is ir.MethodInvocation &&
        body.then is ir.NullLiteral) {
      ir.MethodInvocation invocation = body.condition;
      ir.Expression receiver = invocation.receiver;
      if (invocation.name.name == '==' &&
          receiver is ir.VariableGet &&
          receiver.variable == node.variable &&
          invocation.arguments.positional.single is ir.NullLiteral) {
        // We have
        //   let #t1 = e0 in #t1 == null ? null : e1
        return new NullAwareExpression(node.variable, body.otherwise);
      }
    }
  }
  return null;
}
