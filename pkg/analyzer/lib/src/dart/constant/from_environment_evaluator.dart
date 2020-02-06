// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/generated/type_system.dart';

class FromEnvironmentEvaluator {
  final TypeSystemImpl _typeSystem;
  final DeclaredVariables _declaredVariables;

  FromEnvironmentEvaluator(this._typeSystem, this._declaredVariables);

  /// Return the value of the variable with the given [name] interpreted as a
  /// 'boolean' value. If the variable is not defined (or [name] is `null`), a
  /// DartObject representing "unknown" is returned. If the value cannot be
  /// parsed as a boolean, a DartObject representing 'null' is returned.
  DartObject getBool(String name) {
    String value = _declaredVariables.get(name);
    if (value == null) {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.boolType,
        BoolState.UNKNOWN_VALUE,
      );
    }
    if (value == "true") {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.boolType,
        BoolState.TRUE_STATE,
      );
    } else if (value == "false") {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.boolType,
        BoolState.FALSE_STATE,
      );
    }
    return DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.nullType,
      NullState.NULL_STATE,
    );
  }

  /// Return the value of the variable with the given [name] interpreted as an
  /// integer value. If the variable is not defined (or [name] is `null`), a
  /// DartObject representing "unknown" is returned. If the value cannot be
  /// parsed as an integer, a DartObject representing 'null' is returned.
  DartObject getInt(String name) {
    String value = _declaredVariables.get(name);
    if (value == null) {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.intType,
        IntState.UNKNOWN_VALUE,
      );
    }
    int bigInteger;
    try {
      bigInteger = int.parse(value);
    } on FormatException {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.nullType,
        NullState.NULL_STATE,
      );
    }
    return DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.intType,
      IntState(bigInteger),
    );
  }

  /// Return the value of the variable with the given [name] interpreted as a
  /// String value, or `null` if the variable is not defined. Return the value
  /// of the variable with the given name interpreted as a String value. If the
  /// variable is not defined (or [name] is `null`), a DartObject representing
  /// "unknown" is returned.
  DartObject getString(String name) {
    String value = _declaredVariables.get(name);
    if (value == null) {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.stringType,
        StringState.UNKNOWN_VALUE,
      );
    }
    return DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.stringType,
      StringState(value),
    );
  }
}
