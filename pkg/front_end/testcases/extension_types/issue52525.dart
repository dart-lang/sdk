// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type IC1(int id) {
  factory IC1.f(int id) = IC1;
}

main() {
  var ic1 = IC1.f(1);
  print(ic1.id);
}
