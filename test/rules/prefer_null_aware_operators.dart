// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_null_aware_operators`

var v;

m(p) {
  var a, b;
  a == null ? null : a.b; // LINT
  a == null ? null : a.b(); // LINT
  a == null ? null : a.b.c; // LINT
  a == null ? null : a.b.c(); // LINT
  a.b == null ? null : a.b.c; // LINT
  a.b == null ? null : a.b.c(); // LINT
  p == null ? null : p.b; // LINT
  v == null ? null : v.b; // LINT
  null == a ? null : a.b; // LINT
  null == a ? null : a.b(); // LINT
  null == a ? null : a.b.c; // LINT
  null == a ? null : a.b.c(); // LINT
  null == a.b ? null : a.b.c; // LINT
  null == a.b ? null : a.b.c(); // LINT
  null == p ? null : p.b; // LINT
  null == v ? null : v.b; // LINT
  a != null ? a.b : null; // LINT
  a != null ? a.b() : null; // LINT
  a != null ? a.b.c : null; // LINT
  a != null ? a.b.c() : null; // LINT
  a.b != null ? a.b.c : null; // LINT
  a.b != null ? a.b.c() : null; // LINT
  p != null ? p.b : null; // LINT
  v != null ? v.b : null; // LINT
  null != a ? a.b : null; // LINT
  null != a ? a.b() : null; // LINT
  null != a ? a.b.c : null; // LINT
  null != a ? a.b.c() : null; // LINT
  null != a.b ? a.b.c : null; // LINT
  null != a.b ? a.b.c() : null; // LINT
  null != p ? p.b : null; // LINT
  null != v ? v.b : null; // LINT

  a == null ? b : a; // OK
  a == null ? b.c : null; // OK
  a.b != null ? a.b : null; // OK

  a == null ? null : a.b + 10; // OK
}
