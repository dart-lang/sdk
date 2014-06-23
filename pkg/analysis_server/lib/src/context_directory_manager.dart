// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library context.directory.manager;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:watcher/watcher.dart';

/**
 * Information tracked by the [ContextDirectoryManager] for each context.
 */
class _ContextDirectoryInfo {
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
}

/**
 * Class that maintains a mapping from included/excluded paths to a set of
 * folders that should correspond to analysis contexts.
 */
abstract class ContextDirectoryManager {
  /**
   * File name of pubspec files.
   */
  static const String PUBSPEC_NAME = 'pubspec.yaml';

  /**
   * [_ContextDirectoryInfo] object for each included directory in the most
   * recent successful call to [setRoots].
   */
  Map<Folder, _ContextDirectoryInfo> _currentDirectoryInfo =
      new HashMap<Folder, _ContextDirectoryInfo>();

  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  ContextDirectoryManager(this.resourceProvider);

  /**
   * Change the set of paths which should be used as starting points to
   * determine the context directories.
   */
  void setRoots(List<String> includedPaths,
                List<String> excludedPaths) {
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
      throw new UnimplementedError(
          'Excluded paths are not supported yet');
    }
    Set<Folder> excludedFolders = new HashSet<Folder>();
    // diff
    Set<Folder> currentFolders = _currentDirectoryInfo.keys.toSet();
    Set<Folder> newFolders = includedFolders.difference(currentFolders);
    Set<Folder> oldFolders = currentFolders.difference(includedFolders);
    // destroy old contexts
    for (Folder folder in oldFolders) {
      _destroyContext(folder);
    }
    // create new contexts
    for (Folder folder in newFolders) {
      _createContext(folder);
    }
  }

  /**
   * Create a new context associated with the given folder.
   */
  void _createContext(Folder folder) {
    _ContextDirectoryInfo info = new _ContextDirectoryInfo();
    _currentDirectoryInfo[folder] = info;
    info.changeSubscription = folder.changes.listen((WatchEvent event) {
      _handleWatchEvent(folder, info, event);
    });
    File pubspecFile = folder.getChild(PUBSPEC_NAME);
    addContext(folder);
    ChangeSet changeSet = new ChangeSet();
    _addSourceFiles(changeSet, folder, info);
    applyChangesToContext(folder, changeSet);
  }

  /**
   * Clean up and destroy the context associated with the given folder.
   */
  void _destroyContext(Folder folder) {
    _currentDirectoryInfo[folder].changeSubscription.cancel();
    _currentDirectoryInfo.remove(folder);
    removeContext(folder);
  }

  void _handleWatchEvent(Folder folder, _ContextDirectoryInfo info, WatchEvent event) {
    switch (event.type) {
      case ChangeType.ADD:
        if (_isInPackagesDir(event.path, folder)) {
          // TODO(paulberry): perhaps we should only skip packages dirs if
          // there is a pubspec.yaml?
          break;
        }
        if (_shouldFileBeAnalyzed(event.path)) {
          ChangeSet changeSet = new ChangeSet();
          Resource resource = resourceProvider.getResource(event.path);
          // If the file went away and was replaced by a folder before we
          // had a chance to process the event, resource might be a Folder.  In
          // that case don't add it.
          if (resource is File) {
            File file = resource;
            Source source = file.createSource(UriKind.FILE_URI);
            changeSet.addedSource(source);
            applyChangesToContext(folder, changeSet);
            info.sources[event.path]= source;
          }
        }
        break;
      case ChangeType.REMOVE:
        Source source = info.sources[event.path];
        if (source != null) {
          ChangeSet changeSet = new ChangeSet();
          changeSet.removedSource(source);
          applyChangesToContext(folder, changeSet);
          info.sources.remove(event.path);
        }
        break;
      case ChangeType.MODIFY:
        Source source = info.sources[event.path];
        if (source != null) {
          ChangeSet changeSet = new ChangeSet();
          changeSet.changedSource(source);
          applyChangesToContext(folder, changeSet);
        }
        break;
    }
  }

  /**
   * Determine if the path from [folder] to [path] contains a 'packages'
   * directory.
   */
  bool _isInPackagesDir(String path, Folder folder) {
    String relativePath = resourceProvider.pathContext.relative(path, from: folder.path);
    List<String> pathParts = resourceProvider.pathContext.split(relativePath);
    for (int i = 0; i < pathParts.length - 1; i++) {
      if (pathParts[i] == 'packages') {
        return true;
      }
    }
    return false;
  }

  /**
   * Resursively adds all Dart and HTML files to the [changeSet].
   */
  static void _addSourceFiles(ChangeSet changeSet, Folder folder, _ContextDirectoryInfo info) {
    List<Resource> children = folder.getChildren();
    for (Resource child in children) {
      if (child is File) {
        if (_shouldFileBeAnalyzed(child.path)) {
          Source source = child.createSource(UriKind.FILE_URI);
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

  static bool _shouldFileBeAnalyzed(String path) {
    return AnalysisEngine.isDartFileName(path)
            || AnalysisEngine.isHtmlFileName(path);
  }

  /**
   * Called when a new context needs to be created.
   */
  void addContext(Folder folder);

  /**
   * Called when the set of files associated with a context have changed (or
   * some of those files have been modified).  [changeSet] is the set of
   * changes that need to be applied to the context.
   */
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet);

  /**
   * Remove the context associated with the given [folder].
   */
  void removeContext(Folder folder);
}
