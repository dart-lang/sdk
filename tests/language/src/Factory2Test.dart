// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing factories.

interface Link<T> extends Iterable<T> default LinkFactory<T> {
  Link(T head, [Link<T> tail]);
  Link<T> prepend(T element);
}

interface EmptyLink<T> extends Link<T> default LinkTail<T> {
  const EmptyLink();
}

class LinkFactory<T> {
  factory Link(head, [Link tail]) {
  }
}

class AbstractLink<T> implements Link<T> {
  const AbstractLink();
  Link<T> prepend(T element) {
    return new Link<T>(element, this);
  }
}

class LinkTail<T> extends AbstractLink<T> implements EmptyLink<T> {
  const LinkTail();
}

class LinkEntry<T> extends AbstractLink<T> {
  LinkEntry(T head, Link<T> realTail);
}

class Fisk {
 Link<String> nodes = const EmptyLink();
}

main() {
  new Fisk();
  new EmptyLink<String>().prepend('hest');
  const EmptyLink<String>().prepend('fisk');
}

