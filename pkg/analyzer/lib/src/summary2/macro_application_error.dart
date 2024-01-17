// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:analyzer/src/dart/element/element.dart';

/// Base for all macro related diagnostics.
sealed class AnalyzerMacroDiagnostic {}

final class ApplicationMacroDiagnosticTarget extends MacroDiagnosticTarget {
  final int annotationIndex;

  ApplicationMacroDiagnosticTarget({
    required this.annotationIndex,
  });
}

/// An error while evaluating macro application argument.
final class ArgumentMacroDiagnostic extends AnalyzerMacroDiagnostic {
  final int annotationIndex;
  final int argumentIndex;
  final String message;

  ArgumentMacroDiagnostic({
    required this.annotationIndex,
    required this.argumentIndex,
    required this.message,
  });
}

final class DeclarationsIntrospectionCycleComponent {
  final ElementImpl element;
  final int annotationIndex;
  final ElementImpl introspectedElement;

  DeclarationsIntrospectionCycleComponent({
    required this.element,
    required this.annotationIndex,
    required this.introspectedElement,
  });
}

/// A cycle during declarations phase introspection.
final class DeclarationsIntrospectionCycleDiagnostic
    extends AnalyzerMacroDiagnostic {
  final int annotationIndex;
  final ElementImpl introspectedElement;
  final List<DeclarationsIntrospectionCycleComponent> components;

  DeclarationsIntrospectionCycleDiagnostic({
    required this.annotationIndex,
    required this.introspectedElement,
    required this.components,
  });
}

final class ElementMacroDiagnosticTarget extends MacroDiagnosticTarget {
  final ElementImpl element;

  ElementMacroDiagnosticTarget({
    required this.element,
  });
}

/// An exception while preparing macro application.
final class ExceptionMacroDiagnostic extends AnalyzerMacroDiagnostic {
  final int annotationIndex;
  final String message;
  final String stackTrace;

  ExceptionMacroDiagnostic({
    required this.annotationIndex,
    required this.message,
    required this.stackTrace,
  });
}

/// Diagnostic from the macro framework.
final class MacroDiagnostic extends AnalyzerMacroDiagnostic {
  final macro.Severity severity;
  final MacroDiagnosticMessage message;
  final List<MacroDiagnosticMessage> contextMessages;

  MacroDiagnostic({
    required this.severity,
    required this.message,
    required this.contextMessages,
  });
}

final class MacroDiagnosticMessage {
  final MacroDiagnosticTarget target;
  final String message;

  MacroDiagnosticMessage({
    required this.target,
    required this.message,
  });
}

sealed class MacroDiagnosticTarget {}
