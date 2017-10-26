// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final List<A> children;
  const A({this.children: const []});
}

const a = const A();
const b = const A(children: const [a]);

main() {
  print(b);
}
