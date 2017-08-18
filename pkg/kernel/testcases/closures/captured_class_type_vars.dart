// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Isgen<B> {
  getfn() {
    return (x) => x is B;
  }
}

main() {
  int x = 3;
  var isgen = new Isgen<String>();
  var iser = isgen.getfn();
  assert(!iser(x));
}
