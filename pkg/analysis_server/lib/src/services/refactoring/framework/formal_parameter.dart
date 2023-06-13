// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// The kind of a formal parameter.
enum FormalParameterKind {
  requiredPositional,
  optionalPositional,
  requiredNamed,
  optionalNamed;

  bool get isNamed {
    return this == requiredNamed || this == optionalNamed;
  }

  bool get isOptionalPositional {
    return this == optionalPositional;
  }

  bool get isPositional {
    return this == requiredPositional || this == optionalPositional;
  }
}

/// A reference to a formal parameter.
sealed class FormalParameterReference {
  /// Return the expression used to compute the value of the referenced
  /// formal parameter, or `null` if there is no argument corresponding to the
  /// formal parameter. Note that for named formal parameters this will be an
  /// expression whose parent is a named expression.
  Expression? argumentFrom(ArgumentList argumentList);
}

/// A reference to a named formal parameter.
final class NamedFormalParameterReference extends FormalParameterReference {
  /// The name of the named formal parameter.
  final String name;

  /// Initialize a newly created reference to refer to the named formal
  /// parameter with the given [name].
  NamedFormalParameterReference(this.name) : assert(name.isNotEmpty);

  @override
  Expression? argumentFrom(ArgumentList argumentList) {
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression && argument.name.label.name == name) {
        return argument.expression;
      }
    }
    return null;
  }

  @override
  String toString() => name;
}

/// A reference to a positional formal parameter.
final class PositionalFormalParameterReference
    extends FormalParameterReference {
  /// The index of the positional formal parameter.
  final int index;

  /// Initialize a newly created reference to refer to the positional formal
  /// parameter with the given [index].
  PositionalFormalParameterReference(this.index) : assert(index >= 0);

  @override
  Expression? argumentFrom(ArgumentList argumentList) {
    var arguments = argumentList.arguments;
    if (index >= arguments.length) {
      return null;
    }
    var argument = arguments[index];
    if (argument is NamedExpression) {
      return null;
    }
    return argument;
  }

  @override
  String toString() => '$index';
}
