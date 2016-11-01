// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe.function_set;

import '../common/names.dart' show Identifiers, Selectors;
import '../compiler.dart' show Compiler;
import '../elements/elements.dart';
import '../types/types.dart';
import '../util/util.dart' show Hashing, Setlet;
import '../world.dart' show ClosedWorld;
import 'selector.dart' show Selector;
import 'world_builder.dart' show ReceiverConstraint;

// TODO(kasperl): This actually holds getters and setters just fine
// too and stricly they aren't functions. Maybe this needs a better
// name -- something like ElementSet seems a bit too generic.
class FunctionSet {
  final Compiler compiler;
  final Map<String, FunctionSetNode> nodes = new Map<String, FunctionSetNode>();
  FunctionSet(this.compiler);

  ClosedWorld get closedWorld => compiler.closedWorld;

  FunctionSetNode newNode(String name) => new FunctionSetNode(name);

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
    return (node != null) ? node.contains(element) : false;
  }

  /// Returns all the functions that may be invoked with the [selector] on a
  /// receiver with the given [constraint]. The returned elements may include
  /// noSuchMethod handlers that are potential targets indirectly through the
  /// noSuchMethod mechanism.
  Iterable<Element> filter(Selector selector, ReceiverConstraint constraint) {
    return query(selector, constraint).functions;
  }

  /// Returns the mask for the potential receivers of a dynamic call to
  /// [selector] on [constraint].
  ///
  /// This will narrow the constraints of [constraint] to a [TypeMask] of the
  /// set of classes that actually implement the selected member or implement
  /// the handling 'noSuchMethod' where the selected member is unimplemented.
  TypeMask receiverType(Selector selector, ReceiverConstraint constraint) {
    return query(selector, constraint).computeMask(closedWorld);
  }

  SelectorMask _createSelectorMask(Selector selector,
      ReceiverConstraint constraint, ClosedWorld closedWorld) {
    return constraint != null
        ? new SelectorMask(selector, constraint)
        : new SelectorMask(
            selector,
            new TypeMask.subclass(
                closedWorld.coreClasses.objectClass, closedWorld));
  }

  /// Returns the set of functions that can be the target of a call to
  /// [selector] on a receiver constrained by [constraint] including
  /// 'noSuchMethod' methods where applicable.
  FunctionSetQuery query(Selector selector, ReceiverConstraint constraint) {
    String name = selector.name;
    SelectorMask selectorMask =
        _createSelectorMask(selector, constraint, closedWorld);
    SelectorMask noSuchMethodMask =
        new SelectorMask(Selectors.noSuchMethod_, selectorMask.constraint);
    FunctionSetNode node = nodes[name];
    FunctionSetNode noSuchMethods = nodes[Identifiers.noSuchMethod_];
    if (node != null) {
      return node.query(
          selectorMask, closedWorld, noSuchMethods, noSuchMethodMask);
    }
    // If there is no method that matches [selector] we know we can
    // only hit [:noSuchMethod:].
    if (noSuchMethods == null) {
      return const EmptyFunctionSetQuery();
    }
    return noSuchMethods.query(noSuchMethodMask, closedWorld);
  }

  void forEach(Function action) {
    nodes.forEach((String name, FunctionSetNode node) {
      node.forEach(action);
    });
  }
}

/// A selector/constraint pair representing the dynamic invocation of [selector]
/// on a receiver constrained by [constraint].
class SelectorMask {
  final Selector selector;
  final ReceiverConstraint constraint;
  final int hashCode;

  SelectorMask(Selector selector, ReceiverConstraint constraint)
      : this.selector = selector,
        this.constraint = constraint,
        this.hashCode =
            Hashing.mixHashCodeBits(selector.hashCode, constraint.hashCode) {
    assert(constraint != null);
  }

  String get name => selector.name;

  bool applies(Element element, ClosedWorld closedWorld) {
    if (!selector.appliesUnnamed(element)) return false;
    return constraint.canHit(element, selector, closedWorld);
  }

  bool needsNoSuchMethodHandling(ClosedWorld closedWorld) {
    return constraint.needsNoSuchMethodHandling(selector, closedWorld);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    return selector == other.selector && constraint == other.constraint;
  }

  String toString() => '($selector,$constraint)';
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
  FunctionSetQuery query(SelectorMask selectorMask, ClosedWorld closedWorld,
      [FunctionSetNode noSuchMethods, SelectorMask noSuchMethodMask]) {
    assert(selectorMask.name == name);
    FunctionSetQuery result = cache[selectorMask];
    if (result != null) return result;

    Setlet<Element> functions;
    for (Element element in elements) {
      if (selectorMask.applies(element, closedWorld)) {
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
        selectorMask.needsNoSuchMethodHandling(closedWorld)) {
      FunctionSetQuery noSuchMethodQuery =
          noSuchMethods.query(noSuchMethodMask, closedWorld);
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
  TypeMask computeMask(ClosedWorld closedWorld);

  /// Returns all potential targets of this function set.
  Iterable<Element> get functions;
}

class EmptyFunctionSetQuery implements FunctionSetQuery {
  const EmptyFunctionSetQuery();

  @override
  TypeMask computeMask(ClosedWorld closedWorld) =>
      const TypeMask.nonNullEmpty();

  @override
  Iterable<Element> get functions => const <Element>[];
}

class FullFunctionSetQuery implements FunctionSetQuery {
  @override
  final Iterable<Element> functions;

  TypeMask _mask;

  FullFunctionSetQuery(this.functions);

  @override
  TypeMask computeMask(ClosedWorld closedWorld) {
    assert(
        closedWorld.hasAnyStrictSubclass(closedWorld.coreClasses.objectClass));
    if (_mask != null) return _mask;
    return _mask = new TypeMask.unionOf(
        functions.expand((element) {
          ClassElement cls = element.enclosingClass;
          return [cls]..addAll(closedWorld.mixinUsesOf(cls));
        }).map((cls) {
          if (closedWorld.backendClasses.nullImplementation == cls) {
            return const TypeMask.empty();
          } else if (closedWorld.isInstantiated(cls.declaration)) {
            return new TypeMask.nonNullSubclass(cls.declaration, closedWorld);
          } else {
            // TODO(johnniwinther): Avoid the need for this case.
            return const TypeMask.empty();
          }
        }),
        closedWorld);
  }
}
