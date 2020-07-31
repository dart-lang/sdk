// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that the implicit super call for synthetic constructors are checked.

class A {
  final x;
  A(this.x);
}

class B extends A {

  B() : super(null);

}

// ==========

class Y extends A {

  Y() : super(null);

}

class Z extends Y {
  Z() : super();
}

// ==============

class G extends A {

  G() : super(null);

}

class H extends G {}

main() {
  new B().x;
  new Z().x;
  new H().x;
}
