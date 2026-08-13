// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

class FromEnvironmentEvaluator {
  final TypeSystemImpl _typeSystem;
  final DeclaredVariables _declaredVariables;

  FromEnvironmentEvaluator(this._typeSystem, this._declaredVariables);

  /// Return the value of the variable with the given [name] interpreted as a
  /// 'boolean' value.
  ///
  /// If the variable is not defined, or the value cannot be parsed as a
  /// boolean, return [defaultValue].
  ///
  /// If [defaultValue] is `null`, return a `false` object.
  DartObjectImpl getBool(String? name, DartObjectImpl? defaultValue) {
    var str = name != null ? _declaredVariables.get(name) : null;
    if (str == 'true') {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.boolType,
        BoolState.TRUE_STATE,
      );
    }
    if (str == 'false') {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.boolType,
        BoolState.FALSE_STATE,
      );
    }

    if (defaultValue != null) {
      return defaultValue;
    }

    return DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.boolType,
      BoolState.FALSE_STATE,
    );
  }

  /// Return the value of the variable with the given [name] interpreted as an
  /// integer value.
  ///
  /// If the variable is not defined, or the value cannot be parsed as an
  /// integer, return [defaultValue].
  ///
  /// If [defaultValue] is `null`, return a `0` object.
  DartObjectImpl getInt(String? name, DartObjectImpl? defaultValue) {
    var str = name != null ? _declaredVariables.get(name) : null;
    if (str != null) {
      try {
        var value = int.parse(str);
        return DartObjectImpl(
          _typeSystem,
          _typeSystem.typeProvider.intType,
          IntState(value),
        );
      } on FormatException {
        // fallthrough
      }
    }

    if (defaultValue != null) {
      return defaultValue;
    }

    return DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.intType,
      IntState(0),
    );
  }

  /// Return the value of the variable with the given [name] interpreted as a
  /// string value.
  ///
  /// If the variable is not defined, or the value cannot be parsed as a
  /// boolean, return [defaultValue].
  ///
  /// If [defaultValue] is `null`, return an empty string object.
  DartObjectImpl getString(String? name, DartObjectImpl? defaultValue) {
    var str = name != null ? _declaredVariables.get(name) : null;
    if (str != null) {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.stringType,
        StringState(str),
      );
    }

    if (defaultValue != null) {
      return defaultValue;
    }

    return DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.stringType,
      StringState(''),
    );
  }

  DartObjectImpl hasEnvironment(String? name) {
    var value = name != null && _declaredVariables.get(name) != null;
    return DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.boolType,
      BoolState(value),
    );
  }
}
