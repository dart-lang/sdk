// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:meta/meta.dart';

/// Failure because of there is no most specific signature in [candidates].
class CandidatesConflict extends Conflict {
  /// The list has at least two items, because the only item is always valid.
  final List<ExecutableElementOrMember> candidates;

  CandidatesConflict({required super.name, required this.candidates});

  List<ExecutableElement> get candidates2 =>
      candidates.map((e) => e.asElement2).toList();
}

/// Failure to find a valid signature from superinterfaces.
class Conflict {
  /// The name for which we failed to find a valid signature.
  final Name name;

  Conflict({required this.name});
}

/// Failure because of a getter and a method from direct superinterfaces.
class GetterMethodConflict extends Conflict {
  final ExecutableElementOrMember getter;
  final ExecutableElementOrMember method;

  GetterMethodConflict({
    required super.name,
    required this.getter,
    required this.method,
  });

  ExecutableElement get getter2 => getter.asElement2;

  ExecutableElement get method2 => method.asElement2;
}

/// The extension type has both an extension and non-extension member
/// signature with the same name.
class HasNonExtensionAndExtensionMemberConflict extends Conflict {
  final List<ExecutableElementOrMember> nonExtension;
  final List<ExecutableElementOrMember> extension;

  HasNonExtensionAndExtensionMemberConflict({
    required super.name,
    required this.nonExtension,
    required this.extension,
  });

  List<ExecutableElement> get extension2 =>
      extension.map((e) => e.asElement2).toList();

  List<ExecutableElement> get nonExtension2 =>
      nonExtension.map((e) => e.asElement2).toList();
}

/// Manages knowledge about interface types and their members.
class InheritanceManager3 {
  static final _noSuchMethodName = Name(
    null,
    MethodElement.NO_SUCH_METHOD_METHOD_NAME,
  );

  /// Cached instance interfaces for [InterfaceFragmentImpl].
  final Map<InterfaceFragmentImpl, Interface> _interfaces = {};

  /// Tracks signatures from superinterfaces that were combined.
  /// It is used to track dependencies in manifests.
  final Map<InterfaceFragmentImpl, Map<Name, List<ExecutableElement2OrMember>>>
  _combinedSignatures = {};

  /// The set of classes that are currently being processed, used to detect
  /// self-referencing cycles.
  final Set<InterfaceFragmentImpl> _processingClasses = {};

  /// Combine types of [candidates] into a single most specific type.
  ///
  /// If such signature does not exist, return `null`, and if [conflicts] is
  /// not `null`, add a new [Conflict] to it.
  FunctionTypeImpl? combineSignatureTypes({
    required TypeSystemImpl typeSystem,
    required List<ExecutableElementOrMember> candidates,
    required Name name,
    List<Conflict>? conflicts,
  }) {
    if (candidates.length == 1) {
      return candidates[0].type;
    }

    var validOverrides = _getValidOverrides(
      typeSystem: typeSystem,
      candidates: candidates,
    );

    if (validOverrides.isEmpty) {
      conflicts?.add(CandidatesConflict(name: name, candidates: candidates));
      return null;
    }

    // Often there is one most specific signature.
    var firstType = validOverrides[0].type;
    if (validOverrides.length == 1) {
      return firstType;
    }

    // Maybe more than valid, but the same type.
    if (validOverrides.every((e) => e.type == firstType)) {
      return firstType;
    }

    return _topMergeSignatureTypes(
      typeSystem: typeSystem,
      validOverrides: validOverrides,
    );
  }

  /// Return the most specific signature of the member with the given [name]
  /// that [element] inherits from the mixins, superclasses, or interfaces;
  /// or `null` if no member is inherited because the member is not declared
  /// at all, or because there is no the most specific signature.
  ///
  /// This is equivalent to `getInheritedMap2(element)[name]`.
  ExecutableElementOrMember? getInherited2(
    InterfaceFragmentImpl element,
    Name name,
  ) {
    return getInheritedMap2(element)[name];
  }

  /// Returns the result of [getInherited2] with [type] substitution.
  @experimental
  ExecutableElement? getInherited3(InterfaceType type, Name name) {
    type as InterfaceTypeImpl;
    var rawElement = getInherited2(type.element3.asElement, name);
    if (rawElement == null) {
      return null;
    }

    var element = ExecutableMember.from2(
      rawElement,
      Substitution.fromInterfaceType(type),
    );

    return element.asElement2;
  }

