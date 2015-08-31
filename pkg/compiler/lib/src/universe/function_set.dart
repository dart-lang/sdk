// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of universe;

// TODO(kasperl): This actually holds getters and setters just fine
// too and stricly they aren't functions. Maybe this needs a better
// name -- something like ElementSet seems a bit too generic.
class FunctionSet {
  final Compiler compiler;
  final Map<String, FunctionSetNode> nodes =
      new Map<String, FunctionSetNode>();
  FunctionSet(this.compiler);

  FunctionSetNode newNode(String name)
      => new FunctionSetNode(name);

  void add(Element element) {
    assert(element.isInstanceMember);
    assert(!element.isAbstract);
    String name = element.name;
    FunctionSetNode node = nodes.putIfAbsent(name, () => newNode(name));
    node.add(element);
  }

  void remove(Element element) {
    assert(element.isInstanceMember);
    assert(!element.isAbstract);
    String name = element.name;
    FunctionSetNode node = nodes[name];
    if (node != null) {
      node.remove(element);
    }
  }

  bool contains(Element element) {
    assert(element.isInstanceMember);
    assert(!element.isAbstract);
    String name = element.name;
    FunctionSetNode node = nodes[name];
    return (node != null)
        ? node.contains(element)
        : false;
  }

  /**
   * Returns an object that allows iterating over all the functions
   * that may be invoked with the given [selector].
   */
  Iterable<Element> filter(Selector selector, TypeMask mask) {
    return query(selector, mask).functions;
  }

  TypeMask receiverType(Selector selector, TypeMask mask) {
    return query(selector, mask).computeMask(compiler.world);
  }

  FunctionSetQuery query(Selector selector, TypeMask mask) {
    String name = selector.name;
    FunctionSetNode node = nodes[name];
    FunctionSetNode noSuchMethods = nodes[Compiler.NO_SUCH_METHOD];
    if (node != null) {
      return node.query(selector, mask, compiler, noSuchMethods);
    }
    // If there is no method that matches [selector] we know we can
    // only hit [:noSuchMethod:].
    if (noSuchMethods == null) return const FunctionSetQuery(const <Element>[]);
    return noSuchMethods.query(
        compiler.noSuchMethodSelector, mask, compiler, null);
  }

  void forEach(Function action) {
    nodes.forEach((String name, FunctionSetNode node) {
      node.forEach(action);
    });
  }
}

class SelectorMask {
  final Selector selector;
  final TypeMask mask;
  final int hashCode;

  SelectorMask(Selector selector, TypeMask mask)
      : this.selector = selector,
        this.mask = mask,
        this.hashCode =
            Hashing.mixHashCodeBits(selector.hashCode, mask.hashCode);

  String get name => selector.name;

  bool applies(Element element, ClassWorld classWorld) {
    if (!selector.appliesUnnamed(element, classWorld)) return false;
    if (mask == null) return true;
    return mask.canHit(element, selector, classWorld);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    return selector == other.selector && mask == other.mask;
  }

  String toString() => '($selector,$mask)';
}

class FunctionSetNode {
  final String name;
  final Map<SelectorMask, FunctionSetQuery> cache =
      <SelectorMask, FunctionSetQuery>{};

  // Initially, we keep the elements in a list because it is more
  // compact than a hash set. Once we get enough elements, we change
  // the representation to be a set to get faster contains checks.
  static const int MAX_ELEMENTS_IN_LIST = 8;
  var elements = <Element>[];
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

  TypeMask getNonNullTypeMaskOfSelector(TypeMask mask, ClassWorld classWorld) {
    // TODO(ngeoffray): We should probably change untyped selector
    // to always be a subclass of Object.
    return mask != null
        ? mask
        : new TypeMask.subclass(classWorld.objectClass, classWorld);
    }

  // TODO(johnniwinther): Use [SelectorMask] instead of [Selector] and
  // [TypeMask].
  FunctionSetQuery query(Selector selector,
                         TypeMask mask,
                         Compiler compiler,
                         FunctionSetNode noSuchMethods) {
    mask = getNonNullTypeMaskOfSelector(mask, compiler.world);
    SelectorMask selectorMask = new SelectorMask(selector, mask);
    ClassWorld classWorld = compiler.world;
    assert(selector.name == name);
    FunctionSetQuery result = cache[selectorMask];
    if (result != null) return result;

    Setlet<Element> functions;
    for (Element element in elements) {
      if (selectorMask.applies(element, classWorld)) {
        if (functions == null) {
          // Defer the allocation of the functions set until we are
          // sure we need it. This allows us to return immutable empty
          // lists when the filtering produced no results.
          functions = new Setlet<Element>();
        }
        functions.add(element);
      }
    }

    // If we cannot ensure a method will be found at runtime, we also
    // add [noSuchMethod] implementations that apply to [mask] as
    // potential targets.
    if (noSuchMethods != null
        && mask.needsNoSuchMethodHandling(selector, classWorld)) {
      FunctionSetQuery noSuchMethodQuery = noSuchMethods.query(
          compiler.noSuchMethodSelector,
          mask,
          compiler,
          null);
      if (!noSuchMethodQuery.functions.isEmpty) {
        if (functions == null) {
          functions = new Setlet<Element>.from(noSuchMethodQuery.functions);
        } else {
          functions.addAll(noSuchMethodQuery.functions);
        }
      }
    }
    cache[selectorMask] = result = (functions != null)
        ? newQuery(functions, selector, mask, compiler)
        : const FunctionSetQuery(const <Element>[]);
    return result;
  }

  FunctionSetQuery newQuery(Iterable<Element> functions,
                            Selector selector,
                            TypeMask mask,
                            Compiler compiler) {
    return new FullFunctionSetQuery(functions);
  }
}

class FunctionSetQuery {
  final Iterable<Element> functions;
  TypeMask computeMask(ClassWorld classWorld) => const TypeMask.nonNullEmpty();
  const FunctionSetQuery(this.functions);
}

class FullFunctionSetQuery extends FunctionSetQuery {
  TypeMask _mask;

  /**
   * Compute the type of all potential receivers of this function set.
   */
  TypeMask computeMask(ClassWorld classWorld) {
    assert(classWorld.hasAnyStrictSubclass(classWorld.objectClass));
    if (_mask != null) return _mask;
    return _mask = new TypeMask.unionOf(functions
        .expand((element) {
          ClassElement cls = element.enclosingClass;
          return [cls]..addAll(classWorld.mixinUsesOf(cls));
        })
        .map((cls) {
          if (classWorld.backend.isNullImplementation(cls)) {
            return const TypeMask.empty();
          } else {
            return new TypeMask.nonNullSubclass(cls.declaration, classWorld);
          }
        }),
        classWorld);
  }

  FullFunctionSetQuery(functions) : super(functions);
}
