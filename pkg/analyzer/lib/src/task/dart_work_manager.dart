// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.dart_work_manager;

import 'dart:collection';

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, CacheState, InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';

/**
 * The manager for Dart specific analysis.
 */
class DartWorkManager implements WorkManager {
  final InternalAnalysisContext context;

  /**
   * The [TargetedResult]s that should be computed with priority.
   */
  final LinkedHashSet<TargetedResult> priorityResultQueue =
      new LinkedHashSet<TargetedResult>();

  /**
   * The sources whose kind we don't know yet.
   */
  final LinkedHashSet<Source> unknownSourceQueue = new LinkedHashSet<Source>();

  /**
   * The queue of library sources to process.
   */
  final LinkedHashSet<Source> librarySourceQueue = new LinkedHashSet<Source>();

  /**
   * Initialize a newly created manager.
   */
  DartWorkManager(this.context);

  /**
   * Specifies that the client want the given [result] of the given [target]
   * to be computed with priority.
   */
  void addPriorityResult(AnalysisTarget target, ResultDescriptor result) {
    priorityResultQueue.add(new TargetedResult(target, result));
  }

  /**
   * Notifies the manager about changes in the explicit source list.
   */
  void applyChange(List<Source> addedSources, List<Source> changedSources,
      List<Source> removedSources) {
    addedSources = addedSources.where(_isDartSource).toList();
    changedSources = changedSources.where(_isDartSource).toList();
    removedSources = removedSources.where(_isDartSource).toList();
    // unknown queue
    unknownSourceQueue.addAll(addedSources);
    unknownSourceQueue.addAll(changedSources);
    unknownSourceQueue.removeAll(removedSources);
    // library queue
    librarySourceQueue.removeAll(changedSources);
    librarySourceQueue.removeAll(removedSources);
    // Some of the libraries might have been invalidated, reschedule them.
    {
      MapIterator<AnalysisTarget, CacheEntry> iterator =
          (context.analysisCache as AnalysisCache).iterator();
      while (iterator.moveNext()) {
        AnalysisTarget target = iterator.key;
        if (_isDartSource(target)) {
          CacheEntry entry = iterator.value;
          if (entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY &&
              entry.getValue(LIBRARY_ERRORS_READY) != true) {
            librarySourceQueue.add(target);
          }
        }
      }
    }
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
    // Try to find a new library to analyze.
    while (librarySourceQueue.isNotEmpty) {
      Source librarySource = librarySourceQueue.first;
      // Maybe done with this library.
      if (!_needsComputing(librarySource, LIBRARY_ERRORS_READY)) {
        librarySourceQueue.remove(librarySource);
        continue;
      }
      // Analyze this library.
      return new TargetedResult(librarySource, LIBRARY_ERRORS_READY);
    }
    // No libraries in the queue, check whether there are sources to organize.
    while (unknownSourceQueue.isNotEmpty) {
      Source source = unknownSourceQueue.first;
      // Maybe done with this source.
      if (!_needsComputing(source, SOURCE_KIND)) {
        unknownSourceQueue.remove(source);
        continue;
      }
      // Compute the kind of this source.
      return new TargetedResult(source, SOURCE_KIND);
    }
    // TODO(scheglov) Report errors for parts that remained in the queue after
    // all libraries had been processed.
    // No results to compute.
    return null;
  }

  @override
  WorkOrderPriority getNextResultPriority() {
    if (priorityResultQueue.isNotEmpty) {
      return WorkOrderPriority.PRIORITY;
    }
    if (unknownSourceQueue.isNotEmpty || librarySourceQueue.isNotEmpty) {
      return WorkOrderPriority.NORMAL;
    }
    return WorkOrderPriority.NONE;
  }

  @override
  void resultsComputed(
      AnalysisTarget target, Map<ResultDescriptor, dynamic> outputs) {
    // Organize sources.
    if (_isDartSource(target)) {
      SourceKind kind = outputs[SOURCE_KIND];
      if (kind != null) {
        unknownSourceQueue.remove(target);
        if (kind == SourceKind.LIBRARY) {
          librarySourceQueue.add(target);
        }
      }
    }
  }

  bool _isDartSource(AnalysisTarget target) {
    return target is Source && AnalysisEngine.isDartFileName(target.fullName);
  }

  /**
   * Returns `true` if the given [result] of the given [target] needs
   * computing, i.e. it is not in the valid and not in the error state.
   */
  bool _needsComputing(AnalysisTarget target, ResultDescriptor result) {
    AnalysisCache cache = context.analysisCache;
    CacheState state = cache.getState(target, result);
    return state != CacheState.VALID && state != CacheState.ERROR;
  }
}
