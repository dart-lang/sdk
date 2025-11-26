// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/listener.dart';

export 'package:analyzer/src/error/listener.dart' show DiagnosticReporter;

@Deprecated("Use 'DiagnosticReporter' instead")
typedef ErrorReporter = DiagnosticReporter;

/// A [DiagnosticListener] that keeps track of whether any diagnostic has been
/// reported to it.
class BooleanDiagnosticListener implements DiagnosticListener {
  /// A flag indicating whether a diagnostic has been reported to this listener.
  bool _diagnosticReported = false;

  /// Whether a diagnostic has been reported to this listener.
  bool get errorReported => _diagnosticReported;

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    _diagnosticReported = true;
  }
}

abstract class DiagnosticListener {
  /// A diagnostic listener that ignores diagnostics that are reported to it.
  static const DiagnosticListener nullListener = _NullDiagnosticListener();

  void onDiagnostic(Diagnostic diagnostic);
}

/// A diagnostic listener that records the diagnostics that are reported to it
/// in a way that is appropriate for caching those diagnostic within an
/// analysis context.
class RecordingDiagnosticListener implements DiagnosticListener {
  Set<Diagnostic>? _diagnostics;

  /// The diagnostics collected by the listener.
  List<Diagnostic> get diagnostics {
    if (_diagnostics == null) {
      return const [];
    }
    return _diagnostics!.toList();
  }

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    (_diagnostics ??= {}).add(diagnostic);
  }
}

/// A [DiagnosticListener] that ignores everything.
class _NullDiagnosticListener implements DiagnosticListener {
  const _NullDiagnosticListener();

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    // Ignore diagnostics.
  }
}