  /// Returns the most specific signature of the member with the given [name]
  /// that [element] inherits from the mixins, superclasses, or interfaces.
  ///
  /// Returns `null` if no member is inherited because the member is not
  /// declared at all, or because there is no the most specific signature.
  ///
  /// This is equivalent to `getInheritedMap(type)[name]`.
  // This is a replacement for `getInherited2`.
  @experimental
  ExecutableElement2OrMember? getInherited4(
    InterfaceElement element,
    Name name,
  ) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    var oldElement = getInherited2(element.asElement, name);
    return oldElement?.asElement2;
  }

  /// Returns signatures of all concrete members that the given [element]
  /// inherits from the superclasses and mixins.
  @experimental
  Map<Name, ExecutableElement> getInheritedConcreteMap(
    InterfaceElement element,
  ) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    var fragment = element.asElement;

    if (fragment is ExtensionTypeFragmentImpl) {
      return const {};
    }

    var interface = getInterface(fragment);
    if (interface.superImplemented.isEmpty) {
      assert(fragment.name2 == 'Object');
      return const {};
    }

    var map = interface.superImplemented.last;
    return map.mapValue((e) => e.asElement2);
  }

  /// Returns the mapping from names to most specific signatures of members
  /// inherited from the super-interfaces (superclasses, mixins, and
  /// interfaces).
  ///
  /// If there is no most specific signature for a name, the corresponding name
  /// will not be included.
  @experimental
  Map<Name, ExecutableElement> getInheritedMap(InterfaceElement element) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    var map = getInheritedMap2(element.asElement);
    return map.mapValue((element) => element.asElement2);
  }

  /// Return the mapping from names to most specific signatures of members
  /// inherited from the super-interfaces (superclasses, mixins, and
  /// interfaces).  If there is no most specific signature for a name, the
  /// corresponding name will not be included.
  Map<Name, ExecutableElementOrMember> getInheritedMap2(
    InterfaceFragmentImpl element,
  ) {
    var interface = getInterface(element);
    var inheritedMap = interface.inheritedMap;
    if (inheritedMap == null) {
      inheritedMap = interface.inheritedMap = {};
      _findMostSpecificFromNamedCandidates(
        element,
        inheritedMap,
        element is ExtensionTypeFragmentImpl
            ? interface.redeclared
            : interface.overridden,
      );
    }
    return inheritedMap;
  }

  /// Return the interface of the given [element].  It might include
  /// private members, not necessary accessible in all libraries.
  Interface getInterface(InterfaceFragmentImpl element) {
    var result = _interfaces[element];
    if (result != null) {
      return result;
    }
    _interfaces[element] = Interface._empty;

    if (!_processingClasses.add(element)) {
      return Interface._empty;
    }

    try {
      if (element is ExtensionTypeFragmentImpl) {
        result = _getInterfaceExtensionType(element);
      } else if (element is MixinFragmentImpl) {
        result = _getInterfaceMixin(element);
      } else {
        result = _getInterfaceClass(element);
      }
    } finally {
      _processingClasses.remove(element);
    }

    _interfaces[element] = result;
    return result;
  }

  /// Returns the interface of the given [element].
  ///
  /// The interface might include private members, not necessary accessible in
  /// all libraries.
  @experimental
  Interface getInterface2(InterfaceElement element) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    globalResultRequirements?.record_interface_all(element: element);
    return getInterface(element.asElement);
  }

  /// Return the result of [getMember2] with [type] substitution.
  ExecutableElementOrMember? getMember(
    InterfaceType type,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    type as InterfaceTypeImpl; // TODO(scheglov): remove cast
    var rawElement = getMember2(
      type.element3.asElement,
      name,
      concrete: concrete,
      forMixinIndex: forMixinIndex,
      forSuper: forSuper,
    );
    if (rawElement == null) {
      return null;
    }

    var substitution = Substitution.fromInterfaceType(type);
    return ExecutableMember.from2(rawElement, substitution);
  }

  /// Return the member with the given [name].
  ///
  /// If [concrete] is `true`, the concrete implementation is returned,
  /// from the given [element], or its superclass.
  ///
  /// If [forSuper] is `true`, then [concrete] is implied, and only concrete
  /// members from the superclass are considered.
  ///
  /// If [forMixinIndex] is specified, only the nominal superclass, and the
  /// given number of mixins after it are considered.  For example for `1` in
  /// `class C extends S with M1, M2, M3`, only `S` and `M1` are considered.
  ExecutableElementOrMember? getMember2(
    InterfaceFragmentImpl element,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    var interface = getInterface(element);
    if (forSuper) {
      if (element is ExtensionTypeFragmentImpl) {
        return null;
      }
      var superImplemented = interface.superImplemented;
      if (forMixinIndex >= 0) {
        return superImplemented[forMixinIndex][name];
      }
      if (superImplemented.isNotEmpty) {
        return superImplemented.last[name];
      } else {
        assert(element.name2 == 'Object');
        return null;
      }
    }
    if (concrete) {
      return interface.implemented[name];
    }

    var result = interface.map[name];
    globalResultRequirements?.record_interface_getMember(
      element: element.asElement2,
      nameObj: name,
      methodElement: result?.asElement2,
    );
    return result;
  }

  /// Returns the result of [getMember4] with [type] substitution.
  // This is a replacement for `getMember`.
  @experimental
  ExecutableElement? getMember3(
    InterfaceType type,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    var element = getMember(
      type,
      name,
      concrete: concrete,
      forMixinIndex: forMixinIndex,
      forSuper: forSuper,
    );
    return element?.asElement2;
  }

  /// Returns the member with the given [name].
  ///
  /// If [concrete] is `true`, the concrete implementation is returned, whether
  /// from the given [element] or its superclass.
  ///
  /// If [forSuper] is `true`, then [concrete] is implied, and only concrete
  /// members from the superclass are considered.
  ///
  /// If [forMixinIndex] is specified, only the nominal superclass, and the
  /// given number of mixins after it are considered. For example for `1` in
  /// `class C extends S with M1, M2, M3`, only `S` and `M1` are considered.
  // This is a replacement for `getMember2`.
  @experimental
  ExecutableElement2OrMember? getMember4(
    InterfaceElement element,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    var oldElement = getMember2(
      element.asElement,
      name,
      concrete: concrete,
      forMixinIndex: forMixinIndex,
      forSuper: forSuper,
    );
    return oldElement?.asElement2;
  }

  /// Return all members of mixins, superclasses, and interfaces that a member
  /// with the given [name], defined in the [element], would override; or `null`
  /// if no members would be overridden.
  List<ExecutableElementOrMember>? getOverridden2(
    InterfaceFragmentImpl element,
    Name name,
  ) {
    var interface = getInterface(element);
    return interface.overridden[name];
  }

  /// Return all members of mixins, superclasses, and interfaces that a member
  /// with the given [name], defined in the [element], would override; or `null`
  /// if no members would be overridden.
  List<ExecutableElement>? getOverridden4(InterfaceElement element, Name name) {
    var interface = getInterface2(element);
    var fragments = interface.overridden[name];
    return fragments?.map((fragment) => fragment.asElement2).toList();
  }

  /// Remove interfaces for classes defined in specified libraries.
  void removeOfLibraries(Set<Uri> uriSet) {
    _interfaces.removeWhere((element, _) {
      return uriSet.contains(element.librarySource.uri);
    });
  }

  void _addCandidates({
    required Map<Name, List<ExecutableElementOrMember>> namedCandidates,
    required MapSubstitution substitution,
    required Interface interface,
  }) {
    var map = interface.map;
    for (var entry in map.entries) {
      var name = entry.key;
      var candidate = entry.value;

      candidate = ExecutableMember.from2(candidate, substitution);

      var candidates = namedCandidates[name];
      if (candidates == null) {
        candidates = <ExecutableElementOrMember>[];
        namedCandidates[name] = candidates;
      }

      candidates.add(candidate);
    }
  }

  void _addImplemented(
    Map<Name, ExecutableElementOrMember> implemented,
    InterfaceFragmentImpl fragment,
    InterfaceElementImpl element,
  ) {
    var libraryUri = fragment.librarySource.uri;

    void addMember(ExecutableElementOrMember member) {
      if (!member.isAbstract && !member.isStatic) {
        var lookupName = member.element.lookupName;
        if (lookupName != null) {
          var name = Name(libraryUri, lookupName);
          implemented[name] = member;
        }
      }
    }

    element.methods.map((e) => e.asElement).forEach(addMember);
    element.getters.map((e) => e.asElement).forEach(addMember);
    element.setters.map((e) => e.asElement).forEach(addMember);
  }

  void _addMixinMembers({
    required Map<Name, ExecutableElementOrMember> implemented,
    required MapSubstitution substitution,
    required Interface mixin,
  }) {
    for (var entry in mixin.implemented.entries) {
      var executable = entry.value;
      if (executable.isAbstract) {
        continue;
      }

      var class_ = executable.asElement2.enclosingElement;
      if (class_ is ClassElement && class_.isDartCoreObject) {
        continue;
      }

      executable = ExecutableMember.from2(executable, substitution);

      implemented[entry.key] = executable;
    }
  }

  /// Check that all [candidates] for the given [name] have the same kind, all
  /// getters, all methods, or all setter.  If a conflict found, return the
  /// new [Conflict] instance that describes it.
  Conflict? _checkForGetterMethodConflict(
    Name name,
    List<ExecutableElementOrMember> candidates,
  ) {
    assert(candidates.length > 1);

    ExecutableElementOrMember? getter;
    ExecutableElementOrMember? method;
    for (var candidate in candidates) {
      var kind = candidate.kind;
      if (kind == ElementKind.GETTER) {
        getter ??= candidate;
      }
      if (kind == ElementKind.METHOD) {
        method ??= candidate;
      }
    }

    if (getter == null || method == null) {
      return null;
    } else {
      return GetterMethodConflict(name: name, getter: getter, method: method);
    }
  }

  /// Combine [candidates] into a single signature in the [targetClass].
  ///
  /// If such signature does not exist, return `null`, and if [conflicts] is
  /// not `null`, add a new [Conflict] to it.
  ExecutableElementOrMember? _combineSignatures({
    required InterfaceFragmentImpl targetClass,
    required List<ExecutableElementOrMember> candidates,
    required Name name,
    List<Conflict>? conflicts,
  }) {
    // If just one candidate, it is always valid.
    if (candidates.length == 1) {
      return candidates[0];
    }

    var targetLibrary = targetClass.library;
    var typeSystem = targetLibrary.typeSystem;

    var validOverrides = _getValidOverrides(
      candidates: candidates,
      typeSystem: typeSystem,
    );

    if (validOverrides.isEmpty) {
      conflicts?.add(CandidatesConflict(name: name, candidates: candidates));
      return null;
    }

    (_combinedSignatures[targetClass] ??= {})[name] =
        candidates.map((e) => e.asElement2).toList();

    return _topMerge(typeSystem, targetClass, validOverrides);
  }

  /// The given [namedCandidates] maps names to candidates from direct
  /// superinterfaces.  Find the most specific signature, and put it into the
  /// [map], if there is no one yet (from the class itself).  If there is no
  /// such single most specific signature (i.e. no valid override), then add a
  /// new conflict description.
  List<Conflict> _findMostSpecificFromNamedCandidates(
    InterfaceFragmentImpl targetClass,
    Map<Name, ExecutableElementOrMember> map,
    Map<Name, List<ExecutableElementOrMember>> namedCandidates,
  ) {
    var conflicts = <Conflict>[];

    for (var entry in namedCandidates.entries) {
      var name = entry.key;
      var candidates = entry.value;

      // There is no way to resolve the getter / method conflict.
      if (candidates.length > 1) {
        var conflict = _checkForGetterMethodConflict(name, candidates);
        if (conflict != null) {
          conflicts.add(conflict);
          continue;
        }
      }

      if (map.containsKey(name)) {
        continue;
      }

      var combinedSignature = _combineSignatures(
        targetClass: targetClass,
        candidates: candidates,
        name: name,
        conflicts: conflicts,
      );

      if (combinedSignature != null) {
        map[name] = combinedSignature;
        continue;
      }
    }

    return conflicts;
  }

  Interface _getInterfaceClass(InterfaceFragmentImpl fragment) {
    var element = fragment.element;

    var namedCandidates = <Name, List<ExecutableElementOrMember>>{};
    var superImplemented = <Map<Name, ExecutableElementOrMember>>[];
    var implemented = <Name, ExecutableElementOrMember>{};

    InterfaceType? superType = fragment.supertype;

    Interface? superTypeInterface;
    if (superType != null) {
      superType as InterfaceTypeImpl;
      var substitution = Substitution.fromInterfaceType(superType);
      superTypeInterface = getInterface2(superType.element3);
      _addCandidates(
        namedCandidates: namedCandidates,
        substitution: substitution,
        interface: superTypeInterface,
      );

      for (var entry in superTypeInterface.implemented.entries) {
        var executable = entry.value;
        executable = ExecutableMember.from2(executable, substitution);
        implemented[entry.key] = executable;
      }

      superImplemented.add(implemented);
    }

    // TODO(scheglov): Handling of members for super and mixins is not
    // optimal. We always have just one member for each name in super,
    // multiple candidates happen only when we merge super and multiple
    // interfaces. Consider using `Map<Name, ExecutableElement>` here.
    var mixinsConflicts = <List<Conflict>>[];
    for (var mixin in element.mixins) {
      var mixinElement = mixin.element3;
      var substitution = Substitution.fromInterfaceType(mixin);
      var mixinInterface = getInterface2(mixinElement);
      // `class X extends S with M1, M2 {}` is semantically a sequence of:
      //     class S&M1 extends S implements M1 {
      //       // declared M1 members
      //     }
      //     class S&M2 extends S&M1 implements M2 {
      //       // declared M2 members
      //     }
      //     class X extends S&M2 {
      //       // declared X members
      //     }
      // So, each mixin always replaces members in the interface.
      // And there are individual override conflicts for each mixin.
      var candidatesFromSuperAndMixin =
          <Name, List<ExecutableElementOrMember>>{};
      var mixinConflicts = <Conflict>[];
      for (var entry in mixinInterface.map.entries) {
        var name = entry.key;
        var candidate = ExecutableMember.from2(entry.value, substitution);
        var candidate2 = candidate.asElement2;

        var currentList = namedCandidates[name];
        if (currentList == null) {
          namedCandidates[name] = [candidate];
          continue;
        }

        var current = currentList.single;
        if (candidate2.enclosingElement == mixinElement) {
          namedCandidates[name] = [candidate];
          if (current.kind != candidate.kind) {
            var currentIsGetter = current.kind == ElementKind.GETTER;
            mixinConflicts.add(
              GetterMethodConflict(
                name: name,
                getter: currentIsGetter ? current : candidate,
                method: currentIsGetter ? candidate : current,
              ),
            );
          }
        } else {
          candidatesFromSuperAndMixin[name] = [current, candidate];
        }
      }

      // Merge members from the superclass and the mixin interface.
      {
        var map = <Name, ExecutableElementOrMember>{};
        _findMostSpecificFromNamedCandidates(
          fragment,
          map,
          candidatesFromSuperAndMixin,
        );
        for (var entry in map.entries) {
          namedCandidates[entry.key] = [entry.value];
        }
      }

      mixinsConflicts.add(mixinConflicts);

      implemented = Map.of(implemented);
      _addMixinMembers(
        implemented: implemented,
        substitution: substitution,
        mixin: mixinInterface,
      );

      superImplemented.add(implemented);
    }

    for (var interface in element.interfaces) {
      _addCandidates(
        namedCandidates: namedCandidates,
        substitution: Substitution.fromInterfaceType(interface),
        interface: getInterface2(interface.element3),
      );
    }

    implemented = Map.of(implemented);
    _addImplemented(implemented, fragment, element);

    // If a class declaration has a member declaration, the signature of that
    // member declaration becomes the signature in the interface.
    var declared = _getTypeMembers(fragment, element);

    // If a class declaration does not have a member declaration with a
    // particular name, but some super-interfaces do have a member with that
    // name, it's a compile-time error if there is no signature among the
    // super-interfaces that is a valid override of all the other
    // super-interface signatures with the same name. That "most specific"
    // signature becomes the signature of the class's interface.
    var interface = Map.of(declared);
    List<Conflict> conflicts = _findMostSpecificFromNamedCandidates(
      fragment,
      interface,
      namedCandidates,
    );

    var noSuchMethodForwarders = <Name>{};
    if (fragment is ClassFragmentImpl && fragment.isAbstract) {
      if (superTypeInterface != null) {
        noSuchMethodForwarders = superTypeInterface.noSuchMethodForwarders;
      }
    } else {
      var noSuchMethod = implemented[_noSuchMethodName];
      if (noSuchMethod != null && !_isDeclaredInObject(noSuchMethod)) {
        var superForwarders = superTypeInterface?.noSuchMethodForwarders;
        for (var entry in interface.entries) {
          var name = entry.key;
          if (!implemented.containsKey(name) ||
              superForwarders != null && superForwarders.contains(name)) {
            implemented[name] = entry.value;
            noSuchMethodForwarders.add(name);
          }
        }
      }
    }

    // TODO(scheglov): Instead of merging conflicts we could report them on
    // the corresponding mixins applied in the class.
    for (var mixinConflicts in mixinsConflicts) {
      if (mixinConflicts.isNotEmpty) {
        conflicts.addAll(mixinConflicts);
      }
    }

    implemented = implemented.map<Name, ExecutableElementOrMember>((
      key,
      value,
    ) {
      var result = _inheritCovariance(fragment, namedCandidates, key, value);
      return MapEntry(key, result);
    });

    var implemented2 = implemented.mapValue((value) {
      try {
        return value.asElement2;
      } catch (e) {
        rethrow;
      }
    });

    var namedCandidates2 = namedCandidates.map<Name, List<ExecutableElement>>(
      (key, value) => MapEntry(key, value.map((e) => e.asElement2).toList()),
    );

    var superImplemented2 =
        superImplemented
            .map(
              (e) => e.map<Name, ExecutableElement>(
                (key, value) => MapEntry(key, value.asElement2),
              ),
            )
            .toList();

    return Interface._(
      map: interface,
      declared: declared,
      implemented: implemented,
      implemented2: implemented2,
      noSuchMethodForwarders: noSuchMethodForwarders,
      overridden: namedCandidates,
      overridden2: namedCandidates2,
      redeclared: const {},
      redeclared2: const {},
      superImplemented: superImplemented,
      superImplemented2: superImplemented2,
      conflicts: conflicts.toFixedList(),
      combinedSignatures: _combinedSignatures.remove(fragment) ?? {},
    );
  }

  /// See https://github.com/dart-lang/language
  ///   blob/main/accepted/future-releases/extension-types/feature-specification.md
  ///   #static-analysis-of-an-extension-type-member-invocation
  ///
  /// We handle "has an extension type member" and "has a non-extension type
  /// member" portions, considering redeclaration and conflicts.
  Interface _getInterfaceExtensionType(ExtensionTypeFragmentImpl fragment) {
    var element = fragment.element;

    // Add instance members implemented by the element itself.
    var declared = <Name, ExecutableElementOrMember>{};
    _addImplemented(declared, fragment, element);

    // Prepare precluded names.
    var precludedNames = <Name>{};
    var precludedMethods = <Name>{};
    var precludedSetters = <Name>{};
    for (var entry in declared.entries) {
      var name = entry.key;
      precludedNames.add(name);
      switch (entry.value) {
        case MethodElementOrMember():
          precludedSetters.add(name.forSetter);
        case PropertyAccessorElementOrMember(isSetter: true):
          precludedMethods.add(name.forGetter);
      }
    }

    // These declared members take precedence over "inherited" ones.
    var implemented = Map.of(declared);

    // Prepare candidates for inheritance.
    var extensionCandidates = <Name, _ExtensionTypeCandidates>{};
    var notExtensionCandidates = <Name, _ExtensionTypeCandidates>{};
    for (var interface in element.interfaces) {
      var substitution = Substitution.fromInterfaceType(interface);
      for (var entry in getInterface2(interface.element3).map.entries) {
        var name = entry.key;
        var executable = ExecutableMember.from2(entry.value, substitution);
        if (executable.isExtensionTypeMember) {
          (extensionCandidates[name] ??= _ExtensionTypeCandidates(name)).add(
            executable,
          );
        } else {
          (notExtensionCandidates[name] ??= _ExtensionTypeCandidates(name)).add(
            executable,
          );
        }
      }
    }

    var redeclared = <Name, List<ExecutableElementOrMember>>{};
    var conflicts = <Conflict>[];

    // Add extension type members.
    for (var entry in extensionCandidates.entries) {
      var name = entry.key;
      var candidates = entry.value;
      (redeclared[name] ??= []).addAll(candidates.all);

      var notPrecluded = candidates.notPrecluded(
        precludedNames: precludedNames,
        precludedMethods: precludedMethods,
        precludedSetters: precludedSetters,
      );

      // Stop if all precluded.
      if (notPrecluded.isEmpty) {
        continue;
      }

      // If not precluded, can have either non-extension, or extension.
      var nonExtensionSignatures = notExtensionCandidates[name];
      if (nonExtensionSignatures != null) {
        var notExtensionNotPrecluded = nonExtensionSignatures.notPrecluded(
          precludedNames: precludedNames,
          precludedMethods: precludedMethods,
          precludedSetters: precludedSetters,
        );
        if (notExtensionNotPrecluded.isNotEmpty) {
          conflicts.add(
            HasNonExtensionAndExtensionMemberConflict(
              name: name,
              nonExtension: notExtensionNotPrecluded,
              extension: notPrecluded,
            ),
          );
        }
        continue;
      }

      // The inherited member must be unique.
      ExecutableElementOrMember? uniqueElement;
      for (var candidate in notPrecluded) {
        if (uniqueElement == null) {
          uniqueElement = candidate;
        } else if (uniqueElement.asElement2.baseElement !=
            candidate.asElement2.baseElement) {
          uniqueElement = null;
          break;
        }
      }

      if (uniqueElement == null) {
        conflicts.add(
          NotUniqueExtensionMemberConflict(
            name: name,
            candidates: notPrecluded,
          ),
        );
        continue;
      }

      implemented[name] = uniqueElement;
    }

    // Add non-extension type members.
    for (var entry in notExtensionCandidates.entries) {
      var name = entry.key;
      var candidates = entry.value;
      (redeclared[name] ??= []).addAll(candidates.all);

      var notPrecluded = candidates.notPrecluded(
        precludedNames: precludedNames,
        precludedMethods: precludedMethods,
        precludedSetters: precludedSetters,
      );

      // Stop if all precluded.
      if (notPrecluded.isEmpty) {
        continue;
      }

      // Skip, if also has extension candidates.
      // The conflict is already reported.
      if (extensionCandidates.containsKey(name)) {
        continue;
      }

      var combinedSignature = _combineSignatures(
        targetClass: fragment,
        candidates: notPrecluded,
        name: name,
      );

      if (combinedSignature == null) {
        conflicts.add(CandidatesConflict(name: name, candidates: notPrecluded));
        continue;
      }

      implemented[name] = combinedSignature;
    }

    // Ensure unique overridden elements.
    var uniqueRedeclared = <Name, List<ExecutableElementOrMember>>{};
    for (var entry in redeclared.entries) {
      var name = entry.key;
      var elements = entry.value;
      if (elements.length == 1) {
        uniqueRedeclared[name] = elements;
      } else {
        uniqueRedeclared[name] = elements.toSet().toFixedList();
      }
    }

    var uniqueRedeclared2 = <Name, List<ExecutableElement>>{};
    for (var entry in redeclared.entries) {
      var name = entry.key;
      var fragments = entry.value.map((fragment) => fragment.asElement2);
      if (fragments.length == 1) {
        uniqueRedeclared2[name] = fragments.toFixedList();
      } else {
        var uniqueElements = <ExecutableElement>{};
        for (var fragment in fragments) {
          uniqueElements.add(fragment);
        }
        uniqueRedeclared2[name] = uniqueElements.toFixedList();
      }
    }

    var implemented2 = implemented.mapValue((value) => value.asElement2);

    return Interface._(
      map: implemented,
      declared: declared,
      implemented: implemented,
      implemented2: implemented2,
      noSuchMethodForwarders: const {},
      overridden: const {},
      overridden2: const {},
      redeclared: uniqueRedeclared,
      redeclared2: uniqueRedeclared2,
      superImplemented: const [],
      superImplemented2: const [],
      conflicts: conflicts.toFixedList(),
      combinedSignatures: _combinedSignatures.remove(fragment) ?? {},
    );
  }

  Interface _getInterfaceMixin(MixinFragmentImpl fragment) {
    var element = fragment.element;

    var superCandidates = <Name, List<ExecutableElementOrMember>>{};
    for (var constraint in element.superclassConstraints) {
      var substitution = Substitution.fromInterfaceType(constraint);
      var interfaceObj = getInterface2(constraint.element3);
      _addCandidates(
        namedCandidates: superCandidates,
        substitution: substitution,
        interface: interfaceObj,
      );
    }

    // `mixin M on S1, S2 {}` can call using `super` any instance member
    // from its superclass constraints, whether it is abstract or concrete.
    var superInterface = <Name, ExecutableElementOrMember>{};
    var superConflicts = _findMostSpecificFromNamedCandidates(
      fragment,
      superInterface,
      superCandidates,
    );

    var interfaceCandidates = Map.of(superCandidates);
    for (var interface in element.interfaces) {
      _addCandidates(
        namedCandidates: interfaceCandidates,
        substitution: Substitution.fromInterfaceType(interface),
        interface: getInterface2(interface.element3),
      );
    }

    var declared = _getTypeMembers(fragment, element);

    var interface = Map.of(declared);
    var interfaceConflicts = _findMostSpecificFromNamedCandidates(
      fragment,
      interface,
      interfaceCandidates,
    );

    var implemented = <Name, ExecutableElementOrMember>{};
    _addImplemented(implemented, fragment, element);

    var implemented2 = implemented.mapValue((value) => value.asElement2);

    var interfaceCandidates2 = interfaceCandidates.map<
      Name,
      List<ExecutableElement>
    >((key, value) => MapEntry(key, value.map((e) => e.asElement2).toList()));

    var superInterface2 = superInterface.mapValue((value) => value.asElement2);

    return Interface._(
      map: interface,
      declared: declared,
      implemented: implemented,
      implemented2: implemented2,
      noSuchMethodForwarders: {},
      overridden: interfaceCandidates,
      overridden2: interfaceCandidates2,
      redeclared: const {},
      redeclared2: const {},
      superImplemented: [superInterface],
      superImplemented2: [superInterface2],
      conflicts:
          <Conflict>[...superConflicts, ...interfaceConflicts].toFixedList(),
      combinedSignatures: _combinedSignatures.remove(fragment) ?? {},
    );
  }

  /// If a candidate from [namedCandidates] has covariant parameters, return
  /// a copy of the [executable] with the corresponding parameters marked
  /// covariant. If there are no covariant parameters, or parameters to
  /// update are already covariant, return the [executable] itself.
  ExecutableElementOrMember _inheritCovariance(
    InterfaceFragmentImpl class_,
    Map<Name, List<ExecutableElementOrMember>> namedCandidates,
    Name name,
    ExecutableElementOrMember executable,
  ) {
    if (executable.asElement2.enclosingElement == class_.asElement2) {
      return executable;
    }

    var parameters = executable.parameters;
    if (parameters.isEmpty) {
      return executable;
    }

    var candidates = namedCandidates[name];
    if (candidates == null) {
      return executable;
    }

    // Find parameters that are covariant (by declaration) in any overridden.
    Set<_ParameterDesc>? covariantParameters;
    for (var candidate in candidates) {
      var parameters = candidate.parameters;
      for (var i = 0; i < parameters.length; i++) {
        var parameter = parameters[i];
        if (parameter.isCovariant) {
          covariantParameters ??= {};
          covariantParameters.add(_ParameterDesc(i, parameter));
        }
      }
    }

    if (covariantParameters == null) {
      return executable;
    }

    // Update covariance of the parameters of the chosen executable.
    List<FormalParameterFragmentImpl>? transformedParameters;
    for (var index = 0; index < parameters.length; index++) {
      var parameter = parameters[index];
      var shouldBeCovariant = covariantParameters.contains(
        _ParameterDesc(index, parameter),
      );
      if (parameter.isCovariant != shouldBeCovariant) {
        transformedParameters ??= [
          for (var parameter in parameters) parameter.declaration,
        ];
        transformedParameters[index] = parameter.declaration.copyWith(
          isCovariant: shouldBeCovariant,
        );
      }
    }

    if (transformedParameters == null) {
      return executable;
    }

    if (executable is MethodElementOrMember) {
      var fragmentName = executable.name2 ?? '';

      var elementReference = class_.element.reference!
          .getChild('@method')
          .getChild(fragmentName);
      if (elementReference.element2 case MethodElementImpl result) {
        return result.firstFragment;
      }

      var result = MethodFragmentImpl(name2: executable.name2, nameOffset: -1);
      result.enclosingElement3 = class_;
      result.isSynthetic = true;
      result.parameters = transformedParameters;
      result.returnType = executable.returnType;
      result.typeParameters = executable.typeParameters;

      var elementName = executable.asElement2.name3!;
      MethodElementImpl(
        name3: elementName,
        reference: elementReference,
        firstFragment: result,
      );

      return result;
    }

    if (executable is SetterFragmentImpl) {
      var fragmentName = executable.name2 ?? '';
      var setterReference = class_.element.reference!
          .getChild('@setter')
          .getChild(fragmentName);
      if (setterReference.element2 case SetterElementImpl result) {
        return result.firstFragment;
      }

      var result = SetterFragmentImpl(name2: executable.name2, nameOffset: -1);
      result.enclosingElement3 = class_;
      result.isSynthetic = true;
      result.parameters = transformedParameters;
      result.returnType = executable.returnType;

      SetterElementImpl(setterReference, result);

      var field = executable.variable2!;
      var resultField = FieldFragmentImpl(name2: field.name2, nameOffset: -1);
      resultField.enclosingElement3 = class_;

      var elementName = executable.asElement2.name3!;
      var fieldReference = class_.element.reference!
          .getChild('@field')
          .getChild(elementName);
      assert(fieldReference.element2 == null);
      FieldElementImpl(reference: fieldReference, firstFragment: resultField);

      resultField.type = executable.parameters[0].type;
      return result;
    }

    return executable;
  }

  /// Given one or more [validOverrides], merge them into a single resulting
  /// signature. This signature always exists.
  ExecutableElementOrMember _topMerge(
    TypeSystemImpl typeSystem,
    InterfaceFragmentImpl targetClass,
    List<ExecutableElementOrMember> validOverrides,
  ) {
    var first = validOverrides[0];

    if (validOverrides.length == 1) {
      return first;
    }

    var firstType = first.type;
    if (validOverrides.every((e) => e.type == firstType)) {
      return first;
    }

    var resultType = _topMergeSignatureTypes(
      typeSystem: typeSystem,
      validOverrides: validOverrides,
    );

    for (var executable in validOverrides) {
      if (executable.type == resultType) {
        return executable;
      }
    }

    if (first is MethodElementOrMember) {
      var firstElement = first.asElement2;
      var fragmentName = firstElement.firstFragment.name2!;

      var elementReference = targetClass.element.reference!
          .getChild('@method')
          .getChild(fragmentName);
      if (elementReference.element2 case SetterElementImpl result) {
        return result.firstFragment;
      }

      var result = MethodFragmentImpl(name2: fragmentName, nameOffset: -1);
      result.enclosingElement3 = targetClass;
      result.typeParameters = resultType.typeFormals;
      result.returnType = resultType.returnType;
      // TODO(scheglov): check if can type cast instead
      result.parameters =
          resultType.parameters
              .map((e) => e.firstFragment as FormalParameterFragmentImpl)
              .toList();

      var elementName = first.asElement2.name3!;
      MethodElementImpl(
        name3: elementName,
        reference: elementReference,
        firstFragment: result,
      );

      return result;
    } else {
      var firstAccessor = first as PropertyAccessorElementOrMember;
      var fragmentName = first.asElement2.firstFragment.name2!;
      var field = FieldFragmentImpl(name2: fragmentName, nameOffset: -1);

      PropertyAccessorFragmentImpl result;
      if (firstAccessor.isGetter) {
        var elementReference = targetClass.element.reference!
            .getChild('@getter')
            .getChild(fragmentName);
        if (elementReference.element2 case GetterElementImpl result) {
          return result.firstFragment;
        }

        var fragment = GetterFragmentImpl(name2: fragmentName, nameOffset: -1);
        result = fragment;

        var element = GetterElementImpl(elementReference, fragment);
        element.returnType = resultType.returnType;
      } else {
        var elementReference = targetClass.element.reference!
            .getChild('@setter')
            .getChild(fragmentName);
        if (elementReference.element2 case SetterElementImpl result) {
          return result.firstFragment;
        }

        var fragment = SetterFragmentImpl(name2: fragmentName, nameOffset: -1);
        result = fragment;

        SetterElementImpl(elementReference, fragment);
      }
      result.enclosingElement3 = targetClass;
      result.returnType = resultType.returnType;
      // TODO(scheglov): check if can type cast instead
      result.parameters =
          resultType.parameters
              .map((e) => e.firstFragment as FormalParameterFragmentImpl)
              .toList();

      field.enclosingElement3 = targetClass;

      var elementName = first.asElement2.name3!;
      var elementReference = targetClass.element.reference!
          .getChild('@field')
          .getChild(elementName);
      assert(elementReference.element2 == null);
      var fieldElement = FieldElementImpl(
        reference: elementReference,
        firstFragment: field,
      );
      result.element.variable3 = fieldElement;

      if (firstAccessor.isGetter) {
        field.type = result.returnType;
      } else {
        field.type = result.parameters[0].type;
      }

      return result;
    }
  }

  static Map<Name, ExecutableElementOrMember> _getTypeMembers(
    InterfaceFragmentImpl fragment,
    InterfaceElementImpl element,
  ) {
    var declared = <Name, ExecutableElementOrMember>{};
    var libraryUri = fragment.librarySource.uri;

    void addMember(ExecutableElementOrMember member) {
      if (!member.isStatic) {
        var lookupName = member.element.lookupName;
        if (lookupName != null) {
          var name = Name(libraryUri, lookupName);
          declared[name] = member;
        }
      }
    }

    element.methods.map((e) => e.asElement).forEach(addMember);
    element.getters.map((e) => e.asElement).forEach(addMember);
    element.setters.map((e) => e.asElement).forEach(addMember);

    return declared;
  }

  /// Returns executables that are valid overrides of [candidates].
  static List<ExecutableElementOrMember> _getValidOverrides({
    required TypeSystemImpl typeSystem,
    required List<ExecutableElementOrMember> candidates,
  }) {
    var validOverrides = <ExecutableElementOrMember>[];
    outer:
    for (var i = 0; i < candidates.length; i++) {
      var validOverride = candidates[i];
      var validOverrideType = validOverride.type;
      for (var j = 0; j < candidates.length; j++) {
        var candidate = candidates[j];
        if (!typeSystem.isSubtypeOf(validOverrideType, candidate.type)) {
          continue outer;
        }
      }
      validOverrides.add(validOverride);
    }
    return validOverrides;
  }

  static bool _isDeclaredInObject(ExecutableElementOrMember element) {
    var enclosing = element.asElement2.enclosingElement;
    return enclosing is ClassElement && enclosing.isDartCoreObject;
  }

  static FunctionTypeImpl _topMergeSignatureTypes({
    required TypeSystemImpl typeSystem,
    required List<ExecutableElementOrMember> validOverrides,
  }) {
    return validOverrides
        .map((e) => typeSystem.normalizeFunctionType(e.type))
        .reduce((previous, next) {
          return typeSystem.topMerge(previous, next) as FunctionTypeImpl;
        });
  }
}

