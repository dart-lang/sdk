// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

/// Returns the hash code for [obj]. This includes null, true, false, maps, and
/// lists. Also handles self-referential structures.
int hashCodeFor(obj, [List parents]) {
  if (parents == null) {
    parents = [];
  } else if (parents.any((p) => identical(p, obj))) {
    return -1;
  }

  parents.add(obj);
  try {
    if (obj == null) return 0;
    if (obj == true) return 1;
    if (obj == false) return 2;
    if (obj is Map) {
      return hashCodeFor(obj.keys, parents) ^
        hashCodeFor(obj.values, parents);
    }
    if (obj is Iterable) {
      // This is probably a really bad hash function, but presumably we'll get
      // this in the standard library before it actually matters.
      int hash = 0;
      for (var e in obj) {
        hash ^= hashCodeFor(e, parents);
      }
      return hash;
    }
    return obj.hashCode;
  } finally {
    parents.removeLast();
  }
}

