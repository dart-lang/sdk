// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.evaluation;

import '../compiler.dart' show
    Compiler;
import '../universe/call_structure.dart' show
    CallStructure;
import 'expressions.dart';

/// Environment used for evaluating constant expressions.
abstract class Environment {
  // TODO(johnniwinther): Replace this with [CoreTypes] and maybe [Backend].
  Compiler get compiler;

  /// Read environments string passed in using the '-Dname=value' option.
  String readFromEnvironment(String name);
}

/// The normalized arguments passed to a const constructor computed from the
/// actual [arguments] and the [defaultValues] of the called construrctor.
class NormalizedArguments {
  final Map<dynamic/*int|String*/, ConstantExpression> defaultValues;
  final CallStructure callStructure;
  final List<ConstantExpression> arguments;

  NormalizedArguments(this.defaultValues, this.callStructure, this.arguments);

  /// Returns the normalized named argument [name].
  ConstantExpression getNamedArgument(String name) {
    int index = callStructure.namedArguments.indexOf(name);
    if (index == -1) {
      // The named argument is not provided.
      return defaultValues[name];
    }
    return arguments[index + callStructure.positionalArgumentCount];
  }

  /// Returns the normalized [index]th positional argument.
  ConstantExpression getPositionalArgument(int index) {
    if (index >= callStructure.positionalArgumentCount) {
      // The positional argument is not provided.
      return defaultValues[index];
    }
    return arguments[index];
  }
}
