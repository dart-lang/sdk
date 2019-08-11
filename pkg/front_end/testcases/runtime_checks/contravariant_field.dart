// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class C<T> {
  F<T> y;
  void f() {
    var x = this.y;
  }
}

void g(C<num> c) {
  var x = c. /*@ checkReturn=(num*) ->* void */ y;
}

void main() {}
