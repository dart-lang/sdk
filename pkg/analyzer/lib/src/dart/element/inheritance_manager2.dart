// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

/// Description of a failure to find a valid override from superinterfaces.
class Conflict {
  /// The name of an instance member for which we failed to find a valid
  /// override.
  final Name name;

  /// The list of candidates for a valid override for a member [name].  It has
  /// at least two items, because otherwise the only candidate is always valid.
  final List<FunctionType> candidates;

  /// The getter that conflicts with the [method], or `null`, if the conflict
  /// is inconsistent inheritance.
  final FunctionType getter;

  /// The method tha conflicts with the [getter], or `null`, if the conflict
  /// is inconsistent inheritance.
  final FunctionType method;

  Conflict(this.name, this.candidates, [this.getter, this.method]);
}

/// Manages knowledge about interface types and their members.
class InheritanceManager2 {
  static final _noSuchMethodName = Name(null, 'noSuchMethod');

  final TypeSystem _typeSystem;

  /// Cached instance interfaces for [InterfaceType].
  final Map<InterfaceType, Interface> _interfaces = {};

  /// The set of classes that are currently being processed, used to detect
  /// self-referencing cycles.
  final Set<ClassElement> _processingClasses = new Set<ClassElement>();

  InheritanceManager2(this._typeSystem);

  /// Return the most specific signature of the member with the given [name]
  /// that the [type] inherits from the mixins, superclasses, or interfaces;
  /// or `null` if no member is inherited because the member is not declared
  /// at all, or because there is no the most specific signature.
  ///
  /// This is equivalent to `getInheritedMap(type)[name]`.
  FunctionType getInherited(InterfaceType type, Name name) {
    return getInheritedMap(type)[name];
  }

  /// Return signatures of all concrete members that the given [type] inherits
  /// from the superclasses and mixins.
  Map<Name, FunctionType> getInheritedConcreteMap(InterfaceType type) {
    var interface = getInterface(type);
    return interface._superImplemented.last;
  }

  /// Return the mapping from names to most specific signatures of members
  /// inherited from the super-interfaces (superclasses, mixins, and
  /// interfaces).  If there is no most specific signature for a name, the
  /// corresponding name will not be included.
  Map<Name, FunctionType> getInheritedMap(InterfaceType type) {
    var interface = getInterface(type);
    if (interface._inheritedMap == null) {
      interface._inheritedMap = {};
      _findMostSpecificFromNamedCandidates(
        interface._inheritedMap,
        interface._overridden,
      );
    }
    return interface._inheritedMap;
  }

