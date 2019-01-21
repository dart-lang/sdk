// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_null_aware_operator`

var v;

m() {
  var a;
  a == null ? null : a.b; // LINT
  a == null ? null : a.b(); // LINT
  a == null ? null : a.b.c; // LINT
  a == null ? null : a.b.c(); // LINT
  null == a ? null : a.b; // LINT
  null == a ? null : a.b(); // LINT
  null == a ? null : a.b.c; // LINT
  null == a ? null : a.b.c(); // LINT
  a != null ? a.b : null; // LINT
  a != null ? a.b() : null; // LINT
  a != null ? a.b.c : null; // LINT
  a != null ? a.b.c() : null; // LINT
  null != a ? a.b : null; // LINT
  null != a ? a.b() : null; // LINT
  null != a ? a.b.c : null; // LINT
  null != a ? a.b.c() : null; // LINT

  // lint only for local vars
  v == null ? null : v.b; // OK
}
