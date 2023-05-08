// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/universe/function_set.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/util/util.dart';

class DynamicCallTarget {
  final MemberEntity member;
  final bool isVirtual;

  factory DynamicCallTarget.virtual(MemberEntity member) =>
      DynamicCallTarget(member, isVirtual: true);
  factory DynamicCallTarget.concrete(MemberEntity member) =>
      DynamicCallTarget(member, isVirtual: false);
  DynamicCallTarget(this.member, {required this.isVirtual});

  @override
  int get hashCode => Object.hash(member, isVirtual);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DynamicCallTarget &&
            member == other.member &&
            isVirtual == other.isVirtual);
  }

  @override
  String toString() => 'TargetResult($member, virtual: $isVirtual)';
}

/// Builds and maintains member override hierarchy for easy querying of targets
/// when refining call sites during type inference.
///
/// We introduce the idea of a [DynamicCallTarget] which can either target a
/// 'concrete' or 'virtual' member. A concrete member is one in which we know
/// the target member is being called directly. A virtual member is one in which
/// the call is to the target member or one of its overrides. Each member can
/// have 2 types in the type inference graph, to represent its concrete and
/// virtual versions. The type of a concrete member is based solely on the body
/// of the member. The type of a virtual member is a union of the types of
/// all its overrides. Abstract members only have virtual types since they do
/// not have bodies and cannot be invoked directly.
///
/// Init phase:
/// This class begins by processing all 'live' members, both abstract and not,
/// and constructing an override graph for these members. We track the direct
/// overrides of a member based on the class hierarchy. For every direct
/// override in this graph we also add edges into the type graph. One to join
/// the concrete and virtual version of a member and then one between its
/// virtual type and the virtual type of each direct override.
///
/// Example type flow:
/// ```
/// class A {
///   T foo(U arg) => ...;
/// }
///
/// class B extends A {
///   T foo(U arg) => ...;
/// }
/// ```
/// Parameter types flow to overrides:
/// A.fooConcrete#arg <- A.fooVirtual#arg -> B.fooVirtual#arg
///
/// Return types flow from overrides:
/// A.fooConcrete#Return -> A.fooVirtual#Return <- B.fooVirtual#Return
///
/// We also maintain a list of 'dynamic roots' for each possible selector we can
/// encounter. These dynamic roots are methods that are not overrides and
/// therefore are the minimal set of targets for a dynamic call to that
/// selector. This preprocessing makes handling dynamic calls very fast.
/// See [rootsForSelector].
///
/// Query phase:
/// For each query during type refinement we attempt to return as few targets as
/// possible to represent calls on a receiver type cone. We start by trying to
/// find the call that would be invoked if the call were on the root of the type
/// cone by finding a matching member on a superclass (or the class itself).
/// If we can find one then we determine if the call to this target would be
/// virtual or concrete. The call can be concrete if:
/// 1) The type cone is 'exact' so there is only one receiver class.
/// 2) The type cone is 'subclass' but none of subclasses in the cone override
///    the target.
/// 3) The target we found has no overrides so it must be the actual target.
/// See [findSuperclassTarget].
///
/// The above step produces a single target (virtual or concrete) reducing the
/// number of edges in the type graph. However, since our type masks lose some
/// precision as they get unioned, its possible that neither of those steps
/// finds a target. In these cases we finally iterate over the subclasses (or
/// subtypes for a subtype-cone) and find a set of targets that cover all
/// classes in the cone. See [findMatchingAncestors].
///
/// We handle receiver masks that include `null` as well as no such method
/// handling separately. See [rootsForCall].
///
/// All results returned from the query phase are cached on the pair of receiver
/// type and selector for use in subsequent queries.
class MemberHierarchyBuilder {
  final JClosedWorld closedWorld;
  final Map<SelectorMask, Iterable<DynamicCallTarget>> _callCache = {};
  final Map<Selector, Setlet<MemberEntity>> _dynamicRoots = {};
  final Map<MemberEntity, Setlet<MemberEntity>> _overrides = {};

  MemberHierarchyBuilder(this.closedWorld);

  /// Applies [f] to each override of [entity].
  ///
  /// If [f] returns `false` for a given input then iteration is immediately
  /// stopped and [f] is not called on any more members.
  void forEachOverride(
      MemberEntity entity, bool Function(MemberEntity override) f) {
    _forEachOverrideSkipVisited(entity, f, {entity});
  }

  /// Returns `true` if every target member represented by [target] satisfies
  /// the predicate [f].
  bool everyTargetMember(
      DynamicCallTarget target, bool Function(MemberEntity override) f) {
    bool result = true;
    forEachTargetMember(target, (member) {
      // We exit early on a false result here.
      return result = f(member);
    });
    return result;
  }

