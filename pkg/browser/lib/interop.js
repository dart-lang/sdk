// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Type for remote proxies to Dart objects with dart2js.
// WARNING: do not call this constructor or rely on it being
// in the global namespace, as it may be removed.
function DartObject(o) {
  this.o = o;
}
