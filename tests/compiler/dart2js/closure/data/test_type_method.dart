// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
/// Explicit is-test is always required.
////////////////////////////////////////////////////////////////////////////////

/*element: method1:*/
method1<T>(dynamic o) {
  /*fields=[T,o],free=[T,o]*/
  dynamic local() => o is T;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Explicit as-cast is always required.
////////////////////////////////////////////////////////////////////////////////

/*element: method2:*/
method2<T>(dynamic o) {
  /*fields=[T,o],free=[T,o]*/
  dynamic local() => o as T;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// Implicit as-cast is only required in strong mode.
////////////////////////////////////////////////////////////////////////////////

/*element: method3:*/
method3<T>(dynamic o) {
  /*strong.fields=[T,o],free=[T,o]*/
  /*omit.fields=[o],free=[o]*/
  T local() => o;
  return local;
}

main() {
  method1<int>(0).call();
  method2<int>(0).call();
  method3<int>(0).call();
}
