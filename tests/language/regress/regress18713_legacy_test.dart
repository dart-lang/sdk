// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import "package:expect/expect.dart";

class T<X> {
  final Type tType = X;
  Type get getTType => X;
}

class S<Y> {
  final Type sType = Y;
  Type get getSType => Y;
}

class TS<A, B> = T<A> with S<B>;

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
dyn(x) => x;

main() {
  var ts = new TS<int, String>();

  Expect.equals(String, ts.sType);
  Expect.equals(int, ts.tType);
  Expect.equals(String, ts.getSType);
  Expect.equals(int, ts.getTType);

  Expect.equals(String, dyn(ts).sType);
  Expect.equals(int, dyn(ts).tType);
  Expect.equals(String, dyn(ts).getSType);
  Expect.equals(int, dyn(ts).getTType);
}
