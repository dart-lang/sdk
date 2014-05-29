// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library context.directory.manager;

import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Class that maintains a mapping from included/excluded paths to a set of
 * folders that should correspond to analysis contexts.
 */
abstract class ContextDirectoryManager {
  /**
   * The set of included folders in the most recent successful call to
   * [setRoots].
   */
  Set<Folder> currentFolders = new Set<Folder>();

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
    Set<Folder> includedFolders = new Set<Folder>();
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
    Set<Folder> excludedFolders = new Set<Folder>();
    // diff
    Set<Folder> newFolders = includedFolders.difference(currentFolders);
    Set<Folder> oldFolders = currentFolders.difference(includedFolders);
    // remove old contexts
    for (Folder folder in oldFolders) {
      // TODO(scheglov) implement
    }
    // add new contexts
    for (Folder folder in newFolders) {
      File pubspecFile = folder.getChild('pubspec.yaml');
      addContext(folder, pubspecFile.exists ? pubspecFile : null);
      ChangeSet changeSet = new ChangeSet();
      _addSourceFiles(changeSet, folder);
      applyChangesToContext(folder, changeSet);
    }
    currentFolders = new Set<Folder>.from(includedFolders);
  }

  /**
   * Resursively adds all Dart and HTML files to the [changeSet].
   */
  static void _addSourceFiles(ChangeSet changeSet, Folder folder) {
    List<Resource> children = folder.getChildren();
    for (Resource child in children) {
      if (child is File) {
        String fileName = child.shortName;
        if (AnalysisEngine.isDartFileName(fileName)
            || AnalysisEngine.isHtmlFileName(fileName)) {
          Source source = child.createSource(UriKind.FILE_URI);
          changeSet.addedSource(source);
        }
      } else if (child is Folder) {
        _addSourceFiles(changeSet, child);
      }
    }
  }

  /**
   * Called when a new context needs to be created.  If the context is
   * associated with a pubspec file, that file is passed in [pubspecFile];
   * otherwise it is null.
   */
  void addContext(Folder folder, File pubspecFile);

  /**
   * Called when the set of files associated with a context have changed (or
   * some of those files have been modified).  [changeSet] is the set of
   * changes that need to be applied to the context.
   */
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet);
}