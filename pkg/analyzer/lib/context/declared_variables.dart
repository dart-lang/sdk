// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.context.declared_variables;

import 'dart:collection';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;

/**
 * An object used to provide access to the values of variables that have been
 * defined on the command line using the `-D` option.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class DeclaredVariables {
  /**
   * A table mapping the names of declared variables to their values.
   */
  Map<String, String> _declaredVariables = new HashMap<String, String>();

  /**
   * Return the names of the variables for which a value has been defined.
   */
  Iterable<String> get variableNames => _declaredVariables.keys;

  /**
   * Add all variables of [other] to this object.
   */
  void addAll(DeclaredVariables other) {
    _declaredVariables.addAll(other._declaredVariables);
  }

  /**
   * Define a variable with the given [name] to have the given [value].
   */
  void define(String name, String value) {
    _declaredVariables[name] = value;
  }

  /**
   * Return the raw string value of the variable with the given [name],
   * or `null` of the variable is not defined.
   */
  String get(String name) => _declaredVariables[name];

  /**
   * Return the value of the variable with the given [name] interpreted as a
   * 'boolean' value. If the variable is not defined (or [name] is `null`), a
   * DartObject representing "unknown" is returned. If the value cannot be
   * parsed as a boolean, a DartObject representing 'null' is returned. The
   * [typeProvider] is the type provider used to find the type 'bool'.
   */
  DartObject getBool(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return new DartObjectImpl(typeProvider.boolType, BoolState.UNKNOWN_VALUE);
    }
    if (value == "true") {
      return new DartObjectImpl(typeProvider.boolType, BoolState.TRUE_STATE);
    } else if (value == "false") {
      return new DartObjectImpl(typeProvider.boolType, BoolState.FALSE_STATE);
    }
    return new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE);
  }

  /**
   * Return the value of the variable with the given [name] interpreted as an
   * integer value. If the variable is not defined (or [name] is `null`), a
   * DartObject representing "unknown" is returned. If the value cannot be
   * parsed as an integer, a DartObject representing 'null' is returned.
   */
  DartObject getInt(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return new DartObjectImpl(typeProvider.intType, IntState.UNKNOWN_VALUE);
    }
    int bigInteger;
    try {
      bigInteger = int.parse(value);
    } on FormatException {
      return new DartObjectImpl(typeProvider.nullType, NullState.NULL_STATE);
    }
    return new DartObjectImpl(typeProvider.intType, new IntState(bigInteger));
  }

  /**
   * Return the value of the variable with the given [name] interpreted as a
   * String value, or `null` if the variable is not defined. Return the value of
   * the variable with the given name interpreted as a String value. If the
   * variable is not defined (or [name] is `null`), a DartObject representing
   * "unknown" is returned. The [typeProvider] is the type provider used to find
   * the type 'String'.
   */
  DartObject getString(TypeProvider typeProvider, String name) {
    String value = _declaredVariables[name];
    if (value == null) {
      return new DartObjectImpl(
          typeProvider.stringType, StringState.UNKNOWN_VALUE);
    }
    return new DartObjectImpl(typeProvider.stringType, new StringState(value));
  }
}
