// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.util.link;

import 'link_implementation.dart'
    show LinkBuilderImplementation, LinkEntry, LinkIterator, MappedLinkIterable;

class Link<T> implements Iterable<T> {
  const Link();
  // TODO(ahe): Remove this method?
  @override
  T get first {
    if (isEmpty) throw new StateError('No elements');
    return head;
  }

  @override
  int get hashCode => throw new UnsupportedError('Link.hashCode');

  T get head => throw new StateError("no elements");

  @override
  bool get isEmpty => true;

  @override
  bool get isNotEmpty => false;

  @override
  Iterator<T> get iterator => new LinkIterator<T>(this);

  @override
  T get last => _unsupported('get:last');

  @override
  get length {
    throw new UnsupportedError('get:length');
  }

  // TODO(ahe): Remove this method?
  @override
  T get single {
    if (isEmpty) throw new StateError('No elements');
    if (!tail!.isEmpty) throw new StateError('More than one element');
    return head;
  }

  Link<T>? get tail => null;

  @override
  bool operator ==(other) {
    if (other is! Link<T>) return false;
    return other.isEmpty;
  }

  //
  // Unsupported Iterable<T> methods.
  //
  @override
  bool any(bool f(T e)) => _unsupported('any');

  @override
  Iterable<T> cast<T>() => _unsupported('cast');

  // TODO(ahe): Remove this method?
  @override
  bool contains(Object? element) {
    for (Link<T> link = this; !link.isEmpty; link = link.tail!) {
      if (link.head == element) return true;
    }
    return false;
  }

  @override
  T elementAt(int i) => _unsupported('elementAt');

  /// Returns true if f returns true for all elements of this list.
  ///
  /// Returns true for the empty list.
  @override
  bool every(bool f(T e)) {
    for (Link<T> link = this; !link.isEmpty; link = link.tail!) {
      if (!f(link.head)) return false;
    }
    return true;
  }

  @override
  Iterable<K> expand<K>(Iterable<K> f(T e)) => _unsupported('expand');

  @override
  T firstWhere(bool f(T e), {T orElse()?}) => _unsupported('firstWhere');

  @override
  K fold<K>(K initialValue, K combine(K value, T element)) {
    return _unsupported('fold');
  }

  @override
  Iterable<T> followedBy(Iterable<T> other) => _unsupported('followedBy');

  @override
  void forEach(void f(T element)) {}

  @override
  String join([separator = '']) => _unsupported('join');

  @override
  T lastWhere(bool f(T e), {T orElse()?}) => _unsupported('lastWhere');

  /// Lazily maps over this linked list, returning an [Iterable].
  @override
  Iterable<K> map<K>(K fn(T item)) {
    return new MappedLinkIterable<T, K>(this, fn);
  }

  /// Invokes `fn` for every item in the linked list and returns the results
  /// in a [List].
  /// TODO(scheglov) Rewrite to `List<E>`, or remove.
  List<E?> mapToList<E>(E fn(T item), {bool growable = true}) {
    List<E?> result;
    if (!growable) {
      result = new List<E?>.filled(slowLength(), null);
    } else {
      result = <E?>[];
      result.length = slowLength();
    }
    int i = 0;
    for (Link<T> link = this; !link.isEmpty; link = link.tail!) {
      result[i++] = fn(link.head);
    }
    return result;
  }

  Link<T> prepend(T element) {
    return new LinkEntry<T>(element, this);
  }

  void printOn(StringBuffer buffer, [separatedBy]) {}
  @override
  T reduce(T combine(T a, T b)) => _unsupported('reduce');
  Iterable<T> retype<T>() => _unsupported('retype');

  Link<T> reverse(Link<T> tail) => this;
  Link<T> reversePrependAll(Link<T> from) {
    if (from.isEmpty) return this;
    return this.prepend(from.head).reversePrependAll(from.tail!);
  }

  @override
  T singleWhere(bool f(T e), {T orElse()?}) => _unsupported('singleWhere');
  @override
  Link<T> skip(int n) {
    if (n == 0) return this;
    throw new RangeError('Index $n out of range');
  }

  @override
  Iterable<T> skipWhile(bool f(T e)) => _unsupported('skipWhile');
  int slowLength() => 0;
  @override
  Iterable<T> take(int n) => _unsupported('take');
  @override
  Iterable<T> takeWhile(bool f(T e)) => _unsupported('takeWhile');
  @override
  List<T> toList({bool growable = true}) {
    List<T> result = <T>[];
    for (Link<T> link = this; !link.isEmpty; link = link.tail!) {
      result.add(link.head);
    }
    return result;
  }

  @override
  Set<T> toSet() => _unsupported('toSet');
  @override
  String toString() => "[]";
  @override
  Iterable<T> where(bool f(T e)) => _unsupported('where');
  @override
  Iterable<T> whereType<T>() => _unsupported('whereType');

  Never _unsupported(String method) => throw new UnsupportedError(method);
}

/// Builder object for creating linked lists using [Link] or fixed-length [List]
/// objects.
abstract class LinkBuilder<T> {
  factory LinkBuilder() = LinkBuilderImplementation<T>;

  /// Returns the first element in the list being built.
  T get first;

  /// Returns `true` if the list being built is empty.
  bool get isEmpty;

  /// Returns the number of elements in the list being built.
  int get length;

  /// Adds the element [t] to the end of the list being built.
  Link<T> addLast(T t);

  /// Removes all added elements and resets the builder.
  void clear();

  /// Prepends all elements added to the builder to [tail]. The resulting list
  /// is returned and the builder is cleared.
  Link<T> toLink(Link<T> tail);

  /// Creates a new fixed length containing all added elements. The
  /// resulting list is returned and the builder is cleared.
  List<T> toList();
}
