// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'reference_extensions.dart';

/// Information about optional parameters and their default values for a member
/// or a set of members belonging to the same override group.
class ParameterInfo {
  final Member? member;
  int typeParamCount = 0;

  /// Default values of optional positonal parameters. `positional[i] == null`
  /// means positional parameter `i` is not optional.
  late final List<Constant?> positional;

  /// Default values of named parameters. Similar to [positional], `null` means
  /// the the parameter is not optional.
  late final Map<String, Constant?> named;

  // Do not access these until the info is complete.
  late final List<String> names = named.keys.toList()..sort();
  late final Map<String, int> nameIndex = {
    for (int i = 0; i < names.length; i++) names[i]: positional.length + i
  };

  /// A special marker value to use for default parameter values to indicate
  /// that different implementations within the same selector have different
  /// default values.
  static final Constant defaultValueSentinel =
      UnevaluatedConstant(InvalidExpression("Default value sentinel"));

  int get paramCount => positional.length + named.length;

  static Constant? _defaultValue(VariableDeclaration param) {
    Expression? initializer = param.initializer;
    if (initializer is ConstantExpression) {
      return initializer.constant;
    } else if (initializer == null) {
      return null;
    } else {
      throw "Non-constant default value";
    }
  }

  ParameterInfo.fromMember(Reference target) : member = target.asMember {
    FunctionNode? function = member!.function;
    if (target.isTearOffReference) {
      positional = [];
      named = {};
    } else if (function != null) {
      typeParamCount = (member is Constructor
              ? member!.enclosingClass!.typeParameters
              : function.typeParameters)
          .length;
      positional = List.generate(function.positionalParameters.length, (i) {
        // A required parameter has no default value.
        if (i < function.requiredParameterCount) return null;
        return _defaultValue(function.positionalParameters[i]);
      });
      named = {
        for (VariableDeclaration param in function.namedParameters)
          param.name!: _defaultValue(param)
      };
    } else {
      // A setter parameter has no default value.
      positional = [if (target.isSetter) null];
      named = {};
    }
  }

  ParameterInfo.fromLocalFunction(FunctionNode function) : member = null {
    typeParamCount = function.typeParameters.length;
    positional = List.generate(function.positionalParameters.length, (i) {
      // A required parameter has no default value.
      if (i < function.requiredParameterCount) return null;
      return _defaultValue(function.positionalParameters[i]);
    });
    named = {
      for (VariableDeclaration param in function.namedParameters)
        param.name!: _defaultValue(param)
    };
  }

  void merge(ParameterInfo other) {
    assert(typeParamCount == other.typeParamCount);
    for (int i = 0; i < other.positional.length; i++) {
      if (i >= positional.length) {
        positional.add(other.positional[i]);
      } else {
        if (positional[i] == null) {
          positional[i] = other.positional[i];
        } else if (other.positional[i] != null) {
          if (positional[i] != other.positional[i]) {
            // Default value differs between implementations.
            positional[i] = defaultValueSentinel;
          }
        }
      }
    }
    for (String name in other.named.keys) {
      Constant? value = named[name];
      Constant? otherValue = other.named[name];
      if (value == null) {
        named[name] = otherValue;
      } else if (otherValue != null) {
        if (value != otherValue) {
          // Default value differs between implementations.
          named[name] = defaultValueSentinel;
        }
      }
    }
  }
}
