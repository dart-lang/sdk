// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec:nnbd-off|spec:nnbd-sdk.class: A:checkedInstance,checkedTypeArgument,checks=[],typeArgument*/
/*prod:nnbd-off|prod:nnbd-sdk.class: A:checkedTypeArgument,checks=[],typeArgument*/
/*spec:nnbd-off.class: global#JSArray:checkedInstance,checks=[$isIterable],instance*/
/*prod:nnbd-off.class: global#JSArray:checks=[$isIterable],instance*/

/*class: global#Iterable:checkedInstance*/

class A {}

/*spec:nnbd-off|spec:nnbd-sdk.class: B:checkedInstance,checks=[],typeArgument*/
/*prod:nnbd-off|prod:nnbd-sdk.class: B:checks=[],typeArgument*/
class B {}

@pragma('dart2js:noInline')
test(o) => o is Iterable<A>;

main() {
  test(<A>[]);
  test(<B>[]);
}