/// The instance interface of an [InterfaceType].
class Interface {
  static final _empty = Interface._(
    map: const {},
    declared: const {},
    implemented: const {},
    implemented2: const {},
    noSuchMethodForwarders: <Name>{},
    overridden: const {},
    overridden2: const {},
    redeclared: const {},
    redeclared2: const {},
    superImplemented: const [{}],
    superImplemented2: const [{}],
    conflicts: const [],
    combinedSignatures: const {},
  );

  /// The map of names to their signature in the interface.
  final Map<Name, ExecutableElementOrMember> map;

  /// The map of declared names to their signatures.
  final Map<Name, ExecutableElementOrMember> declared;

  /// The map of names to their concrete implementations.
  final Map<Name, ExecutableElementOrMember> implemented;

  /// The map of names to their concrete implementations.
  final Map<Name, ExecutableElement2OrMember> implemented2;

  /// The set of names that are `noSuchMethod` forwarders in [implemented].
  final Set<Name> noSuchMethodForwarders;

  /// The map of names to their signatures from the mixins, superclasses,
  /// or interfaces.
  final Map<Name, List<ExecutableElementOrMember>> overridden;

  /// The map of names to their signatures from the mixins, superclasses,
  /// or interfaces.
  final Map<Name, List<ExecutableElement>> overridden2;

