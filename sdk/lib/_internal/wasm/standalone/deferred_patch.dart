// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final Set<int> _loaded = {};

// The standalone target doesn't support loading deferred libraries, dart2wasm
// emits an error when `--enable-deferred-loading` is enabled with this target.
// These methods are still referenced in the compiler, but we can simply make
// them do nothing.

Future<void> loadLibraryFromLoadId(int loadId) {
  _loaded.add(loadId);
  return Future.value();
}

bool checkLibraryIsLoadedFromLoadId(int loadId) {
  if (_loaded.contains(loadId)) {
    return true;
  }
  throw DeferredLoadIdNotLoadedError();
}

class DeferredLoadIdNotLoadedError extends Error implements NoSuchMethodError {
  DeferredLoadIdNotLoadedError();

  String toString() {
    return 'Deferred loading is not available with dart2wasm standalone';
  }
}
