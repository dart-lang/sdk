// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API to get results from a static analysis of the source program.
// TODO(sigmund): split out implementations out of this file.
library compiler.src.stats.trusted_types_analysis_result;

import 'analysis_result.dart';
import '../tree/tree.dart' show Node;
import '../universe/selector.dart' show Selector;
import '../resolution/tree_elements.dart' show TreeElements;
import '../world.dart' show ClassWorld;
import '../dart_types.dart' show InterfaceType;

/// An [AnalysisResult] produced by using type-propagation based on
/// trusted type annotations.
class TrustTypesAnalysisResult implements AnalysisResult {
  final ClassWorld world;
  final TreeElements elements;

  TrustTypesAnalysisResult(this.elements, this.world);

  ReceiverInfo infoForReceiver(Node receiver) =>
    new TrustTypesReceiverInfo(receiver, elements.typesCache[receiver], world);
  SelectorInfo infoForSelector(Node receiver, Selector selector) =>
    new TrustTypesSelectorInfo(
        receiver, elements.typesCache[receiver], selector, world);
}

class _SelectorLookupResult {
  final Boolish exists;
  // TODO(sigmund): implement
  final Boolish usesInterceptor = Boolish.no;
  final int possibleTargets;

  _SelectorLookupResult(this.exists, this.possibleTargets);

  const _SelectorLookupResult.dontKnow()
    : exists = Boolish.maybe, possibleTargets = -1;
}

_SelectorLookupResult _lookupSelector(
    String selectorName, InterfaceType type, ClassWorld world) {
  if (type == null) return const _SelectorLookupResult.dontKnow();
  bool isNsm = selectorName == 'noSuchMethod';
  bool notFound = false;
  var uniqueTargets = new Set();
  for (var cls in world.subtypesOf(type.element)) {
    var member = cls.lookupMember(selectorName);
    if (member != null && !member.isAbstract
        // Don't match nsm in Object
        && (!isNsm || !member.enclosingClass.isObject)) {
      uniqueTargets.add(member);
    } else {
      notFound = true;
    }
  }
  Boolish exists = uniqueTargets.length > 0
        ? (notFound ? Boolish.maybe : Boolish.yes)
        : Boolish.no;
  return new _SelectorLookupResult(exists, uniqueTargets.length);
}

class TrustTypesReceiverInfo implements ReceiverInfo {
  final Node receiver;
  final Boolish hasNoSuchMethod;
  final int possibleNsmTargets;
  final Boolish isNull = Boolish.maybe;

  factory TrustTypesReceiverInfo(
      Node receiver, InterfaceType type, ClassWorld world) {
    // TODO(sigmund): refactor, maybe just store nsm as a SelectorInfo
    var res = _lookupSelector('noSuchMethod', type, world);
    return new TrustTypesReceiverInfo._(receiver,
        res.exists, res.possibleTargets);
  }

  TrustTypesReceiverInfo._(this.receiver, this.hasNoSuchMethod,
      this.possibleNsmTargets);
}

class TrustTypesSelectorInfo implements SelectorInfo {
  final Node receiver;
  final Selector selector;

  final Boolish exists;
  final Boolish usesInterceptor;
  final int possibleTargets;
  final bool isAccurate;

  factory TrustTypesSelectorInfo(Node receiver, InterfaceType type,
      Selector selector, ClassWorld world) {
    var res = _lookupSelector(
        selector != null ? selector.name : null, type, world);
    return new TrustTypesSelectorInfo._(receiver, selector, res.exists,
        res.usesInterceptor, res.possibleTargets,
        res.exists != Boolish.maybe);
  }
  TrustTypesSelectorInfo._(
      this.receiver, this.selector, this.exists, this.usesInterceptor,
      this.possibleTargets, this.isAccurate);
}