  /// The map of names to the signatures from superinterfaces that a member
  /// declaration in this extension type redeclares.
  final Map<Name, List<ExecutableElementOrMember>> redeclared;

  /// The map of names to the signatures from superinterfaces that a member
  /// declaration in this extension type redeclares.
  final Map<Name, List<ExecutableElement>> redeclared2;

  /// Each item of this list maps names to their concrete implementations.
  /// The first item of the list is the nominal superclass, next the nominal
  /// superclass plus the first mixin, etc. So, for the class like
  /// `class C extends S with M1, M2`, we get `[S, S&M1, S&M1&M2]`.
  final List<Map<Name, ExecutableElementOrMember>> superImplemented;

  /// Each item of this list maps names to their concrete implementations.
  /// The first item of the list is the nominal superclass, next the nominal
  /// superclass plus the first mixin, etc. So, for the class like
  /// `class C extends S with M1, M2`, we get `[S, S&M1, S&M1&M2]`.
  final List<Map<Name, ExecutableElement>> superImplemented2;

  /// The list of conflicts between superinterfaces - the nominal superclass,
  /// mixins, and interfaces.  Does not include conflicts with the declared
  /// members of the class.
  final List<Conflict> conflicts;

  /// Tracks signatures from superinterfaces that were combined.
  /// It is used to track dependencies in manifests.
  final Map<Name, List<ExecutableElement2OrMember>> combinedSignatures;

