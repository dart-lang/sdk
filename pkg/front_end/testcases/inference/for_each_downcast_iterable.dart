// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test() async {
  Object o;
  for (var /*@type=dynamic*/ x in o) {}
  await for (var /*@type=dynamic*/ x in o) {}
  int y;
  for (y in o) {}
  await for (y in o) {}
}

main() {}
