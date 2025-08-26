// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

import 'models.dart';

/// Helper to collect diagnostics (hook point for timing/metrics if needed).
Future<List<HarnessDiagnostic>> collectAllDiagnostics(
  ABEngine engine,
  List<String> files,
) async {
  return await engine.collect(files);
}

/// Thin wrapper around AnalysisContextCollection with policy flags.
class ABEngine {
  final String label;
  final OverlayResourceProvider overlay;
  final List<String> roots;

  /// If `true`, a new [AnalysisContextCollectionImpl] is created before any
  /// analysis, without using any caching.
  ///
  /// Not compatible with [withFineDependencies].
  final bool rebuildEveryStep;

  /// If `true`, [AnalysisContextCollectionImpl] is created with the
  /// corresponding flag.
  final bool withFineDependencies;

  AnalysisContextCollectionImpl? _collection;

  ABEngine({
    required this.label,
    required this.overlay,
    required this.roots,
    required this.rebuildEveryStep,
    required this.withFineDependencies,
  });

  AnalysisContextCollection get collection {
    return _collection ??= AnalysisContextCollectionImpl(
      includedPaths: roots,
      resourceProvider: overlay,
      withFineDependencies: withFineDependencies,
    );
  }

  /// Collect diagnostics for [files].
  ///
  /// If [rebuildEveryStep] is true, instantiates a fresh collection to
  /// force conservative recomputation.
  Future<List<HarnessDiagnostic>> collect(List<String> files) async {
    if (rebuildEveryStep) {
      _collection = null;
    }

    var out = <HarnessDiagnostic>[];
    for (var file in files) {
      var analysisContext = collection.contextFor(file);
      var analysisSession = analysisContext.currentSession;
      var errorsResult = await analysisSession.getErrors(file);
      if (errorsResult is ErrorsResult) {
        for (var diagnostic in errorsResult.diagnostics) {
          // Filter TODOs, not interesting for comparison.
          if (diagnostic.diagnosticCode is TodoCode) {
            continue;
          }
          var severityName = _getProcessedSeverity(errorsResult, diagnostic);
          if (severityName == null) {
            continue;
          }
          out.add(
            HarnessDiagnostic(
              path: file,
              code: diagnostic.diagnosticCode.name,
              severity: severityName,
              offset: diagnostic.offset,
              length: diagnostic.length,
              message: diagnostic.message,
            ),
          );
        }
      }
    }
    return out;
  }

  /// Notify that [path] has changed (overlay updated).
  Future<void> notifyChange(String path) async {
    if (_collection case var collection?) {
      var analysisContext = collection.contextFor(path);
      analysisContext.changeFile(path);
      await analysisContext.applyPendingFileChanges();
    }
  }

  void resetPerformance() {
    _collection?.scheduler.accumulatedPerformance = OperationPerformanceImpl(
      '<scheduler>',
    );
  }

  void writePerformanceTo(String path) {
    if (_collection case var collection?) {
      var scheduler = collection.scheduler;
      var buffer = StringBuffer();
      scheduler.accumulatedPerformance.write(buffer: buffer);
      scheduler.accumulatedPerformance = OperationPerformanceImpl(
        '<scheduler>',
      );
      io.File(path).writeAsStringSync(buffer.toString());
    }
  }

  /// Returns the name of the severity of the [diagnostic], after applying
  /// processors from the [errorsResult], or `null` if the diagnostic should
  /// be filtered.
  String? _getProcessedSeverity(
    ErrorsResult errorsResult,
    Diagnostic diagnostic,
  ) {
    var processor = ErrorProcessor.getProcessor(
      errorsResult.analysisOptions,
      diagnostic,
    );

    var severityName = diagnostic.diagnosticCode.severity.name;
    if (processor != null) {
      var severity = processor.severity;
      if (severity == null || severity.name == 'NONE') {
        return null;
      }
      severityName = severity.name;
    }

    return severityName;
  }
}

/// Separate selector context used only for site discovery / validation.
/// We provide resolved units for semantic kinds (e.g., alpha) without warming A/B.
class SiteSelector {
  final OverlayResourceProvider overlay;
  final List<String> roots;
  late AnalysisContextCollection _collection;

  SiteSelector(this.overlay, this.roots) {
    _collection = AnalysisContextCollection(
      includedPaths: roots,
      resourceProvider: overlay,
    );
  }

  /// Notify that [path] has changed (overlay updated).
  Future<void> notifyChange(String path) async {
    var analysisContext = _collection.contextFor(path);
    analysisContext.changeFile(path);
    await analysisContext.applyPendingFileChanges();
  }

  CompilationUnit parsedUnit(String path) {
    var analysisContext = _collection.contextFor(path);
    var analysisSession = analysisContext.currentSession;
    var result = analysisSession.getParsedUnit(path);
    result as ParsedUnitResult;
    return result.unit;
  }

  Future<CompilationUnit?> resolvedUnit(String path) async {
    var analysisContext = _collection.contextFor(path);
    var analysisSession = analysisContext.currentSession;
    var result = await analysisSession.getResolvedUnit(path);
    return result.ifTypeOrNull<ResolvedUnitResult>()?.unit;
  }
}
