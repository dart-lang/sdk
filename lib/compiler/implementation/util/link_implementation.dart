// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class LinkIterator<T> implements Iterator<T> {
  Link<T> current;
  LinkIterator(Link<T> this.current);
  bool hasNext() => !current.isEmpty();
  T next() {
    T result = current.head;
    current = current.tail;
    return result;
  }
}

class LinkFactory<T> {
  factory Link(T head, [Link<T> tail]) {
    if (tail === null) {
      tail = new LinkTail<T>();
    }
    return new LinkEntry<T>(head, tail);
  }

  factory Link.fromList(List<T> list) {
    switch (list.length) {
      case 0:
        return new LinkTail<T>();
      case 1:
        return new Link<T>(list[0]);
      case 2:
        return new Link<T>(list[0], new Link<T>(list[1]));
      case 3:
        return new Link<T>(list[0], new Link<T>(list[1], new Link<T>(list[2])));
    }
    Link link = new Link<T>(list.last());
    for (int i = list.length - 1; i > 0; i--) {
      link = link.prepend(list[i - 1]);
    }
    return link;
  }
}

class LinkTail<T> implements EmptyLink<T> {
  T get head() => null;
  Link<T> get tail() => null;

  const LinkTail();

  Link<T> prepend(T element) {
    // TODO(ahe): Use new Link<T>, but this cost 8% performance on VM.
    return new LinkEntry<T>(element, this);
  }

  Iterator<T> iterator() => new LinkIterator<T>(this);

  void printOn(StringBuffer buffer, [separatedBy]) {
  }

  String toString() => "[]";

  Link<T> reverse() => this;

  Link<T> reversePrependAll(Link<T> from) {
    if (from.isEmpty()) return this;
    return this.prepend(from.head).reversePrependAll(from.tail);
  }

  List toList() => const [];

  bool isEmpty() => true;

  void forEach(void f(T element)) {}
}

class LinkEntry<T> implements Link<T> {
  final T head;
  Link<T> tail;

  LinkEntry(T this.head, Link<T> this.tail);

  Link<T> prepend(T element) {
    // TODO(ahe): Use new Link<T>, but this cost 8% performance on VM.
    return new LinkEntry<T>(element, this);
  }

  Iterator<T> iterator() => new LinkIterator<T>(this);

  void printOn(StringBuffer buffer, [separatedBy]) {
    buffer.add(head);
    if (separatedBy === null) separatedBy = '';
    for (Link link = tail; !link.isEmpty(); link = link.tail) {
      buffer.add(separatedBy);
      buffer.add(link.head);
    }
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.add('[ ');
    printOn(buffer, ', ');
    buffer.add(' ]');
    return buffer.toString();
  }

  Link<T> reverse() {
    Link<T> result = const LinkTail();
    for (Link<T> link = this; !link.isEmpty(); link = link.tail) {
      result = result.prepend(link.head);
    }
    return result;
  }

  Link<T> reversePrependAll(Link<T> from) {
    Link<T> result;
    for (result = this; !from.isEmpty(); from = from.tail) {
      result = result.prepend(from.head);
    }
    return result;
  }


  bool isEmpty() => false;

  List<T> toList() {
    List<T> list = new List<T>();
    for (Link<T> link = this; !link.isEmpty(); link = link.tail) {
      list.addLast(link.head);
    }
    return list;
  }

  void forEach(void f(T element)) {
    for (Link<T> link = this; !link.isEmpty(); link = link.tail) {
      f(link.head);
    }
  }
}

class LinkBuilderImplementation<T> implements LinkBuilder<T> {
  LinkEntry<T> head = null;
  LinkEntry<T> lastLink = null;
  int length = 0;

  LinkBuilderImplementation();

  Link<T> toLink() {
    if (head === null) return const LinkTail();
    lastLink.tail = const LinkTail();
    Link<T> link = head;
    lastLink = null;
    head = null;
    return link;
  }

  void addLast(T t) {
    length++;
    LinkEntry<T> entry = new LinkEntry<T>(t, null);
    if (head === null) {
      head = entry;
    } else {
      lastLink.tail = entry;
    }
    lastLink = entry;
  }
}
