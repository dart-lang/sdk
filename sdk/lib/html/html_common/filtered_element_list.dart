// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html_common;

/**
 * An indexable collection of a node's descendants in the document tree,
 * filtered so that only elements are in the collection.
 */
class FilteredElementList extends ListBase<Element> {
  final Node _node;
  final List<Node> _childNodes;

  /**
   * Creates a collection of the elements that descend from a node.
   *
   * Example usage:
   *
   *     var filteredElements = new FilteredElementList(query("#container"));
   *     // filteredElements is [a, b, c].
   */
  FilteredElementList(Node node): _childNodes = node.nodes, _node = node;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  //
  // TODO(nweiz): we don't always need to create a new list. For example
  // forEach, every, any, ... could directly work on the _childNodes.
  List<Element> get _filtered =>
    new List<Element>.from(_childNodes.where((n) => n is Element));

  void forEach(void f(Element element)) {
    _filtered.forEach(f);
  }

  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  void set length(int newLength) {
    final len = this.length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw new ArgumentError("Invalid list length");
    }

    removeRange(newLength, len);
  }

  String join([String separator = ""]) => _filtered.join(separator);

  void add(Element value) {
    _childNodes.add(value);
  }

  void addAll(Iterable<Element> iterable) {
    for (Element element in iterable) {
      add(element);
    }
  }

  bool contains(Element element) {
    return element is Element && _childNodes.contains(element);
  }

  Iterable<Element> get reversed => _filtered.reversed;

  void sort([int compare(Element a, Element b)]) {
    throw new UnsupportedError('TODO(jacobr): should we impl?');
  }

  void setRange(int start, int end, Iterable<Element> iterable,
                [int skipCount = 0]) {
    throw new UnimplementedError();
  }

  void fillRange(int start, int end, [Element fillValue]) {
    throw new UnimplementedError();
  }

  void replaceRange(int start, int end, Iterable<Element> iterable) {
    throw new UnimplementedError();
  }

  void removeRange(int start, int end) {
    _filtered.sublist(start, end).forEach((el) => el.remove());
  }

  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  Element removeLast() {
    final result = this.last;
    if (result != null) {
      result.remove();
    }
    return result;
  }

  Iterable map(f(Element element)) => _filtered.map(f);
  Iterable<Element> where(bool f(Element element)) => _filtered.where(f);
  Iterable expand(Iterable f(Element element)) => _filtered.expand(f);

  void insert(int index, Element value) {
    _childNodes.insert(index, value);
  }

  void insertAll(int index, Iterable<Element> iterable) {
    _childNodes.insertAll(index, iterable);
  }

  Element removeAt(int index) {
    final result = this[index];
    result.remove();
    return result;
  }

  void remove(Object element) {
    if (element is! Element) return;
    for (int i = 0; i < length; i++) {
      Element indexElement = this[i];
      if (identical(indexElement, element)) {
        indexElement.remove();
        return;
      }
    }
  }


  Element reduce(Element combine(Element value, Element element)) {
    return _filtered.reduce(combine);
  }

  dynamic fold(dynamic initialValue,
      dynamic combine(dynamic previousValue, Element element)) {
    return _filtered.fold(initialValue, combine);
  }

  bool every(bool f(Element element)) => _filtered.every(f);
  bool any(bool f(Element element)) => _filtered.any(f);
  List<Element> toList({ bool growable: true }) =>
      new List<Element>.from(this, growable: growable);
  Set<Element> toSet() => new Set<Element>.from(this);
  Element firstWhere(bool test(Element value), {Element orElse()}) {
    return _filtered.firstWhere(test, orElse: orElse);
  }

  Element lastWhere(bool test(Element value), {Element orElse()}) {
    return _filtered.lastWhere(test, orElse: orElse);
  }

  Element singleWhere(bool test(Element value)) {
    return _filtered.singleWhere(test);
  }

  Element elementAt(int index) {
    return this[index];
  }

  bool get isEmpty => _filtered.isEmpty;
  int get length => _filtered.length;
  Element operator [](int index) => _filtered[index];
  Iterator<Element> get iterator => _filtered.iterator;
  List<Element> sublist(int start, [int end]) =>
    _filtered.sublist(start, end);
  Iterable<Element> getRange(int start, int end) =>
    _filtered.getRange(start, end);
  int indexOf(Element element, [int start = 0]) =>
    _filtered.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) {
    if (start == null) start = length - 1;
    return _filtered.lastIndexOf(element, start);
  }

  List<Element> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<Element> takeWhile(bool test(Element value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Element> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<Element> skipWhile(bool test(Element value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Element get first => _filtered.first;

  Element get last => _filtered.last;

  Element get single => _filtered.single;

  Element min([int compare(Element a, Element b)]) => _filtered.min(compare);

  Element max([int compare(Element a, Element b)]) => _filtered.max(compare);

  Map<int, Element> asMap() {
    return IterableMixinWorkaround.asMapList(this);
  }
}
