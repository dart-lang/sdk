// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../native/native.dart' as native;
import '../universe/call_structure.dart';
import '../universe/selector.dart';

/// Interface that translates between Kernel IR nodes and entities.
abstract class KernelElementAdapter {
  /// Returns the [DartType] corresponding to [type].
  DartType getDartType(ir.DartType type);

  /// Returns the list of [DartType]s corresponding to [types].
  List<DartType> getDartTypes(List<ir.DartType> types);

  /// Returns the [InterfaceType] corresponding to [type].
  InterfaceType getInterfaceType(ir.InterfaceType type);

  /// Return the [InterfaceType] corresponding to the [cls] with the given
  /// [typeArguments].
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments);

  /// Returns the [CallStructure] corresponding to the [arguments].
  CallStructure getCallStructure(ir.Arguments arguments);

  /// Returns the [Selector] corresponding to the invocation or getter/setter
  /// access of [node].
  Selector getSelector(ir.Expression node);

  /// Returns the [FunctionEntity] corresponding to the generative or factory
  /// constructor [node].
  FunctionEntity getConstructor(ir.Member node);

  /// Returns the [MemberEntity] corresponding to the member [node].
  MemberEntity getMember(ir.Member node);

  /// Returns the [FunctionEntity] corresponding to the procedure [node].
  FunctionEntity getMethod(ir.Procedure node);

  /// Returns the [FieldEntity] corresponding to the field [node].
  FieldEntity getField(ir.Field node);

  /// Returns the [ClassEntity] corresponding to the class [node].
  ClassEntity getClass(ir.Class node);

  /// Returns the [Local] corresponding to the [node]. The node must be either
  /// a [ir.FunctionDeclaration] or [ir.FunctionExpression].
  Local getLocalFunction(ir.Node node);

  /// Returns the [Name] corresponding to [name].
  Name getName(ir.Name name);

  /// Returns `true` is [node] has a `@Native(...)` annotation.
  bool isNativeClass(ir.Class node);

  /// Return `true` if [node] is the `dart:_foreign_helper` library.
  bool isForeignLibrary(ir.Library node);

  /// Computes the native behavior for reading the native [field].
  native.NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field);

  /// Computes the native behavior for writing to the native [field].
  native.NativeBehavior getNativeBehaviorForFieldStore(ir.Field field);

  /// Computes the native behavior for calling [procedure].
  native.NativeBehavior getNativeBehaviorForMethod(ir.Procedure procedure);

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

  /// Compute the kind of foreign helper function called by [node], if any.
  ForeignKind getForeignKind(ir.StaticInvocation node);

  /// Computes the [InterfaceType] referenced by a call to the
  /// [JS_INTERCEPTOR_CONSTANT] function, if any.
  InterfaceType getInterfaceTypeForJsInterceptorCall(ir.StaticInvocation node);
}

/// Kinds of foreign functions.
enum ForeignKind {
  JS,
  JS_BUILTIN,
  JS_EMBEDDED_GLOBAL,
  JS_INTERCEPTOR_CONSTANT,
  NONE,
}
