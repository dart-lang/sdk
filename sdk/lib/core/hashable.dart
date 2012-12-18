// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/**
 * Temporary interface for backwards compatibility.
 *
 * All objects now have a [hashCode] method. This interface will be removed
 * after a grace period. Code that use the [:Hashable:] interface should
 * remove it, or use [:Object:] instead if a type is necessary.
 */
abstract class Hashable {
  // TODO(lrn): http://darbug.com/5522
  int get hashCode;
}
