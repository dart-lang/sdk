// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// Failure because of there is no most specific signature in [candidates].
class CandidatesConflict extends Conflict {
  /// The list has at least two items, because the only item is always valid.
  final List<ExecutableElement> candidates;

  CandidatesConflict({
    required super.name,
    required this.candidates,
  });
}

/// Failure to find a valid signature from superinterfaces.
class Conflict {
  /// The name for which we failed to find a valid signature.
  final Name name;

  Conflict({
    required this.name,
  });
}

/// Failure because of a getter and a method from direct superinterfaces.
class GetterMethodConflict extends Conflict {
  final ExecutableElement getter;
  final ExecutableElement method;

  GetterMethodConflict({
    required super.name,
    required this.getter,
    required this.method,
  });
}

/// The extension type has both an extension and non-extension member
/// signature with the same name.
class HasNonExtensionAndExtensionMemberConflict extends Conflict {
  final List<ExecutableElement> nonExtension;
  final List<ExecutableElement> extension;

  HasNonExtensionAndExtensionMemberConflict({
    required super.name,
    required this.nonExtension,
    required this.extension,
  });
}

/// Manages knowledge about interface types and their members.
class InheritanceManager3 {
  static final _noSuchMethodName =
      Name(null, FunctionElement.NO_SUCH_METHOD_METHOD_NAME);

  /// Cached instance interfaces for [ClassElement].
  final Map<InterfaceElement, Interface> _interfaces = {};

  /// The set of classes that are currently being processed, used to detect
  /// self-referencing cycles.
  final Set<InterfaceElement> _processingClasses = {};

  /// Combine [candidates] into a single signature in the [targetClass].
  ///
  /// If such signature does not exist, return `null`, and if [conflicts] is
  /// not `null`, add a new [Conflict] to it.
  ExecutableElement? combineSignatures({
    required InterfaceElement targetClass,
    required List<ExecutableElement> candidates,
    required bool doTopMerge,
    required Name name,
    List<Conflict>? conflicts,
  }) {
    // If just one candidate, it is always valid.
    if (candidates.length == 1) {
      return candidates[0];
    }

    // Check for a getter/method conflict.
    var conflict = _checkForGetterMethodConflict(name, candidates);
    if (conflict != null) {
      conflicts?.add(conflict);
      return null;
    }

    var targetLibrary = targetClass.library as LibraryElementImpl;
    var typeSystem = targetLibrary.typeSystem;

    var validOverrides = <ExecutableElement>[];
    for (var i = 0; i < candidates.length; i++) {
      ExecutableElement? validOverride = candidates[i];
      var validOverrideType = validOverride.type;
      for (var j = 0; j < candidates.length; j++) {
        var candidate = candidates[j];
        if (!typeSystem.isSubtypeOf(validOverrideType, candidate.type)) {
          validOverride = null;
          break;
        }
      }
      if (validOverride != null) {
        validOverrides.add(validOverride);
      }
    }

    if (validOverrides.isEmpty) {
      conflicts?.add(
        CandidatesConflict(
          name: name,
          candidates: candidates,
        ),
      );
      return null;
    }

    if (doTopMerge) {
      var typeSystem = targetClass.library.typeSystem as TypeSystemImpl;
      return _topMerge(typeSystem, targetClass, validOverrides);
    } else {
      return validOverrides.first;
    }
  }

  /// Return the result of [getInherited2] with [type] substitution.
  ExecutableElement? getInherited(InterfaceType type, Name name) {
    var rawElement = getInherited2(type.element, name);
    if (rawElement == null) {
      return null;
    }

    return ExecutableMember.from2(
      rawElement,
      Substitution.fromInterfaceType(type),
    );
  }

  /// Return the most specific signature of the member with the given [name]
  /// that [element] inherits from the mixins, superclasses, or interfaces;
  /// or `null` if no member is inherited because the member is not declared
  /// at all, or because there is no the most specific signature.
  ///
  /// This is equivalent to `getInheritedMap2(type)[name]`.
  ExecutableElement? getInherited2(InterfaceElement element, Name name) {
    return getInheritedMap2(element)[name];
  }

