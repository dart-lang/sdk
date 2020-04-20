// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that type casts (as) are allowed.

main() {
  const t1 = T.implicit(Sub());
  const t2 = T.explicit(Sub());
  const t3 = T.implicit(null);
  const t4 = T.explicit(null);

  // Inline.
  const Object o = "";
  const len = (o as String).length;
}

class Super {
  const Super();
}

class Sub extends Super {
  const Sub();
}

class T {
  final Sub value;
  const T.implicit(Super s) : value = s;
  const T.explicit(Super s) : value = s as Sub;
}
