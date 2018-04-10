// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart';

/**
 * An implementation of a context root.
 */
class ContextRootImpl implements ContextRoot {
  @override
  final ResourceProvider resourceProvider;

  @override
  final Folder root;

  @override
  final List<Resource> included = <Resource>[];

  @override
  final List<Resource> excluded = <Resource>[];

  @override
  File optionsFile;

  @override
  File packagesFile;

  /**
   * Initialize a newly created context root.
   */
  ContextRootImpl(this.resourceProvider, this.root);

  @override
  Iterable<String> get excludedPaths =>
      excluded.map((Resource folder) => folder.path);

  @override
  int get hashCode => root.path.hashCode;

  @override
  Iterable<String> get includedPaths =>
      included.map((Resource folder) => folder.path);

  @override
  bool operator ==(Object other) {
    return other is ContextRoot && root.path == other.root.path;
  }

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
    if (name.startsWith('.')) {
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
