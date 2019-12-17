// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;

/// An object used to provide access to the values of variables that have been
/// defined on the command line using the `-D` option.
///
/// Clients may not extend, implement or mix-in this class.
class DeclaredVariables {
  /// A table mapping the names of declared variables to their values.
  final Map<String, String> _declaredVariables = <String, String>{};

  /// Initialize a newly created set of declared variables in which there are no
  /// variables.
  DeclaredVariables();

  /// Initialize a newly created set of declared variables to define variables
  /// whose names are the keys in the give [variableMap] and whose values are
  /// the corresponding values from the map.
  DeclaredVariables.fromMap(Map<String, String> variableMap) {
    _declaredVariables.addAll(variableMap);
  }

  /// Return the names of the variables for which a value has been defined.
  Iterable<String> get variableNames => _declaredVariables.keys;

  /// Add all variables of [other] to this object.
  @deprecated
  void addAll(DeclaredVariables other) {
    _declaredVariables.addAll(other._declaredVariables);
  }

  /// Define a variable with the given [name] to have the given [value].
  @deprecated
  void define(String name, String value) {
    _declaredVariables[name] = value;
  }

  /// Return the raw string value of the variable with the given [name],
  /// or `null` of the variable is not defined.
  String get(String name) => _declaredVariables[name];

  /// Return the value of the variable with the given [name] interpreted as a
  /// 'boolean' value. If the variable is not defined (or [name] is `null`), a
  /// DartObject representing "unknown" is returned. If the value cannot be
  /// parsed as a boolean, a DartObject representing 'null' is returned. The
  /// [typeProvider] is the type provider used to find the type 'bool'.
  DartObject getBool(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return DartObjectImpl(typeProvider.boolType, BoolState.UNKNOWN_VALUE);
    }
    if (value == "true") {
      return DartObjectImpl(typeProvider.boolType, BoolState.TRUE_STATE);
    } else if (value == "false") {
      return DartObjectImpl(typeProvider.boolType, BoolState.FALSE_STATE);
    }
    return DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE);
  }

  /// Return the value of the variable with the given [name] interpreted as an
  /// integer value. If the variable is not defined (or [name] is `null`), a
  /// DartObject representing "unknown" is returned. If the value cannot be
  /// parsed as an integer, a DartObject representing 'null' is returned.
  DartObject getInt(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return DartObjectImpl(typeProvider.intType, IntState.UNKNOWN_VALUE);
    }
    int bigInteger;
    try {
      bigInteger = int.parse(value);
    } on FormatException {
      return DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE);
    }
    return DartObjectImpl(typeProvider.intType, IntState(bigInteger));
  }

  /// Return the value of the variable with the given [name] interpreted as a
  /// String value, or `null` if the variable is not defined. Return the value
  /// of the variable with the given name interpreted as a String value. If the
  /// variable is not defined (or [name] is `null`), a DartObject representing
  /// "unknown" is returned. The [typeProvider] is the type provider used to
  /// find the type 'String'.
  DartObject getString(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return DartObjectImpl(typeProvider.stringType, StringState.UNKNOWN_VALUE);
    }
    return DartObjectImpl(typeProvider.stringType, StringState(value));
  }
}