  /// Return signatures of all concrete members that the given [type] inherits
  /// from the superclasses and mixins.
  @Deprecated('Use getInheritedConcreteMap2')
  Map<Name, ExecutableElement> getInheritedConcreteMap(InterfaceType type) {
    var result = <Name, ExecutableElement>{};

    var substitution = Substitution.fromInterfaceType(type);
    var rawMap = getInheritedConcreteMap2(type.element);
    for (var rawEntry in rawMap.entries) {
      result[rawEntry.key] = ExecutableMember.from2(
        rawEntry.value,
        substitution,
      );
    }

    return result;
  }

  /// Return signatures of all concrete members that the given [element] inherits
  /// from the superclasses and mixins.
  Map<Name, ExecutableElement> getInheritedConcreteMap2(
      InterfaceElement element) {
    if (element is ExtensionTypeElement) {
      return const {};
    }

    var interface = getInterface(element);
    return interface.superImplemented.last;
  }

  /// Return the mapping from names to most specific signatures of members
  /// inherited from the super-interfaces (superclasses, mixins, and
  /// interfaces).  If there is no most specific signature for a name, the
  /// corresponding name will not be included.
  @Deprecated('Use getInheritedMap2')
  Map<Name, ExecutableElement> getInheritedMap(InterfaceType type) {
    var result = <Name, ExecutableElement>{};

    var substitution = Substitution.fromInterfaceType(type);
    var rawMap = getInheritedMap2(type.element);
    for (var rawEntry in rawMap.entries) {
      result[rawEntry.key] = ExecutableMember.from2(
        rawEntry.value,
        substitution,
      );
    }

    return result;
  }

  /// Return the mapping from names to most specific signatures of members
  /// inherited from the super-interfaces (superclasses, mixins, and
  /// interfaces).  If there is no most specific signature for a name, the
  /// corresponding name will not be included.
  Map<Name, ExecutableElement> getInheritedMap2(InterfaceElement element) {
    var interface = getInterface(element);
    var inheritedMap = interface.inheritedMap;
    if (inheritedMap == null) {
      inheritedMap = interface.inheritedMap = {};
      _findMostSpecificFromNamedCandidates(
        element,
        inheritedMap,
        element is ExtensionTypeElement
            ? interface.redeclared
            : interface.overridden,
        doTopMerge: false,
      );
    }
    return inheritedMap;
  }

