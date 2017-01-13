// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.dart_work_manager;

import 'dart:collection';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisErrorInfo, CacheState, InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';

/**
 * The manager for Dart specific analysis.
 */
class DartWorkManager implements WorkManager {
  /**
   * The list of errors that are reported for raw Dart [Source]s.
   */
  static final List<ResultDescriptor<List<AnalysisError>>> _SOURCE_ERRORS =
      <ResultDescriptor<List<AnalysisError>>>[
    BUILD_DIRECTIVES_ERRORS,
    BUILD_LIBRARY_ERRORS,
    PARSE_ERRORS,
    SCAN_ERRORS
  ];

  /**
   * The list of errors that are reported for raw Dart [LibrarySpecificUnit]s.
   */
  static final List<ResultDescriptor<List<AnalysisError>>> _UNIT_ERRORS =
      <ResultDescriptor<List<AnalysisError>>>[
    HINTS,
    LINTS,
    LIBRARY_UNIT_ERRORS,
    RESOLVE_DIRECTIVES_ERRORS,
    RESOLVE_TYPE_NAMES_ERRORS,
    RESOLVE_TYPE_BOUNDS_ERRORS,
    RESOLVE_UNIT_ERRORS,
    STRONG_MODE_ERRORS,
    VARIABLE_REFERENCE_ERRORS,
    VERIFY_ERRORS
  ];

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
   * A table mapping library sources to the part sources they include.
   */
  final HashMap<Source, List<Source>> libraryPartsMap =
      new HashMap<Source, List<Source>>();

  /**
   * A table mapping part sources to the library sources that include them.
   */
  final HashMap<Source, List<Source>> partLibrariesMap =
      new HashMap<Source, List<Source>>();

  /**
   * Initialize a newly created manager.
   */
  DartWorkManager(this.context) {
    context.onResultInvalidated.listen((InvalidatedResult event) {
      if (event.descriptor == LIBRARY_ERRORS_READY) {
        CacheEntry entry = event.entry;
        if (entry.explicitlyAdded &&
            entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY) {
          librarySourceQueue.add(entry.target);
        }
      }
    });
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
    addedSources = addedSources.where(_isDartSource).toList();
    changedSources = changedSources
        .where(_isDartSource)
        .where((source) => _needsComputing(source, SOURCE_KIND))
        .toList();
    removedSources = removedSources.where(_isDartSource).toList();
    // unknown queue
    unknownSourceQueue.addAll(addedSources);
    unknownSourceQueue.addAll(changedSources);
    unknownSourceQueue.removeAll(removedSources);
    // library queue
    librarySourceQueue.removeAll(changedSources);
    librarySourceQueue.removeAll(removedSources);
    // parts in libraries
    for (Source changedSource in changedSources) {
      _onLibrarySourceChangedOrRemoved(changedSource);
    }
    for (Source removedSource in removedSources) {
      partLibrariesMap.remove(removedSource);
      _onLibrarySourceChangedOrRemoved(removedSource);
    }
  }

  @override
  void applyPriorityTargets(List<AnalysisTarget> targets) {
    // Unschedule the old targets.
    List<TargetedResult> resultsToUnschedule = <TargetedResult>[];
    for (TargetedResult result in priorityResultQueue) {
      if (result.result == LIBRARY_ERRORS_READY) {
        resultsToUnschedule.add(result);
      }
    }
    priorityResultQueue.removeAll(resultsToUnschedule);
    // Schedule new targets.
    for (AnalysisTarget target in targets) {
      if (_isDartSource(target)) {
        SourceKind sourceKind = analysisCache.getValue(target, SOURCE_KIND);
        if (sourceKind == SourceKind.UNKNOWN) {
          addPriorityResult(target, SOURCE_KIND);
        } else if (sourceKind == SourceKind.LIBRARY) {
          _schedulePriorityLibrarySourceAnalysis(target);
        } else if (sourceKind == SourceKind.PART) {
          List<Source> libraries = context.getLibrariesContaining(target);
          for (Source library in libraries) {
            addPriorityResult(library, LIBRARY_ERRORS_READY);
          }
        }
      }
    }
  }

