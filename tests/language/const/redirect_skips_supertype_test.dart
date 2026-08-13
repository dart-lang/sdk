// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Since C redirects to C.named, it doesn't implicitly refer to B's
// unnamed constructor.  Therefore there is no cycle.

class B {
  final x;
  const B() : x = y;
  const B.named() : x = null;
}

class C extends B {
  const C() : this.named();
  const C.named() : super.named();
}

const y = const C();

main() {
  print(y);
}
