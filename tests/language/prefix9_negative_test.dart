// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// Local variables can shadow type parameters and hence should result in an
// error.

class Test<T> {
  Test.named(T this.fld);
  T fld;
}

class Param {
  Param.named(int this.fld);
  int fld;
}

main() {
  Param test = new Param.named(10);
  var Param;
  var i = new Test<Param>.named(test);  // This should be an error.
  Expect.equals(10, i.fld.fld);
}
