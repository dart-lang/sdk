// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dap/dap.dart';
import 'package:vm_service/vm_service.dart';

import 'protocol_converter.dart';

/// A wrapper around variables for use in `variablesRequest` that can hold
/// additional data, such as a formatting information supplied in an evaluation
/// request.
class VariableData {
  VariableData(this.data, this.format);
  final Object data;
  final VariableFormat? format;
}

/// Data used to lazily evaluate a getter in a Variables request.
class VariableGetter {
  VariableGetter({
    required this.instance,
    required this.getter,
    required this.parentEvaluateName,
    required this.allowCallingToString,
  });
  final Instance instance;
  final GetterInfo getter;
  final EvaluateName? parentEvaluateName;
  final bool allowCallingToString;
}

/// A wrapper around variables for use in `variablesRequest` that can hold
/// additional data, such as a formatting information supplied in an evaluation
/// request.
class FrameScopeData {
  FrameScopeData(this.frame, this.kind);
  final Frame frame;
  final FrameScopeDataKind kind;
}

enum FrameScopeDataKind { locals, globals }

/// A wrapper around a variable for use in `variablesRequest` that holds
/// an instance sent for inspection.
class InspectData {
  InspectData(this.instance);
  final InstanceRef? instance;
}

/// A wrapper around an Instance ID that will result in a variable with a single
/// field `value` that can be used by DAP-over-DDS clients wanting to use
/// variables requests for variable display.
class WrappedInstanceVariable {
  WrappedInstanceVariable(this.instanceId);
  final String instanceId;
}

/// Formatting preferences for a variable.
class VariableFormat {
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

  /// Whether to supress quotes around [String]s.
  final bool noQuotes;

  /// Whether to render integers as hex.
  final bool hex;

  /// Whether to force rendering integers as decimal (base 10).
  final bool decimal;

  String formatInt(int? value) {
    return value != null && hex
        ? '0x${value.toRadixString(16)}'
        : value.toString();
  }

  String formatString(String value) {
    return noQuotes ? value : '"$value"';
  }

  String format(Object? value) {
    return switch (value) {
      int() => formatInt(value),
      String() => formatString(value),
      _ => value.toString(),
    };
  }

  /// Converts a DAP ValueFormat into our own formatting class used by our
  /// debug adapters.
  ///
  /// Returns `null` if the desired format does not require special handling
  /// (or is something we don't support).
  static VariableFormat? fromDapValueFormat(ValueFormat? format) {
    return (format?.hex ?? false) ? const VariableFormat.hex() : null;
  }
}

/// An evaluation expression and optional formatting preferences that were
/// supplied as a trailing format specifier in expression evaluations.
class EvaluationExpression {
  EvaluationExpression._(this.expression, {this.format});

  /// Parse an expression that may end with a format specifier to dictate the
  /// format a value should be presented in.
  factory EvaluationExpression.parse(String expression) {
    final match = _expressionWithFormatSpecifierRegex.firstMatch(expression);
    expression = match?[1] ?? expression;
    final formatSpecifiers = match?[2]?.split(',').toSet() ?? const {};
    final format = formatSpecifiers.isEmpty
        ? null
        : VariableFormat(
            noQuotes: formatSpecifiers.contains('nq'),
            hex: formatSpecifiers.contains('h'),
            decimal: formatSpecifiers.contains('d'),
          );

    return EvaluationExpression._(expression, format: format);
  }
  final String expression;
  final VariableFormat? format;

  /// A regular expression that extracts format specifiers from an evaluation
  /// expression.
  static final _expressionWithFormatSpecifierRegex = RegExp(
    r'(.*?)(?:,([\w,]+))$',
  );
}

/// Data for a dart:ffi Pointer variable that triggers a _readNativeMemory
/// RPC call when the user expands it in the debugger.
class PointerData {
  PointerData(
    this.address,
    this.format, {
    this.staticType,
    this.pointerInstance,
    this.ffiTypeName,
    this.kind = PointerDataKind.children,
  });
  final String address;
  final VariableFormat? format;
  final InstanceRef? pointerInstance;
  final InstanceRef? staticType;
  final PointerDataKind kind;
  final String? ffiTypeName;
}

enum PointerDataKind {
  /// Initial expand: show typed value + lazy [raw bytes] child.
  children,

  /// Lazy icon clicked: return 1 summary variable ("N bytes @ 0x...").
  rawBytesSummary,

  /// Summary expanded: return individual byte variables ([0]: 0xde, ...).
  rawBytes,
}

/// An expression for evaluating a variable ("evaluateName" in DAP) and a flag
/// that indicates whether it's nullable (in which case it must be suffixed with
/// a `?` when accessing members).
typedef EvaluateName = ({String evaluateName, bool isNullable});
