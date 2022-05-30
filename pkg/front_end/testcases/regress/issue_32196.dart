// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final String name;
  A.get(this.name);
  A.set(this.name);
}

main() {
  new A.get("get");
  new A.set("set");
}
