// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/error/listener.dart';

export 'package:analyzer/src/error/listener.dart' show DiagnosticReporter;

@Deprecated("Use 'BooleanDiagnosticListener' instead")
typedef BooleanErrorListener = BooleanDiagnosticListener;

@Deprecated("Use 'DiagnosticReporter' instead")
typedef ErrorReporter = DiagnosticReporter;

@Deprecated("Use 'RecordingDiagnosticListener' instead")
typedef RecorderingErrorListener = RecordingDiagnosticListener;

/// An object that listens for [Diagnostic]s being produced by the analysis
/// engine.
@Deprecated("Use 'DiagnosticListener' instead")
abstract class AnalysisErrorListener implements DiagnosticOrErrorListener {
  /// A diagnostic listener that ignores diagnostics that are reported to it.
  @Deprecated("Use 'DiagnosticListener.nullListener' instead")
  static const AnalysisErrorListener NULL_LISTENER = _NullErrorListener();

  /// This method is invoked when a [diagnostic] has been found by the analysis
  /// engine.
  void onError(Diagnostic diagnostic);
}

/// A [DiagnosticListener] that keeps track of whether any diagnostic has been
/// reported to it.
class BooleanDiagnosticListener
    implements
        // ignore: deprecated_member_use_from_same_package
        AnalysisErrorListener,
        DiagnosticListener {
  /// A flag indicating whether a diagnostic has been reported to this listener.
  bool _diagnosticReported = false;

  /// Whether a diagnostic has been reported to this listener.
  bool get errorReported => _diagnosticReported;

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    _diagnosticReported = true;
  }

  @override
  void onError(Diagnostic diagnostic) => onDiagnostic(diagnostic);
}

abstract class DiagnosticListener implements DiagnosticOrErrorListener {
  /// A diagnostic listener that ignores diagnostics that are reported to it.
  static const DiagnosticListener nullListener = _NullDiagnosticListener();

  void onDiagnostic(Diagnostic diagnostic);
}

sealed class DiagnosticOrErrorListener {}

/// A diagnostic listener that records the diagnostics that are reported to it
/// in a way that is appropriate for caching those diagnostic within an
/// analysis context.
class RecordingDiagnosticListener
    implements
        // ignore: deprecated_member_use_from_same_package
        AnalysisErrorListener,
        DiagnosticListener {
  Set<Diagnostic>? _diagnostics;

  /// The diagnostics collected by the listener.
  List<Diagnostic> get diagnostics {
    if (_diagnostics == null) {
      return const [];
    }
    return _diagnostics!.toList();
  }

  @Deprecated("Use 'diagnostics' instead")
  List<Diagnostic> get errors => diagnostics;

  /// Return the errors collected by the listener for the given [source].
  @Deprecated('No longer supported')
  List<Diagnostic> getErrorsForSource(Source source) {
    if (_diagnostics == null) {
      return const [];
    }
    return _diagnostics!.where((d) => d.source == source).toList();
  }

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    (_diagnostics ??= {}).add(diagnostic);
  }

  @override
  void onError(Diagnostic diagnostic) => onDiagnostic(diagnostic);
}

/// A [DiagnosticListener] that ignores everything.
class _NullDiagnosticListener implements DiagnosticListener {
  const _NullDiagnosticListener();

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    // Ignore diagnostics.
  }
}

// ignore: deprecated_member_use_from_same_package
/// An [AnalysisErrorListener] that ignores everything.
class _NullErrorListener
    implements
        // ignore: deprecated_member_use_from_same_package
        AnalysisErrorListener {
  const _NullErrorListener();

  @override
  void onError(Diagnostic diagnostic) {
    // Ignore diagnostics.
  }
}

extension DiagnosticOrErrorListenerExtension on DiagnosticOrErrorListener {
  void onDiagnostic(Diagnostic diagnostic) => switch (this) {
    DiagnosticListener self => self.onDiagnostic(diagnostic),
    // ignore: deprecated_member_use_from_same_package
    AnalysisErrorListener self => self.onError(diagnostic),
  };
}
