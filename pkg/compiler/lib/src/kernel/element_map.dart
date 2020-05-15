// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../constants/values.dart';
import '../common_elements.dart' show KCommonElements, KElementEnvironment;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../js_backend/namer.dart';
import '../js_backend/native_data.dart';
import '../native/behavior.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';

/// Interface that translates between Kernel IR nodes and entities used for
/// computing the [WorldImpact] for members.
abstract class KernelToElementMap {
  KElementEnvironment get elementEnvironment;
  NativeBasicData get nativeBasicData;

  /// Access to the commonly used elements and types.
  KCommonElements get commonElements;

  /// Access to the [DartTypes] object.
  DartTypes get types;

  /// Returns the core types for the underlying kernel model.
  ir.CoreTypes get coreTypes;

  /// Returns the type environment for the underlying kernel model.
  ir.TypeEnvironment get typeEnvironment;

  /// Returns the class hierarchy for the underlying kernel model.
  ir.ClassHierarchy get classHierarchy;

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

  /// Returns the [Selector] corresponding to the invocation of [name] with
  /// [arguments].
  Selector getInvocationSelector(ir.Name name, int positionalArguments,
      List<String> namedArguments, int typeArguments);

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

  /// Computes the [NativeBehavior] for a call to the [JS] function.
  NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node);

  /// Computes the [NativeBehavior] for a call to the [JS_BUILTIN]
  /// function.
  NativeBehavior getNativeBehaviorForJsBuiltinCall(ir.StaticInvocation node);

  /// Computes the [NativeBehavior] for a call to the
  /// [JS_EMBEDDED_GLOBAL] function.
  NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node);

  /// Returns the [js.Name] for the `JsGetName` [constant] value.
  js.Name getNameForJsGetName(ConstantValue constant, Namer namer);

  /// Computes the [ConstantValue] for the constant [expression].
  ConstantValue getConstantValue(
      ir.StaticTypeContext staticTypeContext, ir.Expression expression,
      {bool requireConstant: true, bool implicitNull: false});

  /// Return the [ImportEntity] corresponding to [node].
  ImportEntity getImport(ir.LibraryDependency node);

  /// Returns the defining node for [cls].
  ir.Class getClassNode(covariant ClassEntity cls);

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

  /// Computes the native behavior for reading the native [field].
  NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field,
      Iterable<String> createsAnnotations, Iterable<String> returnsAnnotations,
      {bool isJsInterop});

  /// Computes the native behavior for writing to the native [field].
  NativeBehavior getNativeBehaviorForFieldStore(ir.Field field);

  /// Computes the native behavior for calling the function or constructor
  /// [member].
  NativeBehavior getNativeBehaviorForMethod(ir.Member member,
      Iterable<String> createsAnnotations, Iterable<String> returnsAnnotations,
      {bool isJsInterop});

  /// Compute the kind of foreign helper function called by [node], if any.
  ForeignKind getForeignKind(ir.StaticInvocation node);

  /// Computes the [InterfaceType] referenced by a call to the
  /// [JS_INTERCEPTOR_CONSTANT] function, if any.
  InterfaceType getInterfaceTypeForJsInterceptorCall(ir.StaticInvocation node);

  /// Returns the [Local] corresponding to the local function [node].
  Local getLocalFunction(ir.LocalFunction node);

  /// Returns the [ir.Library] corresponding to [library].
  ir.Library getLibraryNode(LibraryEntity library);

  /// Returns the defining node for [member].
  ir.Member getMemberNode(covariant MemberEntity member);

  ir.StaticTypeContext getStaticTypeContext(MemberEntity member);
}

/// Kinds of foreign functions.
enum ForeignKind {
  JS,
  JS_BUILTIN,
  JS_EMBEDDED_GLOBAL,
  JS_INTERCEPTOR_CONSTANT,
  NONE,
}

// Members which dart2js ignores.
bool memberIsIgnorable(ir.Member node, {ir.Class cls}) {
  if (node is! ir.Procedure) return false;
  ir.Procedure member = node;
  if ((member.isMemberSignature || member.isForwardingStub) &&
      member.isAbstract) {
    // Skip abstract forwarding stubs. These are never emitted but they
    // might shadow the inclusion of a mixed in method in code like:
    //
    //     class Super {}
    //     class Mixin<T> {
    //       void method(T t) {}
    //     }
    //     class Class extends Super with Mixin<int> {}
    //     main() => new Class().method();
    //
    // Here a stub is created for `Super&Mixin.method` hiding that
    // `Mixin.method` is inherited by `Class`.
    return true;
  }
  if (cls != null &&
      (member.isMemberSignature || member.isForwardingStub) &&
      cls.isAnonymousMixin) {
    return true;
  }
  return false;
}
