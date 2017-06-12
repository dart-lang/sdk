// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "package:expect/expect.dart";

// Local variables can shadow class names and hence should result in an
// error.

class Test {
  Test.named(int this.fld);
  int fld;
}

main() {
  var Test;
  var i = new Test.named(10); // This should be an error.
  Expect.equals(10, i.fld);
}
