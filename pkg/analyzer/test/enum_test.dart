// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.enums;

import 'dart:mirrors';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart' as html;
import 'package:analyzer/src/generated/instrumentation.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart' as scanner;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:unittest/unittest.dart';

import 'generated/ast_test.dart';
import 'reflective_tests.dart';

void main() {
  groupSep = ' | ';
  runReflectiveTests(EnumTest);
}


@ReflectiveTestCase()
class EnumTest {
  void test_AnalysisLevel() {
    new EnumTester<AnalysisLevel>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_AngularPropertyKind() {
    new EnumTester<AngularPropertyKind>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_AssignmentKind() {
    new EnumTester<AssignmentKind>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_CacheState() {
    new EnumTester<CacheState>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_ElementKind() {
    new EnumTester<ElementKind>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_ErrorProperty() {
    new EnumTester<ErrorProperty>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_ErrorSeverity() {
    new EnumTester<ErrorSeverity>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_ErrorType() {
    new EnumTester<ErrorType>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_html_TokenType() {
    new EnumTester<html.TokenType>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_INIT_STATE() {
    new EnumTester<INIT_STATE>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_InstrumentationLevel() {
    new EnumTester<InstrumentationLevel>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_Keyword() {
    new EnumTester<scanner.Keyword>(ignoreGetters: ['keywords'])
        ..check_getters()
        ..check_explicit_values();
  }

  void test_Modifier() {
    new EnumTester<Modifier>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_ParameterKind() {
    new EnumTester<ParameterKind>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_RedirectingConstructorKind() {
    new EnumTester<RedirectingConstructorKind>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_RetentionPriority() {
    new EnumTester<RetentionPriority>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_scanner_TokenType() {
    new EnumTester<scanner.TokenType>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_SourceKind() {
    new EnumTester<SourceKind>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_SourcePriority() {
    new EnumTester<SourcePriority>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_TokenClass() {
    new EnumTester<scanner.TokenClass>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_UriKind() {
    new EnumTester<UriKind>()
        ..check_getters()
        ..check_explicit_values();
  }

  void test_WrapperKind() {
    new EnumTester<WrapperKind>()
        ..check_getters()
        ..check_explicit_values();
  }
}


/**
 * Helper class for testing invariants of enumerated types.
 */
class EnumTester<C extends Enum> {
  /**
   * Set of getter names which should be ignored when looking for getters
   * representing enum values.
   */
  Set<String> _ignoreGetters = new Set<String>();

  EnumTester({List<String> ignoreGetters}) {
    // Always ignore a getter called "values".
    _ignoreGetters.add('values');

    if (ignoreGetters != null) {
      for (String getterName in ignoreGetters) {
        _ignoreGetters.add(getterName);
      }
    }
  }

  /**
   * Get a map from getter name to the value returned by the getter, for all
   * static getters in [C] whose name isn't in [_ignoreGetters].
   */
  Map<String, C> get _getters {
    Map<String, C> result = <String, C>{};
    ClassMirror reflectedClass = reflectClass(C);
    reflectedClass.staticMembers.forEach((Symbol symbol, MethodMirror method) {
      if (!method.isGetter) {
        return;
      }
      String name = MirrorSystem.getName(symbol);
      if (_ignoreGetters.contains(name)) {
        return;
      }
      C value = reflectedClass.getField(symbol).reflectee;
      result[name] = value;
    });
    return result;
  }

  /**
   * Check invariants on the list of enum values accessible via the static
   * getter "values".
   */
  void check_explicit_values() {
    ClassMirror reflectedClass = reflectClass(C);
    List<C> values = reflectedClass.getField(#values).reflectee;
    Map<C, int> reverseMap = <C, int>{};

    // Check that "values" is a list of values of type C, with no duplicates.
    expect(values, isList);
    for (int i = 0; i < values.length; i++) {
      C value = values[i];
      expect(value, new isInstanceOf<C>(), reason: 'values[$i]');
      if (reverseMap.containsKey(value)) {
        fail('values[$i] and values[${reverseMap[value]}] both equal $value');
      }
      reverseMap[value] = i;
    }

    // Check that the set of values in the "values" list matches the set of
    // values accessible via static fields.
    expect(reverseMap.keys.toSet(), equals(_getters.values.toSet()));

    // Make sure the order of the list matches the ordinal numbers.
    for (int i = 0; i < values.length; i++) {
      expect(values[i].ordinal, equals(i), reason: 'values[$i].ordinal');
    }
  }

  /**
   * Check invariants on the set of enum values accessible via the static
   * getters defined in the class [C] (with the exception of a getter called
   * "values").
   */
  void check_getters() {
    Map<int, String> ordinals = <int, String>{};
    int numValues = 0;

    _getters.forEach((String name, C value) {
      String reason = 'getter: $name';
      ++numValues;

      // Check the type of the value
      expect(value, new isInstanceOf<C>(), reason: reason);

      // Check that the name of the getter matches the name stored in the enum.
      expect(value.name, equals(name), reason: reason);

      // Check that there are no duplicate ordinals.
      if (ordinals.containsKey(value.ordinal)) {
        fail(
            'Getters $name and ${ordinals[value.ordinal]} have ordinal value ${value.ordinal}');
      }
      ordinals[value.ordinal] = name;
    });

    // Check that the set of ordinals runs from 0 to N-1, where N is the number
    // of enumerated values.
    Set<int> expectedOrdinals = new Set<int>();
    for (int i = 0; i < numValues; i++) {
      expectedOrdinals.add(i);
    }
    expect(ordinals.keys.toSet(), equals(expectedOrdinals));
  }
}
