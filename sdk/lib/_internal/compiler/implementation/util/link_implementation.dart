// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of util_implementation;

class LinkIterator<T> implements Iterator<T> {
  T _current;
  Link<T> _link;

  LinkIterator(Link<T> this._link);

  T get current => _current;

  bool moveNext() {
    if (_link.isEmpty) {
      _current = null;
      return false;
    }
    _current = _link.head;
    _link = _link.tail;
    return true;
  }
}

typedef T Transformation<S, T>(S input);

class MappedLinkIterator<S, T> extends Iterator<T> {
  Transformation<S, T> _transformation;
  Link<S> _link;
  T _current;

  MappedLinkIterator(this._link, this._transformation);

  T get current => _current;

  bool moveNext() {
    if (_link.isEmpty) {
      _current = null;
      return false;
    }
    _current = _transformation(_link.head);
    _link = _link.tail;
    return true;
  }
}

class MappedLinkIterable<S, T> extends IterableBase<T> {
  Transformation<S, T> _transformation;
  Link<S> _link;

  MappedLinkIterable(this._link, this._transformation);

  Iterator<T> get iterator {
    return new MappedLinkIterator<S,T>(_link, _transformation);
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
    buffer.write(head);
    if (separatedBy == null) separatedBy = '';
    for (Link link = tail; !link.isEmpty; link = link.tail) {
      buffer.write(separatedBy);
      buffer.write(link.head);
    }
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('[ ');
    printOn(buffer, ', ');
    buffer.write(' ]');
    return buffer.toString();
  }

  Link<T> reverse() {
    Link<T> result = const Link();
    for (Link<T> link = this; !link.isEmpty; link = link.tail) {
      result = result.prepend(link.head);
    }
    return result;
  }

  Link<T> reversePrependAll(Link<T> from) {
    Link<T> result;
    for (result = this; !from.isEmpty; from = from.tail) {
      result = result.prepend(from.head);
    }
    return result;
  }

  Link<T> skip(int n) {
    Link<T> link = this;
    for (int i = 0 ; i < n ; i++) {
      if (link.isEmpty) {
        throw new RangeError('Index $n out of range');
      }
      link = link.tail;
    }
    return link;
  }

  bool get isEmpty => false;

  void forEach(void f(T element)) {
    for (Link<T> link = this; !link.isEmpty; link = link.tail) {
      f(link.head);
    }
  }

  bool operator ==(other) {
    if (other is !Link<T>) return false;
    Link<T> myElements = this;
    while (!myElements.isEmpty && !other.isEmpty) {
      if (myElements.head != other.head) {
        return false;
      }
      myElements = myElements.tail;
      other = other.tail;
    }
    return myElements.isEmpty && other.isEmpty;
  }

  int get hashCode => throw new UnsupportedError('LinkEntry.hashCode');

  int slowLength() => 1 + tail.slowLength();
}

class LinkBuilderImplementation<T> implements LinkBuilder<T> {
  LinkEntry<T> head = null;
  LinkEntry<T> lastLink = null;
  int length = 0;

  LinkBuilderImplementation();

  Link<T> toLink([Link<T> tail = const Link()]) {
    if (head == null) return tail;
    lastLink.tail = tail;
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

  bool get isEmpty => length == 0;
}
