// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {}

extension E on C {
  void f(String b) {}
}

void main() {
  dynamic b = '456';
  var c = C();
  c.f(b);
}
