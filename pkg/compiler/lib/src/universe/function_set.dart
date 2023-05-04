// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe.function_set;

import '../common/names.dart' show Identifiers, Selectors;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../inferrer/abstract_value_domain.dart';
import '../util/util.dart' show Hashing, Setlet;
import 'selector.dart' show Selector;

// TODO(kasperl): This actually holds getters and setters just fine
// too and strictly they aren't functions. Maybe this needs a better
// name -- something like ElementSet seems a bit too generic.
class FunctionSet {
  final Map<String, FunctionSetNode> _publicNodes;
  final Map<Uri, Map<String, FunctionSetNode>> _privateNodes;

  factory FunctionSet(Iterable<MemberEntity> liveInstanceMembers) {
    Map<String, FunctionSetNode> publicNodes = {};
    Map<Uri, Map<String, FunctionSetNode>> privateNodes = {};
    for (MemberEntity member in liveInstanceMembers) {
      String name = member.name!;
      if (member.memberName.isPrivate) {
        final uri = member.memberName.uri!;
        ((privateNodes[uri] ??= {})[name] ??= FunctionSetNode()).add(member);
      } else {
        (publicNodes[name] ??= FunctionSetNode()).add(member);
      }
    }
    return FunctionSet.internal(publicNodes, privateNodes);
  }

  FunctionSet.internal(this._publicNodes, this._privateNodes);

  /// Returns all the functions that may be invoked with the [selector] on a
  /// receiver with the given [constraint]. The returned elements may include
  /// noSuchMethod handlers that are potential targets indirectly through the
  /// noSuchMethod mechanism.
  Iterable<MemberEntity> filter(
      Selector selector, AbstractValue? receiver, AbstractValueDomain domain) {
    return query(selector, receiver, domain).functions;
  }

  SelectorMask _createSelectorMask(
      Selector selector, AbstractValue? receiver, AbstractValueDomain domain) {
    return receiver != null
        ? SelectorMask(selector, receiver)
        : SelectorMask(selector, domain.dynamicType);
  }

  /// Returns the set of functions that can be the target of a call to
  /// [selector] on a receiver constrained by [constraint] including
  /// 'noSuchMethod' methods where applicable.
  FunctionSetQuery query(
      Selector selector, AbstractValue? receiver, AbstractValueDomain domain) {
    Name name = selector.memberName;
    SelectorMask selectorMask = _createSelectorMask(selector, receiver, domain);
    SelectorMask noSuchMethodMask =
        SelectorMask(Selectors.noSuchMethod_, selectorMask.receiver);
    FunctionSetNode? node;
    if (name.isPrivate) {
      final forUri = _privateNodes[name.uri];
      if (forUri != null) node = forUri[name.text];
    } else {
      node = _publicNodes[name.text];
    }
    FunctionSetNode? noSuchMethods = _publicNodes[Identifiers.noSuchMethod_];
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
            Hashing.mixHashCodeBits(selector.hashCode, receiver.hashCode);

  String get name => selector.name;

  /// Check that the mask applies to the element. Skip checking the name since
  /// this is called from [FunctionSet.query] which implicitly checks the name
  /// via the Map lookups.
  bool _applies(MemberEntity element, AbstractValueDomain domain) {
    if (!selector.appliesStructural(element)) {
      return false;
    }
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
  final Map<SelectorMask, FunctionSetQuery> cache = {};

  // Initially, we keep the elements in a list because it is more
  // compact than a hash set. Once we get enough elements, we change
  // the representation to be a set to get faster contains checks.
  static const int MAX_ELEMENTS_IN_LIST = 8;
  Iterable<MemberEntity> elements = [];
  bool isList = true;

  FunctionSetNode();

  void add(MemberEntity element) {
    // We try to avoid clearing the cache unless we have to. For that
    // reason we keep the explicit contains check even though the add
    // method ends up doing the work again (for sets).
    if (!elements.contains(element)) {
      if (isList && elements.length >= MAX_ELEMENTS_IN_LIST) {
        elements = elements.toSet();
        isList = false;
      }
      if (isList) {
        final list = elements as List<MemberEntity>;
        list.add(element);
      } else {
        final set = elements as Set<MemberEntity>;
        set.add(element);
      }
      if (!cache.isEmpty) cache.clear();
    }
  }

  void remove(MemberEntity element) {
    if (isList) {
      final list = elements as List<MemberEntity>;
      int index = list.indexOf(element);
      if (index < 0) return;
      MemberEntity last = list.removeLast();
      if (index != list.length) {
        list[index] = last;
      }
      if (!cache.isEmpty) cache.clear();
    } else {
      final set = elements as List<MemberEntity>;
      if (set.remove(element)) {
        // To avoid wobbling between the two representations, we do
        // not transition back to the list representation even if we
        // end up with few enough elements at this point.
        if (!cache.isEmpty) cache.clear();
      }
    }
  }

  bool contains(MemberEntity element) {
    return elements.contains(element);
  }

  void forEach(void action(MemberEntity member)) {
    elements.forEach(action);
  }

  /// Returns the set of functions that can be the target of [selectorMask]
  /// including no such method handling where applicable.
  FunctionSetQuery query(SelectorMask selectorMask, AbstractValueDomain domain,
      [FunctionSetNode? noSuchMethods, SelectorMask? noSuchMethodMask]) {
    FunctionSetQuery? result = cache[selectorMask];
    if (result != null) return result;

    Setlet<MemberEntity>? functions;
    for (MemberEntity element in elements) {
      if (selectorMask._applies(element, domain)) {
        // Defer the allocation of the functions set until we are
        // sure we need it. This allows us to return immutable empty
        // lists when the filtering produced no results.
        functions ??= Setlet();
        functions.add(element);
      }
    }

    // If we cannot ensure a method will be found at runtime, we also
    // add [noSuchMethod] implementations that apply to [mask] as
    // potential targets.
    if (noSuchMethods != null &&
        selectorMask.needsNoSuchMethodHandling(domain)) {
      // If [noSuchMethods] was provided then [noSuchMethodMask] should also
      // have been provided.
      FunctionSetQuery noSuchMethodQuery =
          noSuchMethods.query(noSuchMethodMask!, domain);
      if (!noSuchMethodQuery.functions.isEmpty) {
        functions ??= Setlet();
        functions.addAll(noSuchMethodQuery.functions);
      }
    }
    cache[selectorMask] = result = (functions != null)
        ? FullFunctionSetQuery(functions)
        : const EmptyFunctionSetQuery();
    return result;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
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

  /// Returns all potential targets of this function set.
  Iterable<MemberEntity> get functions;
}

class EmptyFunctionSetQuery implements FunctionSetQuery {
  const EmptyFunctionSetQuery();

  @override
  Iterable<MemberEntity> get functions => const [];

  @override
  String toString() => '<empty>';
}

class FullFunctionSetQuery implements FunctionSetQuery {
  @override
  final Iterable<MemberEntity> functions;

  FullFunctionSetQuery(this.functions);

  @override
  String toString() => 'FunctionSetQuery($functions)';
}
