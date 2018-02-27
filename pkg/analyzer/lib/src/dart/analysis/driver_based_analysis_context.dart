// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' hide AnalysisResult;
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptions;
import 'package:path/src/context.dart';

/**
 * An analysis context whose implementation is based on an analysis driver.
 */
class DriverBasedAnalysisContext implements AnalysisContext {
  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * The driver on which this context is based.
   */
  final AnalysisDriver driver;

  @override
  List<String> includedPaths;

  @override
  List<String> excludedPaths;

  /**
   * Initialize a newly created context that uses the given [resourceProvider]
   * to access the file system and that is based on the given analysis [driver].
   */
  DriverBasedAnalysisContext(this.resourceProvider, this.driver);

  @override
  AnalysisOptions get analysisOptions => driver.analysisOptions;

  @override
  AnalysisSession get currentSession => driver.currentSession;

  @override
  Iterable<String> analyzedFiles() sync* {
    for (String path in includedPaths) {
      if (!_isExcluded(path)) {
        Resource resource = resourceProvider.getResource(path);
        if (resource is File) {
          yield path;
        } else if (resource is Folder) {
          yield* _includedFilesInFolder(resource);
        } else {
          Type type = resource.runtimeType;
          throw new StateError('Unknown resource at path "$path" ($type)');
        }
      }
    }
  }

  @override
  bool isAnalyzed(String path) {
    return _isIncluded(path) && !_isExcluded(path);
  }

  /**
   * Return the absolute paths of all of the files that are included in the
   * given [folder].
   */
  Iterable<String> _includedFilesInFolder(Folder folder) sync* {
    for (Resource resource in folder.getChildren()) {
      String path = resource.path;
      if (!_isExcluded(path)) {
        if (resource is File) {
          yield path;
        } else if (resource is Folder) {
          yield* _includedFilesInFolder(resource);
        } else {
          Type type = resource.runtimeType;
          throw new StateError('Unknown resource at path "$path" ($type)');
        }
      }
    }
  }

  /**
   * Return `true` if the given [path] is either the same as or inside of one of
   * the [excludedPaths].
   */
  bool _isExcluded(String path) {
    Context context = resourceProvider.pathContext;
    String name = context.basename(path);
    if (name.startsWith('.') ||
        (name == 'packages' && resourceProvider.getResource(path) is Folder)) {
      return true;
    }
    for (String excludedPath in excludedPaths) {
      if (context.isAbsolute(excludedPath)) {
        if (context.isWithin(excludedPath, path)) {
          return true;
        }
      } else {
        // The documentation claims that [excludedPaths] only contains absolute
        // paths, so we shouldn't be able to reach this point.
        for (String includedPath in includedPaths) {
          if (context.isWithin(
              context.join(includedPath, excludedPath), path)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * Return `true` if the given [path] is either the same as or inside of one of
   * the [includedPaths].
   */
  bool _isIncluded(String path) {
    Context context = resourceProvider.pathContext;
    for (String includedPath in includedPaths) {
      if (context.isWithin(includedPath, path)) {
        return true;
      }
    }
    return false;
  }
}
