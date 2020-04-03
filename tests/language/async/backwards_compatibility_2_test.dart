// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int get async {
  return 1;
}

class A {
  async() => null;
}

main() {
  var a = async;
  var b = new A();
  var c = b.async();
}
