// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.source.error_processor;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:yaml/yaml.dart';

/// String identifiers mapped to associated severities.
const Map<String, ErrorSeverity> severityMap = const {
  'error': ErrorSeverity.ERROR,
  'info': ErrorSeverity.INFO,
  'warning': ErrorSeverity.WARNING
};

/// Error processor configuration derived from analysis (or embedder) options.
class ErrorConfig {
  /// The processors in this config.
  final List<ErrorProcessor> processors = <ErrorProcessor>[];

  /// Create an error config for the given error code map.
  /// For example:
  ///     new ErrorConfig({'missing_return' : 'error'});
  /// will create a processor config that turns `missing_return` hints into
  /// errors.
  ErrorConfig(Object codeMap) {
    _processMap(codeMap);
  }

  void _process(String code, Object action) {
    code = toUpperCase(code);
    action = toLowerCase(action);
    if (AnalyzerOptions.ignoreSynonyms.contains(action)) {
      processors.add(new ErrorProcessor.ignore(code));
    } else {
      ErrorSeverity severity = _toSeverity(action);
      if (severity != null) {
        processors.add(new ErrorProcessor(code, severity));
      }
    }
  }

  void _processMap(Object codes) {
    if (codes is YamlMap) {
      // TODO(pq): stop traversing nodes and unify w/ standard map handling
      codes.nodes.forEach((k, v) {
        if (k is YamlScalar && v is YamlScalar) {
          _process(k.value, v.value);
        }
      });
    } else if (codes is Map) {
      codes.forEach((k, v) {
        if (k is String) {
          _process(k, v);
        }
      });
    }
  }

  ErrorSeverity _toSeverity(String severity) => severityMap[severity];
}

/// Process errors by filtering or changing associated [ErrorSeverity].
class ErrorProcessor {
  /// The code name of the associated error.
  final String code;

  /// The desired severity of the processed error.
  ///
  /// If `null`, this processor will "filter" the associated error code.
  final ErrorSeverity severity;

  /// Create an error processor that assigns errors with this [code] the
  /// given [severity].
  ///
  /// If [severity] is `null`, matching errors will be filtered.
  ErrorProcessor(this.code, [this.severity]);

  /// Create an error processor that ignores the given error by [code].
  factory ErrorProcessor.ignore(String code) => new ErrorProcessor(code);

  /// The string that unique describes the processor.
  String get description => '$code -> ${severity?.name}';

  /// Check if this processor applies to the given [error].
  ///
  /// Note: [code] is normalized to uppercase; `errorCode.name` for regular
  /// analysis issues uses uppercase; `errorCode.name` for lints uses lowercase.
  bool appliesTo(AnalysisError error) =>
      code == error.errorCode.name ||
      code == error.errorCode.name.toUpperCase();

  /// Return an error processor associated in the [analysisOptions] for the
  /// given [error], or `null` if none is found.
  static ErrorProcessor getProcessor(
      AnalysisOptions analysisOptions, AnalysisError error) {
    if (analysisOptions == null) {
      return null;
    }

    // Let the user configure how specific errors are processed.
    List<ErrorProcessor> processors = analysisOptions.errorProcessors;

    // Give strong mode a chance to upgrade it.
    if (analysisOptions.strongMode) {
      processors = processors.toList();
      processors.add(_StrongModeTypeErrorProcessor.instance);
    }
    return processors.firstWhere((ErrorProcessor p) => p.appliesTo(error),
        orElse: () => null);
  }
}

/// In strong mode, this upgrades static type warnings to errors.
class _StrongModeTypeErrorProcessor implements ErrorProcessor {
  static final instance = new _StrongModeTypeErrorProcessor();

  // TODO(rnystrom): As far as I know, this is only used to implement
  // appliesTo(). Consider making it private in ErrorProcessor if possible.
  String get code => throw new UnsupportedError(
      "_StrongModeTypeErrorProcessor is not specific to an error code.");

  @override
  String get description => 'allStrongWarnings -> ERROR';

  /// In strong mode, type warnings are upgraded to errors.
  ErrorSeverity get severity => ErrorSeverity.ERROR;

  /// Check if this processor applies to the given [error].
  bool appliesTo(AnalysisError error) {
    ErrorCode errorCode = error.errorCode;
    if (errorCode is StaticTypeWarningCode) {
      return true;
    }
    if (errorCode is StaticWarningCode) {
      return errorCode.isStrongModeError;
    }
    return false;
  }
}
