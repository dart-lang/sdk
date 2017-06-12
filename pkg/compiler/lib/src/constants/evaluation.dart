// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.evaluation;

import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import 'constructors.dart';
import 'expressions.dart';

/// Environment used for evaluating constant expressions.
abstract class EvaluationEnvironment {
  CommonElements get commonElements;

  /// Read environments string passed in using the '-Dname=value' option.
  String readFromEnvironment(String name);

  /// Returns the [ConstantExpression] for the value of the constant [local].
  ConstantExpression getLocalConstant(Local local);

  /// Returns the [ConstantExpression] for the value of the constant [field].
  ConstantExpression getFieldConstant(FieldEntity field);

  /// Returns the [ConstantConstructor] corresponding to the constant
  /// [constructor].
  ConstantConstructor getConstructorConstant(ConstructorEntity constructor);

  /// Performs the substitution of the type arguments of [target] for their
  /// corresponding type variables in [type].
  InterfaceType substByContext(InterfaceType base, InterfaceType target);
}

/// The normalized arguments passed to a const constructor computed from the
/// actual [arguments] and the [defaultValues] of the called construrctor.
class NormalizedArguments {
  final Map<dynamic /*int|String*/, ConstantExpression> defaultValues;
  final CallStructure callStructure;
  final List<ConstantExpression> arguments;

  NormalizedArguments(this.defaultValues, this.callStructure, this.arguments);

  /// Returns the normalized named argument [name].
  ConstantExpression getNamedArgument(String name) {
    int index = callStructure.namedArguments.indexOf(name);
    if (index == -1) {
      // The named argument is not provided.
      assert(
          defaultValues[name] != null,
          failedAt(CURRENT_ELEMENT_SPANNABLE,
              "No default value for named argument '$name' in $this."));
      return defaultValues[name];
    }
    ConstantExpression value =
        arguments[index + callStructure.positionalArgumentCount];
    assert(
        value != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "No value for named argument '$name' in $this."));
    return value;
  }

  /// Returns the normalized [index]th positional argument.
  ConstantExpression getPositionalArgument(int index) {
    if (index >= callStructure.positionalArgumentCount) {
      // The positional argument is not provided.
      assert(
          defaultValues[index] != null,
          failedAt(CURRENT_ELEMENT_SPANNABLE,
              "No default value for positional argument $index in $this."));
      return defaultValues[index];
    }
    ConstantExpression value = arguments[index];
    assert(
        value != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "No value for positional argument $index in $this."));
    return value;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('NormalizedArguments[');
    sb.write('defaultValues={');
    bool needsComma = false;
    defaultValues.forEach((var key, ConstantExpression value) {
      if (needsComma) {
        sb.write(',');
      }
      if (key is String) {
        sb.write('"');
        sb.write(key);
        sb.write('"');
      } else {
        sb.write(key);
      }
      sb.write(':');
      sb.write(value.toStructuredText());
      needsComma = true;
    });
    sb.write('},callStructure=');
    sb.write(callStructure);
    sb.write(',arguments=[');
    arguments.forEach((ConstantExpression value) {
      if (needsComma) {
        sb.write(',');
      }
      sb.write(value.toStructuredText());
      needsComma = true;
    });
    sb.write(']]');
    return sb.toString();
  }
}
