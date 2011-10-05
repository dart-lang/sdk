// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// expect error - Sub calls a non-const super.
class Base {
  Base() { }
}

class Sub extends Base {
 const Sub(a) : super(1), this.a_ = a;
 final a_;
}
