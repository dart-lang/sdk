// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
/// Explicit is-test is required even with --omit-implicit-checks.
////////////////////////////////////////////////////////////////////////////////

/*element: method1:*/
method1<T>(dynamic o) {
  /*fields=[T,o],free=[T,o]*/
  dynamic local() => o is T;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Explicit as-cast is required even with --omit-implicit-checks.
////////////////////////////////////////////////////////////////////////////////

/*element: method2:*/
method2<T>(dynamic o) {
  /*fields=[T,o],free=[T,o]*/
  dynamic local() => o as T;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Implicit as-cast is not required with --omit-implicit-checks.
////////////////////////////////////////////////////////////////////////////////

/*element: method3:*/
method3<T>(dynamic o) {
  // TODO(johnniwinther): Improve rti tracking to avoid capture of `T`.
  /*fields=[T,o],free=[T,o]*/
  T local() => o;
  return local;
}

main() {
  method1<int>(0).call();
  method2<int>(0).call();
  method3<int>(0).call();
}