  /// Return the interface of the given [element].  It might include
  /// private members, not necessary accessible in all libraries.
  Interface getInterface(InterfaceElement element) {
    var result = _interfaces[element];
    if (result != null) {
      return result;
    }
    _interfaces[element] = Interface._empty;

    if (!_processingClasses.add(element)) {
      return Interface._empty;
    }

    try {
      if (element is ExtensionTypeElement) {
        result = _getInterfaceExtensionType(element);
      } else if (element is MixinElement) {
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

  /// Return the result of [getMember2] with [type] substitution.
  ExecutableElement? getMember(
    InterfaceType type,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    var rawElement = getMember2(
      type.element,
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
  ExecutableElement? getMember2(
    InterfaceElement element,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    var interface = getInterface(element);
    if (forSuper) {
      if (element is ExtensionTypeElement) {
        return null;
      }
      var superImplemented = interface.superImplemented;
      if (forMixinIndex >= 0) {
        return superImplemented[forMixinIndex][name];
      }
      if (superImplemented.isNotEmpty) {
        return superImplemented.last[name];
      } else {
        assert(element.name == 'Object');
        return null;
      }
    }
    if (concrete) {
      return interface.implemented[name];
    }
    return interface.map[name];
  }

  /// Return all members of mixins, superclasses, and interfaces that a member
  /// with the given [name], defined in the [type], would override; or `null`
  /// if no members would be overridden.
  @Deprecated('Use getOverridden2')
  List<ExecutableElement>? getOverridden(InterfaceType type, Name name) {
    return getOverridden2(type.element, name);
  }

  /// Return all members of mixins, superclasses, and interfaces that a member
  /// with the given [name], defined in the [element], would override; or `null`
  /// if no members would be overridden.
  List<ExecutableElement>? getOverridden2(InterfaceElement element, Name name) {
    var interface = getInterface(element);
    return interface.overridden[name];
  }

  /// Remove interfaces for classes defined in specified libraries.
  void removeOfLibraries(Set<Uri> uriSet) {
    _interfaces.removeWhere((element, _) {
      return uriSet.contains(element.librarySource.uri);
    });
  }

  void _addCandidates({
    required Map<Name, List<ExecutableElement>> namedCandidates,
    required MapSubstitution substitution,
    required Interface interface,
    required bool isNonNullableByDefault,
  }) {
    var map = interface.map;
    for (var entry in map.entries) {
      var name = entry.key;
      var candidate = entry.value;

      candidate = ExecutableMember.from2(candidate, substitution);

      if (!isNonNullableByDefault) {
        candidate = Member.legacy(candidate) as ExecutableElement;
      }

      var candidates = namedCandidates[name];
      if (candidates == null) {
        candidates = <ExecutableElement>[];
        namedCandidates[name] = candidates;
      }

      candidates.add(candidate);
    }
  }

  void _addImplemented(
    Map<Name, ExecutableElement> implemented,
    InterfaceElement element,
    AugmentedInterfaceElement augmented,
  ) {
    var libraryUri = element.librarySource.uri;

    void addMember(ExecutableElement member) {
      if (!member.isAbstract && !member.isStatic) {
        var name = Name(libraryUri, member.name);
        implemented[name] = member;
      }
    }

    augmented.methods.forEach(addMember);
    augmented.accessors.forEach(addMember);
  }

  void _addMixinMembers({
    required Map<Name, ExecutableElement> implemented,
    required MapSubstitution substitution,
    required Interface mixin,
    required bool isNonNullableByDefault,
  }) {
    for (var entry in mixin.implemented.entries) {
      var executable = entry.value;
      if (executable.isAbstract) {
        continue;
      }

      var class_ = executable.enclosingElement;
      if (class_ is ClassElement && class_.isDartCoreObject) {
        continue;
      }

      executable = ExecutableMember.from2(executable, substitution);

      if (!isNonNullableByDefault) {
        executable = Member.legacy(executable) as ExecutableElement;
      }

      implemented[entry.key] = executable;
    }
  }

  /// Check that all [candidates] for the given [name] have the same kind, all
  /// getters, all methods, or all setter.  If a conflict found, return the
  /// new [Conflict] instance that describes it.
  Conflict? _checkForGetterMethodConflict(
      Name name, List<ExecutableElement> candidates) {
    assert(candidates.length > 1);

    ExecutableElement? getter;
    ExecutableElement? method;
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

  /// The given [namedCandidates] maps names to candidates from direct
  /// superinterfaces.  Find the most specific signature, and put it into the
  /// [map], if there is no one yet (from the class itself).  If there is no
  /// such single most specific signature (i.e. no valid override), then add a
  /// new conflict description.
  List<Conflict> _findMostSpecificFromNamedCandidates(
    InterfaceElement targetClass,
    Map<Name, ExecutableElement> map,
    Map<Name, List<ExecutableElement>> namedCandidates, {
    required bool doTopMerge,
  }) {
    var conflicts = <Conflict>[];

    for (var entry in namedCandidates.entries) {
      var name = entry.key;
      if (map.containsKey(name)) {
        continue;
      }

      var candidates = entry.value;

      var combinedSignature = combineSignatures(
        targetClass: targetClass,
        candidates: candidates,
        doTopMerge: doTopMerge,
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

  Interface _getInterfaceClass(InterfaceElement element) {
    final augmented = element.augmentedOfDeclaration;
    var classLibrary = element.library;
    var isNonNullableByDefault = classLibrary.isNonNullableByDefault;

    var namedCandidates = <Name, List<ExecutableElement>>{};
    var superImplemented = <Map<Name, ExecutableElement>>[];
    var implemented = <Name, ExecutableElement>{};

    final InterfaceType? superType = element.supertype;

    Interface? superTypeInterface;
    if (superType != null) {
      var substitution = Substitution.fromInterfaceType(superType);
      superTypeInterface = getInterface(superType.element);
      _addCandidates(
        namedCandidates: namedCandidates,
        substitution: substitution,
        interface: superTypeInterface,
        isNonNullableByDefault: isNonNullableByDefault,
      );

      for (var entry in superTypeInterface.implemented.entries) {
        var executable = entry.value;
        executable = ExecutableMember.from2(executable, substitution);
        if (!isNonNullableByDefault) {
          executable = Member.legacy(executable) as ExecutableElement;
        }
        implemented[entry.key] = executable;
      }

      superImplemented.add(implemented);
    }

    // TODO(scheglov): Handling of members for super and mixins is not
    // optimal. We always have just one member for each name in super,
    // multiple candidates happen only when we merge super and multiple
    // interfaces. Consider using `Map<Name, ExecutableElement>` here.
    var mixinsConflicts = <List<Conflict>>[];
    for (var mixin in augmented.mixins) {
      var mixinElement = mixin.element;
      var substitution = Substitution.fromInterfaceType(mixin);
      var mixinInterface = getInterface(mixinElement);
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
      var candidatesFromSuperAndMixin = <Name, List<ExecutableElement>>{};
      var mixinConflicts = <Conflict>[];
      for (var entry in mixinInterface.map.entries) {
        var name = entry.key;
        var candidate = ExecutableMember.from2(
          entry.value,
          substitution,
        );

        var currentList = namedCandidates[name];
        if (currentList == null) {
          namedCandidates[name] = [
            isNonNullableByDefault
                ? candidate
                : Member.legacy(candidate) as ExecutableElement,
          ];
          continue;
        }

        var current = currentList.single;
        if (candidate.enclosingElement == mixinElement) {
          namedCandidates[name] = [
            isNonNullableByDefault
                ? candidate
                : Member.legacy(candidate) as ExecutableElement,
          ];
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
        var map = <Name, ExecutableElement>{};
        _findMostSpecificFromNamedCandidates(
          element,
          map,
          candidatesFromSuperAndMixin,
          doTopMerge: true,
        );
        for (var entry in map.entries) {
          namedCandidates[entry.key] = [
            isNonNullableByDefault
                ? entry.value
                : Member.legacy(entry.value) as ExecutableElement,
          ];
        }
      }

      mixinsConflicts.add(mixinConflicts);

      implemented = Map.of(implemented);
      _addMixinMembers(
        implemented: implemented,
        substitution: substitution,
        mixin: mixinInterface,
        isNonNullableByDefault: isNonNullableByDefault,
      );

      superImplemented.add(implemented);
    }

    for (var interface in augmented.interfaces) {
      _addCandidates(
        namedCandidates: namedCandidates,
        substitution: Substitution.fromInterfaceType(interface),
        interface: getInterface(interface.element),
        isNonNullableByDefault: isNonNullableByDefault,
      );
    }

    implemented = Map.of(implemented);
    _addImplemented(implemented, element, augmented);

    // If a class declaration has a member declaration, the signature of that
    // member declaration becomes the signature in the interface.
    var declared = _getTypeMembers(element, augmented);

    // If a class declaration does not have a member declaration with a
    // particular name, but some super-interfaces do have a member with that
    // name, it's a compile-time error if there is no signature among the
    // super-interfaces that is a valid override of all the other
    // super-interface signatures with the same name. That "most specific"
    // signature becomes the signature of the class's interface.
    var interface = Map.of(declared);
    List<Conflict> conflicts = _findMostSpecificFromNamedCandidates(
      element,
      interface,
      namedCandidates,
      doTopMerge: true,
    );

    var noSuchMethodForwarders = <Name>{};
    if (element is ClassElement && element.isAbstract) {
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

    implemented = implemented.map<Name, ExecutableElement>((key, value) {
      var result = _inheritCovariance(element, namedCandidates, key, value);
      return MapEntry(key, result);
    });

    return Interface._(
      map: interface,
      declared: declared,
      implemented: implemented,
      noSuchMethodForwarders: noSuchMethodForwarders,
      overridden: namedCandidates,
      redeclared: const {},
      superImplemented: superImplemented,
      conflicts: conflicts.toFixedList(),
    );
  }

  /// See https://github.com/dart-lang/language
  ///   blob/main/accepted/future-releases/extension-types/feature-specification.md
  ///   #static-analysis-of-an-extension-type-member-invocation
  ///
  /// We handle "has an extension type member" and "has a non-extension type
  /// member" portions, considering redeclaration and conflicts.
  Interface _getInterfaceExtensionType(ExtensionTypeElement element) {
    final augmented = element.augmentedOfDeclaration;

    // Add instance members implemented by the element itself.
    final declared = <Name, ExecutableElement>{};
    _addImplemented(declared, element, augmented);

    // Prepare precluded names.
    final precludedNames = <Name>{};
    final precludedMethods = <Name>{};
    final precludedSetters = <Name>{};
    for (final entry in declared.entries) {
      final name = entry.key;
      precludedNames.add(name);
      switch (entry.value) {
        case MethodElement():
          precludedSetters.add(name.forSetter);
        case PropertyAccessorElement(isSetter: true):
          precludedMethods.add(name.forGetter);
      }
    }

    // These declared members take precedence over "inherited" ones.
    final implemented = Map.of(declared);

    // Prepare candidates for inheritance.
    final extensionCandidates = <Name, _ExtensionTypeCandidates>{};
    final notExtensionCandidates = <Name, _ExtensionTypeCandidates>{};
    for (final interface in augmented.interfaces) {
      final substitution = Substitution.fromInterfaceType(interface);
      for (final entry in getInterface(interface.element).map.entries) {
        final name = entry.key;
        final executable = ExecutableMember.from2(entry.value, substitution);
        if (executable.isExtensionTypeMember) {
          (extensionCandidates[name] ??= _ExtensionTypeCandidates(name))
              .add(executable);
        } else {
          (notExtensionCandidates[name] ??= _ExtensionTypeCandidates(name))
              .add(executable);
        }
      }
    }

    final redeclared = <Name, List<ExecutableElement>>{};
    final conflicts = <Conflict>[];

    // Add extension type members.
    for (final entry in extensionCandidates.entries) {
      final name = entry.key;
      final candidates = entry.value;
      (redeclared[name] ??= []).addAll(candidates.all);

      final notPrecluded = candidates.notPrecluded(
        precludedNames: precludedNames,
        precludedMethods: precludedMethods,
        precludedSetters: precludedSetters,
      );

      // Stop if all precluded.
      if (notPrecluded.isEmpty) {
        continue;
      }

      // If not precluded, can have either non-extension, or extension.
      final nonExtensionSignatures = notExtensionCandidates[name];
      if (nonExtensionSignatures != null) {
        final notExtensionNotPrecluded = nonExtensionSignatures.notPrecluded(
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
      ExecutableElement? uniqueElement;
      for (final candidate in notPrecluded) {
        if (uniqueElement == null) {
          uniqueElement = candidate;
        } else if (uniqueElement.declaration != candidate.declaration) {
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
    for (final entry in notExtensionCandidates.entries) {
      final name = entry.key;
      final candidates = entry.value;
      (redeclared[name] ??= []).addAll(candidates.all);

      final notPrecluded = candidates.notPrecluded(
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

      final combinedSignature = combineSignatures(
        targetClass: element,
        candidates: notPrecluded,
        doTopMerge: true,
        name: name,
      );

      if (combinedSignature == null) {
        conflicts.add(
          CandidatesConflict(
            name: name,
            candidates: notPrecluded,
          ),
        );
        continue;
      }

      implemented[name] = combinedSignature;
    }

    // Ensure unique overridden elements.
    final uniqueRedeclared = <Name, List<ExecutableElement>>{};
    for (final entry in redeclared.entries) {
      final name = entry.key;
      final elements = entry.value;
      if (elements.length == 1) {
        uniqueRedeclared[name] = elements;
      } else {
        uniqueRedeclared[name] = elements.toSet().toFixedList();
      }
    }

    return Interface._(
      map: implemented,
      declared: declared,
      implemented: implemented,
      noSuchMethodForwarders: const {},
      overridden: const {},
      redeclared: uniqueRedeclared,
      superImplemented: const [],
      conflicts: conflicts.toFixedList(),
    );
  }

  Interface _getInterfaceMixin(MixinElement element) {
    final augmented = element.augmentedOfDeclaration;
    var classLibrary = element.library;
    var isNonNullableByDefault = classLibrary.isNonNullableByDefault;

    var superCandidates = <Name, List<ExecutableElement>>{};
    for (var constraint in augmented.superclassConstraints) {
      var substitution = Substitution.fromInterfaceType(constraint);
      var interfaceObj = getInterface(constraint.element);
      _addCandidates(
        namedCandidates: superCandidates,
        substitution: substitution,
        interface: interfaceObj,
        isNonNullableByDefault: isNonNullableByDefault,
      );
    }

    // `mixin M on S1, S2 {}` can call using `super` any instance member
    // from its superclass constraints, whether it is abstract or concrete.
    var superInterface = <Name, ExecutableElement>{};
    var superConflicts = _findMostSpecificFromNamedCandidates(
      element,
      superInterface,
      superCandidates,
      doTopMerge: true,
    );

    var interfaceCandidates = Map.of(superCandidates);
    for (var interface in augmented.interfaces) {
      _addCandidates(
        namedCandidates: interfaceCandidates,
        substitution: Substitution.fromInterfaceType(interface),
        interface: getInterface(interface.element),
        isNonNullableByDefault: isNonNullableByDefault,
      );
    }

    var declared = _getTypeMembers(element, augmented);

    var interface = Map.of(declared);
    var interfaceConflicts = _findMostSpecificFromNamedCandidates(
      element,
      interface,
      interfaceCandidates,
      doTopMerge: true,
    );

    var implemented = <Name, ExecutableElement>{};
    _addImplemented(implemented, element, augmented);

    return Interface._(
      map: interface,
      declared: declared,
      implemented: implemented,
      noSuchMethodForwarders: {},
      overridden: interfaceCandidates,
      redeclared: const {},
      superImplemented: [superInterface],
      conflicts: <Conflict>[
        ...superConflicts,
        ...interfaceConflicts,
      ].toFixedList(),
    );
  }

  /// If a candidate from [namedCandidates] has covariant parameters, return
  /// a copy of the [executable] with the corresponding parameters marked
  /// covariant. If there are no covariant parameters, or parameters to
  /// update are already covariant, return the [executable] itself.
  ExecutableElement _inheritCovariance(
    InterfaceElement class_,
    Map<Name, List<ExecutableElement>> namedCandidates,
    Name name,
    ExecutableElement executable,
  ) {
    if (executable.enclosingElement == class_) {
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
          covariantParameters.add(
            _ParameterDesc(i, parameter),
          );
        }
      }
    }

    if (covariantParameters == null) {
      return executable;
    }

    // Update covariance of the parameters of the chosen executable.
    List<ParameterElement>? transformedParameters;
    for (var index = 0; index < parameters.length; index++) {
      var parameter = parameters[index];
      var shouldBeCovariant = covariantParameters.contains(
        _ParameterDesc(index, parameter),
      );
      if (parameter.isCovariant != shouldBeCovariant) {
        transformedParameters ??= parameters.toList();
        transformedParameters[index] = parameter.copyWith(
          isCovariant: shouldBeCovariant,
        );
      }
    }

    if (transformedParameters == null) {
      return executable;
    }

    if (executable is MethodElement) {
      var result = MethodElementImpl(executable.name, -1);
      result.enclosingElement = class_;
      result.isSynthetic = true;
      result.parameters = transformedParameters;
      result.prototype = executable;
      result.returnType = executable.returnType;
      result.typeParameters = executable.typeParameters;
      return result;
    }

    if (executable is PropertyAccessorElementImpl) {
      assert(executable.isSetter);
      var result = PropertyAccessorElementImpl(executable.name, -1);
      result.enclosingElement = class_;
      result.isSynthetic = true;
      result.parameters = transformedParameters;
      result.prototype = executable;
      result.returnType = executable.returnType;

      var field = executable.variable;
      var resultField = FieldElementImpl(field.name, -1);
      resultField.enclosingElement = class_;
      resultField.getter = field.getter;
      resultField.setter = executable;
      resultField.type = executable.parameters[0].type;
      result.variable = resultField;

      return result;
    }

    return executable;
  }

  /// Given one or more [validOverrides], merge them into a single resulting
  /// signature. This signature always exists.
  ExecutableElement _topMerge(
    TypeSystemImpl typeSystem,
    InterfaceElement targetClass,
    List<ExecutableElement> validOverrides,
  ) {
    var first = validOverrides[0];

    if (validOverrides.length == 1) {
      return first;
    }

    if (!typeSystem.isNonNullableByDefault) {
      return first;
    }

    var firstType = first.type;
    var allTypesEqual = true;
    for (var executable in validOverrides) {
      if (executable.type != firstType) {
        allTypesEqual = false;
        break;
      }
    }

    if (allTypesEqual) {
      return first;
    }

    var resultType = validOverrides.map((e) {
      return typeSystem.normalize(e.type) as FunctionType;
    }).reduce((previous, next) {
      return typeSystem.topMerge(previous, next) as FunctionType;
    });

    for (var executable in validOverrides) {
      if (executable.type == resultType) {
        return executable;
      }
    }

    if (first is MethodElement) {
      var firstMethod = first;
      var result = MethodElementImpl(firstMethod.name, -1);
      result.enclosingElement = targetClass;
      result.typeParameters = resultType.typeFormals;
      result.returnType = resultType.returnType;
      result.parameters = resultType.parameters;
      return result;
    } else {
      var firstAccessor = first as PropertyAccessorElement;
      var variableName = firstAccessor.displayName;

      var result = PropertyAccessorElementImpl(variableName, -1);
      result.enclosingElement = targetClass;
      result.isGetter = firstAccessor.isGetter;
      result.isSetter = firstAccessor.isSetter;
      result.returnType = resultType.returnType;
      result.parameters = resultType.parameters;

      var field = FieldElementImpl(variableName, -1);
      field.enclosingElement = targetClass;
      if (firstAccessor.isGetter) {
        field.getter = result;
        field.type = result.returnType;
      } else {
        field.setter = result;
        field.type = result.parameters[0].type;
      }
      result.variable = field;

      return result;
    }
  }

  static Map<Name, ExecutableElement> _getTypeMembers(
    InterfaceElement element,
    AugmentedInterfaceElement augmented,
  ) {
    var declared = <Name, ExecutableElement>{};
    var libraryUri = element.librarySource.uri;

    var methods = augmented.methods;
    for (var i = 0; i < methods.length; i++) {
      var method = methods[i];
      if (!method.isStatic) {
        var name = Name(libraryUri, method.name);
        declared[name] = method;
      }
    }

    var accessors = augmented.accessors;
    for (var i = 0; i < accessors.length; i++) {
      var accessor = accessors[i];
      if (!accessor.isStatic) {
        var name = Name(libraryUri, accessor.name);
        declared[name] = accessor;
      }
    }

    return declared;
  }

  static bool _isDeclaredInObject(ExecutableElement element) {
    var enclosing = element.enclosingElement;
    return enclosing is ClassElement && enclosing.isDartCoreObject;
  }
}

/// The instance interface of an [InterfaceType].
class Interface {
  static final _empty = Interface._(
    map: const {},
    declared: const {},
    implemented: const {},
    noSuchMethodForwarders: <Name>{},
    overridden: const {},
    redeclared: const {},
    superImplemented: const [{}],
    conflicts: const [],
  );

  /// The map of names to their signature in the interface.
  final Map<Name, ExecutableElement> map;

  /// The map of declared names to their signatures.
  final Map<Name, ExecutableElement> declared;

  /// The map of names to their concrete implementations.
  final Map<Name, ExecutableElement> implemented;

  /// The set of names that are `noSuchMethod` forwarders in [implemented].
  final Set<Name> noSuchMethodForwarders;

  /// The map of names to their signatures from the mixins, superclasses,
  /// or interfaces.
  final Map<Name, List<ExecutableElement>> overridden;

  /// The map of names to the signatures from superinterfaces that a member
  /// declaration in this extension type redeclares.
  final Map<Name, List<ExecutableElement>> redeclared;

  /// Each item of this list maps names to their concrete implementations.
  /// The first item of the list is the nominal superclass, next the nominal
  /// superclass plus the first mixin, etc. So, for the class like
  /// `class C extends S with M1, M2`, we get `[S, S&M1, S&M1&M2]`.
  final List<Map<Name, ExecutableElement>> superImplemented;

  /// The list of conflicts between superinterfaces - the nominal superclass,
  /// mixins, and interfaces.  Does not include conflicts with the declared
  /// members of the class.
  final List<Conflict> conflicts;

  /// The map of names to the most specific signatures from the mixins,
  /// superclasses, or interfaces.
  Map<Name, ExecutableElement>? inheritedMap;

  Interface._({
    required this.map,
    required this.declared,
    required this.implemented,
    required this.noSuchMethodForwarders,
    required this.overridden,
    required this.redeclared,
    required this.superImplemented,
    required this.conflicts,
  });

  /// Return `true` if the [name] is implemented in the supertype.
  bool isSuperImplemented(Name name) {
    return superImplemented.last.containsKey(name);
  }
}

/// A public name, or a private name qualified by a library URI.
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

  Name._internal(this.libraryUri, this.name, this.isPublic, this.hashCode);

  Name get forGetter {
    if (name.endsWith('=')) {
      final getterName = name.substring(0, name.length - 1);
      return Name(libraryUri, getterName);
    } else {
      return this;
    }
  }

  Name get forSetter {
    return Name(libraryUri, '$name=');
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
}

/// Failure because of not unique extension type member.
class NotUniqueExtensionMemberConflict extends Conflict {
  final List<ExecutableElement> candidates;

  NotUniqueExtensionMemberConflict({
    required super.name,
    required this.candidates,
  });
}

class _ExtensionTypeCandidates {
  final Name name;
  final List<MethodElement> methods = [];
  final List<PropertyAccessorElement> getters = [];
  final List<PropertyAccessorElement> setters = [];

  _ExtensionTypeCandidates(this.name);

  List<ExecutableElement> get all {
    return [...methods, ...getters, ...setters];
  }

  void add(ExecutableElement element) {
    switch (element) {
      case MethodElement():
        methods.add(element);
      case PropertyAccessorElement(isGetter: true):
        getters.add(element);
      case PropertyAccessorElement(isSetter: true):
        setters.add(element);
    }
  }

  List<ExecutableElement> notPrecluded({
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

  factory _ParameterDesc(int index, ParameterElement element) {
    return element.isNamed
        ? _ParameterDesc.name(element.name)
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
