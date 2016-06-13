// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.incremental_analyzer;

import 'dart:io' as io;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/incremental_cache.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:analyzer_cli/src/options.dart';

/**
 * If the given [options] enables incremental analysis and [context] and Dart
 * SDK implementations support incremental analysis, configure it for the
 * given [context] and return the handle to work with it.
 */
IncrementalAnalysisSession configureIncrementalAnalysis(
    CommandLineOptions options, AnalysisContext context) {
  String cachePath = options.incrementalCachePath;
  DartSdk sdk = context.sourceFactory.dartSdk;
  // If supported implementations, configure for incremental analysis.
  if (cachePath != null &&
      context is InternalAnalysisContext &&
      sdk is DirectoryBasedDartSdk) {
    context.typeProvider = sdk.context.typeProvider;
    // Set the result provide from the cache.
    CacheStorage storage = new FolderCacheStorage(
        PhysicalResourceProvider.INSTANCE.getFolder(cachePath),
        '${io.pid}.temp');
    List<int> configSalt = <int>[
      context.analysisOptions.encodeCrossContextOptions()
    ];
    IncrementalCache cache = new IncrementalCache(storage, context, configSalt);
    context.resultProvider = new _CacheBasedResultProvider(context, cache);
    // Listen for new libraries to put into the cache.
    _IncrementalAnalysisSession session =
        new _IncrementalAnalysisSession(options, storage, context, cache);
    context
        .onResultChanged(LIBRARY_ELEMENT1)
        .listen((ResultChangedEvent event) {
      if (event.wasComputed) {
        session.newLibrarySources.add(event.target.source);
      }
    });
    return session;
  }
  // Incremental analysis cannot be used.
  return null;
}

/**
 * Interface that is exposed to the clients of incremental analysis.
 */
abstract class IncrementalAnalysisSession {
  /**
   * Finish tasks required after incremental analysis - save results into the
   * cache, evict old results, etc.
   */
  void finish();

  /**
   * Sets the set of [Source]s analyzed in the context, both explicit and
   * implicit, for which errors might be requested.  This set is used to compute
   * containing libraries for every source in the context.
   */
  void setAnalyzedSources(Iterable<Source> sources);
}

/**
 * The [ResultProvider] that provides results from [IncrementalCache].
 */
class _CacheBasedResultProvider extends ResynthesizerResultProvider {
  final IncrementalCache cache;

  final Set<Source> sourcesWithSummaries = new Set<Source>();
  final Set<Source> sourcesWithoutSummaries = new Set<Source>();
  final Set<String> addedLibraryBundleIds = new Set<String>();

  _CacheBasedResultProvider(InternalAnalysisContext context, this.cache)
      : super(context, new SummaryDataStore(<String>[])) {
    AnalysisContext sdkContext = context.sourceFactory.dartSdk.context;
    createResynthesizer(sdkContext, sdkContext.typeProvider);
  }

  @override
  bool compute(CacheEntry entry, ResultDescriptor result) {
    AnalysisTarget target = entry.target;
    // Source based results.
    if (target is Source) {
      if (result == SOURCE_KIND) {
        SourceKind kind = cache.getSourceKind(target);
        if (kind != null) {
          entry.setValue(result, kind, TargetedResult.EMPTY_LIST);
          return true;
        } else {
          return false;
        }
      }
      if (result == INCLUDED_PARTS) {
        List<Source> parts = cache.getLibraryParts(target);
        if (parts != null) {
          entry.setValue(result, parts, TargetedResult.EMPTY_LIST);
          return true;
        } else {
          return false;
        }
      }
      if (result == DART_ERRORS) {
        List<Source> librarySources = context.getLibrariesContaining(target);
        List<List<AnalysisError>> errorList = <List<AnalysisError>>[];
        for (Source librarySource in librarySources) {
          List<AnalysisError> errors =
              cache.getSourceErrorsInLibrary(librarySource, target);
          if (errors == null) {
            return false;
          }
          errorList.add(errors);
        }
        List<AnalysisError> mergedErrors = AnalysisError.mergeLists(errorList);
        // Filter the errors.
        IgnoreInfo ignoreInfo = context.getResult(target, IGNORE_INFO);
        LineInfo lineInfo = context.getResult(target, LINE_INFO);
        List<AnalysisError> filteredErrors =
            DartErrorsTask.filterIgnored(mergedErrors, ignoreInfo, lineInfo);
        // Set the result.
        entry.setValue(result, filteredErrors, TargetedResult.EMPTY_LIST);
        return true;
      }
    }
    return super.compute(entry, result);
  }

  @override
  bool hasResultsForSource(Source source) {
    // Check cache states.
    if (sourcesWithSummaries.contains(source)) {
      return true;
    }
    if (sourcesWithoutSummaries.contains(source)) {
      return false;
    }
    // Try to load bundles.
    List<LibraryBundleWithId> bundles = cache.getLibraryClosureBundles(source);
    if (bundles == null) {
      sourcesWithoutSummaries.add(source);
      return false;
    }
    // Fill the resynthesizer.
    sourcesWithSummaries.add(source);
    for (LibraryBundleWithId bundleWithId in bundles) {
      if (addedLibraryBundleIds.add(bundleWithId.id)) {
        addBundle(null, bundleWithId.bundle);
      }
    }
    return true;
  }
}

class _IncrementalAnalysisSession implements IncrementalAnalysisSession {
  final CommandLineOptions commandLineOptions;
  final CacheStorage cacheStorage;
  final AnalysisContext context;
  final IncrementalCache cache;

  final Set<Source> newLibrarySources = new Set<Source>();

  _IncrementalAnalysisSession(
      this.commandLineOptions, this.cacheStorage, this.context, this.cache);

  @override
  void finish() {
    // Finish computing new libraries and put them into the cache.
    for (Source librarySource in newLibrarySources) {
      if (!commandLineOptions.machineFormat) {
        print('Compute library element for $librarySource');
      }
      _putLibrary(librarySource);
    }
    // Compact the cache.
    cacheStorage.compact();
  }

  @override
  void setAnalyzedSources(Iterable<Source> sources) {
    for (Source source in sources) {
      SourceKind kind = context.computeKindOf(source);
      if (kind == SourceKind.LIBRARY) {
        context.computeResult(source, LINE_INFO);
        context.computeResult(source, IGNORE_INFO);
        context.computeResult(source, INCLUDED_PARTS);
      }
    }
  }

  void _putLibrary(Source librarySource) {
    LibraryElement libraryElement =
        context.computeResult(librarySource, LIBRARY_ELEMENT);
    try {
      cache.putLibrary(libraryElement);
    } catch (e) {
      return;
    }
    // Write errors for the library units.
    for (CompilationUnitElement unit in libraryElement.units) {
      Source unitSource = unit.source;
      List<AnalysisError> errors = context.computeResult(
          new LibrarySpecificUnit(librarySource, unitSource),
          LIBRARY_UNIT_ERRORS);
      cache.putSourceErrorsInLibrary(librarySource, unitSource, errors);
    }
  }
}
