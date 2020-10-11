// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

/// Cache of [AnalysisOptionsImpl] objects that correspond to directories
/// with analyzed files, used to reduce searching for `analysis_options.yaml`
/// files.
class ContextCache {
  final ResourceProvider resourceProvider;
  final CommandLineOptions clOptions;
  final void Function(String) verbosePrint;

  /// A mapping from normalized paths (currently, directories) to cache entries
  /// which include builder, analysis_options paths, and [AnalysisOptionImpl]s.
  final Map<String, ContextCacheEntry> _byDirectory = {};

  ContextCache(this.resourceProvider, this.clOptions, this.verbosePrint);

  /// Look up info about a context from the cache. You can pass in any [path],
  /// and it will try to provide an existing [ContextCacheEntry] that is
  /// suitable for that [path] if one exists.
  ContextCacheEntry forSource(String path) {
    path = _normalizeSourcePath(path);
    return _byDirectory.putIfAbsent(path, () {
      final builder = ContextBuilder(resourceProvider, null, null,
          options: clOptions.contextBuilderOptions);
      return ContextCacheEntry(builder, path, clOptions, verbosePrint);
    });
  }

  /// Cheaply normalize source paths so we can increase cache performance.
  /// Getting the location of an analysis_options.yaml file for a given source
  /// can be expensive, so we want to reduce extra lookups where possible. We
  /// know that two files in the same directory share an analysis options file,
  /// so that's the normalization we perform currently. However, this could be
  /// any form of performance-increasing cache key normalization.
  String _normalizeSourcePath(String sourcePath) {
    if (!resourceProvider.pathContext.isAbsolute(sourcePath)) {
      // TODO(mfairhurst) Use resourceProvider.pathContext.absolute(). For the
      // moment, we get an issues where pathContext.current is `.`, which causes
      // pathContext.absolute() to produce `./foo` instead of `/absolute/foo`.
      sourcePath = path.absolute(sourcePath);
    }

    sourcePath = resourceProvider.pathContext.normalize(sourcePath);

    // Prepare the directory which is, or contains, the context root.
    if (resourceProvider.getFolder(sourcePath).exists) {
      return sourcePath;
    }

    return resourceProvider.pathContext.dirname(sourcePath);
  }
}

/// Each entry of the [ContextCache] caches three things: the [ContextBuilder],
/// the analysis_options.yaml path of the context, and the [AnalysisOptionsImpl]
/// of the context.
class ContextCacheEntry {
  final CommandLineOptions clOptions;
  final ContextBuilder builder;
  final String requestedSourceDirectory;
  final void Function(String) verbosePrint;

  AnalysisOptionsImpl _analysisOptions;
  String _analysisRoot;

  ContextCacheEntry(this.builder, this.requestedSourceDirectory, this.clOptions,
      this.verbosePrint);

  /// Get the fully parsed [AnalysisOptionsImpl] for this entry.
  AnalysisOptionsImpl get analysisOptions =>
      _analysisOptions ??= _getAnalysisOptions();

  /// Find the root path from which excludes should be considered due to where
  /// the analysis_options.yaml was defined.
  String get analysisRoot => _analysisRoot ??= _getAnalysisRoot();

  void _buildContextFeatureSet(AnalysisOptionsImpl analysisOptions) {
    var featureSet = FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: clOptions.enabledExperiments,
    );

    analysisOptions.contextFeatures = featureSet;

    if (clOptions.defaultLanguageVersion != null) {
      var nonPackageLanguageVersion = Version.parse(
        clOptions.defaultLanguageVersion + '.0',
      );
      analysisOptions.nonPackageLanguageVersion = nonPackageLanguageVersion;
      analysisOptions.nonPackageFeatureSet = FeatureSet.latestLanguageVersion()
          .restrictToVersion(nonPackageLanguageVersion);
    }
  }

  /// The actual calculation to get the [AnalysisOptionsImpl], with no caching.
  /// This should not be used except behind the getter which caches this result
  /// automatically.
  AnalysisOptionsImpl _getAnalysisOptions() {
    var contextOptions = builder.getAnalysisOptions(requestedSourceDirectory,
            verbosePrint: clOptions.verbose ? verbosePrint : null)
        as AnalysisOptionsImpl;

    _buildContextFeatureSet(contextOptions);
    contextOptions.hint = !clOptions.disableHints;
    return contextOptions;
  }

  /// The actual calculation to get the analysis root, with no caching. This
  /// should not be used except behind the getter which caches this result
  /// automatically.
  String _getAnalysisRoot() {
    // The analysis yaml defines the root, if it exists.
    var analysisOptionsPath = builder
        .getOptionsFile(requestedSourceDirectory, forceSearch: true)
        ?.path;

    if (analysisOptionsPath == null) {
      return requestedSourceDirectory;
    }

    return path.dirname(analysisOptionsPath);
  }
}
