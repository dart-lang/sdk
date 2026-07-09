// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

self.create = function() {
  return {
    // If the dispatch property name is uninitialized, it will be `undefined` or
    // `null`, which will match these properties on dispatch record
    // lookup. These properties map to malformed dispatch records to force an
    // error.

    'undefined': {p: false},
    'null': {p: false},

    foo: function(x) { return 'Foo ' + x; },
  };
}