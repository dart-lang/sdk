// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dap/dap.dart';
import 'package:vm_service/vm_service.dart';

/// A wrapper around variables for use in `variablesRequest` that can hold
/// additional data, such as a formatting information supplied in an evaluation
/// request.
class VariableData {
  final Object data;
  final VariableFormat? format;

  VariableData(this.data, this.format);
}

/// Data used to lazily evaluate a getter in a Variables request.
class VariableGetter {
  final Instance instance;
  final String getterName;
  final String? parentEvaluateName;
  final bool allowCallingToString;

  VariableGetter({
    required this.instance,
    required this.getterName,
    required this.parentEvaluateName,
    required this.allowCallingToString,
  });
}

/// A wrapper around variables for use in `variablesRequest` that can hold
/// additional data, such as a formatting information supplied in an evaluation
/// request.
class FrameScopeData {
  final Frame frame;
  final FrameScopeDataKind kind;

  FrameScopeData(this.frame, this.kind);
}

enum FrameScopeDataKind {
  locals,
  globals,
}

/// A wrapper around a variable for use in `variablesRequest` that holds
/// an instance sent for inspection.
class InspectData {
  final InstanceRef? instance;

  InspectData(this.instance);
}

/// A wrapper around an Instance ID that will result in a variable with a single
/// field `value` that can be used by DAP-over-DDS clients wanting to use
/// variables requests for variable display.
class WrappedInstanceVariable {
  final String instanceId;

  WrappedInstanceVariable(this.instanceId);
}

/// Formatting preferences for a variable.
class VariableFormat {
  /// Whether to supress quotes around [String]s.
  final bool noQuotes;

  /// Whether to render integers as hex.
  final bool hex;

  /// Whether to force rendering integers as decimal (base 10).
  final bool decimal;

  const VariableFormat({
    this.noQuotes = false,
    this.hex = false,
    this.decimal = false,
  });

  factory VariableFormat.from(
    VariableFormat base, {
    bool? noQuotes,
    bool? hex,
    bool? decimal,
  }) {
    return VariableFormat(
      noQuotes: noQuotes ?? base.noQuotes,
      hex: hex ?? base.hex,
      decimal: decimal ?? base.decimal,
    );
  }

  const VariableFormat.noQuotes() : this(noQuotes: true);
  const VariableFormat.hex() : this(hex: true);

  String formatInt(int? value) {
    return value != null && hex
        ? '0x${value.toRadixString(16)}'
        : value.toString();
  }

  String formatString(String value) {
    return noQuotes ? value : '"$value"';
  }

  /// Converts a DAP ValueFormat into our own formatting class used by our
  /// debug adapters.
  ///
  /// Returns `null` if the desired format does not require special handling
  /// (or is something we don't support).
  static VariableFormat? fromDapValueFormat(ValueFormat? format) {
    return (format?.hex ?? false) ? VariableFormat.hex() : null;
  }
}

/// An evaluation expression and optional formatting preferences that were
/// supplied as a trailing format specifier in expression evaluations.
class EvaluationExpression {
  final String expression;
  final VariableFormat? format;

  EvaluationExpression._(this.expression, {this.format});

  /// A regular expression that extracts format specifiers from an evaluation
  /// expression.
  static final _expressionWithFormatSpecifierRegex =
      RegExp(r'(.*?)(?:,([\w,]+))$');

  /// Parse an expression that may end with a format specifier to dictate the
  /// format a value should be presented in.
  factory EvaluationExpression.parse(String expression) {
    final match = _expressionWithFormatSpecifierRegex.firstMatch(expression);
    expression = match?.group(1) ?? expression;
    final formatSpecifiers = match?.group(2)?.split(',').toSet() ?? const {};
    final format = formatSpecifiers.isEmpty
        ? null
        : VariableFormat(
            noQuotes: formatSpecifiers.contains('nq'),
            hex: formatSpecifiers.contains('h'),
            decimal: formatSpecifiers.contains('d'),
          );

    return EvaluationExpression._(expression, format: format);
  }
}
