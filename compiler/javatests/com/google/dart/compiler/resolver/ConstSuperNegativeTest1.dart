// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Expect error - Sub omits call to Base final ctor in the init list.

class Base {
  const Base();
}

class Sub extends Base {
 const Sub(a) : this.a_ = a;
 final a_;
}
