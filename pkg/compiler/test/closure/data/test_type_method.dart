// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

////////////////////////////////////////////////////////////////////////////////
/// Explicit is-test is always required.
////////////////////////////////////////////////////////////////////////////////

/*member: method1:*/
method1<T>(dynamic o) {
  /*fields=[T,o],free=[T,o]*/
  dynamic local() => o is T;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Explicit as-cast is always required.
////////////////////////////////////////////////////////////////////////////////

/*member: method2:*/
method2<T>(dynamic o) {
  /*fields=[T,o],free=[T,o]*/
  dynamic local() => o as T;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Implicit as-cast is only required in spec:nnbd-off mode.
////////////////////////////////////////////////////////////////////////////////

/*member: method3:*/
method3<T>(dynamic o) {
  /*spec.fields=[T,o],free=[T,o]*/
  /*prod.fields=[o],free=[o]*/
  T local() => o;
  return local;
}

main() {
  method1<int>(0).call();
  method2<int>(0).call();
  method3<int>(0).call();
}
