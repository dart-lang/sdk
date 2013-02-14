// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of universe;

// TODO(kasperl): This actually holds getters and setters just fine
// too and stricly they aren't functions. Maybe this needs a better
// name -- something like ElementSet seems a bit too generic.
class FunctionSet {
  final Compiler compiler;
  final Map<SourceString, FunctionSetNode> nodes =
      new Map<SourceString, FunctionSetNode>();
  FunctionSet(this.compiler);

  void add(Element element) {
    assert(element.isMember());
    SourceString name = element.name;
    FunctionSetNode node = nodes.putIfAbsent(
        name, () => new FunctionSetNode(name));
    node.add(element);
  }

  void remove(Element element) {
    assert(element.isMember());
    SourceString name = element.name;
    FunctionSetNode node = nodes[name];
    if (node != null) {
      node.remove(element);
    }
  }

  bool contains(Element element) {
    assert(element.isMember());
    SourceString name = element.name;
    FunctionSetNode node = nodes[name];
    return (node != null)
        ? node.contains(element)
        : false;
  }

  /**
   * Returns all elements that may be invoked with the given [selector].
   */
  Iterable<Element> filterBySelector(Selector selector) {
    SourceString name = selector.name;
    FunctionSetNode node = nodes[name];
    return (node != null)
        ? node.filter(selector, compiler)
        : const <Element>[];
  }

  /**
   * Returns whether the set has any element matching the given
   * [selector].
   */
  bool hasAnyElementMatchingSelector(Selector selector) {
    return !filterBySelector(selector).isEmpty;
  }

  void forEach(Function action) {
    nodes.forEach((SourceString name, FunctionSetNode node) {
      node.forEach(action);
    });
  }
}

class FunctionSetNode {
  final SourceString name;
  final Map<Selector, List<Element>> cache = new Map<Selector, List<Element>>();

  // Initially, we keep the elements in a list because it is more
  // compact than a hash set. Once we get enough elements, we change
  // the representation to be a set to get faster contains checks.
  static const int MAX_ELEMENTS_IN_LIST = 8;
  Collection<Element> elements = <Element>[];
  bool isList = true;

  FunctionSetNode(this.name);

  void add(Element element) {
    assert(element.name == name);
    // We try to avoid clearing the cache unless we have to. For that
    // reason we keep the explicit contains check even though the add
    // method ends up doing the work again (for sets).
    if (!elements.contains(element)) {
      if (isList && elements.length >= MAX_ELEMENTS_IN_LIST) {
        elements = elements.toSet();
        isList = false;
      }
      elements.add(element);
      if (!cache.isEmpty) cache.clear();
    }
  }

  void remove(Element element) {
    assert(element.name == name);
    if (isList) {
      List list = elements;
      int index = list.indexOf(element);
      if (index < 0) return;
      Element last = list.removeLast();
      if (index != list.length) {
        list[index] = last;
      }
      if (!cache.isEmpty) cache.clear();
    } else {
      Set set = elements;
      if (set.remove(element)) {
        // To avoid wobbling between the two representations, we do
        // not transition back to the list representation even if we
        // end up with few enough elements at this point.
        if (!cache.isEmpty) cache.clear();
      }
    }
  }

  bool contains(Element element) {
    assert(element.name == name);
    return elements.contains(element);
  }

  void forEach(Function action) {
    elements.forEach(action);
  }

  Iterable<Element> filter(Selector selector, Compiler compiler) {
    assert(selector.name == name);
    List<Element> result = cache[selector];
    if (result != null) return result;
    for (Element element in elements) {
      if (selector.appliesUnnamed(element, compiler)) {
        if (result == null) {
          // Defer the allocation of the resulting list until we are
          // sure we need it. This allows us to return immutable empty
          // lists when the filtering produced no results.
          result = <Element>[];
        }
        result.add(element);
      }
    }
    if (result == null) result = const <Element>[];
    cache[selector] = result;
    return result;
  }
}
