// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe.function_set;

import '../common/names.dart' show Identifiers, Selectors;
import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../util/util.dart' show Hashing, Setlet;
import 'selector.dart' show Selector;

// TODO(kasperl): This actually holds getters and setters just fine
// too and stricly they aren't functions. Maybe this needs a better
// name -- something like ElementSet seems a bit too generic.
class FunctionSet {
  final Map<String, FunctionSetNode> _nodes;

  factory FunctionSet(Iterable<MemberEntity> liveInstanceMembers) {
    Map<String, FunctionSetNode> nodes = new Map<String, FunctionSetNode>();
    for (MemberEntity member in liveInstanceMembers) {
      String name = member.name;
      (nodes[name] ??= new FunctionSetNode(name)).add(member);
    }
    return new FunctionSet.internal(nodes);
  }

  FunctionSet.internal(this._nodes);

  bool contains(MemberEntity element) {
    assert(element.isInstanceMember);
    assert(!element.isAbstract);
    String name = element.name;
    FunctionSetNode node = _nodes[name];
    return (node != null) ? node.contains(element) : false;
  }

  /// Returns all the functions that may be invoked with the [selector] on a
  /// receiver with the given [constraint]. The returned elements may include
  /// noSuchMethod handlers that are potential targets indirectly through the
  /// noSuchMethod mechanism.
  Iterable<MemberEntity> filter(
      Selector selector, AbstractValue receiver, AbstractValueDomain domain) {
    return query(selector, receiver, domain).functions;
  }

  /// Returns the mask for the potential receivers of a dynamic call to
  /// [selector] on [constraint].
  ///
  /// This will narrow the constraints of [constraint] to a [TypeMask] of the
  /// set of classes that actually implement the selected member or implement
  /// the handling 'noSuchMethod' where the selected member is unimplemented.
  AbstractValue receiverType(
      Selector selector, AbstractValue receiver, AbstractValueDomain domain) {
    return query(selector, receiver, domain).computeMask(domain);
  }

  SelectorMask _createSelectorMask(
      Selector selector, AbstractValue receiver, AbstractValueDomain domain) {
    return receiver != null
        ? new SelectorMask(selector, receiver)
        : new SelectorMask(selector, domain.dynamicType);
  }

  /// Returns the set of functions that can be the target of a call to
  /// [selector] on a receiver constrained by [constraint] including
  /// 'noSuchMethod' methods where applicable.
  FunctionSetQuery query(
      Selector selector, AbstractValue receiver, AbstractValueDomain domain) {
    String name = selector.name;
    SelectorMask selectorMask = _createSelectorMask(selector, receiver, domain);
    SelectorMask noSuchMethodMask =
        new SelectorMask(Selectors.noSuchMethod_, selectorMask.receiver);
    FunctionSetNode node = _nodes[name];
    FunctionSetNode noSuchMethods = _nodes[Identifiers.noSuchMethod_];
    if (node != null) {
      return node.query(selectorMask, domain, noSuchMethods, noSuchMethodMask);
    }
    // If there is no method that matches [selector] we know we can
    // only hit [:noSuchMethod:].
    if (noSuchMethods == null) {
      return const EmptyFunctionSetQuery();
    }
    return noSuchMethods.query(noSuchMethodMask, domain);
  }

  void forEach(void action(MemberEntity member)) {
    _nodes.forEach((String name, FunctionSetNode node) {
      node.forEach(action);
    });
  }
}

/// A selector/constraint pair representing the dynamic invocation of [selector]
/// on a receiver constrained by [constraint].
class SelectorMask {
  final Selector selector;
  final AbstractValue receiver;
  @override
  final int hashCode;

  SelectorMask(this.selector, this.receiver)
      : this.hashCode =
            Hashing.mixHashCodeBits(selector.hashCode, receiver.hashCode) {
    assert(receiver != null);
  }

  String get name => selector.name;

  bool applies(MemberEntity element, AbstractValueDomain domain) {
    if (!selector.appliesUnnamed(element)) return false;
    return domain
        .isTargetingMember(receiver, element, selector.memberName)
        .isPotentiallyTrue;
  }

  bool needsNoSuchMethodHandling(AbstractValueDomain domain) {
    return domain
        .needsNoSuchMethodHandling(receiver, selector)
        .isPotentiallyTrue;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is SelectorMask &&
        selector == other.selector &&
        receiver == other.receiver;
  }

