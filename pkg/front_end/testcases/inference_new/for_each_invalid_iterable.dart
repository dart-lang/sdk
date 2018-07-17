// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference,error*/
library test;

test() async {
  String s;
  for (int x in /*@error=ForInLoopTypeNotIterable*/ s) {}
  await for (int x in /*@error=ForInLoopTypeNotIterable*/ s) {}
  int y;
  for (y in /*@error=ForInLoopTypeNotIterable*/ s) {}
  await for (y in /*@error=ForInLoopTypeNotIterable*/ s) {}
}

main() {}
