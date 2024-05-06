// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.class: A:explicit=[A.T],needsArgs,test*/
/*prod.class: A:needsArgs*/
class A<T> {
  m() {
    return /*needsSignature*/ (T t) {};
  }

  /*member: A.f:*/
  f() {
    // TODO(johnniwinther): Optimize local function type signature need.
    return

        /*needsSignature*/
        (int t) {};
  }
}

main() {
  A<int>().m() is void Function(int);
  A<int>().f() is void Function(int);
}
