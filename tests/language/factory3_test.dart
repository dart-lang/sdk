// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_checked_mode

interface Link<T> extends Iterable<T> default LinkFactory<T> {
  Link(T head, [Link<T> tail]);
  Link<T> prepend(T element);
}

interface EmptyLink<T> extends Link<T> default LinkTail<T> {
  const EmptyLink();
}

class LinkFactory<T> {
  factory Link(T head, [Link<T> tail]) {
    return new LinkEntry<T>(head, tail);
  }
}

class AbstractLink<T> implements Link<T> {
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
  const LinkTail();
}

class LinkEntry<T> extends AbstractLink<T> {
  LinkEntry(T head, Link<T> realTail);
}

class Fisk {
  Link<Fisk> nodes = const EmptyLink<Fisk>();
  final int id;
  Fisk(this.id);
  toString() => id.toString();
}

main() {
  new Fisk(0).nodes.prepend(new Fisk(1)).prepend(new Fisk(2));
}

