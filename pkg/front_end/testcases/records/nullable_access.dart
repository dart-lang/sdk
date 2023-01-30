// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method((int,{String a})? r) {
  var l0 = r.$1; // Error.
  var l1 = r.a; // Error.
  var l2 = r?.$1;
  var l3 = r?.a;
  if (r != null) {
    var l4 = r.$1;
    var l5 = r.a;
    var l6 = r?.$1; // Warning.
    var l7 = r?.a; // Warning.
  }
}