// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for illegally self referencing function type alias.

typedef Handle Handle(String command); //# 00: compile-time error

typedef F(F x); //# 01: compile-time error

typedef A(B x); //# 02: compile-time error
typedef B(A x); //# 02: continued

main() {
  Handle h; //# 00: continued
  F f; //# 01: continued
  A f; //# 02: continued
}
