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
import 'package:compiler/src/universe/function_set.dart';
import 'package:compiler/src/universe/selector.dart';

class _QueuedMember {
  /// The member to be processed.
  final MemberEntity member;

  /// The class we want to look for ancestors of [member] from. This might be
  /// a supertype of member's enclosing class or a mixin application.
  final ClassEntity cls;

  /// Whether or not [cls] is the declarer of [member]. In most cases this is
  /// true when [cls] equals member's [MemberEntity.enclosingClass]. However
  /// for mixins this can be true when [cls] is the mixin application class.
  final bool isDeclaration;

  _QueuedMember(this.member, this.cls, {required this.isDeclaration});
}

class MemberHierarchyBuilder {
  final JClosedWorld closedWorld;
  final Map<SelectorMask, Iterable<MemberEntity>> _callCache = {};
  final Map<Selector, Set<MemberEntity>> _selectorRoots = {};
  final Map<MemberEntity, Set<MemberEntity>> _overrides = {};

  MemberHierarchyBuilder(this.closedWorld);

  /// Uses [visited] to detect and avoid cycles in the override graph.
  void _forEachOverride(MemberEntity member,
      void Function(MemberEntity override) f, Set<MemberEntity> visited) {
    final overrides = _overrides[member];
    if (overrides == null) return;
    for (final override in overrides) {
      if (!visited.add(override)) continue;
      f(override);
      _forEachOverride(override, f, visited);
    }
  }

  /// Recursively applies [f] to each override of [entity].
  void forEachOverride(
      MemberEntity entity, void Function(MemberEntity override) f) {
    _forEachOverride(entity, f, {});
  }

