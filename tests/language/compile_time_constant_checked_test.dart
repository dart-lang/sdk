// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final int x = 'foo'; //# 01: static type warning, dynamic type error
const int y = 'foo'; //# 02: static type warning, checked mode compile-time error
int z = 'foo'; //# 03: static type warning, dynamic type error

main() {
  print(x); //# 01: continued
  print(y); //# 02: continued
  print(z); //# 03: continued
}
