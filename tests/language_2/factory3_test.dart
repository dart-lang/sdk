// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_checked_mode

import "dart:collection";

// Test compile time error for factories with parameterized types.

abstract class A<T> {
  A();
  A.create();
}

abstract class B<T> extends A<T>{}

// Compile time error: should be AFactory<T> to match abstract class above
class AFactory extends B<int> {
  factory A.create() { // //# 01: compile-time error
    return null; // //# 01: continued
  } // //# 01: continued
}

abstract class Link<T> extends IterableBase<T> {
  factory Link(T head, [Link<T> tail]) = LinkEntry<T>;
  Link<T> prepend(T element);
}

abstract class EmptyLink<T> extends Link<T> {
  const factory EmptyLink() = LinkTail<T>;
}

class AbstractLink<T> implements Link<T> { /*@compile-error=unspecified*/
  const AbstractLink();
  Link<T> prepend(T element) {
    print("$element");
    if (0 is T) {
      throw "0 is not a T";
    }
    return new Link<T>(element, this);
  }
}

class LinkTail<T> extends AbstractLink<T> implements EmptyLink<T> { /*@compile-error=unspecified*/
  const LinkTail();
}

class LinkEntry<T> extends AbstractLink<T> { /*@compile-error=unspecified*/
  LinkEntry(T head, [Link<T> Tail]);
}

class Fisk {
  Link<Fisk> nodes = const EmptyLink<Fisk>();
  final int id;
  Fisk(this.id);
  toString() => id.toString();
}

main() {
  var a = new AFactory.create(); // //# 01: continued
  var a = new AFactory.create(); // //# none: compile-time error
  new Fisk(0).nodes.prepend(new Fisk(1)).prepend(new Fisk(2));
}
