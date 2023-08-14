// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compile time error for factories with parameterized types.

import "dart:collection";

abstract class A<T> {
  factory A.create() = AFactory<T>.create;
  //                   ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
  //                   ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_INVALID_RETURN_TYPE
  // [cfe] Expected 0 type arguments.
}

class AFactory {
  //   Compile time error: should be AFactory<T> to match abstract class above
  factory A.create() {
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_FACTORY_NAME_NOT_A_CLASS
  // [cfe] The name of a constructor must match the name of the enclosing class.
    throw UnimplementedError();
  }
}

abstract class Link<T> extends IterableBase<T> {
  // does not match constructor for LinkFactory
  factory Link(T head, [Link<T>? tail]) =
      LinkFactory<T>;
//    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_INVALID_RETURN_TYPE
// [cfe] The constructor function type 'LinkFactory<T> Function(dynamic, [Link<dynamic>?])' isn't a subtype of 'Link<T> Function(T, [Link<T>?])'.
  Link<T> prepend(T element);
}

abstract class EmptyLink<T> extends Link<T> {
  const factory EmptyLink() = LinkTail<T>;
}

class LinkFactory<T> {
  factory LinkFactory(head, [Link? tail]) {
    throw UnimplementedError();
  }
}

// Does not implement all of Iterable
class AbstractLink<T> implements Link<T> {
//    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The non-abstract class 'AbstractLink' is missing implementations for these members:
  const AbstractLink();
  Link<T> prepend(T element) {
    return new Link<T>(element, this);
  }
}

// Does not implement all of Iterable
class LinkTail<T> extends AbstractLink<T> implements EmptyLink<T> {
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The non-abstract class 'LinkTail' is missing implementations for these members:
  const LinkTail();
}

// Does not implement all of Iterable
class LinkEntry<T> extends AbstractLink<T> {
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The non-abstract class 'LinkEntry' is missing implementations for these members:
  LinkEntry(T head, Link<T>? realTail);
}

class Fisk {
  // instantiation of abstract class
  Link<String> nodes = const EmptyLink();
}

main() {
  // Equivalent to new Link<dynamic>.create().
  var a = new A.create();

  new Fisk();
  // instantiation of abstract class
  new EmptyLink<String>().prepend('hest');
  // instantiation of abstract class
  const EmptyLink<String>().prepend('fisk');
}
