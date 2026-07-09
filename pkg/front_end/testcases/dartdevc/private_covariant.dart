// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  _privateMethod(covariant int i) {}
}

main() {
  new Class()._privateMethod(0);
}
