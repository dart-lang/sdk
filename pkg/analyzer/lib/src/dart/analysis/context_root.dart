// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';

/// An implementation of a context root.
class ContextRootImpl implements ContextRoot {
  @override
  final ResourceProvider resourceProvider;

  @override
  final Folder root;

  @override
  final Workspace workspace;

  @override
  final List<Resource> included = [];

  @override
  final List<Resource> excluded = [];

  /// A list of the globs for excluded files that were read from the analysis
  /// options file.
  final List<LocatedGlob> excludedGlobs = [];

  @override
  final File? optionsFile;

  /// Maintains a mapping of folders to associated analysis options files.
  final Map<File, Set<Folder>> optionsFileMap = {};

  @override
  final File? packagesFile;

  /// Initialize a newly created context root.
  new(
    this.resourceProvider,
    this.root,
    this.workspace, {
    this.optionsFile,
    this.packagesFile,
  });

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
    return other is ContextRootImpl && root.path == other.root.path;
  }

  @override
  Iterable<String> analyzedFiles() sync* {
    var visited = <String>{};
    for (var includedPath in includedPaths) {
      var included = resourceProvider.getResource(includedPath);
      if (included is File) {
        yield includedPath;
      } else if (included is Folder) {
        yield* _includedFilesInFolder(visited, included, includedPath);
      } else {
        Type type = included.runtimeType;
        throw StateError('Unknown resource at path "$includedPath" ($type)');
      }
    }
  }

  @override
  bool isAnalyzed(String path) {
    for (var included in included) {
      if (included is File) {
        if (included.path == path) {
          return true;
        }
      } else if (included is Folder) {
        if (included.isOrContains(path)) {
          if (!_isExcluded(path, included.path)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Whether [path], or one of its ancestors under [root], has a name that
  /// starts with `.`, such as `.dart_tool`.
  bool _hasDotNameUnderRoot(String path) {
    var context = resourceProvider.pathContext;

    bool walkAncestors() {
      for (var current = path; root.contains(current);) {
        if (context.basename(current).startsWith('.')) {
          return true;
        }
        current = context.dirname(current);
      }
      return false;
    }

    // This runs for every file, so for the usual normalized [path] that starts
    // with the path of [root], the names after it are scanned once, instead
    // of parsing the whole path for every ancestor. Any other path, such as
    // one with a different case on Windows, or with `.` or `..` segments,
    // walks the ancestors.
    var separator = context.separator.codeUnitAt(0);
    bool isSeparator(int c) => c == separator || c == $SLASH;
    bool isNameEnd(int i) =>
        i == path.length || isSeparator(path.codeUnitAt(i));

    var rootPath = root.path;
    var start = rootPath.length;
    if (!isSeparator(rootPath.codeUnitAt(start - 1))) {
      start++;
    }
    if (path.length <= start ||
        !path.startsWith(rootPath) ||
        !isSeparator(path.codeUnitAt(start - 1))) {
      return walkAncestors();
    }

    var isNameStart = true;
    for (var i = start; i < path.length; i++) {
      var c = path.codeUnitAt(i);
      if (isSeparator(c)) {
        isNameStart = true;
        continue;
      }
      if (isNameStart && c == $PERIOD) {
        if (isNameEnd(i + 1) ||
            path.codeUnitAt(i + 1) == $PERIOD && isNameEnd(i + 2)) {
          return walkAncestors();
        }
        return true;
      }
      isNameStart = false;
    }
    return false;
  }

  /// Return the absolute paths of all of the files that are included in the
  /// given [folder]. Ignore globs that match the explicit [includedPath].
  Iterable<String> _includedFilesInFolder(
    Set<String> visited,
    Folder folder,
    String includedPath,
  ) sync* {
    List<Resource> children;
    try {
      children = folder.getChildren();
    } on FileSystemException {
      return;
    }

    for (Resource resource in children) {
      String path = resource.path;
      if (!_isExcluded(path, includedPath)) {
        if (resource is File) {
          yield path;
        } else if (resource is Folder) {
          String canonicalPath;
          try {
            canonicalPath = resource.resolveSymbolicLinksSync().path;
          } on FileSystemException {
            return;
          }
          if (visited.add(canonicalPath)) {
            yield* _includedFilesInFolder(visited, resource, includedPath);
            visited.remove(canonicalPath);
          }
        } else {
          Type type = resource.runtimeType;
          throw StateError('Unknown resource at path "$path" ($type)');
        }
      }
    }
  }

  /// Return `true` if the given [path] is not excluded by one of the
  /// [excludedPaths], or an applicable [excludedGlobs].
  ///
  /// This method is invoked while processing an explicitly [includedPath],
  /// and so we should ignore globs that would have excluded it.
  bool _isExcluded(String path, String includedPath) {
    if (_hasDotNameUnderRoot(path)) {
      return true;
    }

    Context context = resourceProvider.pathContext;
    for (String excludedPath in excludedPaths) {
      if (context.isAbsolute(excludedPath)) {
        if (path == excludedPath || context.isWithin(excludedPath, path)) {
          return true;
        }
      } else {
        // The documentation claims that [excludedPaths] only contains absolute
        // paths, so we shouldn't be able to reach this point.
        for (String includedPath in includedPaths) {
          if (context.isWithin(
            context.join(includedPath, excludedPath),
            path,
          )) {
            return true;
          }
        }
      }
    }

    for (var pattern in excludedGlobs) {
      if (!pattern.matches(includedPath) && pattern.matches(path)) {
        return true;
      }
    }

    return false;
  }
}

/// [Glob] to apply to resources inside the [parent].
class LocatedGlob {
  final Folder parent;
  final Glob glob;

  new(this.parent, this.glob);

  bool matches(String path) {
    var relativePath = parent.relativeIfContains(path);
    if (relativePath == null) return false;
    return glob.matches(relativePath);
  }
}