  /// Return the interface of the given [type].  It might include private
  /// members, not necessary accessible in all libraries.
  Interface getInterface(InterfaceType type) {
    if (type == null) {
      return Interface._empty;
    }

    var result = _interfaces[type];
    if (result != null) {
      return result;
    }
    _interfaces[type] = Interface._empty;

    var classElement = type.element;
    if (!_processingClasses.add(classElement)) {
      return Interface._empty;
    }

    Map<Name, List<FunctionType>> namedCandidates = {};
    List<Map<Name, FunctionType>> superImplemented = [];
    Map<Name, FunctionType> declared;
    Interface superInterface;
    Map<Name, FunctionType> implemented;
    Map<Name, FunctionType> implementedForMixing;
    try {
      // If a class declaration has a member declaration, the signature of that
      // member declaration becomes the signature in the interface.
      declared = _getTypeMembers(type);

      for (var interface in type.interfaces) {
        var interfaceObj = getInterface(interface);
        _addCandidates(namedCandidates, interfaceObj);
      }

      if (classElement.isMixin) {
        var superClassCandidates = <Name, List<FunctionType>>{};
        for (var constraint in type.superclassConstraints) {
          var interfaceObj = getInterface(constraint);
          _addCandidates(superClassCandidates, interfaceObj);
          _addCandidates(namedCandidates, interfaceObj);
        }

        implemented = {};

        // `mixin M on S1, S2 {}` can call using `super` any instance member
        // from its superclass constraints, whether it is abstract or concrete.
        var superClass = <Name, FunctionType>{};
        _findMostSpecificFromNamedCandidates(superClass, superClassCandidates);
        superImplemented.add(superClass);
      } else {
        if (type.superclass != null) {
          superInterface = getInterface(type.superclass);
          _addCandidates(namedCandidates, superInterface);

          implemented = superInterface.implemented;
          superImplemented.add(implemented);
        } else {
          implemented = {};
        }

        implementedForMixing = {};
        for (var mixin in type.mixins) {
          var interfaceObj = getInterface(mixin);
          _addCandidates(namedCandidates, interfaceObj);

          implemented = <Name, FunctionType>{}
            ..addAll(implemented)
            ..addAll(interfaceObj._implementedForMixing);
          superImplemented.add(implemented);
          implementedForMixing.addAll(interfaceObj._implementedForMixing);
        }
      }
    } finally {
      _processingClasses.remove(classElement);
    }

    var thisImplemented = <Name, FunctionType>{};
    _addImplemented(thisImplemented, type);

    if (classElement.isMixin) {
      implementedForMixing = thisImplemented;
    } else {
      implementedForMixing.addAll(thisImplemented);
    }

    implemented = <Name, FunctionType>{}..addAll(implemented);
    _addImplemented(implemented, type);

    // If a class declaration does not have a member declaration with a
    // particular name, but some super-interfaces do have a member with that
    // name, it's a compile-time error if there is no signature among the
    // super-interfaces that is a valid override of all the other
    // super-interface signatures with the same name. That "most specific"
    // signature becomes the signature of the class's interface.
    Map<Name, FunctionType> map = new Map.of(declared);
    List<Conflict> conflicts = _findMostSpecificFromNamedCandidates(
      map,
      namedCandidates,
    );

    var noSuchMethodForwarders = Set<Name>();
    if (classElement.isAbstract) {
      if (superInterface != null) {
        noSuchMethodForwarders = superInterface._noSuchMethodForwarders;
      }
    } else {
      var noSuchMethod = implemented[_noSuchMethodName]?.element;
      if (noSuchMethod != null && !_isDeclaredInObject(noSuchMethod)) {
        var superForwarders = superInterface?._noSuchMethodForwarders;
        for (var name in map.keys) {
          if (!implemented.containsKey(name) ||
              superForwarders != null && superForwarders.contains(name)) {
            implemented[name] = map[name];
            noSuchMethodForwarders.add(name);
          }
        }
      }
    }

    var interface = new Interface._(
      map,
      declared,
      implemented,
      noSuchMethodForwarders,
      implementedForMixing,
      namedCandidates,
      superImplemented,
      conflicts ?? const [],
    );
    _interfaces[type] = interface;
    return interface;
  }

  /// Return the member with the given [name].
  ///
  /// If [concrete] is `true`, the the concrete implementation is returned,
  /// from the given [type], or its superclass.
  ///
  /// If [forSuper] is `true`, then [concrete] is implied, and only concrete
  /// members from the superclass are considered.
  ///
  /// If [forMixinIndex] is specified, only the nominal superclass, and the
  /// given number of mixins after it are considered.  For example for `1` in
  /// `class C extends S with M1, M2, M3`, only `S` and `M1` are considered.
  FunctionType getMember(
    InterfaceType type,
    Name name, {
    bool concrete: false,
    int forMixinIndex: -1,
    bool forSuper: false,
  }) {
    var interface = getInterface(type);
    if (forSuper) {
      var superImplemented = interface._superImplemented;
      if (forMixinIndex >= 0) {
        return superImplemented[forMixinIndex][name];
      }
      return superImplemented.last[name];
    }
    if (concrete) {
      return interface.implemented[name];
    }
    return interface.map[name];
  }

  /// Return all members of mixins, superclasses, and interfaces that a member
  /// with the given [name], defined in the [type], would override; or `null`
  /// if no members would be overridden.
  List<FunctionType> getOverridden(InterfaceType type, Name name) {
    var interface = getInterface(type);
    return interface._overridden[name];
  }

