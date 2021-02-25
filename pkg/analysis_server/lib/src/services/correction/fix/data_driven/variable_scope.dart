// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/value_generator.dart';

/// A scope in which the generators associated with variables can be looked up.
class VariableScope {
  /// An empty variable scope.
  static final empty = VariableScope(null, {});

  /// The outer scope in which this scope is nested.
  final VariableScope outerScope;

  /// A table mapping variable names to generators.
  final Map<String, ValueGenerator> _generators;

  /// Initialize a newly created variable scope defining the variables in the
  /// [_generators] map. Any variables not defined locally will be looked up in
  /// the [outerScope].
  VariableScope(this.outerScope, this._generators);

  /// Return the generator used to generate the value of the variable with the
  /// given [variableName], or `null` if the variable is not defined.
  ValueGenerator lookup(String variableName) {
    return _generators[variableName] ?? outerScope?.lookup(variableName);
  }
}
