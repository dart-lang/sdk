// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*strong.class: A:checkedInstance,checkedTypeArgument,checks=[],typeArgument*/
/*omit.class: A:checkedTypeArgument,checks=[],typeArgument*/
/*strong.class: global#JSArray:checkedInstance,checks=[$isIterable],instance*/
/*omit.class: global#JSArray:checks=[$isIterable],instance*/

/*class: global#Iterable:checkedInstance*/

class A {}

/*strong.class: B:checkedInstance,checks=[],typeArgument*/
/*omit.class: B:checks=[],typeArgument*/
class B {}

@pragma('dart2js:noInline')
test(o) => o is Iterable<A>;

main() {
  test(<A>[]);
  test(<B>[]);
}
