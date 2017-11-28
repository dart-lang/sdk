// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

@NoInline()
@AssumeDynamic()
dyn(x) => x;

main() {
  var ts = new TS<int, String>();

  Expect.equals("String", ts.sType.toString());
  Expect.equals("int", ts.tType.toString());
  Expect.equals("String", ts.getSType.toString());
  Expect.equals("int", ts.getTType.toString());

  Expect.equals("String", dyn(ts).sType.toString());
  Expect.equals("int", dyn(ts).tType.toString());
  Expect.equals("String", dyn(ts).getSType.toString());
  Expect.equals("int", dyn(ts).getTType.toString());
}