  void _addCandidate(Map<Name, List<FunctionType>> namedCandidates, Name name,
      FunctionType candidate) {
    var candidates = namedCandidates[name];
    if (candidates == null) {
      candidates = <FunctionType>[];
      namedCandidates[name] = candidates;
    }

    candidates.add(candidate);
  }

  void _addCandidates(
      Map<Name, List<FunctionType>> namedCandidates, Interface interface) {
    var map = interface.map;
    for (var name in map.keys) {
      var candidate = map[name];
      _addCandidate(namedCandidates, name, candidate);
    }
  }

  void _addImplemented(
      Map<Name, FunctionType> implemented, InterfaceType type) {
    var libraryUri = type.element.librarySource.uri;

    void addMember(ExecutableElement member) {
      if (!member.isAbstract && !member.isStatic) {
        var name = new Name(libraryUri, member.name);
        implemented[name] = member.type;
      }
    }

    void addMembers(InterfaceType type) {
      type.methods.forEach(addMember);
      type.accessors.forEach(addMember);
    }

    addMembers(type);
  }

  /// Check that all [candidates] for the given [name] have the same kind, all
  /// getters, all methods, or all setter.  If a conflict found, return the
  /// new [Conflict] instance that describes it.
  Conflict _checkForGetterMethodConflict(
      Name name, List<FunctionType> candidates) {
    assert(candidates.length > 1);

    bool allGetters = true;
    bool allMethods = true;
    bool allSetters = true;
    for (var candidate in candidates) {
      var kind = candidate.element.kind;
      if (kind != ElementKind.GETTER) {
        allGetters = false;
      }
      if (kind != ElementKind.METHOD) {
        allMethods = false;
      }
      if (kind != ElementKind.SETTER) {
        allSetters = false;
      }
    }

    if (allGetters || allMethods || allSetters) {
      return null;
    }

    FunctionType getterType;
    FunctionType methodType;
    for (var candidate in candidates) {
      var kind = candidate.element.kind;
      if (kind == ElementKind.GETTER) {
        getterType ??= candidate;
      }
      if (kind == ElementKind.METHOD) {
        methodType ??= candidate;
      }
    }
    return new Conflict(name, candidates, getterType, methodType);
  }

  /// The given [namedCandidates] maps names to candidates from direct
  /// superinterfaces.  Find the most specific signature, and put it into the
  /// [map], if there is no one yet (from the class itself).  If there is no
  /// such single most specific signature (i.e. no valid override), then add a
  /// new conflict description.
  List<Conflict> _findMostSpecificFromNamedCandidates(
      Map<Name, FunctionType> map,
      Map<Name, List<FunctionType>> namedCandidates) {
    List<Conflict> conflicts = null;

    for (var name in namedCandidates.keys) {
      if (map.containsKey(name)) {
        continue;
      }

      var candidates = namedCandidates[name];

      // If just one candidate, it is always valid.
      if (candidates.length == 1) {
        map[name] = candidates[0];
        continue;
      }

      // Check for a getter/method conflict.
      var conflict = _checkForGetterMethodConflict(name, candidates);
      if (conflict != null) {
        conflicts ??= <Conflict>[];
        conflicts.add(conflict);
      }

      // Candidates are recorded in forward order, so
      // `class X extends S with M1, M2 implements I1, I2 {}` will record
      // candidates from [I1, I2, S, M1, M2]. But during method lookup
      // candidates should be considered in backward order, i.e. from `M2`,
      // then from `M1`, then from `S`.
      FunctionType validOverride;
      for (var i = candidates.length - 1; i >= 0; i--) {
        validOverride = candidates[i];
        for (var j = 0; j < candidates.length; j++) {
          var candidate = candidates[j];
          if (!_typeSystem.isOverrideSubtypeOf(validOverride, candidate)) {
            validOverride = null;
            break;
          }
        }
        if (validOverride != null) {
          break;
        }
      }

      if (validOverride != null) {
        map[name] = validOverride;
      } else {
        conflicts ??= <Conflict>[];
        conflicts.add(new Conflict(name, candidates));
      }
    }

    return conflicts;
  }

