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

/// Failure because of there is no most specific signature in [candidates].
class CandidatesConflict extends Conflict {
  /// The list has at least two items, because the only item is always valid.
  final List<InternalExecutableElement> candidates;

  CandidatesConflict({required super.name, required this.candidates});
}

/// Failure to find a valid signature from superinterfaces.
class Conflict {
  /// The name for which we failed to find a valid signature.
  final Name name;

  Conflict({required this.name});
}

/// Failure because of a getter and a method from direct superinterfaces.
class GetterMethodConflict extends Conflict {
  final InternalExecutableElement getter;
  final InternalExecutableElement method;

  GetterMethodConflict({
    required super.name,
    required this.getter,
    required this.method,
  });
}

/// The extension type has both an extension and non-extension member
/// signature with the same name.
class HasNonExtensionAndExtensionMemberConflict extends Conflict {
  final List<InternalExecutableElement> nonExtension;
  final List<InternalExecutableElement> extension;

  HasNonExtensionAndExtensionMemberConflict({
    required super.name,
    required this.nonExtension,
    required this.extension,
  });
}

/// Manages knowledge about interface types and their members.
class InheritanceManager3 {
  static final _noSuchMethodName = Name(
    null,
    MethodElement.NO_SUCH_METHOD_METHOD_NAME,
  );

  /// Cached instance interfaces for [InterfaceElementImpl].
  final Map<InterfaceElementImpl, Interface> _interfaces = {};

  /// Tracks signatures from superinterfaces that were combined.
  /// It is used to track dependencies in manifests.
  final Map<InterfaceElementImpl, Map<Name, List<InternalExecutableElement>>>
  _combinedSignatures = {};

  /// The set of classes that are currently being processed, used to detect
  /// self-referencing cycles.
  final Set<InterfaceElementImpl> _processingClasses = {};

  /// Combine types of [candidates] into a single most specific type.
  ///
  /// If such signature does not exist, return `null`, and if [conflicts] is
  /// not `null`, add a new [Conflict] to it.
  FunctionTypeImpl? combineSignatureTypes({
    required TypeSystemImpl typeSystem,
    required List<InternalExecutableElement> candidates,
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

  /// Returns the most specific signature of the member with the given [name]
  /// that [element] inherits from the mixins, superclasses, or interfaces.
  ///
  /// Returns `null` if no member is inherited because the member is not
  /// declared at all, or because there is no the most specific signature.
  ///
  /// This is equivalent to `getInheritedMap(type)[name]`.
  InternalExecutableElement? getInherited(InterfaceElement element, Name name) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    return getInheritedMap(element)[name];
  }

  /// Returns signatures of all concrete members that the given [element]
  /// inherits from the superclasses and mixins.
  Map<Name, ExecutableElement> getInheritedConcreteMap(
    InterfaceElement element,
  ) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    if (element is ExtensionTypeElementImpl) {
      return const {};
    }

    var interface = getInterface(element);
    if (interface.superImplemented.isEmpty) {
      assert(element.name == 'Object');
      return const {};
    }

    return interface.superImplemented.last;
  }

  /// Returns the mapping from names to most specific signatures of members
  /// inherited from the super-interfaces (superclasses, mixins, and
  /// interfaces).
  ///
  /// If there is no most specific signature for a name, the corresponding name
  /// will not be included.
  Map<Name, InternalExecutableElement> getInheritedMap(
    InterfaceElement element,
  ) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast

