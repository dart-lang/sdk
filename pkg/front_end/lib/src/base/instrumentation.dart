// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/problems.dart';
import 'package:kernel/ast.dart';

/// Convert '→' to '->' because '→' doesn't show up in some terminals.
/// Remove prefixes that are used very often in tests.
String _shortenInstrumentationString(String s) => s
    .replaceAll('→', '->')
    .replaceAll('dart.core::', '')
    .replaceAll('dart.async::', '')
    .replaceAll('test::', '');

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

/// Instance of [InstrumentationValue] describing a forwarding stub.
class InstrumentationValueForForwardingStub extends InstrumentationValue {
  final Procedure procedure;

  InstrumentationValueForForwardingStub(this.procedure);

  @override
  String toString() {
    var buffer = new StringBuffer();
    void writeParameter(VariableDeclaration parameter) {
      var covariances = <String>[];
      if (parameter.isGenericCovariantInterface) {
        covariances.add('genericInterface');
      }
      if (parameter.isGenericCovariantImpl) {
        covariances.add('genericImpl');
      }
      if (parameter.isCovariant) {
        covariances.add('explicit');
      }
      buffer.write('covariance=(${covariances.join(', ')}) ');
      buffer.write(parameter.type);
      buffer.write(' ');
      buffer.write(parameter.name);
    }

    var function = procedure.function;
    buffer.write(function.returnType);
    buffer.write(' ');
    switch (procedure.kind) {
      case ProcedureKind.Operator:
        buffer.write('operator');
        break;
      case ProcedureKind.Method:
        break;
      case ProcedureKind.Setter:
        buffer.write('set ');
        break;
      case ProcedureKind.Getter:
        buffer.write('get ');
        break;
      default:
        unhandled('${procedure.kind}', 'InstrumentationValueForForwardingStub',
            -1, null);
        break;
    }
    buffer.write(procedure.name.name);
    if (function.typeParameters.isNotEmpty) {
      buffer.write('<');
      for (int i = 0; i < function.typeParameters.length; i++) {
        if (i != 0) buffer.write(', ');
        var typeParameter = function.typeParameters[i];
        var covariances = <String>[];
        if (typeParameter.isGenericCovariantInterface) {
          covariances.add('genericInterface');
        }
        if (typeParameter.isGenericCovariantImpl) {
          covariances.add('genericImpl');
        }
        buffer.write('covariance=(${covariances.join(', ')}) ');
        buffer.write(typeParameter.name);
        buffer.write(' extends ');
        buffer.write(
            new InstrumentationValueForType(typeParameter.bound).toString());
      }
      buffer.write('>');
    }
    buffer.write('(');
    for (int i = 0; i < function.positionalParameters.length; i++) {
      if (i != 0) buffer.write(', ');
      if (i == function.requiredParameterCount) buffer.write('[');
      writeParameter(function.positionalParameters[i]);
    }
    if (function.requiredParameterCount <
        function.positionalParameters.length) {
      buffer.write(']');
    }
    if (function.namedParameters.isNotEmpty) {
      if (function.positionalParameters.length != 0) buffer.write(', ');
      buffer.write('{');
      for (int i = 0; i < function.namedParameters.length; i++) {
        if (i != 0) buffer.write(', ');
        writeParameter(function.namedParameters[i]);
      }
      buffer.write('}');
    }
    buffer.write(')');
    return _shortenInstrumentationString(buffer.toString());
  }
}

/// Instance of [InstrumentationValue] describing a [Member].
class InstrumentationValueForMember extends InstrumentationValue {
  final Member member;

  InstrumentationValueForMember(this.member);

  @override
  String toString() => _shortenInstrumentationString(member.toString());
}

/// Instance of [InstrumentationValue] describing a [DartType].
class InstrumentationValueForType extends InstrumentationValue {
  final DartType type;

  InstrumentationValueForType(this.type);

  @override
  String toString() => _shortenInstrumentationString(type.toString());
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
