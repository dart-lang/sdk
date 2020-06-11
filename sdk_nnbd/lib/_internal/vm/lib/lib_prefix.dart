// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

// This type corresponds to the VM-internal class LibraryPrefix.
@pragma("vm:entry-point")
class _LibraryPrefix {
  factory _LibraryPrefix._uninstantiable() {
    throw "Unreachable";
  }

  bool _isLoaded() native "LibraryPrefix_isLoaded";
  void _setLoaded() native "LibraryPrefix_setLoaded";
}

class _DeferredNotLoadedError extends Error implements NoSuchMethodError {
  final _LibraryPrefix prefix;

  _DeferredNotLoadedError(this.prefix);

  String toString() {
    return "Deferred library $prefix was not loaded.";
  }
}

@pragma("vm:entry-point")
@pragma("vm:never-inline") // Don't duplicate prefix checking code.
Future<void> _loadLibrary(_LibraryPrefix prefix) {
  return new Future<void>(() {
    prefix._setLoaded();
  });
}

@pragma("vm:entry-point")
@pragma("vm:never-inline") // Don't duplicate prefix checking code.
void _checkLoaded(_LibraryPrefix prefix) {
  if (!prefix._isLoaded()) {
    throw new _DeferredNotLoadedError(prefix);
  }
}