  @override
  List<AnalysisError> getErrors(Source source) {
    if (!_isDartSource(source) && source is! DartScript) {
      return AnalysisError.NO_ERRORS;
    }
    // If analysis is finished, use all the errors.
    if (analysisCache.getState(source, DART_ERRORS) == CacheState.VALID) {
      return analysisCache.getValue(source, DART_ERRORS);
    }
    // If analysis is in progress, combine all known partial results.
    List<AnalysisError> errors = <AnalysisError>[];
    for (ResultDescriptor<List<AnalysisError>> descriptor in _SOURCE_ERRORS) {
      errors.addAll(analysisCache.getValue(source, descriptor));
    }
    for (Source library in context.getLibrariesContaining(source)) {
      LibrarySpecificUnit unit = new LibrarySpecificUnit(library, source);
      for (ResultDescriptor<List<AnalysisError>> descriptor in _UNIT_ERRORS) {
        errors.addAll(analysisCache.getValue(unit, descriptor));
      }
    }
    return errors;
  }

  /**
   * Returns libraries containing the given [part].
   * Maybe empty, but not null.
   */
  List<Source> getLibrariesContainingPart(Source part) {
    if (part.isInSystemLibrary) {
      DartWorkManager sdkDartWorkManager = _getSdkDartWorkManager();
      if (sdkDartWorkManager != this) {
        return sdkDartWorkManager.getLibrariesContainingPart(part);
      }
    }
    List<Source> libraries = partLibrariesMap[part];
    libraries ??= _getLibrariesContainingPartFromResultProvider(part);
    return libraries?.toList() ?? Source.EMPTY_LIST;
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

  /**
   * Notifies the manager about analysis options changes.
   */
  void onAnalysisOptionsChanged() {
    _invalidateAllLocalResolutionInformation(false);
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
    bool isDartSource = _isDartSource(target);
    // Route SDK outputs to the SDK WorkManager.
    if (isDartSource && target.source.isInSystemLibrary) {
      DartWorkManager sdkWorkManager = _getSdkDartWorkManager();
      if (sdkWorkManager != this) {
        sdkWorkManager.resultsComputed(target, outputs);
        return;
      }
    }
    // Organize sources.
    bool isDartLibrarySource = false;
    if (isDartSource) {
      Source source = target;
      SourceKind kind = outputs[SOURCE_KIND];
      if (kind != null) {
        unknownSourceQueue.remove(source);
        if (kind == SourceKind.LIBRARY) {
          isDartLibrarySource = true;
          if (context.prioritySources.contains(source)) {
            _schedulePriorityLibrarySourceAnalysis(source);
          } else {
            bool needErrors = _shouldErrorsBeComputed(source);
            if (needErrors) {
              librarySourceQueue.add(target);
            }
          }
        }
      }
    }
    // Update parts in libraries.
    if (isDartLibrarySource) {
      Source library = target;
      List<Source> includedParts = outputs[INCLUDED_PARTS] as List<Source>;
      if (includedParts != null) {
        libraryPartsMap[library] = includedParts;
        for (Source part in includedParts) {
          List<Source> libraries =
              partLibrariesMap.putIfAbsent(part, () => <Source>[]);
          if (!libraries.contains(library)) {
            libraries.add(library);
            _invalidateContainingLibraries(part);
          }
        }
      }
    }
    // Update notice.
    if (isDartSource) {
      bool shouldSetErrors = false;
      outputs.forEach((ResultDescriptor descriptor, value) {
        if (descriptor == PARSED_UNIT && value != null) {
          context.getNotice(target).parsedDartUnit = value;
          shouldSetErrors = true;
        }
        if (descriptor == DART_ERRORS) {
          shouldSetErrors = true;
        }
      });
      if (shouldSetErrors) {
        AnalysisErrorInfo info = context.getErrors(target);
        context.getNotice(target).setErrors(info.errors, info.lineInfo);
      }
    }
    if (target is LibrarySpecificUnit) {
      Source source = target.source;
      bool shouldSetErrors = false;
      outputs.forEach((ResultDescriptor descriptor, value) {
        if (descriptor == RESOLVED_UNIT && value != null) {
          context.getNotice(source).resolvedDartUnit = value;
          shouldSetErrors = true;
        }
      });
      if (shouldSetErrors) {
        AnalysisErrorInfo info = context.getErrors(source);
        context.getNotice(source).setErrors(info.errors, info.lineInfo);
      }
    }
  }

  /**
   * The given unit was incrementally resolved. Some of its error results might
   * have been invalidated, so we schedule it for computing errors.
   */
  void unitIncrementallyResolved(Source librarySource, Source unitSource) {
    librarySourceQueue.add(librarySource);
  }

  /**
   * Ask the [context]'s result provider for [CONTAINING_LIBRARIES].
   * Return the list of containing libraries, or `null` if unknown.
   */
  List<Source> _getLibrariesContainingPartFromResultProvider(Source part) {
    CacheEntry cacheEntry = context.getCacheEntry(part);
    bool knows = context.aboutToComputeResult(cacheEntry, CONTAINING_LIBRARIES);
    if (knows) {
      return cacheEntry.getValue(CONTAINING_LIBRARIES);
    }
    return null;
  }

  /**
   * Return the SDK [DartWorkManager] or this one.
   */
  DartWorkManager _getSdkDartWorkManager() {
    SourceFactory sourceFactory = context.sourceFactory;
    InternalAnalysisContext sdkContext = sourceFactory.dartSdk.context;
    if (sdkContext != context) {
      for (WorkManager workManager in sdkContext.workManagers) {
        if (workManager is DartWorkManager) {
          return workManager;
        }
      }
    }
    return this;
  }

  /**
   * Invalidate all of the resolution results computed by this context. The flag
   * [invalidateUris] should be `true` if the cached results of converting URIs
   * to source files should also be invalidated.
   */
  void _invalidateAllLocalResolutionInformation(bool invalidateUris) {
    CachePartition partition = privateAnalysisCachePartition;
    // Prepare targets and values to invalidate.
    List<Source> dartSources = <Source>[];
    List<LibrarySpecificUnit> unitTargets = <LibrarySpecificUnit>[];
    MapIterator<AnalysisTarget, CacheEntry> iterator = partition.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      // Optionally gather Dart sources to invalidate URIs resolution.
      if (invalidateUris && _isDartSource(target)) {
        dartSources.add(target);
      }
      // LibrarySpecificUnit(s) are roots of Dart resolution.
      // When one is invalidated, invalidation is propagated to all resolution.
      if (target is LibrarySpecificUnit) {
        unitTargets.add(target);
        Source library = target.library;
        if (context.exists(library)) {
          CacheEntry entry = iterator.value;
          if (entry.explicitlyAdded) {
            librarySourceQueue.add(library);
          }
        }
      }
    }
    // Invalidate targets and values.
    unitTargets.forEach(partition.remove);
    for (Source dartSource in dartSources) {
      CacheEntry entry = partition.get(dartSource);
      if (entry != null) {
        // TODO(scheglov) we invalidate too much.
        // Would be nice to invalidate just URLs resolution.
        entry.setState(PARSED_UNIT, CacheState.INVALID);
        entry.setState(IMPORTED_LIBRARIES, CacheState.INVALID);
        entry.setState(EXPLICITLY_IMPORTED_LIBRARIES, CacheState.INVALID);
        entry.setState(EXPORTED_LIBRARIES, CacheState.INVALID);
        entry.setState(INCLUDED_PARTS, CacheState.INVALID);
        entry.setState(LIBRARY_SPECIFIC_UNITS, CacheState.INVALID);
        entry.setState(UNITS, CacheState.INVALID);
      }
    }
  }

