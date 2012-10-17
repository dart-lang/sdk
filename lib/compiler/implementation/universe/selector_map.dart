// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SelectorMap<T> extends PartialTypeTree {

  SelectorMap(Compiler compiler) : super(compiler);

  SelectorMapNode<T> newSpecializedNode(ClassElement type)
      => new SelectorMapNode<T>(type);

  T operator [](Selector selector) {
    SelectorMapNode<T> node = findNode(selectorType(selector), false);
    if (node == null) return null;
    Link<SelectorValue<T>> selectors = node.selectorsByName[selector.name];
    if (selectors == null) return null;
    for (Link link = selectors; !link.isEmpty(); link = link.tail) {
      SelectorValue<T> existing = link.head;
      if (existing.selector.equalsUntyped(selector)) return existing.value;
    }
    return null;
  }

  void operator []=(Selector selector, T value) {
    SelectorMapNode<T> node = findNode(selectorType(selector), true);
    Link<SelectorValue<T>> selectors = node.selectorsByName[selector.name];
    if (selectors == null) {
      // No existing selectors with the given name. Create a new
      // linked list.
      SelectorValue<T> head = new SelectorValue<T>(selector, value);
      node.selectorsByName[selector.name] =
          new Link<SelectorValue<T>>().prepend(head);
    } else {
      // Run through the linked list of selectors with the same name. If
      // we find one that matches, we update the value in the mapping.
      for (Link link = selectors; !link.isEmpty(); link = link.tail) {
        SelectorValue<T> existing = link.head;
        // It is safe to ignore the type here, because all selector
        // mappings that are stored in a single node have the same type.
        if (existing.selector.equalsUntyped(selector)) {
          existing.value = value;
          return;
        }
      }
      // We could not find an existing mapping for the selector, so
      // we add a new one to the existing linked list.
      SelectorValue<T> head = new SelectorValue<T>(selector, value);
      node.selectorsByName[selector.name] = selectors.prepend(head);
    }
  }

  // TODO(kasperl): Share code with the [] operator?
  bool containsKey(Selector selector) {
    SelectorMapNode<T> node = findNode(selectorType(selector), false);
    if (node == null) return false;
    Link<SelectorValue<T>> selectors = node.selectorsByName[selector.name];
    if (selectors == null) return false;
    for (Link link = selectors; !link.isEmpty(); link = link.tail) {
      SelectorValue<T> existing = link.head;
      if (existing.selector.equalsUntyped(selector)) return true;
    }
    return false;
  }

  /**
   * Visits all mappings for selectors that may be used to invoke the
   * given [member] element. If the [visit] function ever returns false,
   * we abort the traversal early.
   */
  void visitMatching(Element member, bool visit(Selector selector, T value)) {
    assert(member.isMember());
    if (root == null) return;
    // TODO(kasperl): For now, we use a different implementation for
    // visiting if the tree contains interface subtypes.
    if (containsInterfaceSubtypes) {
      visitAllMatching(member, visit);
    } else {
      visitHierarchyMatching(member, visit);
    }
  }

  void visitAllMatching(Element member, bool visit(selector, value)) {
    root.visitRecursively((SelectorMapNode<T> node) {
      Link<SelectorValue<T>> selectors = node.selectorsByName[member.name];
      if (selectors == null) return true;
      for (Link link = selectors; !link.isEmpty(); link = link.tail) {
        SelectorValue<T> existing = link.head;
        Selector selector = existing.selector;
        // Since we're running through the entire tree we have to use
        // the applies method that takes types into account.
        if (selector.applies(member, compiler)) {
          if (!visit(selector, existing.value)) return false;
        }
      }
      return true;
    });
  }

  void visitHierarchyMatching(Element member, bool visit(selector, value)) {
    visitHierarchy(member.getEnclosingClass(), (SelectorMapNode<T> node) {
      Link<SelectorValue<T>> selectors = node.selectorsByName[member.name];
      if (selectors == null) return true;
      for (Link link = selectors; !link.isEmpty(); link = link.tail) {
        SelectorValue<T> existing = link.head;
        Selector selector = existing.selector;
        if (selector.appliesUntyped(member, compiler)) {
          if (!visit(selector, existing.value)) return false;
        }
      }
      return true;
    });
  }

}

class SelectorMapNode<T> extends PartialTypeTreeNode {

  final Map<SourceString, Link<SelectorValue<T>>> selectorsByName;

  SelectorMapNode(ClassElement type) : super(type),
      selectorsByName = new Map<SourceString, Link<SelectorValue<T>>>();

}

class SelectorValue<T> {
  final Selector selector;
  T value;
  SelectorValue(this.selector, this.value);
  toString() => "$selector -> $value";
}
