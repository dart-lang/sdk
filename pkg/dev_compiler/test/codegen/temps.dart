// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FormalCollision {
  // These shouldn't collide (see issue #136)
  int _x, __x;
  // This shouldn't generate a keyword as an identifier.
  Function _function;
  FormalCollision(this._x, this.__x, this._function);
}

main() {
  print(new FormalCollision(1, 2, (x) => x));
}
