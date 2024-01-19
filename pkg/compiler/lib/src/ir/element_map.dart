// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_shared/variance.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/core_types.dart' as ir;

import '../common.dart';
import '../common/elements.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../ordered_typeset.dart';
import '../universe/call_structure.dart';

/// Interface that translates between Kernel IR nodes and entities.
///
/// This interface is used internally to implement [KernelToElementMap] in the
/// frontend and [JsToElementMap] in the backend.
abstract class IrToElementMap {
  /// Returns the [DartType] corresponding to [type].
  DartType getDartType(ir.DartType type);

  /// Returns the [Name] corresponding to [name].
  ///
  /// If [setter] is `true`, the setter name is returned.
  Name getName(ir.Name name, {bool setter = false});

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

  /// Returns the [FunctionType] of the [node].
  FunctionType getFunctionType(ir.FunctionNode node);

  /// Return the [InterfaceType] corresponding to the [cls] with the given
  /// [typeArguments] and [nullability].
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments);

  /// Returns the [CallStructure] corresponding to the [arguments].
  CallStructure getCallStructure(ir.Arguments arguments);

  /// Returns the [TypeVariableEntity] corresponding to the type parameter
  /// [node].
  TypeVariableEntity getTypeVariable(ir.TypeParameter node);

  CommonElements get commonElements;
  DiagnosticReporter get reporter;
  ir.CoreTypes get coreTypes;
  InterfaceType getThisType(covariant ClassEntity cls);
  InterfaceType? getSuperType(covariant ClassEntity cls);
  OrderedTypeSet getOrderedTypeSet(covariant ClassEntity cls);

  /// Returns the [ClassEntity] objects for interfaces that [cls] `implements`.
  Iterable<InterfaceType> getInterfaces(covariant ClassEntity cls);
  InterfaceType? asInstanceOf(InterfaceType type, ClassEntity cls);
  DartType substByContext(DartType type, InterfaceType context);
  FunctionType? getCallType(InterfaceType type);
  int getHierarchyDepth(covariant ClassEntity cls);
  DartType getTypeVariableBound(covariant TypeVariableEntity typeVariable);
  List<Variance> getTypeVariableVariances(covariant ClassEntity cls);
}
