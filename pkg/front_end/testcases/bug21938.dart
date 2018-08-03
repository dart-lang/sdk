// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=error*/

test() {
  Object x;
  Function f;
  x /*@error=UndefinedMethod*/ ();
  x /*@error=UndefinedMethod*/ (3);
  f(5, 2);
  x. /*@error=UndefinedMethod*/ call();
  f.call;
  f.call(5, 2);
}

main() {}
