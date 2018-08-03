// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisErrorInfo, CacheState, InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:analyzer/src/task/options.dart';

/// The manager for analysis options specific analysis.
class OptionsWorkManager implements WorkManager {
  /// The context for which work is being managed.
  final InternalAnalysisContext context;

  /// The options file sources.
  final LinkedHashSet<Source> sourceQueue = new LinkedHashSet<Source>();

  /// The [TargetedResult]s that should be computed with priority.
  final LinkedHashSet<TargetedResult> priorityResultQueue =
      new LinkedHashSet<TargetedResult>();

  /// Initialize a newly created manager.
  OptionsWorkManager(this.context) {
    analysisCache.onResultInvalidated.listen(onResultInvalidated);
  }

  /// Returns the correctly typed result of `context.analysisCache`.
  AnalysisCache get analysisCache => context.analysisCache;

  /// Specifies that the client wants the given [result] of the given [target]
  /// to be computed with priority.
  void addPriorityResult(AnalysisTarget target, ResultDescriptor result) {
    priorityResultQueue.add(new TargetedResult(target, result));
  }

  @override
  void applyChange(List<Source> addedSources, List<Source> changedSources,
      List<Source> removedSources) {
    addedSources = addedSources.where(_isOptionsSource).toList();
    changedSources = changedSources.where(_isOptionsSource).toList();
    removedSources = removedSources.where(_isOptionsSource).toList();
    // source queue
    sourceQueue.addAll(addedSources);
    sourceQueue.addAll(changedSources);
    sourceQueue.removeAll(removedSources);
  }

  @override
  void applyPriorityTargets(List<AnalysisTarget> targets) {
    // Unschedule the old targets.
    List<TargetedResult> resultsToUnschedule = <TargetedResult>[];
    for (TargetedResult result in priorityResultQueue) {
      if (result.result == ANALYSIS_OPTIONS_ERRORS) {
        resultsToUnschedule.add(result);
      }
    }
    priorityResultQueue.removeAll(resultsToUnschedule);
    // Schedule new targets.
    for (AnalysisTarget target in targets) {
      if (_isOptionsSource(target)) {
        addPriorityResult(target, ANALYSIS_OPTIONS_ERRORS);
      }
    }
  }

  @override
  List<AnalysisError> getErrors(Source source) {
    if (!_isOptionsSource(source)) {
      return AnalysisError.NO_ERRORS;
    }
    // If analysis is finished, use all the errors.
    if (analysisCache.getState(source, ANALYSIS_OPTIONS_ERRORS) ==
        CacheState.VALID) {
      return analysisCache.getValue(source, ANALYSIS_OPTIONS_ERRORS);
    }
    // No partial results.
    return AnalysisError.NO_ERRORS;
  }

  @override
  TargetedResult getNextResult() {
    // Try to find a priority result to compute.
    while (priorityResultQueue.isNotEmpty) {
      TargetedResult result = priorityResultQueue.first;
      if (!_needsComputing(result.target, result.result)) {
        priorityResultQueue.remove(result);
        continue;
      }
      return result;
    }
    // Try to find a new options file to analyze.
    while (sourceQueue.isNotEmpty) {
      Source optionsSource = sourceQueue.first;
      if (!_needsComputing(optionsSource, ANALYSIS_OPTIONS_ERRORS)) {
        sourceQueue.remove(optionsSource);
        continue;
      }
      return new TargetedResult(optionsSource, ANALYSIS_OPTIONS_ERRORS);
    }
    // No results to compute.
    return null;
  }

  @override
  WorkOrderPriority getNextResultPriority() {
    if (priorityResultQueue.isNotEmpty) {
      return WorkOrderPriority.PRIORITY;
    }
    if (sourceQueue.isNotEmpty) {
      return WorkOrderPriority.NORMAL;
    }
    return WorkOrderPriority.NONE;
  }

  @override
  void onAnalysisOptionsChanged() {
    // Do nothing.
  }

  /// Notifies the manager that a result has been invalidated.
  void onResultInvalidated(InvalidatedResult event) {
    ResultDescriptor descriptor = event.descriptor;
    if (descriptor == ANALYSIS_OPTIONS_ERRORS) {
      sourceQueue.add(event.entry.target);
    }
  }

  @override
  void onSourceFactoryChanged() {
    // Do nothing.
  }

  @override
  void resultsComputed(
      AnalysisTarget target, Map<ResultDescriptor, dynamic> outputs) {
    // Update notice.
    if (_isOptionsSource(target)) {
      bool shouldSetErrors = false;
      outputs.forEach((ResultDescriptor descriptor, value) {
        if (descriptor == ANALYSIS_OPTIONS_ERRORS) {
          shouldSetErrors = true;
        }
      });
      if (shouldSetErrors) {
        AnalysisErrorInfo info = context.getErrors(target);
        context.getNotice(target).setErrors(info.errors, info.lineInfo);
      }
    }
  }

  /// Returns `true` if the given [result] of the given [target] needs
  /// computing, i.e. it is not in the valid and not in the error state.
  bool _needsComputing(AnalysisTarget target, ResultDescriptor result) {
    CacheState state = analysisCache.getState(target, result);
    return state != CacheState.VALID && state != CacheState.ERROR;
  }

  /// Return `true` if the given target is an analysis options source.
  static bool _isOptionsSource(AnalysisTarget target) =>
      target is Source &&
      AnalysisEngine.isAnalysisOptionsFileName(target.fullName);
}
