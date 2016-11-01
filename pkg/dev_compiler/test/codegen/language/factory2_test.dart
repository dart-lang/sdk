// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

abstract class Link<T> extends IterableBase<T> {
  // does not match constructor for LinkFactory
  factory Link(T head, [Link<T> tail]) = LinkFactory<T>; /// static type warning
  Link<T> prepend(T element);
}

abstract class EmptyLink<T> extends Link<T> {
  const factory EmptyLink() = LinkTail<T>;
}

class LinkFactory<T> {
  factory LinkFactory(head, [Link tail]) { }
}

// Does not implement all of Iterable
class AbstractLink<T> implements Link<T> {
  const AbstractLink();
  Link<T> prepend(T element) {
    return new Link<T>(element, this);
  }
}

// Does not implement all of Iterable
class LinkTail<T> extends AbstractLink<T>
    implements EmptyLink<T> {
  const LinkTail();
}

// Does not implement all of Iterable
class LinkEntry<T> extends AbstractLink<T> {
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

