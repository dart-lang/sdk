// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(vsm): Don't monkey patch Object and make this work on
// non-chrome browsers.
Object.prototype.get$typeName = function() {
  return this.constructor.name;
}
