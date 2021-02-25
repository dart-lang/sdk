// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A class that can be used to access a value from a target.
abstract class Accessor {
  /// Return the result of using this accessor to access a value from the
  /// [target].
  AccessorResult getValue(Object target);
}

/// The result of using an accessor to get a result.
abstract class AccessorResult {
  /// Initialize a newly created result.
  const AccessorResult();

  /// Return `true` if the accessor returned a valid result.
  bool get isValid;

  /// Return the result of the accessor if it was valid.
  ///
  /// Throws a `StateError` if the accessor did not return a valid result.
  Object get result;
}

/// An accessor that returns a specific argument from an argument list.
class ArgumentAccessor extends Accessor {
  /// The parameter corresponding to the argument from the original invocation.
  final ParameterReference parameter;

  /// Initialize a newly created accessor to access the argument that
  /// corresponds to the given [parameter].
  ArgumentAccessor(this.parameter) : assert(parameter != null);

  @override
  AccessorResult getValue(Object target) {
    if (target is AstNode) {
      var argumentList = _getArgumentList(target);
      if (argumentList != null) {
        var argument = parameter.argumentFrom(argumentList);
        if (argument != null) {
          return ValidResult(argument);
        }
      }
    }
    return const InvalidResult();
  }

  /// Return the argument list associated with the [node].
  ArgumentList _getArgumentList(AstNode node) {
    if (node is Annotation) {
      return node.arguments;
    } else if (node is ExtensionOverride) {
      return node.argumentList;
    } else if (node is InstanceCreationExpression) {
      return node.argumentList;
    } else if (node is InvocationExpression) {
      return node.argumentList;
    } else if (node is RedirectingConstructorInvocation) {
      return node.argumentList;
    } else if (node is SuperConstructorInvocation) {
      return node.argumentList;
    }
    return null;
  }
}

/// A representation of an invalid result.
class InvalidResult implements AccessorResult {
  /// Initialize a newly created invalid result.
  const InvalidResult();

  @override
  bool get isValid => false;

  @override
  Object get result => throw StateError('Cannot access an invalid result');
}

/// An accessor that returns a specific type argument from a type argument list.
class TypeArgumentAccessor extends Accessor {
  /// The index of the type argument.
  final int index;

  /// Initialize a newly created accessor to access the type argument at the
  /// given [index].
  TypeArgumentAccessor(this.index) : assert(index != null);

  @override
  AccessorResult getValue(Object target) {
    if (target is AstNode) {
      var typeArgumentList = _getTypeArgumentList(target);
      if (typeArgumentList != null) {
        var arguments = typeArgumentList.arguments;
        if (arguments.length > index) {
          var argument = arguments[index];
          if (argument != null) {
            return ValidResult(argument);
          }
        }
      }
    }
    return const InvalidResult();
  }

  /// Return the type argument list associated with the [node].
  TypeArgumentList _getTypeArgumentList(AstNode node) {
    if (node is ExtensionOverride) {
      return node.typeArguments;
    } else if (node is InstanceCreationExpression) {
      return node.constructorName.type.typeArguments;
    } else if (node is InvocationExpression) {
      return node.typeArguments;
    } else if (node is NamedType) {
      return node.typeArguments;
    } else if (node is TypedLiteral) {
      return node.typeArguments;
    }
    return null;
  }
}

/// A representation of a valid result.
class ValidResult implements AccessorResult {
  @override
  final Object result;

  /// Initialize a newly created valid result.
  ValidResult(this.result);

  @override
  bool get isValid => true;
}
