// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Foo<T extends Pattern> {
  U method<U extends T>(U u) => u;
}

main() {
/*!!!
  String s;
  var a = new Foo().method<String>("str");
  s = a;
  new Foo();

  var b = new Foo<String>().method("str");
  s = b;
  var c = new Foo().method("str");
  s = c;
  */

  new Foo<String>()
      . /*error:COULD_NOT_INFER*/ /*@typeArgs=int*/ /*@target=Foo::method*/ method(
          42);
}
