// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<X> {
  C(void Function(X) x);
}

T check<T>(C<List<T>> f) {
  print('check<$T>(...)');
  return 42 as T;
}

void main() {
  var x =
      check
      /*cfe.T :> int,T :> int*/
      /*analyzer.T :> int*/ (
        C
        /*cfe.X <: List<_>,X <: List<int>,X <: List<int>*/
        /*analyzer.X <: List<_>,X <: List<int>*/ ((List<int> x) {}),
      );
  print(x); // VM prints 42
}
