// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.html_work_manager;

import 'dart:collection';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisErrorInfo, CacheState, InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';

/**
 * The manager for HTML specific analysis.
 */
class HtmlWorkManager implements WorkManager {
  /**
   * The context for which work is being managed.
   */
  final InternalAnalysisContext context;

  /**
   * The [TargetedResult]s that should be computed with priority.
   */
  final LinkedHashSet<TargetedResult> priorityResultQueue =
      new LinkedHashSet<TargetedResult>();

  /**
   * The HTML sources.
   */
  final LinkedHashSet<Source> sourceQueue = new LinkedHashSet<Source>();

  /**
   * Initialize a newly created manager.
   */
  HtmlWorkManager(this.context) {
    context.onResultInvalidated.listen(onResultInvalidated);
  }

  /**
   * Returns the correctly typed result of `context.analysisCache`.
   */
  AnalysisCache get analysisCache => context.analysisCache;

  /**
   * The partition that contains analysis results that are not shared with other
   * contexts.
   */
  CachePartition get privateAnalysisCachePartition =>
      context.privateAnalysisCachePartition;

  /**
   * Specifies that the client want the given [result] of the given [target]
   * to be computed with priority.
   */
  void addPriorityResult(AnalysisTarget target, ResultDescriptor result) {
    priorityResultQueue.add(new TargetedResult(target, result));
  }

  @override
  void applyChange(List<Source> addedSources, List<Source> changedSources,
      List<Source> removedSources) {
    addedSources = addedSources.where(_isHtmlSource).toList();
    changedSources = changedSources.where(_isHtmlSource).toList();
    removedSources = removedSources.where(_isHtmlSource).toList();
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
      if (result.result == HTML_ERRORS) {
        resultsToUnschedule.add(result);
      }
    }
    priorityResultQueue.removeAll(resultsToUnschedule);
    // Schedule new targets.
    for (AnalysisTarget target in targets) {
      if (_isHtmlSource(target)) {
        addPriorityResult(target, HTML_ERRORS);
      }
    }
  }

  @override
  List<AnalysisError> getErrors(Source source) {
    if (!_isHtmlSource(source)) {
      return AnalysisError.NO_ERRORS;
    }
    // If analysis is finished, use all the errors.
    if (analysisCache.getState(source, HTML_ERRORS) == CacheState.VALID) {
      return analysisCache.getValue(source, HTML_ERRORS);
    }
    // If analysis is in progress, combine all known partial results.
    List<AnalysisError> errors = <AnalysisError>[];
    errors.addAll(analysisCache.getValue(source, HTML_DOCUMENT_ERRORS));
    List<DartScript> scripts = analysisCache.getValue(source, DART_SCRIPTS);
    for (DartScript script in scripts) {
      errors.addAll(context.getErrors(script).errors);
    }
    return errors;
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
    // Try to find a new HTML file to analyze.
    while (sourceQueue.isNotEmpty) {
      Source htmlSource = sourceQueue.first;
      if (!_needsComputing(htmlSource, HTML_ERRORS)) {
        sourceQueue.remove(htmlSource);
        continue;
      }
      return new TargetedResult(htmlSource, HTML_ERRORS);
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

  /**
   * Notifies the manager about analysis options changes.
   */
  void onAnalysisOptionsChanged() {
    _invalidateAllLocalResolutionInformation(false);
  }

  /**
   * Notifies the manager that a result has been invalidated.
   */
  onResultInvalidated(InvalidatedResult event) {
    ResultDescriptor descriptor = event.descriptor;
    if (descriptor == HTML_ERRORS) {
      sourceQueue.add(event.entry.target);
    } else if (descriptor == DART_SCRIPTS) {
      // TODO(brianwilkerson) Remove the scripts from the DartWorkManager's
      // queues.
    }
  }

  /**
   * Notifies the manager about [SourceFactory] changes.
   */
  void onSourceFactoryChanged() {
    _invalidateAllLocalResolutionInformation(true);
  }

  @override
  void resultsComputed(
      AnalysisTarget target, Map<ResultDescriptor, dynamic> outputs) {
    // Update notice.
    if (_isHtmlSource(target)) {
      bool shouldSetErrors = false;
      outputs.forEach((ResultDescriptor descriptor, value) {
        if (descriptor == HTML_ERRORS) {
          shouldSetErrors = true;
        } else if (descriptor == DART_SCRIPTS) {
          // List<DartScript> scripts = value;
          if (priorityResultQueue.contains(target)) {
            // TODO(brianwilkerson) Add the scripts to the DartWorkManager's
            // priority queue.
          } else {
            // TODO(brianwilkerson) Add the scripts to the DartWorkManager's
            // library queue.
          }
        }
      });
      if (shouldSetErrors) {
        AnalysisErrorInfo info = context.getErrors(target);
        context.getNotice(target).setErrors(info.errors, info.lineInfo);
      }
    }
  }

  /**
   * Invalidate all of the resolution results computed by this context. The flag
   * [invalidateUris] should be `true` if the cached results of converting URIs
   * to source files should also be invalidated.
   */
  void _invalidateAllLocalResolutionInformation(bool invalidateUris) {
    CachePartition partition = privateAnalysisCachePartition;
    // Prepare targets and values to invalidate.
    List<Source> htmlSources = <Source>[];
    List<DartScript> scriptTargets = <DartScript>[];
    MapIterator<AnalysisTarget, CacheEntry> iterator = partition.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      if (_isHtmlSource(target)) {
        htmlSources.add(target);
      }
      if (target is DartScript) {
        scriptTargets.add(target);
      }
    }
    // Invalidate targets and values.
    scriptTargets.forEach(partition.remove);
    for (Source htmlSource in htmlSources) {
      CacheEntry entry = partition.get(htmlSource);
      if (entry != null) {
        entry.setState(HTML_ERRORS, CacheState.INVALID);
        if (invalidateUris) {
          entry.setState(REFERENCED_LIBRARIES, CacheState.INVALID);
        }
      }
    }
  }

  /**
   * Returns `true` if the given [result] of the given [target] needs
   * computing, i.e. it is not in the valid and not in the error state.
   */
  bool _needsComputing(AnalysisTarget target, ResultDescriptor result) {
    CacheState state = analysisCache.getState(target, result);
    return state != CacheState.VALID && state != CacheState.ERROR;
  }

  /**
   * Return `true` if the given target is an HTML source.
   */
  static bool _isHtmlSource(AnalysisTarget target) {
    return target is Source && AnalysisEngine.isHtmlFileName(target.fullName);
  }
}
