// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A(a);
  const A.named({a: 42});
  const A.optional([a]);
}

main() {
  const A(1);


  const A.named();



  const A.optional();
  const A.optional(42);

}
