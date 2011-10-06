// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// expect no failures - Sub.A omits call to const super, but one will be added

class Base {
  const Base(a);
  Base.A(a,b) { }
}

class Sub extends Base {
 const Sub(a)   : super(a), this.a_ = a;
 const Sub.A(a) : this.a_ = a;
 const Sub.B(a) : super(a), this.a_ = a;
 final a_;
}
