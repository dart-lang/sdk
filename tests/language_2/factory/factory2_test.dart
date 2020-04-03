// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compile time error for factories with parameterized types.

import "dart:collection";

abstract class A<T> {
  factory A.create() = AFactory<T>.create; // //# 01: compile-time error
}

class AFactory {
  //   Compile time error: should be AFactory<T> to match abstract class above
  factory A.create() { // //# 01: compile-time error
    return null;// //# 01: continued
  } // //# 01: continued
}

abstract class Link<T> extends IterableBase<T> {
  // does not match constructor for LinkFactory
  factory Link(T head, [Link<T> tail]) = LinkFactory<T>; //# 03: compile-time error
  Link<T> prepend(T element);
}

abstract class EmptyLink<T> extends Link<T> {
  const factory EmptyLink() = LinkTail<T>;
}

class LinkFactory<T> {
  factory LinkFactory(head, [Link tail]) {}
}

// Does not implement all of Iterable
class AbstractLink<T> implements Link<T> { /*@compile-error=unspecified*/
  const AbstractLink();
  Link<T> prepend(T element) {
    return new Link<T>(element, this);
  }
}

// Does not implement all of Iterable
class LinkTail<T> extends AbstractLink<T> implements EmptyLink<T> { /*@compile-error=unspecified*/
  const LinkTail();
}

// Does not implement all of Iterable
class LinkEntry<T> extends AbstractLink<T> { /*@compile-error=unspecified*/
  LinkEntry(T head, Link<T> realTail);
}

class Fisk {
  // instantiation of abstract class
  Link<String> nodes = const EmptyLink(); /*@compile-error=unspecified*/
}

main() {
  // Equivalent to new Link<dynamic>.create().
  var a = new A.create(); // //# none: compile-time error
  var a = new A.create(); // //# 01: continued

  new Fisk();
  // instantiation of abstract class
  new EmptyLink<String>().prepend('hest'); //# compile-time error
  // instantiation of abstract class
  const EmptyLink<String>().prepend('fisk'); //# compile-time error
}
