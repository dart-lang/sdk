// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// A reference to a named parameter.
class NamedParameterReference extends ParameterReference {
  /// The name of the named parameter.
  final String name;

  /// Initialize a newly created reference to refer to the named parameter with
  /// the given [name].
  NamedParameterReference(this.name) : assert(name.isNotEmpty);

  @override
  Expression argumentFrom(ArgumentList argumentList) {
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression && argument.name.label.name == name) {
        return argument.expression;
      }
    }
    return null;
  }
}

/// A reference to a formal parameter.
abstract class ParameterReference {
  /// Return the expression used to compute the value of the referenced
  /// parameter, or `null` if there is no argument corresponding to the
  /// parameter. Note that for named parameters this will be an expression whose
  /// parent is a named expression.
  Expression argumentFrom(ArgumentList argumentList);
}

/// A reference to a positional parameter.
class PositionalParameterReference extends ParameterReference {
  /// The index of the positional parameter.
  final int index;

  /// Initialize a newly created reference to refer to the positional parameter
  /// with the given [index].
  PositionalParameterReference(this.index) : assert(index >= 0);

  @override
  Expression argumentFrom(ArgumentList argumentList) {
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
}
