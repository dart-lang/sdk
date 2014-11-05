// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show
    HashMap,
    HashSet;

/**
 * Helper class for allocating sets and maps appropriate for caching objects
 * that can be assumed to be canonicalized.
 *
 * When compiling dart2js to JavaScript, profiling reveals that identity maps
 * and sets have superior performance.  However, we know that [Object.hashCode]
 * is slow on the Dart VM.  This class is meant to encapsulate the decision
 * about which data structure is best, and we anticipate specific subclasses
 * for JavaScript and Dart VM in the future.
 */
class CacheStrategy {
  final bool hasIncrementalSupport;

  CacheStrategy(this.hasIncrementalSupport);

  Map newMap() => hasIncrementalSupport ? new HashMap.identity() : null;

  Set newSet() => hasIncrementalSupport ? new HashSet.identity() : null;
}
