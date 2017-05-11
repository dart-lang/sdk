// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/**
 * Indicates that loading of [libraryName] is deferred.
 *
 * This class is obsolete. Instead use the syntax:
 * import "library.dart" deferred as prefix;
 */
@Deprecated("Dart sdk v. 1.8")
class DeferredLibrary {
  final String libraryName;
  final String uri;

  const DeferredLibrary(this.libraryName, {this.uri});

  /**
   * Ensure that [libraryName] has been loaded.
   *
   * If the library fails to load, the Future will complete with a
   * DeferredLoadException.
   */
  external Future<Null> load();
}

/**
 * Thrown when a deferred library fails to load.
 */
class DeferredLoadException implements Exception {
  DeferredLoadException(this._s);
  String toString() => "DeferredLoadException: '$_s'";
  final String _s;
}
