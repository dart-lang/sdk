// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:collection";

// Test compile time error for factories with parameterized types.

abstract class A<T> {
  A();
  A.create();
}

abstract class B<T> extends A<T> {}

// Compile time error: should be AFactory<T> to match abstract class above
class AFactory extends B<int> {
  factory A.create() {
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_FACTORY_NAME_NOT_A_CLASS
    // [cfe] The name of a constructor must match the name of the enclosing class.
  }
}

abstract class Link<T> extends IterableBase<T> {
  factory Link(T head, [Link<T> tail]) = LinkEntry<T>;
  Link<T> prepend(T element);
}

abstract class EmptyLink<T> extends Link<T> {
  const factory EmptyLink() = LinkTail<T>;
}

class AbstractLink<T> implements Link<T> {
//    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The non-abstract class 'AbstractLink' is missing implementations for these members:
  const AbstractLink();
  Link<T> prepend(T element) {
    print("$element");
    if (0 is T) {
      throw "0 is not a T";
    }
    return new Link<T>(element, this);
  }
}

class LinkTail<T> extends AbstractLink<T> implements EmptyLink<T> {
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The non-abstract class 'LinkTail' is missing implementations for these members:
  const LinkTail();
}

class LinkEntry<T> extends AbstractLink<T> {
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The non-abstract class 'LinkEntry' is missing implementations for these members:
  LinkEntry(T head, [Link<T> Tail]);
}

class Fisk {
  Link<Fisk> nodes = const EmptyLink<Fisk>();
  final int id;
  Fisk(this.id);
  toString() => id.toString();
}

main() {
  var a = new AFactory.create();
  new Fisk(0).nodes.prepend(new Fisk(1)).prepend(new Fisk(2));
}
