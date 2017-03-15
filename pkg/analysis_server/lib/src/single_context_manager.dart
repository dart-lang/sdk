// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.single_context_manager;

import 'dart:async';
import 'dart:core';
import 'dart:math' as math;

import 'package:analysis_server/src/context_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

/**
 * Implementation of [ContextManager] that supports only one [AnalysisContext].
 * So, sources from all analysis roots are added to this single context. All
 * features that could otherwise cause creating additional contexts, such as
 * presence of `pubspec.yaml` or `.packages` files, or analysis options files
 * are ignored.
 */
class SingleContextManager implements ContextManager {
  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * The context used to work with file system paths.
   */
  path.Context pathContext;

  /**
   * The manager used to access the SDK that should be associated with a
   * particular context.
   */
  final DartSdkManager sdkManager;

  /**
   * A function that will return a [UriResolver] that can be used to resolve
   * `package:` URIs.
   */
  final ResolverProvider packageResolverProvider;

  /**
   * A list of the globs used to determine which files should be analyzed.
   */
  final List<Glob> analyzedFilesGlobs;

  /**
   * The default options used to create new analysis contexts.
   */
  final AnalysisOptionsImpl defaultContextOptions;

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
   * The analysis driver which analyses everything.
   */
  AnalysisDriver analysisDriver;

  /**
   * The context in which everything is being analyzed.
   */
  AnalysisContext context;

  /**
   * The folder associated with the context.
   */
  Folder contextFolder;

  /**
   * The current watch subscriptions.
   */
  Map<String, StreamSubscription<WatchEvent>> watchSubscriptions =
      new Map<String, StreamSubscription<WatchEvent>>();

  /**
   * The [packageResolverProvider] must not be `null`.
   */
  SingleContextManager(
      this.resourceProvider,
      this.sdkManager,
      this.packageResolverProvider,
      this.analyzedFilesGlobs,
      this.defaultContextOptions) {
    pathContext = resourceProvider.pathContext;
  }

  @override
  Iterable<AnalysisContext> get analysisContexts =>
      context == null ? <AnalysisContext>[] : <AnalysisContext>[context];

  @override
  Map<Folder, AnalysisDriver> get driverMap => {contextFolder: analysisDriver};

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
  Folder getContextFolderFor(String path) {
    if (isInAnalysisRoot(path)) {
      return contextFolder;
    }
    return null;
  }

  @override
  AnalysisDriver getDriverFor(String path) {
    throw new UnimplementedError(
        'Unexpected invocation of getDriverFor in SingleContextManager');
  }

  @override
  List<AnalysisDriver> getDriversInAnalysisRoot(Folder analysisRoot) {
    throw new UnimplementedError(
        'Unexpected invocation of getDriversInAnalysisRoot in SingleContextManager');
  }

  @override
  bool isIgnored(String path) {
    return !_isContainedIn(includedPaths, path) || _isExcludedPath(path);
  }

  @override
  bool isInAnalysisRoot(String path) {
    return _isContainedIn(includedPaths, path) &&
        !_isContainedIn(excludedPaths, path);
  }

