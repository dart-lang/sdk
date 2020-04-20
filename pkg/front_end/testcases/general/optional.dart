// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  method(x, [y, z]) {
    return "string";
  }
}

abstract class External {
  String externalMethod(int x, [int y, int z]);
  void listen(Listener listener);
}

external External createExternal();

abstract class Listener {
  void event(String input, [int x, int y]);
}

class TestListener extends Listener {
  void event(input, [x, y]) {}
}

class ExtendedListener extends Listener {
  void event(input, [x, y, z]) {}
}

class InvalidListener {
  void event(input, [x]) {}
}

main() {
  var foo = new Foo();
  var string1 = foo.method(1);
  var string2 = foo.method(1, 2);
  var string3 = foo.method(1, 2, 3);

  var extern = createExternal();
  var string4 = extern.externalMethod(1);
  var string5 = extern.externalMethod(1, 2);
  var string6 = extern.externalMethod(1, 2, 3);

  extern.listen(new TestListener());
  extern.listen(new ExtendedListener());
  extern.listen(new InvalidListener());

  var nothing1 = foo.method();
  var nothing2 = foo.method(1, 2, 3, 4);
  var nothing3 = extern.externalMethod();
  var nothing4 = extern.externalMethod(1, 2, 3, 4);
}
