// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library context.directory.manager;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/package_map_provider.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as pathos;
import 'package:watcher/watcher.dart';


/**
 * File name of pubspec files.
 */
const String PUBSPEC_NAME = 'pubspec.yaml';


/**
 * Class that maintains a mapping from included/excluded paths to a set of
 * folders that should correspond to analysis contexts.
 */
abstract class ContextManager {
  /**
   * [_ContextInfo] object for each included directory in the most
   * recent successful call to [setRoots].
   */
  Map<Folder, _ContextInfo> _contexts = new HashMap<Folder, _ContextInfo>();

  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * The context used to work with file system paths.
   */
  pathos.Context pathContext;

  /**
   * Provider which is used to determine the mapping from package name to
   * package folder.
   */
  final PackageMapProvider packageMapProvider;

  ContextManager(this.resourceProvider, this.packageMapProvider) {
    pathContext = resourceProvider.pathContext;
  }

  /**
   * Called when a new context needs to be created.
   */
  void addContext(Folder folder, Map<String, List<Folder>> packageMap);

  /**
   * Called when the set of files associated with a context have changed (or
   * some of those files have been modified).  [changeSet] is the set of
   * changes that need to be applied to the context.
   */
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet);

  /**
   * Returns `true` if the given absolute [path] is in one of the current
   * root folders and is not excluded.
   */
  bool isInAnalysisRoot(String path) {
    // TODO(scheglov) check for excluded paths
    for (Folder root in _contexts.keys) {
      if (root.contains(path)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Remove the context associated with the given [folder].
   */
  void removeContext(Folder folder);

  /**
   * Change the set of paths which should be used as starting points to
   * determine the context directories.
   */
  void setRoots(List<String> includedPaths, List<String> excludedPaths) {
    // included
    Set<Folder> includedFolders = new HashSet<Folder>();
    for (int i = 0; i < includedPaths.length; i++) {
      String path = includedPaths[i];
      Resource resource = resourceProvider.getResource(path);
      if (resource is Folder) {
        includedFolders.add(resource);
      } else {
        // TODO(scheglov) implemented separate files analysis
        throw new UnimplementedError(
            '$path is not a folder. '
                'Only support for folder analysis is implemented currently.');
      }
    }
    // excluded
    // TODO(scheglov) remove when implemented
    if (excludedPaths.isNotEmpty) {
      throw new UnimplementedError('Excluded paths are not supported yet');
    }
    Set<Folder> excludedFolders = new HashSet<Folder>();
    // diff
    Set<Folder> currentFolders = _contexts.keys.toSet();
    Set<Folder> newFolders = new HashSet<Folder>();
    Set<Folder> oldFolders = new HashSet<Folder>();
    for (Folder currentFolder in currentFolders) {
      bool isIncluded = includedFolders.any((folder) {
        return folder.contains(currentFolder.path);
      });
      if (!isIncluded) {
        oldFolders.add(currentFolder);
      }
    }
    for (Folder includedFolder in includedFolders) {
      bool wasIncluded = currentFolders.any((folder) {
        return folder.contains(includedFolder.path);
      });
      if (!wasIncluded) {
        newFolders.add(includedFolder);
      }
    }
    // destroy old contexts
    for (Folder folder in oldFolders) {
      _destroyContext(folder);
    }
    // create new contexts
    for (Folder folder in newFolders) {
      _createContexts(folder, false);
    }
  }

  /**
   * Called when the package map for a context has changed.
   */
  void updateContextPackageMap(Folder contextFolder, Map<String,
      List<Folder>> packageMap);

  /**
   * Create a new empty context associated with [folder].
   */
  _ContextInfo _createContext(Folder folder, List<_ContextInfo> children) {
    _ContextInfo info = new _ContextInfo(folder, children);
    _contexts[folder] = info;
    info.changeSubscription = folder.changes.listen((WatchEvent event) {
      _handleWatchEvent(folder, info, event);
    });
    PackageMapInfo packageMapInfo =
        packageMapProvider.computePackageMap(folder);
    info.packageMapDependencies = packageMapInfo.dependencies;
    // TODO(paulberry): if any of the dependencies is outside of [folder],
    // we'll need to watch their parent folders as well.
    addContext(folder, packageMapInfo.packageMap);
    return info;
  }

  /**
   * Create a new context associated with [folder] and fills its with sources.
   */
  _ContextInfo _createContextWithSources(Folder folder,
      List<_ContextInfo> children) {
    _ContextInfo info = _createContext(folder, children);
    ChangeSet changeSet = new ChangeSet();
    _addSourceFiles(changeSet, folder, info);
    applyChangesToContext(folder, changeSet);
    return info;
  }

  /**
   * Creates a new context associated with [folder].
   *
   * If there are subfolders with 'pubspec.yaml' files, separate contexts
   * are created for them, and excluded from the context associated with
   * [folder].
   *
   * If [folder] itself contains a 'pubspec.yaml' file, subfolders are ignored.
   *
   * Returns create pubspec-based contexts.
   */
  List<_ContextInfo> _createContexts(Folder folder, bool withPubspecOnly) {
    // check if there is a pubspec in the folder
    {
      File pubspecFile = folder.getChild(PUBSPEC_NAME);
      if (pubspecFile.exists) {
        _ContextInfo info = _createContextWithSources(folder, <_ContextInfo>[]);
        return [info];
      }
    }
    // try to find subfolders with pubspec files
    List<_ContextInfo> children = <_ContextInfo>[];
    for (Resource child in folder.getChildren()) {
      if (child is Folder) {
        List<_ContextInfo> childContexts = _createContexts(child, true);
        children.addAll(childContexts);
      }
    }
    // no pubspec, done
    if (withPubspecOnly) {
      return children;
    }
    // OK, create a context without a pubspec
    _createContextWithSources(folder, children);
    return children;
  }

  /**
   * Clean up and destroy the context associated with the given folder.
   */
  void _destroyContext(Folder folder) {
    _contexts[folder].changeSubscription.cancel();
    _contexts.remove(folder);
    removeContext(folder);
  }

  /**
   * Extract a new [pubspecFile]-based context from [oldInfo].
   */
  void _extractContext(_ContextInfo oldInfo, File pubspecFile) {
    Folder newFolder = pubspecFile.parent;
    _ContextInfo newInfo = _createContext(newFolder, []);
    newInfo.parent = oldInfo;
    // prepare sources to extract
    Map<String, Source> extractSources = new HashMap<String, Source>();
    oldInfo.sources.forEach((path, source) {
      if (newFolder.contains(path)) {
        extractSources[path] = source;
      }
    });
    // update new context
    {
      ChangeSet changeSet = new ChangeSet();
      extractSources.forEach((path, source) {
        newInfo.sources[path] = source;
        changeSet.addedSource(source);
      });
      applyChangesToContext(newFolder, changeSet);
    }
    // update old context
    {
      ChangeSet changeSet = new ChangeSet();
      extractSources.forEach((path, source) {
        oldInfo.sources.remove(path);
        changeSet.removedSource(source);
      });
      applyChangesToContext(oldInfo.folder, changeSet);
    }
  }

  void _handleWatchEvent(Folder folder, _ContextInfo info, WatchEvent event) {
    String path = event.path;
    // maybe excluded, so other context will handle it
    if (info.excludes(path)) {
      return;
    }
    // handle the change
    switch (event.type) {
      case ChangeType.ADD:
        if (_isInPackagesDir(path, folder)) {
          // TODO(paulberry): perhaps we should only skip packages dirs if
          // there is a pubspec.yaml?
          break;
        }
        Resource resource = resourceProvider.getResource(path);
        // pubspec was added, extract a new context
        if (_isPubspec(path)) {
          _extractContext(info, resource);
          return;
        }
        // If the file went away and was replaced by a folder before we
        // had a chance to process the event, resource might be a Folder.  In
        // that case don't add it.
        if (resource is File) {
          File file = resource;
          if (_shouldFileBeAnalyzed(file)) {
            ChangeSet changeSet = new ChangeSet();
            Source source = file.createSource();
            changeSet.addedSource(source);
            applyChangesToContext(folder, changeSet);
            info.sources[path] = source;
          }
        }
        break;
      case ChangeType.REMOVE:
        // pubspec was removed, merge the context into its parent
        if (info.isPubspec(path)) {
          _mergeContext(info);
          return;
        }
        Source source = info.sources[path];
        if (source != null) {
          ChangeSet changeSet = new ChangeSet();
          changeSet.removedSource(source);
          applyChangesToContext(folder, changeSet);
          info.sources.remove(path);
        }
        break;
      case ChangeType.MODIFY:
        Source source = info.sources[path];
        if (source != null) {
          ChangeSet changeSet = new ChangeSet();
          changeSet.changedSource(source);
          applyChangesToContext(folder, changeSet);
        }
        break;
    }

    if (info.packageMapDependencies.contains(path)) {
      // TODO(paulberry): when computePackageMap is changed into an
      // asynchronous API call, we'll want to suspend analysis for this context
      // while we're rerunning "pub list", since any analysis we complete while
      // "pub list" is in progress is just going to get thrown away anyhow.
      PackageMapInfo packageMapInfo =
          packageMapProvider.computePackageMap(folder);
      info.packageMapDependencies = packageMapInfo.dependencies;
      updateContextPackageMap(folder, packageMapInfo.packageMap);
    }
  }

  /**
   * Determine if the path from [folder] to [path] contains a 'packages'
   * directory.
   */
  bool _isInPackagesDir(String path, Folder folder) {
    String relativePath = pathContext.relative(path, from: folder.path);
    List<String> pathParts = pathContext.split(relativePath);
    for (int i = 0; i < pathParts.length - 1; i++) {
      if (pathParts[i] == 'packages') {
        return true;
      }
    }
    return false;
  }

  /**
   * Returns `true` if the given absolute [path] is a pubspec file.
   */
  bool _isPubspec(String path) {
    return pathContext.basename(path) == PUBSPEC_NAME;
  }

  /**
   * Merges [info] context into its parent.
   */
  void _mergeContext(_ContextInfo info) {
    // destroy the context
    _destroyContext(info.folder);
    // add files to the parent context
    _ContextInfo parentInfo = info.parent;
    if (parentInfo != null) {
      parentInfo.children.remove(info);
      ChangeSet changeSet = new ChangeSet();
      _addSourceFiles(changeSet, info.folder, parentInfo);
      applyChangesToContext(parentInfo.folder, changeSet);
    }
  }

  /**
   * Resursively adds all Dart and HTML files to the [changeSet].
   */
  static void _addSourceFiles(ChangeSet changeSet, Folder folder,
      _ContextInfo info) {
    if (info.excludesResource(folder)) {
      return;
    }
    List<Resource> children = folder.getChildren();
    for (Resource child in children) {
      if (child is File) {
        if (_shouldFileBeAnalyzed(child)) {
          Source source = child.createSource();
          changeSet.addedSource(source);
          info.sources[child.path] = source;
        }
      } else if (child is Folder) {
        if (child.shortName == 'packages') {
          // TODO(paulberry): perhaps we should only skip packages dirs if
          // there is a pubspec.yaml?
          continue;
        }
        _addSourceFiles(changeSet, child, info);
      }
    }
  }

  static bool _shouldFileBeAnalyzed(File file) {
    if (!(AnalysisEngine.isDartFileName(file.path) ||
        AnalysisEngine.isHtmlFileName(file.path))) {
      return false;
    }
    // Emacs creates dummy links to track the fact that a file is open for
    // editing and has unsaved changes (e.g. having unsaved changes to
    // 'foo.dart' causes a link '.#foo.dart' to be created, which points to the
    // non-existent file 'username@hostname.pid'.  To avoid these dummy links
    // causing the analyzer to thrash, just ignore links to non-existent files.
    return file.exists;
  }
}

/**
 * Information tracked by the [ContextManager] for each context.
 */
class _ContextInfo {
  /**
   * The [Folder] for which this information object is created.
   */
  final Folder folder;

  /**
   * The enclosed pubspec-based contexts.
   */
  final List<_ContextInfo> children;

  /**
   * The [_ContextInfo] that encloses this one.
   */
  _ContextInfo parent;

  /**
   * The `pubspec.yaml` file path for this context.
   */
  String pubspecPath;

  /**
   * Stream subscription we are using to watch the context's directory for
   * changes.
   */
  StreamSubscription<WatchEvent> changeSubscription;

  /**
   * Map from full path to the [Source] object, for each source that has been
   * added to the context.
   */
  Map<String, Source> sources = new HashMap<String, Source>();

  /**
   * Dependencies of the context's package map.
   * If any of these files changes, the package map needs to be recomputed.
   */
  Set<String> packageMapDependencies;

  _ContextInfo(this.folder, this.children) {
    pubspecPath = folder.getChild(PUBSPEC_NAME).path;
    for (_ContextInfo child in children) {
      child.parent = this;
    }
  }

  /**
   * Returns `true` if [path] is excluded, as it is in one of the children.
   */
  bool excludes(String path) {
    return children.any((child) {
      return child.folder.contains(path);
    });
  }

  /**
   * Returns `true` if [resource] is excldued, as it is in one of the children.
   */
  bool excludesResource(Resource resource) {
    return excludes(resource.path);
  }

  /**
   * Returns `true` if [path] is the pubspec file of this context.
   */
  bool isPubspec(String path) {
    return path == pubspecPath;
  }
}
