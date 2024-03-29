// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:compiler/src/util/testing.dart";

/*class: T:checks=[],indirectInstance*/
class T<X> {
  final Type tType = X;
  Type get getTType => X;
}

/*class: S:checks=[]*/
mixin S<Y> {
  final Type sType = Y;
  Type get getSType => Y;
}

/*class: TS:checks=[],instance*/
class TS<A, B> = T<A> with S<B>;

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
dyn(x) => x;

main() {
  var ts = TS<int, String>();

  makeLive("String" == ts.sType.toString());
  makeLive("int" == ts.tType.toString());
  makeLive("String" == ts.getSType.toString());
  makeLive("int" == ts.getTType.toString());

  makeLive("String" == dyn(ts).sType.toString());
  makeLive("int" == dyn(ts).tType.toString());
  makeLive("String" == dyn(ts).getSType.toString());
  makeLive("int" == dyn(ts).getTType.toString());
}