  /// The map of names to the most specific signatures from the mixins,
  /// superclasses, or interfaces.
  Map<Name, ExecutableElementOrMember>? inheritedMap;

  Interface._({
    required this.map,
    required this.declared,
    required this.implemented,
    required this.implemented2,
    required this.noSuchMethodForwarders,
    required this.overridden,
    required this.overridden2,
    required this.redeclared,
    required this.redeclared2,
    required this.superImplemented,
    required this.superImplemented2,
    required this.conflicts,
    required this.combinedSignatures,
  });

  /// The map of declared names to their signatures.
  @experimental
  Map<Name, ExecutableElement> get declared2 {
    return declared.mapValue((element) => element.asElement2);
  }

  /// The map of names to the most specific signatures from the mixins,
  /// superclasses, or interfaces.
  Map<Name, ExecutableElement>? get inheritedMap2 {
    if (inheritedMap == null) {
      return null;
    }
    var inheritedMap2 = <Name, ExecutableElement>{};
    for (var entry in inheritedMap!.entries) {
      inheritedMap2[entry.key] = entry.value.asElement2;
    }
    return inheritedMap2;
  }

  /// The map of names to their signature in the interface.
  @experimental
  Map<Name, ExecutableElement2OrMember> get map2 {
    return map.mapValue((element) => element.asElement2);
  }

