// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final Set<String> _loadedLibraries = new Set<String>();

patch class DeferredLibrary {
  /* patch */ Future<bool> load() {
    // Dummy implementation that should eventually be replaced by real
    // implementation.
    Future future =
        new Future<bool>.value(!_loadedLibraries.contains(libraryName));
    _loadedLibraries.add(libraryName);
    return future;
  }
}
