// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show DartType, Member;
import 'package:kernel/src/text_util.dart';

/// Convert '→' to '->' because '→' doesn't show up in some terminals.
/// Remove prefixes that are used very often in tests.
String _shortenInstrumentationString(String s) => s
    .replaceAll('→', '->')
    .replaceAll('dart.core::', '')
    .replaceAll('dart.async::', '')
    .replaceAll('test::', '')
    .replaceAll(new RegExp(r'\s*/\*.*?\*/\s*'), '');

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

/// Instance of [InstrumentationValue] describing a [Member].
class InstrumentationValueForMember extends InstrumentationValue {
  final Member member;

  InstrumentationValueForMember(this.member);

  @override
  String toString() => _shortenInstrumentationString(
      qualifiedMemberNameToString(member, includeLibraryName: true));
}

/// Instance of [InstrumentationValue] describing a [DartType].
class InstrumentationValueForType extends InstrumentationValue {
  final DartType type;

  InstrumentationValueForType(this.type);

  @override
  String toString() =>
      _shortenInstrumentationString(type.leakingDebugToString());
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
