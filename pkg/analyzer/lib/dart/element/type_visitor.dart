// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

/// Interface for type visitors.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class TypeVisitor<R> {
  const TypeVisitor();

  R visitDynamicType(DynamicType type);

  R visitFunctionType(FunctionType type);

  R visitInterfaceType(InterfaceType type);

  R visitNeverType(NeverType type);

  R visitTypeParameterType(TypeParameterType type);

  R visitVoidType(VoidType type);
}

/// Invokes [visitDartType] from any other `visitXyz` method.
///
/// Clients may extend this class.
abstract class UnifyingTypeVisitor<R> implements TypeVisitor<R> {
  const UnifyingTypeVisitor();

  /// By default other `visitXyz` methods invoke this method.
  R visitDartType(DartType type);

  @override
  R visitDynamicType(DynamicType type) => visitDartType(type);

  @override
  R visitFunctionType(FunctionType type) => visitDartType(type);

  @override
  R visitInterfaceType(InterfaceType type) => visitDartType(type);

  @override
  R visitNeverType(NeverType type) => visitDartType(type);

  @override
  R visitTypeParameterType(TypeParameterType type) => visitDartType(type);

  @override
  R visitVoidType(VoidType type) => visitDartType(type);
}
