// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that external variable declarations are allowed.
// Can only be statically checked, there is no implementation at run-time.

// External variables cannot be abstract, const, late or have an initializer.

external var top1;
external final top2;
external int top3;
external final bool top4;

/// Class C is not abstract.
class C {
  external static var static1;
  external static final static2;
  external static int static3;
  external static final bool static4;

  external var instance1;
  external final instance2;
  external int instance3;
  external final bool instance4;
  external covariant var instance5;
  external covariant num instance6;
}

class D extends C {
  // Valid override. Inherits covariance.
  external int instance6;
}

void main() {
  top1;
  top1 = 0;
  top2;
  top3;
  top3 = 0;
  top4;

  C.static1;
  C.static1 = 0;
  C.static2;
  C.static3;
  C.static3 = 0;
  C.static4;

  C c = C();
  c.instance1;
  c.instance1 = 0;
  c.instance2;
  c.instance3;
  c.instance3 = 0;
  c.instance4;
  c.instance5;
  c.instance5 = 0;
  c.instance6;
  c.instance6 = 0;
}
