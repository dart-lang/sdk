// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that a forwarding constructor is generated even when there is an
// optional parameter.

abstract class Mixin {}

class Base {
  Base(
      {x} //       //# 01: ok
      {x} //       //# 02: ok
      {x} //       //# 03: ok
      );
}

class C extends Base with Mixin {
  C(); //          //# 02: continued
  C() : super(); //# 03: continued
}

main() {
  new C();
}
