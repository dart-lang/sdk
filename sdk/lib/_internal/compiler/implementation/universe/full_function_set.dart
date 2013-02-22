// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of universe;

class FullFunctionSet extends FunctionSet {
  FullFunctionSet(Compiler compiler) : super(compiler);

  FunctionSetNode newNode(SourceString name)
      => new FullFunctionSetNode(name);

  // TODO(kasperl): This interface is a little bit weird and mostly
  // put here to illustrate how we can refine types. Returning a
  // selector seems weird because we're only really interested in the
  // receiver type information and the type kind.
  Selector refine(Selector selector) {
    SourceString name = selector.name;
    FunctionSetNode node = nodes[name];
    if (node == null) return null;
    FullFunctionSetQuery query = node.query(selector, compiler);

    // If the selector is already exact, then we cannot refine it
    // further. If the query isn't exact, it means that the exact
    // class didn't contain any mathing element.
    if (selector.typeKind == TypedSelectorKind.EXACT) {
      if (!query.isExact) return null;
      assert(selector.receiverType.element == query.classes[0]);
      return selector;
    }

    // If the query yields an exact class, we refine the selector.
    if (query.isExact) {
      ClassElement refinement = query.classes[0];
      DartType type = refinement.computeType(compiler);
      return new TypedSelector.exact(type, selector);
    }

    // Get the list of classes from the query. If the type information
    // cannot be represented in the selector, we avoid refining it.
    List<ClassElement> classes = query.classes;
    if (classes == null || classes.length != 1) return selector;
    if (classes.isEmpty) return null;

    // We found one non-exact class, so we try to refine the selector
    // to be of subclass kind. We take care to reuse the existing
    // selector if matching class.
    assert(classes.length == 1);
    ClassElement refinement = query.classes[0];
    if (selector.typeKind == TypedSelectorKind.SUBCLASS) {
      ClassElement existing = selector.receiverType.element;
      if (refinement == existing) return selector;
      assert(refinement.isSubclassOf(existing));
    }
    DartType type = refinement.computeType(compiler);
    return new TypedSelector.subclass(type, selector);
  }
}

class FullFunctionSetNode extends FunctionSetNode {
  // To cut down on the time we spend on computing type information
  // about the function holders, we limit the number of classes and
  // the number of steps it takes to compute them.
  static const int MAX_CLASSES = 4;
  static const int MAX_CLASSES_STEPS = 32;

  FullFunctionSetNode(SourceString name) : super(name);

  FunctionSetQuery newQuery(List<Element> functions,
                            Selector selector,
                            Compiler compiler) {
    List<ClassElement> classes = computeClasses(functions, compiler);
    bool isExact = (selector.typeKind == TypedSelectorKind.EXACT)
        || isExactClass(classes, compiler);
    return new FullFunctionSetQuery(functions, classes, isExact);
  }

  static List<ClassElement> computeClasses(List<Element> functions,
                                           Compiler compiler) {
    // TODO(kasperl): Check if any of the found classes may have a
    // non-throwing noSuchMethod implementation in a subclass instead
    // of always disabling the class list computation.
    if (compiler.enabledNoSuchMethod) return null;
    List<ClassElement> classes = <ClassElement>[];
    int budget = MAX_CLASSES_STEPS;
    L: for (Element element in functions) {
      ClassElement enclosing = element.getEnclosingClass();
      for (int i = 0; i < classes.length; i++) {
        if (--budget <= 0) {
          return null;
        } else if (enclosing.isSubclassOf(classes[i])) {
          continue L;
        } else if (classes[i].isSubclassOf(enclosing)) {
          classes[i] = enclosing;
          continue L;
        }
      }
      if (classes.length >= MAX_CLASSES) return null;
      classes.add(enclosing);
    }
    return classes;
  }

  static bool isExactClass(List<ClassElement> classes, Compiler compiler) {
    if (classes == null || classes.length != 1) return false;
    ClassElement single = classes[0];
    // Return true if the single class in our list does not have a
    // single instantiated subclass.
    Set<ClassElement> subtypes = compiler.world.subtypes[single];
    return subtypes == null
        || subtypes.every((ClassElement each) => !each.isSubclassOf(single));
  }
}

class FullFunctionSetQuery extends FunctionSetQuery {
  final List<ClassElement> classes;
  final bool isExact;
  FullFunctionSetQuery(List<Element> functions, this.classes, this.isExact)
      : super(functions);
}
