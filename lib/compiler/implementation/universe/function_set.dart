// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(kasperl): This actually holds getters and setters just fine
// too and stricly they aren't functions. Maybe this needs a better
// name -- something like ElementSet seems a bit too generic.
class FunctionSet extends PartialTypeTree {

  FunctionSet(Compiler compiler) : super(compiler);

  FunctionSetNode newSpecializedNode(ClassElement type)
      => new FunctionSetNode(type);

  // TODO(kasperl): Allow static members too?
  void add(Element element) {
    assert(element.isMember());
    FunctionSetNode node = findNode(element.getEnclosingClass(), true);
    node.membersByName[element.name] = element;
  }

  // TODO(kasperl): Allow static members too?
  void remove(Element element) {
    assert(element.isMember());
    FunctionSetNode node = findNode(element.getEnclosingClass(), false);
    if (node !== null) node.membersByName.remove(element.name);
  }

  // TODO(kasperl): Allow static members too?
  bool contains(Element element) {
    assert(element.isMember());
    FunctionSetNode node = findNode(element.getEnclosingClass(), false);
    return (node !== null)
        ? node.membersByName.containsKey(element.name)
        : false;
  }

  /**
   * Returns all elements that may be invoked with the given [selector].
   */
  Set<Element> filterBySelector(Selector selector) {
    // TODO(kasperl): For now, we use a different implementation for
    // filtering if the tree contains interface subtypes.
    return containsInterfaceSubtypes
        ? filterAllBySelector(selector)
        : filterHierarchyBySelector(selector);
  }

  Set<Element> filterAllBySelector(Selector selector) {
    Set<Element> result = new Set<Element>();
    if (root === null) return result;
    root.visitRecursively((FunctionSetNode node) {
      Element member = node.membersByName[selector.name];
      // Since we're running through the entire tree we have to use
      // the applies method that takes types into account.
      if (member !== null && selector.applies(member, compiler)) {
        result.add(member);
      }
      return true;
    });
    return result;
  }

  Set<Element> filterHierarchyBySelector(Selector selector) {
    Set<Element> result = new Set<Element>();
    if (root === null) return result;
    visitHierarchy(selectorType(selector), (FunctionSetNode node) {
      Element member = node.membersByName[selector.name];
      if (member !== null && selector.appliesUntyped(member, compiler)) {
        result.add(member);
      }
      return true;
    });
    return result;
  }

}

class FunctionSetNode extends PartialTypeTreeNode {

  final Map<SourceString, Element> membersByName;

  FunctionSetNode(ClassElement type) : super(type),
      membersByName = new Map<SourceString, Element>();

}
