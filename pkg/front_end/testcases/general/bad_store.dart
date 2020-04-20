// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  var field;
}

dynamic identity(x) => x;

void use(x) {}

main(List<String> args) {
  dynamic foo = identity(new Foo());
  if (args.length > 1) {
    foo.field = "string";
    var first = foo.field;
    use(first);
    foo.noField = "string";
    var second = foo.noField;
    use(second);
  }
}