    var interface = getInterface(element);
    var inheritedMap = interface.inheritedMap;
    if (inheritedMap == null) {
      inheritedMap = interface.inheritedMap = {};
      _findMostSpecificFromNamedCandidates(
        element,
        inheritedMap,
        element is ExtensionTypeElementImpl
            ? interface.redeclared
            : interface.overridden,
      );
    }
    return inheritedMap;
  }

  /// Returns the interface of the given [element].
  ///
  /// The interface might include private members, not necessary accessible in
  /// all libraries.
  Interface getInterface(InterfaceElement element) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    globalResultRequirements?.record_interface_all(element: element);
    return _getInterface(element);
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
  InternalExecutableElement? getMember(
    InterfaceElement element,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast

    var interface = _getInterface(element);

    InternalExecutableElement? result;
    if (forSuper) {
      if (element is ExtensionTypeElementImpl) {
        result = null;
      } else {
        var superImplemented = interface.superImplemented;
        if (forMixinIndex >= 0) {
          result = superImplemented[forMixinIndex][name];
        } else if (superImplemented.isNotEmpty) {
          result = superImplemented.last[name];
        } else {
          assert(element.name == 'Object');
          result = null;
        }
      }
    } else if (concrete) {
      result = interface.implemented[name];
    } else {
      result = interface.map[name];
    }

    // if (forSuper) {
    //   if (element is ExtensionTypeElementImpl) {
    //     return null;
    //   }
    //   var superImplemented = interface.superImplemented;
    //   if (forMixinIndex >= 0) {
    //     return superImplemented[forMixinIndex][name];
    //   }
    //   if (superImplemented.isNotEmpty) {
    //     return superImplemented.last[name];
    //   } else {
    //     assert(element.name == 'Object');
    //     return null;
    //   }
    // }
    // if (concrete) {
    //   return interface.implemented[name];
    // }
    // var result = interface.map[name];

    globalResultRequirements?.record_interface_getMember(
      element: element,
      nameObj: name,
      methodElement: result,
      concrete: concrete,
      forSuper: forSuper,
      forMixinIndex: forMixinIndex,
    );
    return result;
  }

  /// Returns the result of [getMember] with [type] substitution.
  InternalExecutableElement? getMember3(
    InterfaceType type,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    type as InterfaceTypeImpl; // TODO(scheglov): remove cast
    var rawElement = getMember(
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
    return SubstitutedExecutableElementImpl.from(rawElement, substitution);
  }

  /// Return all members of mixins, superclasses, and interfaces that a member
  /// with the given [name], defined in the [element], would override; or `null`
  /// if no members would be overridden.
  List<InternalExecutableElement>? getOverridden(
    InterfaceElement element,
    Name name,
  ) {
    var interface = getInterface(element);
    return interface.overridden[name];
  }

  /// Remove interfaces for classes defined in specified libraries.
  void removeOfLibraries(Set<Uri> uriSet) {
    _interfaces.removeWhere((element, _) {
      return uriSet.contains(element.library.uri);
    });
  }

  void _addCandidates({
    required Map<Name, List<InternalExecutableElement>> namedCandidates,
    required MapSubstitution substitution,
    required Interface interface,
  }) {
    var map = interface.map;
    for (var entry in map.entries) {
      var name = entry.key;
      var candidate = entry.value;

      candidate = SubstitutedExecutableElementImpl.from(
        candidate,
        substitution,
      );

      var candidates = namedCandidates[name];
      if (candidates == null) {
        candidates = <InternalExecutableElement>[];
        namedCandidates[name] = candidates;
      }

      candidates.add(candidate);
    }
  }

  void _addImplemented(
    Map<Name, InternalExecutableElement> implemented,
    InterfaceElementImpl element,
  ) {
    var libraryUri = element.library.uri;

    void addMember(InternalExecutableElement member) {
      if (!member.isAbstract && !member.isStatic) {
        var lookupName = member.lookupName;
        if (lookupName != null) {
          var name = Name(libraryUri, lookupName);
          implemented[name] = member;
        }
      }
    }

    element.methods.forEach(addMember);
    element.getters.forEach(addMember);
    element.setters.forEach(addMember);
  }

  void _addMixinMembers({
    required Map<Name, InternalExecutableElement> implemented,
    required MapSubstitution substitution,
    required Interface mixin,
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

      executable = SubstitutedExecutableElementImpl.from(
        executable,
        substitution,
      );

      implemented[entry.key] = executable;
    }
  }

  /// Check that all [candidates] for the given [name] have the same kind, all
  /// getters, all methods, or all setter.  If a conflict found, return the
  /// new [Conflict] instance that describes it.
  Conflict? _checkForGetterMethodConflict(
    Name name,
    List<InternalExecutableElement> candidates,
  ) {
    assert(candidates.length > 1);

    InternalExecutableElement? getter;
    InternalExecutableElement? method;
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
  InternalExecutableElement? _combineSignatures({
    required InterfaceElementImpl targetClass,
    required List<InternalExecutableElement> candidates,
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

    (_combinedSignatures[targetClass] ??= {})[name] = candidates;

    return _topMerge(typeSystem, targetClass, validOverrides);
  }

  /// The given [namedCandidates] maps names to candidates from direct
  /// superinterfaces.  Find the most specific signature, and put it into the
  /// [map], if there is no one yet (from the class itself).  If there is no
  /// such single most specific signature (i.e. no valid override), then add a
  /// new conflict description.
  List<Conflict> _findMostSpecificFromNamedCandidates(
    InterfaceElementImpl targetClass,
    Map<Name, InternalExecutableElement> map,
    Map<Name, List<InternalExecutableElement>> namedCandidates,
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

  /// Implementation of [getInterface], without dependency tracking.
  Interface _getInterface(InterfaceElement element) {
    element as InterfaceElementImpl; // TODO(scheglov): remove cast
    var result = _interfaces[element];
    if (result != null) {
      return result;
    }
    _interfaces[element] = Interface._empty;

    if (!_processingClasses.add(element)) {
      return Interface._empty;
    }

    try {
      if (element is ExtensionTypeElementImpl) {
        result = _getInterfaceExtensionType(element);
      } else if (element is MixinElementImpl) {
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

  Interface _getInterfaceClass(InterfaceElementImpl element) {
    var namedCandidates = <Name, List<InternalExecutableElement>>{};
    var superImplemented = <Map<Name, InternalExecutableElement>>[];
    var implemented = <Name, InternalExecutableElement>{};

    InterfaceType? superType = element.supertype;

    Interface? superTypeInterface;
    if (superType != null) {
      superType as InterfaceTypeImpl;
      var substitution = Substitution.fromInterfaceType(superType);
      superTypeInterface = getInterface(superType.element);
      _addCandidates(
        namedCandidates: namedCandidates,
        substitution: substitution,
        interface: superTypeInterface,
      );

      for (var entry in superTypeInterface.implemented.entries) {
        var executable = entry.value;
        executable = SubstitutedExecutableElementImpl.from(
          executable,
          substitution,
        );
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
      var candidatesFromSuperAndMixin =
          <Name, List<InternalExecutableElement>>{};
      var mixinConflicts = <Conflict>[];
      for (var entry in mixinInterface.map.entries) {
        var name = entry.key;
        var candidate = SubstitutedExecutableElementImpl.from(
          entry.value,
          substitution,
        );

        var currentList = namedCandidates[name];
        if (currentList == null) {
          namedCandidates[name] = [candidate];
          continue;
        }

        var current = currentList.single;
        if (candidate.enclosingElement == mixinElement) {
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
        var map = <Name, InternalExecutableElement>{};
        _findMostSpecificFromNamedCandidates(
          element,
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
        interface: getInterface(interface.element),
      );
    }

    implemented = Map.of(implemented);
    _addImplemented(implemented, element);

    // If a class declaration has a member declaration, the signature of that
    // member declaration becomes the signature in the interface.
    var declared = _getTypeMembers(element);

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
    );

    var noSuchMethodForwarders = <Name>{};
    if (element is ClassElementImpl && element.isAbstract) {
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

    implemented = implemented.map<Name, InternalExecutableElement>((
      key,
      value,
    ) {
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
      combinedSignatures: _combinedSignatures.remove(element) ?? {},
    );
  }

  /// See https://github.com/dart-lang/language
  ///   blob/main/accepted/future-releases/extension-types/feature-specification.md
  ///   #static-analysis-of-an-extension-type-member-invocation
  ///
  /// We handle "has an extension type member" and "has a non-extension type
  /// member" portions, considering redeclaration and conflicts.
  Interface _getInterfaceExtensionType(ExtensionTypeElementImpl element) {
    // Add instance members implemented by the element itself.
    var declared = <Name, InternalExecutableElement>{};
    _addImplemented(declared, element);

    // Prepare precluded names.
    var precludedNames = <Name>{};
    var precludedMethods = <Name>{};
    var precludedSetters = <Name>{};
    for (var entry in declared.entries) {
      var name = entry.key;
      precludedNames.add(name);
      switch (entry.value) {
        case InternalMethodElement():
          precludedSetters.add(name.forSetter);
        case InternalSetterElement():
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
      for (var entry in getInterface(interface.element).map.entries) {
        var name = entry.key;
        var executable = SubstitutedExecutableElementImpl.from(
          entry.value,
          substitution,
        );
        if (executable.isExtensionTypeMember) {
          (extensionCandidates[name] ??= _ExtensionTypeCandidates(
            name,
          )).add(executable);
        } else {
          (notExtensionCandidates[name] ??= _ExtensionTypeCandidates(
            name,
          )).add(executable);
        }
      }
    }

    var redeclared = <Name, List<InternalExecutableElement>>{};
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
      InternalExecutableElement? uniqueElement;
      for (var candidate in notPrecluded) {
        if (uniqueElement == null) {
          uniqueElement = candidate;
        } else if (uniqueElement.baseElement != candidate.baseElement) {
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
        targetClass: element,
        candidates: notPrecluded,
        name: name,
      );

      if (combinedSignature == null) {
        conflicts.add(CandidatesConflict(name: name, candidates: notPrecluded));
        continue;
      }

      implemented[name] = combinedSignature;
    }

    var uniqueRedeclared = <Name, List<InternalExecutableElement>>{};
    for (var entry in redeclared.entries) {
      var name = entry.key;
      var elements = entry.value;
      if (elements.length == 1) {
        uniqueRedeclared[name] = elements.toFixedList();
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
      combinedSignatures: _combinedSignatures.remove(element) ?? {},
    );
  }

  Interface _getInterfaceMixin(MixinElementImpl element) {
    var superCandidates = <Name, List<InternalExecutableElement>>{};
    for (var constraint in element.superclassConstraints) {
      var substitution = Substitution.fromInterfaceType(constraint);
      var interfaceObj = getInterface(constraint.element);
      _addCandidates(
        namedCandidates: superCandidates,
        substitution: substitution,
        interface: interfaceObj,
      );
    }

    // `mixin M on S1, S2 {}` can call using `super` any instance member
    // from its superclass constraints, whether it is abstract or concrete.
    var superInterface = <Name, InternalExecutableElement>{};
    var superConflicts = _findMostSpecificFromNamedCandidates(
      element,
      superInterface,
      superCandidates,
    );

    var interfaceCandidates = Map.of(superCandidates);
    for (var interface in element.interfaces) {
      _addCandidates(
        namedCandidates: interfaceCandidates,
        substitution: Substitution.fromInterfaceType(interface),
        interface: getInterface(interface.element),
      );
    }

    var declared = _getTypeMembers(element);

    var interface = Map.of(declared);
    var interfaceConflicts = _findMostSpecificFromNamedCandidates(
      element,
      interface,
      interfaceCandidates,
    );

    var implemented = <Name, InternalExecutableElement>{};
    _addImplemented(implemented, element);

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
      combinedSignatures: _combinedSignatures.remove(element) ?? {},
    );
  }

  /// If a candidate from [namedCandidates] has covariant parameters, return
  /// a copy of the [executable] with the corresponding parameters marked
  /// covariant. If there are no covariant parameters, or parameters to
  /// update are already covariant, return the [executable] itself.
  InternalExecutableElement _inheritCovariance(
    InterfaceElementImpl class_,
    Map<Name, List<InternalExecutableElement>> namedCandidates,
    Name name,
    InternalExecutableElement executable,
  ) {
    if (executable.enclosingElement == class_) {
      return executable;
    }

    var parameters = executable.formalParameters;
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
      var parameters = candidate.formalParameters;
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
    List<FormalParameterElementImpl>? transformedParameters;
    for (var index = 0; index < parameters.length; index++) {
      var parameter = parameters[index];
      var shouldBeCovariant = covariantParameters.contains(
        _ParameterDesc(index, parameter),
      );
      if (parameter.isCovariant != shouldBeCovariant) {
        transformedParameters ??= [
          for (var parameter in parameters) parameter.baseElement,
        ];
        transformedParameters[index] = parameter.baseElement.copyWith(
          isCovariant: shouldBeCovariant,
        );
      }
    }

    if (transformedParameters == null) {
      return executable;
    }

    if (executable is InternalMethodElement) {
      var fragmentName = executable.name ?? '';

      var elementReference = class_.reference!
          .getChild('@method')
          .getChild(fragmentName);
      if (elementReference.element case MethodElementImpl result) {
        return result;
      }

      var resultFragment = MethodFragmentImpl(name: executable.name);
      resultFragment.enclosingFragment = class_.firstFragment;
      resultFragment.isSynthetic = true;
      resultFragment.formalParameters = transformedParameters
          .map((e) => e.firstFragment)
          .toList();
      resultFragment.typeParameters = executable.typeParameters
          .map((e) => e.firstFragment)
          .toList();

      var elementName = executable.name!;
      var result = MethodElementImpl(
        name: elementName,
        reference: elementReference,
        firstFragment: resultFragment,
      );
      result.returnType = executable.returnType;

      return result;
    }

    if (executable is SetterElementImpl) {
      var fragmentName = executable.name ?? '';
      var setterReference = class_.reference!
          .getChild('@setter')
          .getChild(fragmentName);
      if (setterReference.element case SetterElementImpl result) {
        return result;
      }

      var resultFragment = SetterFragmentImpl(name: executable.name);
      resultFragment.enclosingFragment = class_.firstFragment;
      resultFragment.isSynthetic = true;
      resultFragment.formalParameters = transformedParameters
          .map((e) => e.firstFragment)
          .toList();

      var result = SetterElementImpl(setterReference, resultFragment);
      result.returnType = executable.returnType;

      var resultField = FieldFragmentImpl(name: executable.name);
      resultField.enclosingFragment = class_.firstFragment;

      var elementName = executable.name!;
      var fieldReference = class_.reference!
          .getChild('@field')
          .getChild(elementName);
      assert(fieldReference.element == null);
      FieldElementImpl(reference: fieldReference, firstFragment: resultField);

      return result;
    }

    return executable;
  }

  /// Given one or more [validOverrides], merge them into a single resulting
  /// signature. This signature always exists.
  InternalExecutableElement _topMerge(
    TypeSystemImpl typeSystem,
    InterfaceElementImpl targetClass,
    List<InternalExecutableElement> validOverrides,
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

    if (first is InternalMethodElement) {
      var firstElement = first;
      var fragmentName = firstElement.firstFragment.name!;

      var elementReference = targetClass.reference!
          .getChild('@method')
          .getChild(fragmentName);
      if (elementReference.element case MethodElementImpl result) {
        return result;
      }
      assert(elementReference.element == null);

      var resultFragment = MethodFragmentImpl(name: fragmentName);
      resultFragment.enclosingFragment = targetClass.firstFragment;
      resultFragment.typeParameters = resultType.typeParameters
          .map((e) => e.firstFragment)
          .toList();
      // TODO(scheglov): check if can type cast instead
      resultFragment.formalParameters = resultType.parameters
          .map((e) => e.firstFragment)
          .toList();

      var elementName = firstElement.name!;
      var resultElement = MethodElementImpl(
        name: elementName,
        reference: elementReference,
        firstFragment: resultFragment,
      );
      resultElement.returnType = resultType.returnType;

      return resultElement;
    } else {
      var firstElement = first as InternalPropertyAccessorElement;
      var fragmentName = first.name!;
      var field = FieldFragmentImpl(name: fragmentName);

      PropertyAccessorFragmentImpl resultFragment;
      PropertyAccessorElementImpl resultElement;
      if (firstElement is InternalGetterElement) {
        var elementReference = targetClass.reference!
            .getChild('@getter')
            .getChild(fragmentName);
        if (elementReference.element case GetterElementImpl result) {
          return result;
        }
        assert(elementReference.element == null);

        var fragment = GetterFragmentImpl(name: fragmentName);
        resultFragment = fragment;

        var element = GetterElementImpl(elementReference, fragment);
        element.returnType = resultType.returnType;
        resultElement = element;
      } else {
        var elementReference = targetClass.reference!
            .getChild('@setter')
            .getChild(fragmentName);
        if (elementReference.element case SetterElementImpl result) {
          return result;
        }
        assert(elementReference.element == null);

        var fragment = SetterFragmentImpl(name: fragmentName);
        resultFragment = fragment;

        var element = SetterElementImpl(elementReference, fragment);
        element.returnType = resultType.returnType;
        resultElement = element;
      }
      resultFragment.enclosingFragment = targetClass.firstFragment;
      // TODO(scheglov): check if can type cast instead
      resultFragment.formalParameters = resultType.parameters
          .map((e) => e.firstFragment)
          .toList();

      field.enclosingFragment = targetClass.firstFragment;

      var elementName = first.name!;
      var elementReference = targetClass.reference!
          .getChild('@field')
          .getChild(elementName);
      assert(elementReference.element == null);
      var fieldElement = FieldElementImpl(
        reference: elementReference,
        firstFragment: field,
      );
      resultFragment.element.variable = fieldElement;

      if (firstElement is GetterElement) {
        fieldElement.type = resultType.returnType;
      } else {
        var type = resultType.formalParameters[0].type;
        fieldElement.type = type;
      }

      return resultElement;
    }
  }

  static Map<Name, InternalExecutableElement> _getTypeMembers(
    InterfaceElementImpl element,
  ) {
    var declared = <Name, InternalExecutableElement>{};
    var libraryUri = element.library.uri;

    void addMember(InternalExecutableElement member) {
      if (!member.isStatic) {
        var lookupName = member.lookupName;
        if (lookupName != null) {
          var name = Name(libraryUri, lookupName);
          declared[name] = member;
        }
      }
    }

    element.methods.forEach(addMember);
    element.getters.forEach(addMember);
    element.setters.forEach(addMember);

    return declared;
  }

  /// Returns executables that are valid overrides of [candidates].
  static List<InternalExecutableElement> _getValidOverrides({
    required TypeSystemImpl typeSystem,
    required List<InternalExecutableElement> candidates,
  }) {
    var validOverrides = <InternalExecutableElement>[];
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

  static bool _isDeclaredInObject(InternalExecutableElement element) {
    var enclosing = element.enclosingElement;
    return enclosing is ClassElement && enclosing.isDartCoreObject;
  }

  static FunctionTypeImpl _topMergeSignatureTypes({
    required TypeSystemImpl typeSystem,
    required List<InternalExecutableElement> validOverrides,
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
    noSuchMethodForwarders: <Name>{},
    overridden: const {},
    redeclared: const {},
    superImplemented: const [{}],
    conflicts: const [],
    combinedSignatures: const {},
  );

  /// The map of names to their signature in the interface.
  final Map<Name, InternalExecutableElement> map;

  /// The map of declared names to their signatures.
  final Map<Name, InternalExecutableElement> declared;

  /// The map of names to their concrete implementations.
  final Map<Name, InternalExecutableElement> implemented;

  /// The set of names that are `noSuchMethod` forwarders in [implemented].
  final Set<Name> noSuchMethodForwarders;

  /// The map of names to their signatures from the mixins, superclasses,
  /// or interfaces.
  final Map<Name, List<InternalExecutableElement>> overridden;

  /// The map of names to the signatures from superinterfaces that a member
  /// declaration in this extension type redeclares.
  final Map<Name, List<InternalExecutableElement>> redeclared;

  /// Each item of this list maps names to their concrete implementations.
  /// The first item of the list is the nominal superclass, next the nominal
  /// superclass plus the first mixin, etc. So, for the class like
  /// `class C extends S with M1, M2`, we get `[S, S&M1, S&M1&M2]`.
  final List<Map<Name, InternalExecutableElement>> superImplemented;

  /// The list of conflicts between superinterfaces - the nominal superclass,
  /// mixins, and interfaces.  Does not include conflicts with the declared
  /// members of the class.
  final List<Conflict> conflicts;

  /// Tracks signatures from superinterfaces that were combined.
  /// It is used to track dependencies in manifests.
  final Map<Name, List<InternalExecutableElement>> combinedSignatures;

  /// The map of names to the most specific signatures from the mixins,
  /// superclasses, or interfaces.
  Map<Name, InternalExecutableElement>? inheritedMap;

  Interface._({
    required this.map,
    required this.declared,
    required this.implemented,
    required this.noSuchMethodForwarders,
    required this.overridden,
    required this.redeclared,
    required this.superImplemented,
    required this.conflicts,
    required this.combinedSignatures,
  });

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
      var libraryUri = element.library!.uri;
      return Name(libraryUri, name);
    } else {
      return Name(null, name);
    }
  }
}

/// Failure because of not unique extension type member.
class NotUniqueExtensionMemberConflict extends Conflict {
  final List<InternalExecutableElement> candidates;

  NotUniqueExtensionMemberConflict({
    required super.name,
    required this.candidates,
  });
}

class _ExtensionTypeCandidates {
  final Name name;
  final List<InternalMethodElement> methods = [];
  final List<InternalGetterElement> getters = [];
  final List<InternalSetterElement> setters = [];

  _ExtensionTypeCandidates(this.name);

  List<InternalExecutableElement> get all {
    return [...methods, ...getters, ...setters];
  }

  void add(InternalExecutableElement element) {
    switch (element) {
      case InternalMethodElement():
        methods.add(element);
      case InternalGetterElement():
        getters.add(element);
      case InternalSetterElement():
        setters.add(element);
    }
  }

  List<InternalExecutableElement> notPrecluded({
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

  factory _ParameterDesc(int index, FormalParameterElement element) {
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
