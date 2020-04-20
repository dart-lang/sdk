// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {}

class Bar extends Foo {}

class Base {
  Foo method() {
    return new Foo();
  }
}

class Sub extends Base {
  Foo method() {
    return new Bar();
  }
}

main(List<String> args) {
  var object = args.length == 0 ? new Base() : new Sub();
  var a = object.method();
  print(a);
}
