// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

class FromEnvironmentEvaluator {
  /// Parameter to "fromEnvironment" methods that denotes the default value.
  static const String _defaultValue = 'defaultValue';

  final TypeSystemImpl _typeSystem;
  final DeclaredVariables _declaredVariables;

  FromEnvironmentEvaluator(this._typeSystem, this._declaredVariables);

  /// Return the value of the variable with the given [name] interpreted as a
  /// 'boolean' value. If the variable is not defined, or the value cannot be
  /// parsed as a boolean, return the default value from [namedValues]. If no
  /// default value, return the default value of the default value from
  /// the [constructor], possibly a [DartObject] representing 'null'.
  DartObject getBool2(
    String name,
    Map<String, DartObjectImpl> namedValues,
    ConstructorElement constructor,
  ) {
    var str = _declaredVariables.get(name);
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

    if (namedValues.containsKey(_defaultValue)) {
      return namedValues[_defaultValue];
    }

    return _defaultValueDefaultValue(constructor);
  }

  /// Return the value of the variable with the given [name] interpreted as an
  /// integer value. If the variable is not defined, or the value cannot be
  /// parsed as an integer, return the default value from [namedValues]. If no
  /// default value, return the default value of the default value from
  /// the [constructor], possibly a [DartObject] representing 'null'.
  DartObject getInt2(
    String name,
    Map<String, DartObjectImpl> namedValues,
    ConstructorElement constructor,
  ) {
    var str = _declaredVariables.get(name);
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

    if (namedValues.containsKey(_defaultValue)) {
      return namedValues[_defaultValue];
    }

    var defaultDefault = _defaultValueDefaultValue(constructor);

    // TODO(scheglov) Remove after https://github.com/dart-lang/sdk/issues/40678
    if (defaultDefault.isNull) {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.intType,
        IntState.UNKNOWN_VALUE,
      );
    }

    return defaultDefault;
  }

  /// Return the value of the variable with the given [name] interpreted as a
  /// string value. If the variable is not defined, or the value cannot be
  /// parsed as a boolean, return the default value from [namedValues]. If no
  /// default value, return the default value of the default value from
  /// the [constructor], possibly a [DartObject] representing 'null'.
  DartObject getString2(
    String name,
    Map<String, DartObjectImpl> namedValues,
    ConstructorElement constructor,
  ) {
    String str = _declaredVariables.get(name);
    if (str != null) {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.stringType,
        StringState(str),
      );
    }

    if (namedValues.containsKey(_defaultValue)) {
      return namedValues[_defaultValue];
    }

    var defaultDefault = _defaultValueDefaultValue(constructor);

    // TODO(scheglov) Remove after https://github.com/dart-lang/sdk/issues/40678
    if (defaultDefault.isNull) {
      return DartObjectImpl(
        _typeSystem,
        _typeSystem.typeProvider.stringType,
        StringState.UNKNOWN_VALUE,
      );
    }

    return defaultDefault;
  }

  DartObject hasEnvironment(String name) {
    var value = _declaredVariables.get(name) != null;
    return DartObjectImpl(
      _typeSystem,
      _typeSystem.typeProvider.boolType,
      BoolState(value),
    );
  }

  static DartObject _defaultValueDefaultValue(ConstructorElement constructor) {
    return constructor.parameters
        .singleWhere((parameter) => parameter.name == _defaultValue)
        .computeConstantValue();
  }
}
