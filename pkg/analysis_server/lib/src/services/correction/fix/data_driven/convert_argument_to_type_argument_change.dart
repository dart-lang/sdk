// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

/// The data related to a function for which one of the `Type` valued arguments
/// has been converted into a type argument.
class ConvertArgumentToTypeArgumentChange extends Change<_Data> {
  /// The index of the argument that was transformed.
  final ParameterReference parameterReference;

  /// The index of the type argument into which the argument was transformed.
  final int typeArgumentIndex;

  /// Initialize a newly created transform to describe a conversion of the
  /// argument at the [argumentIndex] to the type parameter at the
  /// [typeArgumentIndex] for the function [element].
  ConvertArgumentToTypeArgumentChange(
      {@required this.parameterReference, @required this.typeArgumentIndex})
      : assert(parameterReference != null),
        assert(typeArgumentIndex >= 0);

  @override
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    var typeArguments = data.typeArguments;
    var typeName = data.argumentValue;
    if (typeArguments == null) {
      // Adding the first type argument.
      builder.addSimpleInsertion(
          data.argumentList.offset, '<${typeName.name}>');
    } else {
      if (typeArgumentIndex == 0) {
        // Inserting the type argument at the beginning of the list.
        builder.addSimpleInsertion(
            typeArguments.leftBracket.end, '${typeName.name}, ');
      } else {
        // Inserting the type argument after an existing type argument.
        var previous = typeArguments.arguments[typeArgumentIndex - 1];
        builder.addSimpleInsertion(previous.end, ', ${typeName.name}');
      }
    }
    builder.addDeletion(range.nodeInList(data.arguments, data.argument));
  }

  @override
  _Data validate(DataDrivenFix fix) {
    var parent = fix.node.parent;
    if (parent is MethodInvocation) {
      var argumentList = parent.argumentList;
      var argument = parameterReference.argumentFrom(argumentList);
      if (argument is! SimpleIdentifier) {
        return null;
      }
      var typeArguments = parent.typeArguments;
      var typeArgumentLength =
          typeArguments == null ? 0 : typeArguments.arguments.length;
      if (typeArgumentIndex > typeArgumentLength) {
        return null;
      }
      return _Data(argumentList, argument, typeArguments);
    }
    return null;
  }
}

class _Data {
  /// The argument list of the invocation.
  final ArgumentList argumentList;

  /// The value of the argument being moved to the list of type arguments.
  final Identifier argumentValue;

  /// The list of type arguments for the invocation, or `null` if the invocation
  /// does not have any type arguments.
  final TypeArgumentList typeArguments;

  _Data(this.argumentList, this.argumentValue, this.typeArguments);

  /// Return the argument being moved to the list of type arguments.
  Expression get argument {
    var parent = argumentValue.parent;
    if (parent is NamedExpression) {
      return parent;
    }
    return argumentValue;
  }

  /// The list of invocation arguments.
  NodeList<Expression> get arguments => argumentList.arguments;
}
