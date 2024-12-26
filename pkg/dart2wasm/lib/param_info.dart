// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'reference_extensions.dart';

/// Information about optional parameters and their default values for a member
/// or a set of members belonging to the same override group.
class ParameterInfo {
  final int typeParamCount;

  /// Default values of optional positonal parameters. `positional[i] == null`
  /// means positional parameter `i` is not optional.
  final List<Constant?> positional;

  /// Default values of named parameters. Similar to [positional], `null` means
  /// the the parameter is not optional.
  final Map<String, Constant?> named;

  final bool takesContextOrReceiver;

  // Dispatch table builder updates `ParameterInfo`s, do not access late fields
  // until the `ParameterInfo` is complete.
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

  ParameterInfo._(this.takesContextOrReceiver, this.typeParamCount,
      this.positional, this.named);

  factory ParameterInfo.fromMember(Reference target) {
    final member = target.asMember; // Constructor, Field, or Procedure
    final function = member.function;

    if (target.isTearOffReference) {
      // Tear-off getters don't take type parameters even if the member is
      // generic.
      return ParameterInfo._(true, 0, [], {});
    }

    if (function != null) {
      // Constructor, or static or instance method.
      assert(member is Constructor || member is Procedure);

      final typeParamCount = (member is Constructor
              ? member.enclosingClass.typeParameters
              : function.typeParameters)
          .length;

      final positional =
          List.generate(function.positionalParameters.length, (i) {
        // A required parameter has no default value.
        if (i < function.requiredParameterCount) return null;
        return _defaultValue(function.positionalParameters[i]);
      });

      final named = {
        for (VariableDeclaration param in function.namedParameters)
          param.name!: _defaultValue(param)
      };

      return ParameterInfo._(
          member.isInstanceMember, typeParamCount, positional, named);
    }

    // A setter or getter. A setter parameter has no default value.
    assert(member is Field);
    return ParameterInfo._(true, 0, [if (target.isSetter) null], {});
  }

  factory ParameterInfo.fromLocalFunction(FunctionNode function) {
    final typeParamCount = function.typeParameters.length;
    final positional = List.generate(function.positionalParameters.length, (i) {
      // A required parameter has no default value.
      if (i < function.requiredParameterCount) return null;
      return _defaultValue(function.positionalParameters[i]);
    });
    final named = {
      for (VariableDeclaration param in function.namedParameters)
        param.name!: _defaultValue(param)
    };
    return ParameterInfo._(true, typeParamCount, positional, named);
  }

  void merge(ParameterInfo other) {
    assert(typeParamCount == other.typeParamCount);
    assert(takesContextOrReceiver == other.takesContextOrReceiver);
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