  /// Returns `true` if any target member represented by [target] satisfies the
  /// predicate [f].
  bool anyTargetMember(
      DynamicCallTarget target, bool Function(MemberEntity override) f) {
    bool result = false;
    forEachTargetMember(target, (member) {
      result = f(member);
      // We exit early on a true result here.
      return !result;
    });
    return result;
  }

  /// Applies [f] to each target represented by [target] including overrides
  /// if the call is virtual.
  ///
  /// If [f] returns `false` for a given input then iteration is immediately
  /// stopped and [f] is not called on any more members.
  void forEachTargetMember(
      DynamicCallTarget target, bool Function(MemberEntity override) f) {
    if (!f(target.member)) return;

    if (target.isVirtual) {
      forEachOverride(target.member, f);
    }
  }

  void _forEachOverrideSkipVisited(MemberEntity entity,
      bool Function(MemberEntity override) f, Set<MemberEntity> visited) {
    final overrides = _overrides[entity];
    if (overrides == null) return;
    for (final override in overrides) {
      if (!visited.add(override)) continue;
      if (!f(override)) return;
      _forEachOverrideSkipVisited(override, f, visited);
    }
  }

  /// Check to see if any override of [match] is a target for a subclass call on
  /// [cls]. If not then the call can be concrete rather than virtual.
  bool _subclassNeedsVirtual(MemberEntity match, ClassEntity cls) {
    bool needsVirtual = false;
    final classHierarchy = closedWorld.classHierarchy;
    forEachOverride(match, (override) {
      if (classHierarchy.isSubclassOf(override.enclosingClass!, cls) ||
          closedWorld.hasAnySubclassThatMixes(cls, override.enclosingClass!)) {
        needsVirtual = true;
        return false;
      }
      return true;
    });
    return needsVirtual;
  }

  /// Finds the first non-strict superclass of [cls] that contains a member
  /// matching [selector] and returns that member.
  ///
  /// Returns the first non-abstract match found while ascending the class
  /// hierarchy. If no non-abstract matches are found then the first abstract
  /// match is used.
  ///
  /// If [isExact] is true, the resulting [DynamicCallTarget] will be
  /// virtual when the match is non-abstract and has overrides.
  /// Otherwise the resulting [DynamicCallTarget] is concrete.
  ///
  /// For some selectors susceptible to degraded interceptor results,
  /// when [isSubclass] is true, this will return a set of concrete subclass
  /// targets rather than attempting to find a single virtual target.
  Iterable<DynamicCallTarget> findSuperclassTarget(
      ClassEntity cls, Selector selector,
      {bool isExact = false, bool isSubclass = false}) {
    MemberEntity? firstAbstractMatch;
    ClassEntity? current = cls;
    final elementEnv = closedWorld.elementEnvironment;
    while (current != null) {
      final match =
          elementEnv.lookupLocalClassMember(current, selector.memberName);
      if (match != null && !skipMember(match, selector)) {
        if (match.isAbstract) {
          firstAbstractMatch ??= match;
        } else {
          return [
            DynamicCallTarget(match,
                isVirtual: !isExact &&
                    _hasOverride(match) &&
                    (!isSubclass || _subclassNeedsVirtual(match, cls)))
          ];
        }
      }
      current = elementEnv.getSuperClass(current);
    }
    return firstAbstractMatch != null
        ? [DynamicCallTarget.virtual(firstAbstractMatch)]
        : const [];
  }

  /// For each subclass/subtype try to find a member matching selector.
  ///
  /// If we find a match then it covers the entire subtree below that match so
  /// we do not need to check subclasses/subtypes below it.
  Iterable<DynamicCallTarget> findMatchingAncestors(
      ClassEntity baseCls, Selector selector,
      {required bool isSubtype}) {
    final results = Setlet<DynamicCallTarget>();
    IterationStep handleEntity(entity) {
      final match = findSuperclassTarget(entity, selector);
      if (match.isNotEmpty) {
        results.addAll(match);
        return IterationStep.SKIP_SUBCLASSES;
      }
      return IterationStep.CONTINUE;
    }

    if (isSubtype) {
      closedWorld.classHierarchy.forEachStrictSubtypeOf(baseCls, handleEntity);
    } else {
      closedWorld.classHierarchy.forEachStrictSubclassOf(baseCls, handleEntity);
    }
    return results;
  }

