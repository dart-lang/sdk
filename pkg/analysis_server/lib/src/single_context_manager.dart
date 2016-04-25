// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.single_context_manager;

import 'dart:core' hide Resource;
import 'dart:math' as math;

import 'package:analysis_server/src/context_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/path_filter.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:path/path.dart' as path;

/**
 * A function that will return a [UriResolver] that can be used to resolve
 * `package:` URIs in [SingleContextManager].
 */
typedef UriResolver PackageResolverProvider();

/**
 * Implementation of [ContextManager] that supports only one [AnalysisContext].
 * So, sources from all analysis roots are added to this single context. All
 * features that could otherwise cause creating additional contexts, such as
 * presence of `pubspec.yaml` or `.packages` files, or `.analysis_options` files
 * are ignored.
 */
class SingleContextManager implements ContextManager {
  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * The manager used to access the SDK that should be associated with a
   * particular context.
   */
  final DartSdkManager sdkManager;

  /**
   * A function that will return a [UriResolver] that can be used to resolve
   * `package:` URIs.
   */
  final PackageResolverProvider packageResolverProvider;

  /**
   * A list of the globs used to determine which files should be analyzed.
   */
  final List<Glob> analyzedFilesGlobs;

  /**
   * The list of included paths (folders and files) most recently passed to
   * [setRoots].
   */
  List<String> includedPaths = <String>[];

  /**
   * The list of excluded paths (folders and files) most recently passed to
   * [setRoots].
   */
  List<String> excludedPaths = <String>[];

  /**
   * The map of package roots most recently passed to [setRoots].
   */
  Map<String, String> packageRoots = <String, String>{};

  /**
   * Same as [packageRoots], except that source folders have been normalized
   * and non-folders have been removed.
   */
  Map<String, String> normalizedPackageRoots = <String, String>{};

  @override
  ContextManagerCallbacks callbacks;

  /**
   * The context in which everything is being analyzed.
   */
  AnalysisContext context;

  /**
   * The folder associated with the context.
   */
  Folder contextFolder;

  /**
   * The [PathFilter] used to filter sources from being analyzed.
   */
  PathFilter pathFilter;

  /**
   * The [packageResolverProvider] must not be `null`.
   */
  SingleContextManager(this.resourceProvider, this.sdkManager,
      this.packageResolverProvider, this.analyzedFilesGlobs);

  @override
  Iterable<AnalysisContext> get analysisContexts =>
      context == null ? <AnalysisContext>[] : <AnalysisContext>[context];

  @override
  Map<Folder, AnalysisContext> get folderMap => {contextFolder: context};

  @override
  List<AnalysisContext> contextsInAnalysisRoot(Folder analysisRoot) {
    if (context == null || !includedPaths.contains(analysisRoot.path)) {
      return <AnalysisContext>[];
    }
    return <AnalysisContext>[context];
  }

  @override
  AnalysisContext getContextFor(String path) {
    if (context == null) {
      return null;
    } else if (_isContainedIn(includedPaths, path)) {
      return context;
    }
    return null;
  }

  @override
  bool isIgnored(String path) => pathFilter.ignored(path);

  @override
  bool isInAnalysisRoot(String path) {
    return _isContainedIn(includedPaths, path) &&
        !_isContainedIn(excludedPaths, path);
  }

  @override
  void refresh(List<Resource> roots) {
    if (context != null) {
      // TODO(brianwilkerson) Not sure whether this is right.
      callbacks.removeContext(contextFolder, null);
      context.dispose();
      context = null;
      contextFolder = null;
      pathFilter = null;
      setRoots(includedPaths, excludedPaths, packageRoots);
    }
  }

  @override
  void setRoots(List<String> includedPaths, List<String> excludedPaths,
      Map<String, String> packageRoots) {
    includedPaths = _nonOverlappingPaths(includedPaths);
    excludedPaths = _nonOverlappingPaths(excludedPaths);
    this.packageRoots = packageRoots;
    _updateNormalizedPackageRoots();
    // Update context path.
    {
      String contextPath = _commonPrefix(includedPaths);
      Folder contextFolder = resourceProvider.getFolder(contextPath);
      if (contextFolder != this.contextFolder) {
        if (context != null) {
          callbacks.moveContext(this.contextFolder, contextFolder);
        }
        this.contextFolder = contextFolder;
        // TODO(scheglov) watch for changes in `contextFolder`
      }
    }
    if (context == null) {
      UriResolver packageResolver = packageResolverProvider();
      context = callbacks.addContext(contextFolder, new AnalysisOptionsImpl(),
          new CustomPackageResolverDisposition(packageResolver));
      ChangeSet changeSet =
          _buildChangeSet(added: _includedFiles(includedPaths, excludedPaths));
      callbacks.applyChangesToContext(contextFolder, changeSet);
    } else {
      // TODO(brianwilkerson) Optimize this.
      List<File> oldFiles =
          _includedFiles(this.includedPaths, this.excludedPaths);
      List<File> newFiles = _includedFiles(includedPaths, excludedPaths);
      ChangeSet changeSet = _buildChangeSet(
          added: _diff(newFiles, oldFiles), removed: _diff(oldFiles, newFiles));
      callbacks.applyChangesToContext(contextFolder, changeSet);
    }
    this.includedPaths = includedPaths;
    this.excludedPaths = excludedPaths;
  }

