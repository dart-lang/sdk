// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Abstraction layer allowing the mechanism for looking up the types of
/// elements to be customized.
///
/// This is needed for the NNBD migration engine, which needs to analyze
/// NNBD-disabled code as though it has NNBD enabled.
///
/// This base class implementation gets types directly from the elements; for
/// other behaviors, create a class that extends or implements this class.
class ElementTypeProvider {
  const ElementTypeProvider();

  /// Queries the parameters of an executable element's signature.
  ///
  /// Equivalent to `getExecutableType(...).parameters`.
  List<ParameterElement> getExecutableParameters(ExecutableElement element) =>
      element.parameters;

  /// Queries the return type of an executable element.
  ///
  /// Equivalent to `getExecutableType(...).returnType`.
  DartType getExecutableReturnType(FunctionTypedElement element) =>
      element.returnType;

  /// Queries the full type of an executable element.
  ///
  /// Guaranteed to be a function type.
  FunctionType getExecutableType(FunctionTypedElement element) => element.type;

  /// Queries the type of a variable element.
  DartType getVariableType(VariableElement variable) => variable.type;
}

/// Extension providing additional convenience functions based on
/// [ElementTypeProvider].  This is an extension so that these methods don't
/// need to be replicated when [ElementTypeProvider] is overridden.
extension E on ElementTypeProvider {
  /// Null-aware version of [ElementTypeProvider.getExecutableParameters].
  List<ParameterElement> safeExecutableParameters(ExecutableElement element) =>
      element == null ? null : getExecutableParameters(element);

  /// Null-aware version of [ElementTypeProvider.getExecutableReturnType].
  DartType safeExecutableReturnType(FunctionTypedElement element) =>
      element == null ? null : getExecutableReturnType(element);

  /// Null-aware version of [ElementTypeProvider.getExecutableType].
  FunctionType safeExecutableType(ExecutableElement element) =>
      element == null ? null : getExecutableType(element);

  /// Null-aware version of [ElementTypeProvider.getVariableType].
  DartType safeVariableType(VariableElement variable) =>
      variable == null ? null : getVariableType(variable);
}
