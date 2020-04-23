// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

String toplevel = 'A';

class Foo {
  String x = 'x';

  easy(z) {

  }

  // Shadow the 'y' field in various ways
  shadow_y_parameter(y) {

  }

  shadow_y_local(z) {
    var y = z;

  }

  shadow_y_capturedLocal(z) {
    var y = z;
    foo() {

    }
    return foo();
  }

  shadow_y_closureParam(z) {
    foo(y) {

    }
    return foo(z);
  }

  shadow_y_localInsideClosure(z) {
    foo() {
      var y = z;

    }

    return foo();
  }

  // Shadow the 'x' field in various ways
  shadow_x_parameter(x) {

  }

  shadow_x_local(z) {
    var x = z;

  }

  shadow_x_capturedLocal(z) {
    var x = z;
    foo() {

    }
    return foo();
  }

  shadow_x_closureParam(z) {
    foo(x) {

    }
    return foo(z);
  }

  shadow_x_localInsideClosure(z) {
    foo() {
      var x = z;

    }

    return foo();
  }

  shadow_x_toplevel() {

  }
}

class Sub extends Foo {
  String y = 'y';
  String toplevel = 'B';
}

main() {













}