  /**
   * Recursively add the given [resource] (if it's a file) or its children (if
   * it's a folder) to the [addedFiles].
   */
  void _addFilesInResource(
      List<File> addedFiles, Resource resource, List<String> excludedPaths) {
    if (_isImplicitlyExcludedResource(resource)) {
      return;
    }
    String path = resource.path;
    if (_isEqualOrWithinAny(excludedPaths, path)) {
      return;
    }
    if (resource is File) {
      if (_matchesAnyAnalyzedFilesGlob(path) && resource.exists) {
        addedFiles.add(resource);
      }
    } else if (resource is Folder) {
      for (Resource child in _getChildrenSafe(resource)) {
        _addFilesInResource(addedFiles, child, excludedPaths);
      }
    }
  }

  List<Resource> _existingResources(List<String> pathList) {
    List<Resource> resources = <Resource>[];
    for (String path in pathList) {
      Resource resource = resourceProvider.getResource(path);
      if (resource is Folder) {
        resources.add(resource);
      } else if (!resource.exists) {
        // Non-existent resources are ignored.  TODO(paulberry): we should set
        // up a watcher to ensure that if the resource appears later, we will
        // begin analyzing it.
      } else if (resource is File) {
        resources.add(resource);
      } else {
        throw new UnimplementedError('$path is not a folder. '
            'Only support for file and folder analysis is implemented.');
      }
    }
    return resources;
  }

  List<File> _includedFiles(
      List<String> includedPaths, List<String> excludedPaths) {
    List<Resource> includedResources = _existingResources(includedPaths);
    List<File> includedFiles = <File>[];
    for (Resource resource in includedResources) {
      _addFilesInResource(includedFiles, resource, excludedPaths);
    }
    return includedFiles;
  }

  /**
   * Return `true` if the given [resource] and children should be excluded
   * because of some implicit exclusion rules, e.g. `.name`.
   */
  bool _isImplicitlyExcludedResource(Resource resource) {
    String shortName = resource.shortName;
    if (shortName.startsWith('.')) {
      return true;
    }
    return false;
  }

  /**
   * Return `true` if the given [path] matches one of the [analyzedFilesGlobs].
   */
  bool _matchesAnyAnalyzedFilesGlob(String path) {
    for (Glob glob in analyzedFilesGlobs) {
      if (glob.matches(path)) {
        return true;
      }
    }
    return false;
  }

  /**
   *  Normalize all package root sources by mapping them to folders on the
   * filesystem.  Ignore any package root sources that aren't folders.
   */
  void _updateNormalizedPackageRoots() {
    normalizedPackageRoots = <String, String>{};
    packageRoots.forEach((String sourcePath, String targetPath) {
      Resource resource = resourceProvider.getResource(sourcePath);
      if (resource is Folder) {
        normalizedPackageRoots[resource.path] = targetPath;
      }
    });
  }

  static ChangeSet _buildChangeSet({List<File> added, List<File> removed}) {
    ChangeSet changeSet = new ChangeSet();
    if (added != null) {
      for (File file in added) {
        changeSet.addedSource(file.createSource());
      }
    }
    if (removed != null) {
      for (File file in removed) {
        changeSet.removedSource(file.createSource());
      }
    }
    return changeSet;
  }

  static int _commonComponents(
      List<String> left, int count, List<String> right) {
    int max = math.min(count, right.length);
    for (int i = 0; i < max; i++) {
      if (left[i] != right[i]) {
        return i;
      }
    }
    return max;
  }

  static String _commonPrefix(List<String> paths) {
    if (paths.isEmpty) {
      return '';
    }
    List<String> left = path.split(paths[0]);
    int count = left.length;
    for (int i = 1; i < paths.length; i++) {
      List<String> right = path.split(paths[i]);
      count = _commonComponents(left, count, right);
    }
    return path.joinAll(left.sublist(0, count));
  }

  /**
   * Return a list of all the files in the [left] that are not in the [right].
   */
  static List<File> _diff(List<File> left, List<File> right) {
    List<File> diff = new List.from(left);
    for (File file in right) {
      diff.remove(file);
    }
    return diff;
  }

  static List<Resource> _getChildrenSafe(Folder folder) {
    try {
      return folder.getChildren();
    } on FileSystemException {
      // The folder either doesn't exist or cannot be read.
      // Either way, there are no children.
      return const <Resource>[];
    }
  }

  static bool _isContainedIn(List<String> pathList, String path) {
    for (String pathInList in pathList) {
      if (_isEqualOrWithin(path, pathInList)) {
        return true;
      }
    }
    return false;
  }

  static bool _isEqualOrWithin(String parent, String child) {
    return child == parent || path.isWithin(parent, child);
  }

  static bool _isEqualOrWithinAny(List<String> parents, String child) {
    for (String parent in parents) {
      if (_isEqualOrWithin(parent, child)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return a list consisting of the elements from [pathList] that describe the
   * minimal set of directories that include everything in the original list of
   * paths and nothing more. In particular:
   *
   *  * if a path is in the input list multiple times it will appear at most
   *    once in the output list, and
   *  * if a directory D and a subdirectory of it are both in the input list
   *    then only the directory D will be in the output list.
   *
   * The original list is not modified.
   */
  static List<String> _nonOverlappingPaths(List<String> pathList) {
    List<String> sortedPaths = new List<String>.from(pathList);
    sortedPaths.sort((a, b) => a.length - b.length);
    int pathCount = sortedPaths.length;
    for (int i = pathCount - 1; i > 0; i--) {
      String path = sortedPaths[i];
      for (int j = 0; j < i; j++) {
        if (_isEqualOrWithin(path, sortedPaths[j])) {
          sortedPaths.removeAt(i);
          break;
        }
      }
    }
    return sortedPaths;
  }
}
