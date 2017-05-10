// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Interface providing the ability to record property/value pairs associated
/// with source file locations.  Intended to facilitate testing.
abstract class Instrumentation {
  /// Records a property/value pair associated with the given URI and offset.
  void record(Uri uri, int offset, String property, InstrumentationValue value);
}

/// Interface for values recorded by [Instrumentation].
abstract class InstrumentationValue {
  const InstrumentationValue();

  /// Checks if the given String is an accurate description of this value.
  ///
  /// The default implementation just checks for equality with the return value
  /// of [toString], however derived classes may want a more sophisticated
  /// implementation (e.g. to allow abbreviations in the description).
  ///
  /// Derived classes should ensure that the invariant holds:
  /// `this.matches(this.toString())` should always return `true`.
  bool matches(String description) => description == toString();
}

/// Instance of [InstrumentationValue] describing a [Procedure].
class InstrumentationValueForProcedure extends InstrumentationValue {
  final Procedure procedure;

  InstrumentationValueForProcedure(this.procedure);

  @override
  String toString() => procedure
      .toString()
      .replaceAll('dart.core::', '')
      .replaceAll('dart.async::', '')
      .replaceAll('test::', '');
}

/// Instance of [InstrumentationValue] describing a [DartType].
class InstrumentationValueForType extends InstrumentationValue {
  final DartType type;

  InstrumentationValueForType(this.type);

  @override
  String toString() {
    // Convert '→' to '->' because '→' doesn't show up in some terminals.
    // Remove prefixes that are used very often in tests.
    return type
        .toString()
        .replaceAll('→', '->')
        .replaceAll('dart.core::', '')
        .replaceAll('dart.async::', '')
        .replaceAll('test::', '');
  }
}

/// Instance of [InstrumentationValue] describing a list of [DartType]s.
class InstrumentationValueForTypeArgs extends InstrumentationValue {
  final List<DartType> types;

  InstrumentationValueForTypeArgs(this.types);

  @override
  String toString() => types
      .map((type) => new InstrumentationValueForType(type).toString())
      .join(', ');
}

/// Instance of [InstrumentationValue] which only matches the given literal
/// string.
class InstrumentationValueLiteral extends InstrumentationValue {
  final String value;

  const InstrumentationValueLiteral(this.value);

  @override
  String toString() => value;
}
