// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.util;

class Link<T> {
  T get head => null;
  Link<T> get tail => null;

  factory Link.fromList(List<T> list) {
    switch (list.length) {
      case 0:
        return new Link<T>();
      case 1:
        return new LinkEntry<T>(list[0]);
      case 2:
        return new LinkEntry<T>(list[0], new LinkEntry<T>(list[1]));
      case 3:
        return new LinkEntry<T>(
            list[0], new LinkEntry<T>(list[1], new LinkEntry<T>(list[2])));
    }
    Link link = new Link<T>();
    for (int i = list.length ; i > 0; i--) {
      link = link.prepend(list[i - 1]);
    }
    return link;
  }

  const Link();

  Link<T> prepend(T element) {
    return new LinkEntry<T>(element, this);
  }

  Iterator<T> get iterator => new LinkIterator<T>(this);

  void printOn(StringBuffer buffer, [separatedBy]) {
  }

  List<T> toList({ bool growable: true }) {
    List<T> result;
    if (!growable) {
      result = new List<T>(slowLength());
    } else {
      result = new List<T>();
      result.length = slowLength();
    }
    int i = 0;
    for (Link<T> link = this; !link.isEmpty; link = link.tail) {
      result[i++] = link.head;
    }
    return result;
  }

  /// Lazily maps over this linked list, returning an [Iterable].
  Iterable map(dynamic fn(T item)) {
    return new MappedLinkIterable<T,dynamic>(this, fn);
  }

  /// Invokes `fn` for every item in the linked list and returns the results
  /// in a [List].
  List mapToList(dynamic fn(T item), { bool growable: true }) {
    List result;
    if (!growable) {
      result = new List(slowLength());
    } else {
      result = new List();
      result.length = slowLength();
    }
    int i = 0;
    for (Link<T> link = this; !link.isEmpty; link = link.tail) {
      result[i++] = fn(link.head);
    }
    return result;
  }

  /// Invokes `fn` for every item in the linked list and returns the results
  /// in a [Set].
  Set mapToSet(dynamic fn(T item)) {
    Set result = new Set();
    for (Link<T> link = this; !link.isEmpty; link = link.tail) {
      result.add(fn(link.head));
    }
    return result;
  }

  bool get isEmpty => true;

  Link<T> reverse() => this;

  Link<T> reversePrependAll(Link<T> from) {
    if (from.isEmpty) return this;
    return this.prepend(from.head).reversePrependAll(from.tail);
  }

  Link<T> skip(int n) {
    if (n == 0) return this;
    throw new RangeError('Index $n out of range');
  }

  void forEach(void f(T element)) {}

  bool operator ==(other) {
    if (other is !Link<T>) return false;
    return other.isEmpty;
  }

  int get hashCode => throw new UnsupportedError('Link.hashCode');

  String toString() => "[]";

  get length {
    throw new UnsupportedError('get:length');
  }

  int slowLength() => 0;

  // TODO(ahe): Remove this method?
  bool contains(T element) {
    for (Link<T> link = this; !link.isEmpty; link = link.tail) {
      if (link.head == element) return true;
    }
    return false;
  }

  // TODO(ahe): Remove this method?
  T get single {
    if (isEmpty) throw new StateError('No elements');
    if (!tail.isEmpty) throw new StateError('More than one element');
    return head;
  }

  // TODO(ahe): Remove this method?
  T get first {
    if (isEmpty) throw new StateError('No elements');
    return head;
  }

  /// Returns true if f returns true for all elements of this list.
  ///
  /// Returns true for the empty list.
  bool every(bool f(T)) {
    for (Link<T> link = this; !link.isEmpty; link = link.tail){
      if (!f(link.head)) return false;
    }
    return true;
  }
}

abstract class LinkBuilder<T> {
  factory LinkBuilder() = LinkBuilderImplementation;

  /**
   * Prepends all elements added to the builder to [tail]. The resulting list is
   * returned and the builder is cleared.
   */
  Link<T> toLink([Link<T> tail = const Link()]);

  List<T> toList();

  void addLast(T t);

  final int length;
  final bool isEmpty;
}
