// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "async_patch.dart";

final Set<String> _loadedLibraries = new Set<String>();

@patch
class DeferredLibrary {
  @patch
  Future<Null> load() {
    // Dummy implementation that should eventually be replaced by real
    // implementation.
    Future future = new Future<Null>.value(null);
    _loadedLibraries.add(libraryName);
    return future;
  }
}
