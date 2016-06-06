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
        new _IncrementalAnalysisSession(options, cache, context);
    context
        .onResultChanged(LIBRARY_ELEMENT1)
        .listen((ResultChangedEvent event) {
      if (event.wasComputed) {
        session.librarySources.add(event.target.source);
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
    // TODO(scheglov) remove the check after finishing optimizations.
    if (target.source != null &&
        target.source.fullName
            .endsWith('analysis_server/lib/src/computer/computer_hover.dart')) {
      return false;
    }
    // Source based results.
    if (target is Source) {
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
        // TODO(scheglov) provide actual errors
        entry.setValue(result, <AnalysisError>[], TargetedResult.EMPTY_LIST);
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
  final IncrementalCache cache;
  final AnalysisContext context;

  final Set<Source> librarySources = new Set<Source>();

  _IncrementalAnalysisSession(
      this.commandLineOptions, this.cache, this.context);

  @override
  void finish() {
    // Finish computing new libraries and put them into the cache.
    for (Source librarySource in librarySources) {
      if (!commandLineOptions.machineFormat) {
        print('Compute library element for $librarySource');
      }
      LibraryElement libraryElement =
          context.computeResult(librarySource, LIBRARY_ELEMENT);
      // TODO(scheglov) compute and store errors
//      context.computeResult(librarySource, DART_ERRORS);
      try {
        cache.putLibrary(libraryElement);
      } catch (e) {}
    }
  }
}