  /**
   * Invalidate  [CONTAINING_LIBRARIES] for the given [source].
   * [CONTAINING_LIBRARIES] does not have dependencies, so we manage it here.
   * The [source] may be a part, or a library whose contents is updated so
   * will be a part.
   */
  void _invalidateContainingLibraries(Source source) {
    CacheEntry entry = analysisCache.get(source);
    if (entry != null) {
      entry.setState(CONTAINING_LIBRARIES, CacheState.INVALID);
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
   * The given [library] source was changed or removed.
   * Update [libraryPartsMap] and [partLibrariesMap].
   */
  void _onLibrarySourceChangedOrRemoved(Source library) {
    List<Source> parts = libraryPartsMap.remove(library);
    if (parts != null) {
      for (Source part in parts) {
        List<Source> libraries = partLibrariesMap[part];
        if (libraries != null) {
          libraries.remove(library);
          _invalidateContainingLibraries(part);
        }
      }
    }
    _invalidateContainingLibraries(library);
  }

  /**
   * Schedule computing [RESOLVED_UNIT] for the given [librarySource].
   * If errors should be computed, then schedule [LIBRARY_ERRORS_READY] instead,
   * it also computes [RESOLVED_UNIT] in process.
   */
  void _schedulePriorityLibrarySourceAnalysis(Source librarySource) {
    bool needErrors = _shouldErrorsBeComputed(librarySource);
    if (needErrors) {
      addPriorityResult(librarySource, LIBRARY_ERRORS_READY);
    } else {
      var target = new LibrarySpecificUnit(librarySource, librarySource);
      addPriorityResult(target, RESOLVED_UNIT);
    }
  }

  bool _shouldErrorsBeComputed(Source source) =>
      context.shouldErrorsBeAnalyzed(source);

  static bool _isDartSource(AnalysisTarget target) {
    return target is Source && AnalysisEngine.isDartFileName(target.fullName);
  }
}