  /// Returns the set of root member declarations for [selector]. [cls] acts as
  /// a subclass filter for these roots.
  ///
  /// The set of roots is the smallest set of members that are an ancestor of
  /// every implementation of [selector]. This is with the caveat that we
  /// consider each mixin application to declare a "copy" of each member of that
  /// mixin. They share the same [MemberEntity] but each copy is considered a
  /// separate potential root.
  Iterable<DynamicCallTarget> rootsForSelector(
      ClassEntity cls, Selector selector) {
    final roots = _dynamicRoots[_normalizeSelector(selector)];
    if (roots == null) return const [];
    final classHierarchy = closedWorld.classHierarchy;
    return Setlet.of(roots
        .where((r) =>
            selector.appliesStructural(r) &&
            classHierarchy.isSubclassOf(r.enclosingClass!, cls))
        .map((r) => DynamicCallTarget(r, isVirtual: _hasOverride(r))));
  }

  /// Returns a set of common ancestors (not necessarily the smallest) for all
  /// possible targets when calling [selector] on an object with type
  /// [receiverType].
  ///
  /// Caches results for each receiver/selector pair. If [receiverType] is
  /// `null` the receiver is considered dynamic and any member that matches
  /// [selector] is a possible target. Also adds relevant [noSuchMethod] and
  /// `null` targets if needed for the call.
  Iterable<DynamicCallTarget> rootsForCall(
      AbstractValue? receiverType, Selector selector) {
    final domain = closedWorld.abstractValueDomain;
    receiverType ??= domain.dynamicType;
    final selectorMask = SelectorMask(selector, receiverType);
    final cachedResult = _callCache[selectorMask];
    if (cachedResult != null) return cachedResult;

    Iterable<DynamicCallTarget> targetsForReceiver =
        domain.findRootsOfTargets(receiverType, selector, this);

    // TODO(natebiggs): Can we calculate this as part of the above call to
    // findRootsOfTargets?
    final needsNoSuchMethod = selector != Selectors.noSuchMethod_ &&
        domain
            .needsNoSuchMethodHandling(receiverType, selector)
            .isPotentiallyTrue;

    final isNull = domain.isNull(receiverType);

    if (isNull.isPotentiallyTrue) {
      // Add relevant member if null is a potential target.
      final nullMatch = closedWorld.elementEnvironment.lookupLocalClassMember(
          closedWorld.commonElements.jsNullClass, selector.memberName);
      if (nullMatch != null) {
        targetsForReceiver = {
          ...targetsForReceiver,
          DynamicCallTarget.concrete(nullMatch)
        };
      }
    }

    final result = needsNoSuchMethod
        ? Setlet.of(targetsForReceiver
            .followedBy(rootsForCall(receiverType, Selectors.noSuchMethod_)))
        : targetsForReceiver;

    return _callCache[selectorMask] = result;
  }

  /// Map call selectors to a getter with the same name. This allows us to
  /// ignore their call structure since overridden methods can have different
  /// call structures. This also handles method tear-offs.
  static Selector _normalizeSelector(Selector selector) =>
      selector.isCall ? Selector.getter(selector.memberName) : selector;

  static bool _skipMemberInternal(MemberEntity member) {
    return member.isStatic;
  }

  static bool skipMember(MemberEntity member, Selector selector) {
    return _skipMemberInternal(member) || !selector.appliesStructural(member);
  }

  bool _hasOverride(MemberEntity member) {
    return _overrides.containsKey(member);
  }

  static List<Selector> _selectorsForMember(MemberEntity member) {
    final List<Selector> result = [];
    if (member is FieldEntity) {
      // A field implicitly defines both a getter and setter. Each of these can
      // have different overrides so we consider them separately.
      result.add(Selector.getter(member.memberName));
      result.add(Selector.setter(member.memberName));
    } else {
      final selector = Selector.fromElement(member);
      result.add(_normalizeSelector(selector));
    }
    return result;
  }

