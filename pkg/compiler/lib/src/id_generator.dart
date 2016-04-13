// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A generator of globally unique identifiers.
class IdGenerator {
  int _nextFreeId = 0;

  /// Returns the next free identifier.
  ///
  /// This identifier is guaranteed to be unique.
  int getNextFreeId() => _nextFreeId++;
}