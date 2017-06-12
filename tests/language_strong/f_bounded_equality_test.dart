// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Magnitude<T> {
  get t => T;
}

class Real extends Magnitude<Real> {}

class FBound<F extends FBound<F>> {
  get f => F;
}

class Bar extends FBound<Bar> {}

main() {
  var r = new Real();
  Expect.equals(r.runtimeType, Real);
  Expect.equals(r.t, Real);
  Expect.equals(r.runtimeType, r.t);

  var b = new Bar();
  Expect.equals(b.runtimeType, Bar);
  Expect.equals(b.f, Bar);
  Expect.equals(b.runtimeType, b.f);
}
