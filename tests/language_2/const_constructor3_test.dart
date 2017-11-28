// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  final double d;
  const C(this.d);
}

class D extends C {
  const D(var d) : super(d);
}

const c = const C(0.0); //# 01: ok
const d = const C(0); //# 02: compile-time error
const e = const D(0.0); //# 03: ok
const f = const D(0); //# 04: compile-time error

main() {
  print(c); //# 01: continued
  print(d); //# 02: continued
  print(e); //# 03: continued
  print(f); //# 04: continued
}
