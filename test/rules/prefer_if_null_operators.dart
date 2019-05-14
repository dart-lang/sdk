// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_if_null_operators`

var v;

m(p) {
  var a, b;
  a == null ? b : a; // LINT
  null == a ? b : a; // LINT
  a != null ? a : b; // LINT
  null != a ? a : b; // LINT
  a.b != null ? a.b : b; // LINT
  v == null ? b : v; // LINT
  p == null ? b : p; // LINT
}