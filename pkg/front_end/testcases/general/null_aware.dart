// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
class Foo {
  int field;
  static int staticField;
}

main() {
  Foo foo = new Foo();
  foo?.field = 5;
  Foo?.staticField = 5;
  foo.field ??= 5;
  Foo.staticField ??= 5;
  foo?.field ??= 5;
  Foo?.staticField ??= 5;

  int intValue = foo.field ?? 6;
  num numValue = foo.field ?? 4.5;
}