  /// Returns the set of root member declarations for [selector]. [cls] acts as
  /// a subclass filter for these roots.
  ///
  /// The set of roots is the smallest set of members that are an ancestor of
  /// every implementation of [selector]. This is with the caveat that we
  /// consider each mixin application to declare a "copy" of each member of that
  /// mixin. They share the same [MemberEntity] but each copy is considered a
  /// separate potential root.
  Iterable<MemberEntity> rootsForSelector(ClassEntity cls, Selector selector) {
    final roots = _selectorRoots[_normalizeSelector(selector)];
    if (roots == null) return const [];
    final classHierarchy = closedWorld.classHierarchy;
    return roots
        .where((r) =>
            selector.appliesStructural(r) &&
            classHierarchy.isSubclassOf(r.enclosingClass!, cls))
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
  Iterable<MemberEntity> rootsForCall(
      AbstractValue? receiverType, Selector selector) {
    final domain = closedWorld.abstractValueDomain;
    receiverType ??= domain.dynamicType;
    final selectorMask = SelectorMask(selector, receiverType);
    final cachedResult = _callCache[selectorMask];
    if (cachedResult != null) return cachedResult;

    Iterable<MemberEntity> targetsForReceiver = const [];

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
        targetsForReceiver = {...targetsForReceiver, nullMatch};
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
    return _skipMemberInternal(member) || !selector.appliesUnnamed(member);
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

  void _processNext(
      Queue<_QueuedMember> queue,
      Selector selector,
      Map<ClassEntity, MemberEntity?> roots,
      void Function(MemberEntity parent, MemberEntity override) join) {
    final state = queue.removeFirst();
    if (state.isDeclaration && !roots.containsKey(state.cls)) {
      // Only add the potential root if we're processing a declaration of
      // the member and have not already found an override for the class'
      // declaration.
      roots[state.cls] = state.member;
    }
    final elementEnv = closedWorld.elementEnvironment;
    final elementMap = closedWorld.elementMap;
    final member = state.member;
    final cls = state.cls;
    final name = selector.memberName;

    void addParent(
        MemberEntity parent, ClassEntity parentCls, bool fromSuperclass) {
      if ((_overrides[parent] ??= {}).add(member)) {
        join(parent, member);
      }

      // Both the class we are considering and the enclosing class of [member]
      // are not roots since we found an override for them.
      roots[cls] = null;
      roots[member.enclosingClass!] = null;

      // Enqueue parent to continue processing from there. parentCls can be a
      // mixin application since we consider these to have duplicates of the
      // mixin's members.
      queue.add(_QueuedMember(parent, parentCls, isDeclaration: true));
    }

    void processInterfaces(IndexedClass toProcess) {
      final interfaces = elementMap.getInterfaces(toProcess);
      for (final interface in interfaces) {
        final interfaceCls = interface.element;
        // For unnamed mixin applications, members can be owned by the
        // underlying mixin which is also an interface for that same
        // application. This would cause a self-override unless we explicitly
        // ignore that interface relationship.
        if (interfaceCls == member.enclosingClass) continue;
        final match = elementEnv.lookupLocalClassMember(interfaceCls, name);
        if (match != null &&
            !MemberHierarchyBuilder._skipMemberInternal(match)) {
          addParent(match, interfaceCls, false);
        } else {
          // The interface does not contain a match so enqueue the current
          // member to continue checking the superclasses and supertypes of the
          // interface.
          queue.add(_QueuedMember(member, interfaceCls, isDeclaration: false));
        }
      }
    }

    void addInterfaces(IndexedClass toProcess) {
      processInterfaces(toProcess);

      // Supertypes of the mixin for this class are also supertypes of this
      // class.
      final mixinClass = elementEnv.getEffectiveMixinClass(toProcess);
      if (mixinClass != null) {
        processInterfaces(mixinClass as IndexedClass);
      }
    }

    // Check and add any interfaces for the current class.
    addInterfaces(cls as IndexedClass);

    // Check each superclass in ascending order until we find an ancestor.
    ClassEntity? current = elementEnv.getSuperClass(cls);
    while (current != null) {
      final match = elementEnv.lookupLocalClassMember(current, name);
      if (match != null && !MemberHierarchyBuilder._skipMemberInternal(match)) {
        addParent(match, current, true);
        break;
      }

      // If this superclass does not declare a relevant member then check its
      // interfaces too since a supertype can contain an ancestor.
      addInterfaces(current as IndexedClass);
      current = elementEnv.getSuperClass(current);
    }
  }

  void _processMember(
      MemberEntity member,
      Map<Selector, Map<ClassEntity, MemberEntity?>> roots,
      void Function(MemberEntity parent, MemberEntity override) join,
      Queue<_QueuedMember> queue) {
    if (_skipMemberInternal(member)) return;
    final cls = member.enclosingClass!;
    final mixinUses = closedWorld.mixinUsesOf(cls);
    // Process each selector matching member separately.
    for (final selector in _selectorsForMember(member)) {
      for (final mixinUse in mixinUses) {
        queue.add(_QueuedMember(member, mixinUse, isDeclaration: true));
      }
      queue.add(_QueuedMember(member, cls, isDeclaration: true));
      final selectorRoots = roots[selector] ??= {};
      while (queue.isNotEmpty) {
        _processNext(queue, selector, selectorRoots, join);
      }
    }
  }

  void init(void Function(MemberEntity parent, MemberEntity override) join) {
    final liveMembers = closedWorld.liveInstanceMembers
        .followedBy(closedWorld.liveAbstractInstanceMembers);

    // Track root declarations for each selector encountered. Each inner map
    // tracks declarations of the selector. A null member indicates we found
    // an override for that declaration.
    final Map<Selector, Map<ClassEntity, MemberEntity?>> roots = {};
    final queue = Queue<_QueuedMember>();
    for (final member in liveMembers) {
      assert(queue.isEmpty);
      _processMember(member, roots, join, queue);
    }

    // Finalize roots for each selector. Deduplicate remaining root declarations
    // and store them for later.
    roots.forEach((selector, selectorRoots) {
      final validRoots = selectorRoots.values.whereType<MemberEntity>().toSet();
      if (validRoots.isNotEmpty) _selectorRoots[selector] = validRoots;
    });
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
    (_selectorRoots.entries
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
