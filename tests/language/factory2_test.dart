// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing default keyword on interfaces
// Test case for issues 500 and 512

interface Link<T> extends Iterable<T> default LinkFactory<T> {
  // does not match constructor for  LinkFactory
  Link(T head, [Link<T> tail]); /// static type warning
  Link<T> prepend(T element);
}

interface EmptyLink<T> extends Link<T> default LinkTail<T> {
  const EmptyLink();
}

class LinkFactory<T> {
  factory Link(head, [Link tail]) {
  }
}

// Does not implement all of Iterable
class AbstractLink<T> implements Link<T> {  /// static type warning
  const AbstractLink();
  Link<T> prepend(T element) {
    return new Link<T>(element, this);
  }
}

// Does not implement all of Iterable
class LinkTail<T> extends AbstractLink<T>    /// static type warning
    implements EmptyLink<T> {
  const LinkTail();
}

// Does not implement all of Iterable
class LinkEntry<T> extends AbstractLink<T> {  /// static type warning
  LinkEntry(T head, Link<T> realTail);
}

class Fisk {
  // instantiation of abstract class
  Link<String> nodes = const EmptyLink();  /// static type warning
}

main() {
  new Fisk();
  // instantiation of abstract class
  new EmptyLink<String>().prepend('hest'); /// static type warning
  // instantiation of abstract class
  const EmptyLink<String>().prepend('fisk'); /// static type warning
}