  Map<Name, FunctionType> _getTypeMembers(InterfaceType type) {
    var declared = <Name, FunctionType>{};
    var libraryUri = type.element.librarySource.uri;

    var methods = type.methods;
    for (var i = 0; i < methods.length; i++) {
      var method = methods[i];
      if (!method.isStatic) {
        var name = new Name(libraryUri, method.name);
        declared[name] = method.type;
      }
    }

    var accessors = type.accessors;
    for (var i = 0; i < accessors.length; i++) {
      var accessor = accessors[i];
      if (!accessor.isStatic) {
        var name = new Name(libraryUri, accessor.name);
        declared[name] = accessor.type;
      }
    }

    return declared;
  }

  static bool _isDeclaredInObject(ExecutableElement element) {
    var enclosing = element.enclosingElement;
    return enclosing is ClassElement &&
        enclosing.supertype == null &&
        !enclosing.isMixin;
  }
}

/// The instance interface of an [InterfaceType].
class Interface {
  static final _empty = Interface._(
    const {},
    const {},
    const {},
    Set<Name>(),
    const {},
    const {},
    const [{}],
    const [],
  );

  /// The map of names to their signature in the interface.
  final Map<Name, FunctionType> map;

  /// The map of declared names to their signatures.
  final Map<Name, FunctionType> declared;

  /// The map of names to their concrete implementations.
  final Map<Name, FunctionType> implemented;

  /// The set of names that are `noSuchMethod` forwarders in [implemented].
  final Set<Name> _noSuchMethodForwarders;

  /// The map of names to their concrete implementations that can be mixed
  /// when this type is used as a mixin.
  final Map<Name, FunctionType> _implementedForMixing;

  /// The map of names to their signatures from the mixins, superclasses,
  /// or interfaces.
  final Map<Name, List<FunctionType>> _overridden;

  /// Each item of this list maps names to their concrete implementations.
  /// The first item of the list is the nominal superclass, next the nominal
  /// superclass plus the first mixin, etc. So, for the class like
  /// `class C extends S with M1, M2`, we get `[S, S&M1, S&M1&M2]`.
  final List<Map<Name, FunctionType>> _superImplemented;

  /// The list of conflicts between superinterfaces - the nominal superclass,
  /// mixins, and interfaces.  Does not include conflicts with the declared
  /// members of the class.
  final List<Conflict> conflicts;

  /// The map of names to the most specific signatures from the mixins,
  /// superclasses, or interfaces.
  Map<Name, FunctionType> _inheritedMap;

  Interface._(
    this.map,
    this.declared,
    this.implemented,
    this._noSuchMethodForwarders,
    this._implementedForMixing,
    this._overridden,
    this._superImplemented,
    this.conflicts,
  );

  /// Return `true` if the [name] is implemented in the supertype.
  bool isSuperImplemented(Name name) {
    return _superImplemented.last.containsKey(name);
  }
}

/// A public name, or a private name qualified by a library URI.
class Name {
  /// If the name is private, the URI of the defining library.
  /// Otherwise, it is `null`.
  final Uri libraryUri;

  /// The name of this name object.
  /// If the name starts with `_`, then the name is private.
  /// Names of setters end with `=`.
  final String name;

  /// Precomputed
  final bool isPublic;

  /// The cached, pre-computed hash code.
  final int hashCode;

  factory Name(Uri libraryUri, String name) {
    if (name.startsWith('_')) {
      var hashCode = JenkinsSmiHash.hash2(libraryUri.hashCode, name.hashCode);
      return new Name._internal(libraryUri, name, false, hashCode);
    } else {
      return new Name._internal(null, name, true, name.hashCode);
    }
  }

  Name._internal(this.libraryUri, this.name, this.isPublic, this.hashCode);

  @override
  bool operator ==(other) {
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