  @override
  String toString() => '($selector,$receiver)';
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
  Iterable<MemberEntity> elements = <MemberEntity>[];
  bool isList = true;

  FunctionSetNode(this.name);

  void add(MemberEntity element) {
    assert(element.name == name);
    // We try to avoid clearing the cache unless we have to. For that
    // reason we keep the explicit contains check even though the add
    // method ends up doing the work again (for sets).
    if (!elements.contains(element)) {
      if (isList && elements.length >= MAX_ELEMENTS_IN_LIST) {
        elements = elements.toSet();
        isList = false;
      }
      if (isList) {
        List<MemberEntity> list = elements;
        list.add(element);
      } else {
        Set<MemberEntity> set = elements;
        set.add(element);
      }
      if (!cache.isEmpty) cache.clear();
    }
  }

  void remove(MemberEntity element) {
    assert(element.name == name);
    if (isList) {
      List<MemberEntity> list = elements;
      int index = list.indexOf(element);
      if (index < 0) return;
      MemberEntity last = list.removeLast();
      if (index != list.length) {
        list[index] = last;
      }
      if (!cache.isEmpty) cache.clear();
    } else {
      Set<MemberEntity> set = elements;
      if (set.remove(element)) {
        // To avoid wobbling between the two representations, we do
        // not transition back to the list representation even if we
        // end up with few enough elements at this point.
        if (!cache.isEmpty) cache.clear();
      }
    }
  }

  bool contains(MemberEntity element) {
    assert(element.name == name);
    return elements.contains(element);
  }

  void forEach(void action(MemberEntity member)) {
    elements.forEach(action);
  }

  /// Returns the set of functions that can be the target of [selectorMask]
  /// including no such method handling where applicable.
  FunctionSetQuery query(SelectorMask selectorMask, AbstractValueDomain domain,
      [FunctionSetNode noSuchMethods, SelectorMask noSuchMethodMask]) {
    assert(selectorMask.name == name);
    FunctionSetQuery result = cache[selectorMask];
    if (result != null) return result;

    Setlet<MemberEntity> functions;
    for (MemberEntity element in elements) {
      if (selectorMask.applies(element, domain)) {
        if (functions == null) {
          // Defer the allocation of the functions set until we are
          // sure we need it. This allows us to return immutable empty
          // lists when the filtering produced no results.
          functions = new Setlet<MemberEntity>();
        }
        functions.add(element);
      }
    }

    // If we cannot ensure a method will be found at runtime, we also
    // add [noSuchMethod] implementations that apply to [mask] as
    // potential targets.
    if (noSuchMethods != null &&
        selectorMask.needsNoSuchMethodHandling(domain)) {
      FunctionSetQuery noSuchMethodQuery =
          noSuchMethods.query(noSuchMethodMask, domain);
      if (!noSuchMethodQuery.functions.isEmpty) {
        if (functions == null) {
          functions =
              new Setlet<MemberEntity>.from(noSuchMethodQuery.functions);
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

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('FunctionSetNode(');
    String comma = '';
    cache.forEach((mask, query) {
      sb.write(comma);
      sb.write('$mask=$query');
      comma = ',';
    });
    sb.write(')');
    return sb.toString();
  }
}

/// A set of functions that are the potential targets of all call sites sharing
/// the same receiver mask and selector.
abstract class FunctionSetQuery {
  const FunctionSetQuery();

  /// Compute the type of all potential receivers of this function set.
  AbstractValue computeMask(AbstractValueDomain domain);

  /// Returns all potential targets of this function set.
  Iterable<MemberEntity> get functions;
}

class EmptyFunctionSetQuery implements FunctionSetQuery {
  const EmptyFunctionSetQuery();

  @override
  AbstractValue computeMask(AbstractValueDomain domain) => domain.emptyType;

  @override
  Iterable<MemberEntity> get functions => const <MemberEntity>[];

  @override
  String toString() => '<empty>';
}

class FullFunctionSetQuery implements FunctionSetQuery {
  @override
  final Iterable<MemberEntity> functions;

  AbstractValue _receiver;

  FullFunctionSetQuery(this.functions);

  @override
  AbstractValue computeMask(AbstractValueDomain domain) {
    return _receiver ??= domain.computeReceiver(functions);
  }

  @override
  String toString() => '$_receiver:$functions';
}
