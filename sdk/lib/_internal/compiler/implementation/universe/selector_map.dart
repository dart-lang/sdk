// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of universe;

class SelectorMap<T> {
  final Compiler compiler;
  final Map<SourceString, SelectorMapNode<T>> nodes =
      new Map<SourceString, SelectorMapNode<T>>();
  SelectorMap(this.compiler);

  T operator [](Selector selector) {
    SourceString name = selector.name;
    SelectorMapNode node = nodes[name];
    return (node != null)
        ? node.lookup(selector)
        : null;
  }

  void operator []=(Selector selector, T value) {
    SourceString name = selector.name;
    SelectorMapNode node = nodes.putIfAbsent(
        name, () => new SelectorMapNode(name));
    node.update(selector, value);
  }

  bool containsKey(Selector selector) {
    SourceString name = selector.name;
    SelectorMapNode node = nodes[name];
    return (node != null)
        ? node.containsKey(selector)
        : false;
  }

  T remove(Selector selector) {
    SourceString name = selector.name;
    SelectorMapNode node = nodes[name];
    return (node != null)
        ? node.remove(selector)
        : null;
  }

  /**
   * Visits all mappings for selectors that may be used to invoke the
   * given [member] element. If the [visit] function ever returns false,
   * we abort the traversal early.
   */
  void visitMatching(Element member, bool visit(Selector selector, T value)) {
    assert(member.isMember());
    SourceString name = member.name;
    SelectorMapNode node = nodes[name];
    if (node != null) {
      node.visitMatching(member, compiler, visit);
    }
  }
}

class SelectorMapNode<T> {
  final SourceString name;
  final Map<Selector, T> selectors = new Map<Selector, T>();

  // We start caching which selectors match which elements when the
  // number of different selectors exceed a threshold. This way we
  // avoid lots of repeated calls to the Selector.applies method.
  static const int MAX_SELECTORS_NO_CACHE = 8;
  Map<Element, List<Selector>> cache;

  SelectorMapNode(this.name);

  T lookup(Selector selector) {
    assert(selector.name == name);
    return selectors[selector];
  }

  void update(Selector selector, T value) {
    assert(selector.name == name);
    bool existing = selectors.containsKey(selector);
    selectors[selector] = value;
    if (existing) return;
    // The update has introduced a new selector in the map, so we need
    // to consider if we should start caching. At the very least, we
    // have to clear the cache because the new element may invalidate
    // existing cache entries.
    if (cache == null) {
      if (selectors.length > MAX_SELECTORS_NO_CACHE) {
        cache = new Map<Element, List<Selector>>();
      }
    } else if (!cache.isEmpty) {
      cache.clear();
    }
  }

  bool containsKey(Selector selector) {
    assert(selector.name == name);
    return selectors.containsKey(selector);
  }

  T remove(Selector selector) {
    assert(selector.name == name);
    if (!selectors.containsKey(selector)) return null;
    if (cache != null && !cache.isEmpty) cache.clear();
    return selectors.remove(selector);
  }

  void visitMatching(Element member, Compiler compiler,
                     bool visit(Selector selector, T value)) {
    assert(member.name == name);
    Iterable<Selector> matching = computeMatching(member, compiler);
    for (Selector selector in matching) {
      if (!visit(selector, selectors[selector])) return;
    }
  }

  Iterable<Selector> computeMatching(Element member, Compiler compiler) {
    // Probe the cache if it exists. Do this before creating the
    // matching iterable to cut down on the overhead for cache hits.
    if (cache != null) {
      List<Selector> cached = cache[member];
      if (cached != null) return cached;
    }
    // Filter the selectors keys so we only have the ones that apply
    // to the given member element.
    Iterable<Selector> matching = selectors.keys.where(
        (Selector selector) => selector.appliesUnnamed(member, compiler));
    if (cache == null) return matching;
    return cache[member] = matching.toList();
  }
}