  /// Return `true` if the [name] is implemented in the supertype.
  bool isSuperImplemented(Name name) {
    return superImplemented.last.containsKey(name);
  }
}

/// A public name, or a private name qualified by a library URI.
@AnalyzerPublicApi(message: 'Exposed by InterfaceElement2 methods')
class Name {
  /// If the name is private, the URI of the defining library.
  /// Otherwise, it is `null`.
  final Uri? libraryUri;

  /// The name of this name object.
  /// If the name starts with `_`, then the name is private.
  /// Names of setters end with `=`.
  final String name;

  /// Precomputed
  final bool isPublic;

  /// The cached, pre-computed hash code.
  @override
  final int hashCode;

  factory Name(Uri? libraryUri, String name) {
    if (name.startsWith('_')) {
      var hashCode = Object.hash(libraryUri, name);
      return Name._internal(libraryUri, name, false, hashCode);
    } else {
      return Name._internal(null, name, true, name.hashCode);
    }
  }

  factory Name.forLibrary(LibraryElement? library, String name) {
    return Name(library?.uri, name);
  }

  Name._internal(this.libraryUri, this.name, this.isPublic, this.hashCode);

  Name get forGetter {
    if (name.endsWith('=')) {
      var getterName = name.substring(0, name.length - 1);
      return Name(libraryUri, getterName);
    } else {
      return this;
    }
  }

