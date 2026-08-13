// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  void Function()? field;
  void Function()? get getter => null;
}

error() {
  void Function()? f;
  f();
  f.call();
  Class c = new Class();
  c.field();
  c.getter();
}

main() {}
