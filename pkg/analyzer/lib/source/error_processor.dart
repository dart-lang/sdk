// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// String identifiers mapped to associated severities.
const Map<String, DiagnosticSeverity> severityMap = {
  'error': DiagnosticSeverity.ERROR,
  'info': DiagnosticSeverity.INFO,
  'warning': DiagnosticSeverity.WARNING,
};

/// Error processor configuration derived from analysis (or embedder) options.
class ErrorConfig {
  /// The processors in this config.
  final List<ErrorProcessor> processors = <ErrorProcessor>[];

  /// Create an error config for the given error code map.
  /// For example:
  ///     new ErrorConfig({'missing_return' : 'error'});
  /// will create a processor config that turns `missing_return` warnings into
  /// errors.
  ErrorConfig(YamlNode? codeMap) {
    if (codeMap is YamlMap) {
      _processMap(codeMap);
    }
  }

  void _processMap(YamlMap codes) {
    codes.nodes.forEach((k, v) {
      if (k is YamlScalar && v is YamlScalar) {
        var code = k.value;
        if (code is! String) return;

        code = code.toUpperCase();
        var action = v.value.toString().toLowerCase();
        if (AnalysisOptionsFile.ignoreSynonyms.contains(action)) {
          processors.add(ErrorProcessor.ignore(code));
        } else {
          var severity = severityMap[action];
          if (severity != null) {
            processors.add(ErrorProcessor(code, severity));
          }
        }
      }
    });
  }
}

/// Process errors by filtering or changing associated [DiagnosticSeverity].
class ErrorProcessor {
  /// The code name of the associated error.
  final String code;

  /// The desired severity of the processed error.
  ///
  /// If `null`, this processor will "filter" the associated error code.
  final DiagnosticSeverity? severity;

  /// Create an error processor that assigns errors with this [code] the
  /// given [severity].
  ///
  /// If [severity] is `null`, matching errors will be filtered.
  ErrorProcessor(this.code, [this.severity]);

  /// Create an error processor that ignores the given error by [code].
  factory ErrorProcessor.ignore(String code) => ErrorProcessor(code);

  /// The string that unique describes the processor.
  String get description => '$code -> ${severity?.name}';

  /// Check if this processor applies to the given [diagnostic].
  ///
  /// Note: [code] is normalized to uppercase; `errorCode.name` for regular
  /// analysis issues uses uppercase; `errorCode.name` for lints uses lowercase.
  @visibleForTesting
  bool appliesTo(Diagnostic diagnostic) =>
      code == diagnostic.diagnosticCode.name ||
      code == diagnostic.diagnosticCode.name.toUpperCase();

  @override
  String toString() => "ErrorProcessor[code='$code', severity=$severity]";

  /// Returns an error processor associated in the [analysisOptions] for the
  /// given [diagnostic], or `null` if none is found.
  static ErrorProcessor? getProcessor(
    // TODO(srawlins): Make `analysisOptions` non-nullable, in a breaking
    // change release.
    AnalysisOptions? analysisOptions,
    Diagnostic diagnostic,
  ) {
    return analysisOptions?.errorProcessors.firstWhereOrNull(
      (processor) => processor.appliesTo(diagnostic),
    );
  }
}
