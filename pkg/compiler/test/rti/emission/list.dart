// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.class: global#JSArray:checkedInstance,checks=[$isIterable,$isList],instance*/
/*prod.class: global#JSArray:checks=[$isIterable],instance*/

/*class: global#Iterable:checkedInstance*/

/*class: A:checkedInstance,checkedTypeArgument,typeArgument*/
class A {}

/*class: B:checkedInstance,typeArgument*/
class B {}

@pragma('dart2js:noInline')
test(o) => o is Iterable<A>;

main() {
  test(<A>[]);
  test(<B>[]);
}
