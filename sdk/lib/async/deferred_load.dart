// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/// Thrown when a deferred library fails to load.
class DeferredLoadException implements Exception {
  DeferredLoadException(String message) : _s = message;
  String toString() => "DeferredLoadException: '$_s'";
  final String _s;
}
