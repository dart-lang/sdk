// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: global#JSArray:checkedInstance,checks=[$isIterable],instance*/
/*prod.class: global#JSArray:checks=[$isIterable],instance*/

/*class: global#Iterable:checkedInstance*/

/*spec.class: A:checkedInstance,checkedTypeArgument,checks=[],onlyForRti,typeArgument*/
/*prod.class: A:checkedTypeArgument,checks=[],onlyForRti,typeArgument*/
class A {}

/*spec.class: B:checkedInstance,checks=[],onlyForRti,typeArgument*/
/*prod.class: B:checks=[],onlyForRti,typeArgument*/
class B {}

@pragma('dart2js:noInline')
test(o) => o is Iterable<A>;

main() {
  test(<A>[]);
  test(<B>[]);
}
