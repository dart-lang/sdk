// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library context.directory.manager;

import 'package:analysis_server/src/resource.dart';

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
      addContext(folder);
    }
    currentFolders = new Set<Folder>.from(includedFolders);
  }

  /**
   * Called when a new context needs to be created.
   */
  void addContext(Folder folder);
}