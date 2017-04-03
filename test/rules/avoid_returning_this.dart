// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_returning_this`

class A {
  int x;
  A badAddOne() { // LINT
    x++;
    return this;
  }

  Object goodAddOne1() { // OK it is ok because it does not return an A type.
    x++;
    return this;
  }

  int goodAddOne2() { // OK
    x++;
    return this.x;
  }
  A getThing() { // OK
    return this;
  }

  B doSomething() { // OK it is ok because it does not return an A type.
    x++;
    return this;
  }
}

class B extends A{
  @override
  A badAddOne() { // OK it is ok because it is an inherited method.
    x++;
    return this;
  }

  @override
  B doSomething() { // OK it is ok because it is an inherited method.
    x++;
    return this;
  }

  B badAddOne2() { // LINT
    x++;
    return this;
  }
}