  Name get forSetter {
    if (name.endsWith('=')) {
      return this;
    } else {
      return Name(libraryUri, '$name=');
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Name &&
        name == other.name &&
        libraryUri == other.libraryUri;
  }

  bool isAccessibleFor(Uri libraryUri) {
    return isPublic || this.libraryUri == libraryUri;
  }

  @override
  String toString() => libraryUri != null ? '$libraryUri::$name' : name;

  /// Returns the name that corresponds to [element].
  ///
  /// If the element is private, the name includes the library URI.
  ///
  /// If the name is a setter, the name ends with `=`.
  static Name? forElement(Element element) {
    var name = element.lookupName;
    if (name == null) {
      return null;
    }

    if (name.startsWith('_')) {
      var libraryUri = element.library2!.uri;
      return Name(libraryUri, name);
    } else {
      return Name(null, name);
    }
  }
}

/// Failure because of not unique extension type member.
class NotUniqueExtensionMemberConflict extends Conflict {
  final List<ExecutableElementOrMember> candidates;

  NotUniqueExtensionMemberConflict({
    required super.name,
    required this.candidates,
  });

  List<ExecutableElement> get candidates2 =>
      candidates.map((e) => e.asElement2).toList();
}

class _ExtensionTypeCandidates {
  final Name name;
  final List<MethodElementOrMember> methods = [];
  final List<PropertyAccessorElementOrMember> getters = [];
  final List<PropertyAccessorElementOrMember> setters = [];

