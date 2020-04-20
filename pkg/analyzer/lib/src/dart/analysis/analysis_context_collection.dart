// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:meta/meta.dart';

/// An implementation of [AnalysisContextCollection].
class AnalysisContextCollectionImpl implements AnalysisContextCollection {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The list of analysis contexts.
  @override
  final List<AnalysisContext> contexts = [];

  /// Initialize a newly created analysis context manager.
  AnalysisContextCollectionImpl(
      {bool enableIndex = false,
      @required List<String> includedPaths,
      List<String> excludedPaths,
      ResourceProvider resourceProvider,
      String sdkPath})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE {
    _throwIfAnyNotAbsoluteNormalizedPath(includedPaths);
    if (sdkPath != null) {
      _throwIfNotAbsoluteNormalizedPath(sdkPath);
    }

    var contextLocator = ContextLocator(
      resourceProvider: this.resourceProvider,
    );
    var roots = contextLocator.locateRoots(
      includedPaths: includedPaths,
      excludedPaths: excludedPaths,
    );
    for (var root in roots) {
      var contextBuilder = ContextBuilderImpl(
        resourceProvider: this.resourceProvider,
      );
      var context = contextBuilder.createContext(
        contextRoot: root,
        enableIndex: enableIndex,
        sdkPath: sdkPath,
      );
      contexts.add(context);
    }
  }

  @override
  AnalysisContext contextFor(String path) {
    _throwIfNotAbsoluteNormalizedPath(path);

    for (var context in contexts) {
      if (context.contextRoot.isAnalyzed(path)) {
        return context;
      }
    }

    throw StateError('Unable to find the context to $path');
  }

  /// Check every element with [_throwIfNotAbsoluteNormalizedPath].
  void _throwIfAnyNotAbsoluteNormalizedPath(List<String> paths) {
    for (var path in paths) {
      _throwIfNotAbsoluteNormalizedPath(path);
    }
  }

  /// The driver supports only absolute normalized paths, this method is used
  /// to validate any input paths to prevent errors later.
  void _throwIfNotAbsoluteNormalizedPath(String path) {
    var pathContext = resourceProvider.pathContext;
    if (!pathContext.isAbsolute(path) || pathContext.normalize(path) != path) {
      throw ArgumentError(
          'Only absolute normalized paths are supported: $path');
    }
  }
}
