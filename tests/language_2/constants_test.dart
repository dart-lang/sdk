// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  factory C() => null;
}

const //# 01: compile-time error
t() => null;

const //# 02: compile-time error
get v => null;

main() {
  const //# 03: compile-time error
      dynamic x = t();
  const y = const C(); //# 04: compile-time error
  const //# 05: compile-time error
      dynamic z = v;
}
