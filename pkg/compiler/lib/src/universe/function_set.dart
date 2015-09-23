// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe.function_set;

import '../common/names.dart' show
    Identifiers,
    Selectors;
import '../compiler.dart' show
    Compiler;
import '../elements/elements.dart';
import '../types/types.dart';
import '../util/util.dart' show
    Hashing,
    Setlet;
import '../world.dart' show
    ClassWorld;

import 'selector.dart' show
    Selector;

// TODO(kasperl): This actually holds getters and setters just fine
// too and stricly they aren't functions. Maybe this needs a better
// name -- something like ElementSet seems a bit too generic.
class FunctionSet {
  final Compiler compiler;
  final Map<String, FunctionSetNode> nodes =
      new Map<String, FunctionSetNode>();
  FunctionSet(this.compiler);

  ClassWorld get classWorld => compiler.world;

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

  /// Returns an object that allows iterating over all the functions
  /// that may be invoked with the given [selector].
  Iterable<Element> filter(Selector selector, TypeMask mask) {
    return query(selector, mask).functions;
  }

  /// Returns the mask for the potential receivers of a dynamic call to
  /// [selector] on [mask].
  ///
  /// This will reduce the set of classes in [mask] to a [TypeMask] of the set
  /// of classes that actually implement the selected member or implement the
  /// handling 'noSuchMethod' where the selected member is unimplemented.
  TypeMask receiverType(Selector selector, TypeMask mask) {
    return query(selector, mask).computeMask(classWorld);
  }

  SelectorMask _createSelectorMask(
      Selector selector, TypeMask mask, ClassWorld classWorld) {
    return mask != null
        ? new SelectorMask(selector, mask)
        : new SelectorMask(selector,
            new TypeMask.subclass(classWorld.objectClass, classWorld));
  }

  /// Returns the set of functions that can be the target of a call to
  /// [selector] on a receiver of type [mask] including 'noSuchMethod' methods
  /// where applicable.
  FunctionSetQuery query(Selector selector, TypeMask mask) {
    String name = selector.name;
    SelectorMask selectorMask = _createSelectorMask(selector, mask, classWorld);
    SelectorMask noSuchMethodMask =
        new SelectorMask(Selectors.noSuchMethod_, selectorMask.mask);
    FunctionSetNode node = nodes[name];
    FunctionSetNode noSuchMethods = nodes[Identifiers.noSuchMethod_];
    if (node != null) {
      return node.query(
          selectorMask, classWorld, noSuchMethods, noSuchMethodMask);
    }
    // If there is no method that matches [selector] we know we can
    // only hit [:noSuchMethod:].
    if (noSuchMethods == null) {
      return const EmptyFunctionSetQuery();
    }
    return noSuchMethods.query(noSuchMethodMask, classWorld);
  }

  void forEach(Function action) {
    nodes.forEach((String name, FunctionSetNode node) {
      node.forEach(action);
    });
  }
}

/// A selector/mask pair representing the dynamic invocation of [selector] on
/// a receiver of type [mask].
class SelectorMask {
  final Selector selector;
  final TypeMask mask;
  final int hashCode;

  SelectorMask(Selector selector, TypeMask mask)
      : this.selector = selector,
        this.mask = mask,
        this.hashCode =
            Hashing.mixHashCodeBits(selector.hashCode, mask.hashCode) {
    assert(mask != null);
  }

  String get name => selector.name;

  bool applies(Element element, ClassWorld classWorld) {
    if (!selector.appliesUnnamed(element, classWorld)) return false;
    return mask.canHit(element, selector, classWorld);
  }

  bool needsNoSuchMethodHandling(ClassWorld classWorld) {
    return mask.needsNoSuchMethodHandling(selector, classWorld);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    return selector == other.selector && mask == other.mask;
  }

  String toString() => '($selector,$mask)';
}

/// A node in the [FunctionSet] caching all [FunctionSetQuery] object for
/// selectors with the same [name].
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

  /// Returns the set of functions that can be the target of [selectorMask]
  /// including no such method handling where applicable.
  FunctionSetQuery query(SelectorMask selectorMask,
                         ClassWorld classWorld,
                         [FunctionSetNode noSuchMethods,
                          SelectorMask noSuchMethodMask]) {
    assert(selectorMask.name == name);
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
    if (noSuchMethods != null &&
        selectorMask.needsNoSuchMethodHandling(classWorld)) {
      FunctionSetQuery noSuchMethodQuery =
          noSuchMethods.query(noSuchMethodMask, classWorld);
      if (!noSuchMethodQuery.functions.isEmpty) {
        if (functions == null) {
          functions = new Setlet<Element>.from(noSuchMethodQuery.functions);
        } else {
          functions.addAll(noSuchMethodQuery.functions);
        }
      }
    }
    cache[selectorMask] = result = (functions != null)
        ? new FullFunctionSetQuery(functions)
        : const EmptyFunctionSetQuery();
    return result;
  }
}

/// A set of functions that are the potential targets of all call sites sharing
/// the same receiver mask and selector.
abstract class FunctionSetQuery {
  const FunctionSetQuery();

  /// Compute the type of all potential receivers of this function set.
  TypeMask computeMask(ClassWorld classWorld);

  /// Returns all potential targets of this function set.
  Iterable<Element> get functions;
}

class EmptyFunctionSetQuery implements FunctionSetQuery {
  const EmptyFunctionSetQuery();

  @override
  TypeMask computeMask(ClassWorld classWorld) => const TypeMask.nonNullEmpty();

  @override
  Iterable<Element> get functions => const <Element>[];
}

class FullFunctionSetQuery implements FunctionSetQuery {
  @override
  final Iterable<Element> functions;

  TypeMask _mask;

  FullFunctionSetQuery(this.functions);

  @override
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
}
