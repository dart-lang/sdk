// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/indexed.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/universe/function_set.dart';
import 'package:compiler/src/universe/selector.dart';

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

class MemberHierarchyBuilder {
  final JClosedWorld closedWorld;
  final Map<SelectorMask, Iterable<DynamicCallTarget>> _callCache = {};
  final Map<Selector, Set<MemberEntity>> _dynamicRoots = {};
  final Map<MemberEntity, Set<MemberEntity>> _overrides = {};

  MemberHierarchyBuilder(this.closedWorld);

  /// Applies [f] to each override of [entity].
  ///
  /// If [f] returns `true` for a given input then its children are also
  /// visited.
  void forEachOverride(
      MemberEntity entity, bool Function(MemberEntity override) f) {
    final overrides = _overrides[entity];
    if (overrides == null) return;
    for (final override in overrides) {
      if (f(override)) forEachOverride(override, f);
    }
  }

  /// Finds the first non-strict superclass of [cls] that contains a member
  /// matching [selector] and returns that member.
  ///
  /// Returns the first non-abstract match found while ascending the class
  /// hierarchy. If no non-abstract matches are found then the first abstract
  /// match is used.
  ///
  /// If [virtualResult] is true, the resulting [DynamicCallTarget] will be
  /// virtual when the match is non-abstract and has overrides.
  /// Otherwise the resulting [DynamicCallTarget] is concrete.
  DynamicCallTarget? findSuperclassTarget(ClassEntity cls, Selector selector,
      {required bool virtualResult}) {
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
          return DynamicCallTarget(match,
              isVirtual: virtualResult && _hasOverride(match));
        }
      }
      current = elementEnv.getSuperClass(current);
    }
    return firstAbstractMatch != null
        ? DynamicCallTarget.virtual(firstAbstractMatch)
        : null;
  }

  /// Finds the first non-strict supertype of [cls] that contains a member
  /// matching [selector] and returns that member.
  DynamicCallTarget? findSupertypeTarget(ClassEntity cls, Selector selector) {
    final queue = Queue<ClassEntity>();
    final elementEnv = closedWorld.elementEnvironment;
    queue.add(cls);
    queue.addAll(closedWorld.elementMap
        .getInterfaces(cls as IndexedClass)
        .map((c) => c.element));
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final match =
          elementEnv.lookupLocalClassMember(current, selector.memberName);
      if (match != null && !skipMember(match, selector)) {
        return DynamicCallTarget.virtual(match);
      } else {
        final superClass = elementEnv.getSuperClass(current);
        if (superClass != null) queue.add(superClass);
        queue.addAll(closedWorld.elementMap
            .getInterfaces(current as IndexedClass)
            .map((c) => c.element));
      }
    }
    return null;
  }

  /// For each subclass/subtype try to find a member matching selector.
  ///
  /// If we find a match then it covers the entire subtree below that match so
  /// we do not need to check subclasses/subtypes below it.
  Iterable<DynamicCallTarget> findMatchingAncestors(
      ClassEntity baseCls, Selector selector,
      {required bool isSubtype}) {
    final Set<DynamicCallTarget> results = {};
    IterationStep handleEntity(entity) {
      final match = findSuperclassTarget(entity, selector, virtualResult: true);
      if (match != null) {
        results.add(match);
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
    return roots
        .where((r) =>
            selector.appliesStructural(r) &&
            classHierarchy.isSubclassOf(r.enclosingClass!, cls))
        .map((r) => DynamicCallTarget(r, isVirtual: _hasOverride(r)))
        .toSet();
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
        ? targetsForReceiver
            .followedBy(rootsForCall(receiverType, Selectors.noSuchMethod_))
            .toSet()
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
      void Function(MemberEntity parent, MemberEntity override) join) {
    final elementEnv = closedWorld.elementEnvironment;
    final name = selector.memberName;

    void addParent(MemberEntity child, ClassEntity childCls,
        MemberEntity parent, ClassEntity parentCls) {
      if (child == parent) return;
      if ((_overrides[parent] ??= {}).add(child)) {
        join(parent, child);
      }
    }

    // Check each superclass in ascending order until we find an ancestor.
    ClassEntity? current = elementEnv.getSuperClass(cls);
    while (current != null) {
      final match = elementEnv.lookupLocalClassMember(current, name);
      if (match != null && !MemberHierarchyBuilder._skipMemberInternal(match)) {
        addParent(member, cls, match, current);
        break;
      }
      current = elementEnv.getSuperClass(current);
    }

    closedWorld.classHierarchy.getClassSet(cls).forEachSubtype((subtype) {
      final override = elementEnv.lookupClassMember(subtype, name);
      if (override == null) return IterationStep.CONTINUE;
      addParent(override, subtype, member, cls);
      return IterationStep.CONTINUE;
    }, ClassHierarchyNode.INSTANTIATED, strict: true);
  }

  void _processMember(MemberEntity member,
      void Function(MemberEntity parent, MemberEntity override) join) {
    if (_skipMemberInternal(member)) return;
    final cls = member.enclosingClass!;
    final mixinUses = closedWorld.mixinUsesOf(cls);
    // Process each selector matching member separately.
    for (final selector in _selectorsForMember(member)) {
      if (!member.isAbstract) {
        (_dynamicRoots[selector] ??= {}).add(member);
      }
      for (final mixinUse in mixinUses) {
        _handleMember(member, mixinUse, selector, join);
      }
      _handleMember(member, cls, selector, join);
    }
  }

  void init(void Function(MemberEntity parent, MemberEntity override) join) {
    final liveMembers = closedWorld.liveInstanceMembers
        .followedBy(closedWorld.liveAbstractInstanceMembers);

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
