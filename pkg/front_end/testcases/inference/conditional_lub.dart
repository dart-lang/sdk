// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

bool b = true;
int x = 0;
double y = 0.0;
var /*@topType=num*/ z = b ? x : y;

main() {
  var /*@type=num*/ z = b ? x : y;
}