  _ExtensionTypeCandidates(this.name);

  List<ExecutableElementOrMember> get all {
    return [...methods, ...getters, ...setters];
  }

  void add(ExecutableElementOrMember element) {
    switch (element) {
      case MethodElementOrMember():
        methods.add(element);
      case PropertyAccessorElementOrMember(isGetter: true):
        getters.add(element);
      case PropertyAccessorElementOrMember(isSetter: true):
        setters.add(element);
    }
  }

  List<ExecutableElementOrMember> notPrecluded({
    required Set<Name> precludedNames,
    required Set<Name> precludedMethods,
    required Set<Name> precludedSetters,
  }) {
    if (precludedNames.contains(name)) {
      return const [];
    }
    return [
      if (!precludedMethods.contains(name)) ...methods,
      ...getters,
      if (!precludedSetters.contains(name)) ...setters,
    ];
  }
}

class _ParameterDesc {
  final int? index;
  final String? name;

  factory _ParameterDesc(int index, ParameterElementMixin element) {
    return element.isNamed
        ? _ParameterDesc.name(element.name2)
        : _ParameterDesc.index(index);
  }

  _ParameterDesc.index(this.index) : name = null;

  _ParameterDesc.name(this.name) : index = null;

  @override
  int get hashCode {
    return index?.hashCode ?? name?.hashCode ?? 0;
  }

  @override
  bool operator ==(other) {
    return other is _ParameterDesc &&
        other.index == index &&
        other.name == name;
  }
}
