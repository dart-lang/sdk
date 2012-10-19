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

class LinkEntry<T> extends Link<T> {
  final T head;
  Link<T> tail;

  LinkEntry(T this.head, [Link<T> tail])
    : this.tail = ((tail == null) ? new Link<T>() : tail);

  Link<T> prepend(T element) {
    // TODO(ahe): Use new Link<T>, but this cost 8% performance on VM.
    return new LinkEntry<T>(element, this);
  }

  void printOn(StringBuffer buffer, [separatedBy]) {
    buffer.add(head);
    if (separatedBy == null) separatedBy = '';
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
    Link<T> result = const Link();
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

  bool operator ==(other) {
    if (other is !Link<T>) return false;
    Link<T> myElements = this;
    while (!myElements.isEmpty() && !other.isEmpty()) {
      if (myElements.head != other.head) {
        return false;
      }
      myElements = myElements.tail;
      other = other.tail;
    }
    return myElements.isEmpty() && other.isEmpty();
  }
}

class LinkBuilderImplementation<T> implements LinkBuilder<T> {
  LinkEntry<T> head = null;
  LinkEntry<T> lastLink = null;
  int length = 0;

  LinkBuilderImplementation();

  Link<T> toLink() {
    if (head == null) return const Link();
    lastLink.tail = const Link();
    Link<T> link = head;
    lastLink = null;
    head = null;
    return link;
  }

  void addLast(T t) {
    length++;
    LinkEntry<T> entry = new LinkEntry<T>(t, null);
    if (head == null) {
      head = entry;
    } else {
      lastLink.tail = entry;
    }
    lastLink = entry;
  }
}