  void _handleMember(MemberEntity member, ClassEntity cls, Selector selector,
      void Function(MemberEntity parent, MemberEntity override) join,
      {required bool isMixinUse}) {
    final elementEnv = closedWorld.elementEnvironment;
    final name = selector.memberName;
    bool foundSuperclass = false;

    void addParent(MemberEntity child, MemberEntity parent) {
      if (child == parent) return;
      if (!isMixinUse && (_overrides[parent] ??= Setlet()).add(child)) {
        join(parent, child);
      }

      // For mixins defining an abstract member, foo, implementations of foo
      // (either directly on the mixin target or superclasses of it) should
      // propagate their types to the abstract foo as they are effectively
      // overriding it. Calls to foo within the body of the mixin can only
      // target the abstract foo with a virtual call so that virtual target
      // needs to reflect the types of all its overrides.
      if (isMixinUse &&
          child.isAbstract &&
          (_overrides[child] ??= Setlet()).add(parent)) {
        join(child, parent);
      }
    }

    // Check each superclass in ascending order until we find an ancestor.
    ClassEntity? current = elementEnv.getSuperClass(cls);
    while (current != null) {
      final match = elementEnv.lookupLocalClassMember(current, name);
      if (match != null && !MemberHierarchyBuilder._skipMemberInternal(match)) {
        addParent(member, match);
        foundSuperclass = true;
        break;
      }
      current = elementEnv.getSuperClass(current);
    }

    closedWorld.classHierarchy.getClassSet(cls).forEachSubtype((subtype) {
      final override = elementEnv.lookupClassMember(subtype, name);
      if (override != null) addParent(override, member);
      return IterationStep.CONTINUE;
    }, ClassHierarchyNode.INSTANTIATED, strict: true);

    if (!foundSuperclass) {
      (_dynamicRoots[selector] ??= Setlet()).add(member);
    }
  }

  void _processMember(MemberEntity member,
      void Function(MemberEntity parent, MemberEntity override) join) {
    if (_skipMemberInternal(member)) return;
    final cls = member.enclosingClass!;
    final mixinUses = closedWorld.mixinUsesOf(cls);
    // Process each selector matching member separately.
    for (final selector in _selectorsForMember(member)) {
      for (final mixinUse in mixinUses) {
        // For mixin uses we treat the mixin's members as if they are part of
        // the mixin target itself.
        _handleMember(member, mixinUse, selector, join, isMixinUse: true);
      }
      _handleMember(member, cls, selector, join, isMixinUse: false);
    }
  }

  void init(void Function(MemberEntity parent, MemberEntity override) join) {
    final liveMembers = closedWorld.liveInstanceMembers
        .followedBy(closedWorld.liveAbstractInstanceMembers)
        .followedBy(closedWorld.recordData.allGetters);

    for (final member in liveMembers) {
      _processMember(member, join);
    }
  }

  // TODO(natebiggs): Clean up debug code below.
  void debugCall(String selectorName, String className,
      {bool nullReceiver = false,
      bool nullValue = false,
      bool subClass = false,
      bool subType = false,
      bool setter = false,
      CallStructure? call}) {
    final allMembers = closedWorld.liveInstanceMembers
        .followedBy(closedWorld.liveAbstractInstanceMembers);
    final cls = allMembers
        .firstWhere((e) => e.enclosingClass!.name == className)
        .enclosingClass!;
    final domain = closedWorld.abstractValueDomain;
    final receiver = nullValue
        ? domain.nullType
        : (nullReceiver
            ? null
            : (subClass
                ? domain.createNonNullSubclass(cls)
                : (subType
                    ? domain.createNonNullSubtype(cls)
                    : domain.createNullableExact(cls))));
    final name = Name(selectorName, null);
    final selector = call != null
        ? Selector.call(name, call)
        : (setter ? Selector.setter(name) : Selector.getter(name));

    print('Receiver: $receiver, Selector: $selector');
    print('Locate members: ${closedWorld.locateMembers(selector, receiver)}');
    print('Targets for call: ${rootsForCall(receiver, selector).toList()}');
  }

  void dumpOverrides([String? memberName]) {
    print(_overrides.entries
        .where((e) => memberName == null || e.key.name == memberName)
        .map((e) => '${e.key}\n  ${e.value.join('\n  ')}')
        .join('\n'));
  }

  void dumpRoots([String? selectorName]) {
    (_dynamicRoots.entries
            .where((e) => selectorName == null || e.key.name == selectorName)
            .map((e) {
      final members = e.value.map((m) => m).toList();
      members.sort((a, b) => a.toString().compareTo(b.toString()));
      return MapEntry(e.key, members.join(', '));
    }).toList()
          ..sort((a, b) {
            final keyComp = a.key.toString().compareTo(b.key.toString());
            return keyComp != 0 ? keyComp : a.value.compareTo(b.value);
          }))
        .forEach((e) => print('${e.key}: ${e.value}'));
  }

  void dumpCache({String? selectorName, String? receiverString}) {
    _callCache.entries
        .where((e) =>
            (selectorName == null || e.key.name == selectorName) &&
            (receiverString == null ||
                e.key.receiver.toString().contains(receiverString)))
        .forEach((e) => print('${e.key}: ${e.value.join(', ')}'));
  }
}
