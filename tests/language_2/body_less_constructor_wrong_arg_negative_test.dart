// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  C o = const C(1);
}

class Base {
  final String name;
  const Base(this.name);
}

class C extends Base {
  const C(var x) : super(); // call super constructor with wrong argument count.
}
