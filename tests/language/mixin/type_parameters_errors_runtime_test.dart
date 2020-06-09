// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S<T> {}

class M<U> {}

class A<X> extends S<int> with M<double> {}



class F<X> = S<X> with M<X>;


main() {
  var a;
  a = new A();
  a = new A<int>();

  a = new F<int>();

}
