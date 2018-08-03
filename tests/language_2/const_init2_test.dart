// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const double c = 0.0; //# 01: ok
const double d = 0; //# 02: compile-time error

main() {
  print(c); //# 01: continued
  print(d); //# 02: continued
}
