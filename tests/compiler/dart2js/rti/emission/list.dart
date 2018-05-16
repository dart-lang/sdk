// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*kernel.class: global#JSArray:checkedInstance,checks=[$isIterable],instance*/
/*strong.class: global#JSArray:checkedInstance,checks=[$isIterable,$isList],instance*/

/*class: global#Iterable:checkedInstance*/

/*class: A:checkedTypeArgument,checks=[],typeArgument*/
class A {}

/*class: B:checks=[],typeArgument*/
class B {}

@noInline
test(o) => o is Iterable<A>;

main() {
  test(<A>[]);
  test(<B>[]);
}