  @override
  void refresh(List<Resource> roots) {
    if (context != null) {
      callbacks.removeContext(contextFolder, null);
      context.dispose();
      context = null;
      contextFolder = null;
      _cancelCurrentWatchSubscriptions();
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
      }
    }
    // Start new watchers and cancel old ones.
    {
      Map<String, StreamSubscription<WatchEvent>> newSubscriptions =
          new Map<String, StreamSubscription<WatchEvent>>();
      for (String includedPath in includedPaths) {
        Resource resource = resourceProvider.getResource(includedPath);
        if (resource is Folder) {
          // Extract the existing subscription or create a new one.
          StreamSubscription<WatchEvent> subscription =
              watchSubscriptions.remove(includedPath);
          if (subscription == null) {
            subscription = resource.changes.listen(_handleWatchEvent);
          }
          // Remember the subscription.
          newSubscriptions[includedPath] = subscription;
        }
        _cancelCurrentWatchSubscriptions();
        this.watchSubscriptions = newSubscriptions;
      }
    }
    // Create or update the analysis context.
    if (context == null) {
      context = callbacks.addContext(contextFolder, defaultContextOptions);
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

  ChangeSet _buildChangeSet({List<File> added, List<File> removed}) {
    ChangeSet changeSet = new ChangeSet();
    if (added != null) {
      for (File file in added) {
        Source source = createSourceInContext(context, file);
        changeSet.addedSource(source);
      }
    }
    if (removed != null) {
      for (File file in removed) {
        Source source = createSourceInContext(context, file);
        changeSet.removedSource(source);
      }
    }
    return changeSet;
  }

  void _cancelCurrentWatchSubscriptions() {
    for (StreamSubscription<WatchEvent> subscription
        in watchSubscriptions.values) {
      subscription.cancel();
    }
    watchSubscriptions.clear();
  }

  String _commonPrefix(List<String> paths) {
    if (paths.isEmpty) {
      return '';
    }
    List<String> left = pathContext.split(paths[0]);
    int count = left.length;
    for (int i = 1; i < paths.length; i++) {
      List<String> right = pathContext.split(paths[i]);
      count = _commonComponents(left, count, right);
    }
    return pathContext.joinAll(left.sublist(0, count));
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

  void _handleWatchEvent(WatchEvent event) {
    String path = event.path;
    // Ignore if excluded.
    if (_isExcludedPath(path)) {
      return;
    }
    // Ignore if not in a root.
    if (!_isContainedIn(includedPaths, path)) {
      return;
    }
    // Handle the change.
    switch (event.type) {
      case ChangeType.ADD:
        Resource resource = resourceProvider.getResource(path);
        if (resource is File) {
          if (_matchesAnyAnalyzedFilesGlob(path)) {
            callbacks.applyChangesToContext(
                contextFolder, _buildChangeSet(added: <File>[resource]));
          }
        }
        break;
      case ChangeType.REMOVE:
        List<Source> sources = context.getSourcesWithFullName(path);
        if (!sources.isEmpty) {
          ChangeSet changeSet = new ChangeSet();
          sources.forEach(changeSet.removedSource);
          callbacks.applyChangesToContext(contextFolder, changeSet);
        }
        break;
      case ChangeType.MODIFY:
        List<Source> sources = context.getSourcesWithFullName(path);
        if (!sources.isEmpty) {
          ChangeSet changeSet = new ChangeSet();
          sources.forEach(changeSet.changedSource);
          callbacks.applyChangesToContext(contextFolder, changeSet);
        }
        break;
    }
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

  bool _isContainedIn(List<String> pathList, String path) {
    for (String pathInList in pathList) {
      if (_isEqualOrWithin(pathInList, path)) {
        return true;
      }
    }
    return false;
  }

  bool _isEqualOrWithin(String parent, String child) {
    return child == parent || pathContext.isWithin(parent, child);
  }

  bool _isEqualOrWithinAny(List<String> parents, String child) {
    for (String parent in parents) {
      if (_isEqualOrWithin(parent, child)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given [path] should be excluded, using explicit
   * or implicit rules.
   */
  bool _isExcludedPath(String path) {
    List<String> parts = resourceProvider.pathContext.split(path);
    // Implicit rules.
    for (String part in parts) {
      if (part.startsWith('.')) {
        return true;
      }
    }
    // Explicitly excluded paths.
    if (_isEqualOrWithinAny(excludedPaths, path)) {
      return true;
    }
    // OK
    return false;
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
  List<String> _nonOverlappingPaths(List<String> pathList) {
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

  /**
   * Create and return a source representing the given [file] within the given
   * [context].
   */
  static Source createSourceInContext(AnalysisContext context, File file) {
    // TODO(brianwilkerson) Optimize this, by allowing support for source
    // factories to restore URI's from a file path rather than a source.
    Source source = file.createSource();
    if (context == null) {
      return source;
    }
    Uri uri = context.sourceFactory.restoreUri(source);
    return file.createSource(uri);
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
}
