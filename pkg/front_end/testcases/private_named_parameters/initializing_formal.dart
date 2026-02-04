// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int? _foo;
  C({this._foo});
}

main() {
  var c = C(foo: 1);
  print(c._foo);
}
