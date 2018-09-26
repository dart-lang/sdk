// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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
  final StrongTypeSystemImpl _typeSystem;

  /// Cached instance interfaces for [InterfaceType].
  final Map<InterfaceType, Interface> _interfaces = {};

  InheritanceManager2(this._typeSystem);

  /// Return the interface of the given [type].  It might include private
  /// members, not necessary accessible in all libraries.
  Interface getInterface(InterfaceType type) {
    if (type == null) {
      return const Interface(const {}, const []);
    }

    var result = _interfaces[type];
    if (result != null) {
      return result;
    }

    _interfaces[type] = const Interface(const {}, const []);
    Map<Name, FunctionType> map = {};
    List<Conflict> conflicts = null;

    // If a class declaration has a member declaration, the signature of that
    // member declaration becomes the signature in the interface.
    var libraryUri = type.element.librarySource.uri;
    _addTypeMembers(map, type, libraryUri);

    // If a class declaration does not have a member declaration with a
    // particular name, but some super-interfaces do have a member with that
    // name, it's a compile-time error if there is no signature among the
    // super-interfaces that is a valid override of all the other
    // super-interface signatures with the same name. That "most specific"
    // signature becomes the signature of the class's interface.
    var namedCandidates =
        _computeCandidatesFromSuperinterfaces(map, type, libraryUri);
    for (var name in namedCandidates.keys) {
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

      FunctionType validOverride;
      for (var i = 0; i < candidates.length; i++) {
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

    var interface = new Interface(map, conflicts ?? const []);
    _interfaces[type] = interface;
    return interface;
  }

  void _addTypeMembers(
      Map<Name, FunctionType> map, InterfaceType type, Uri libraryUri) {
    void addTypeMember(ExecutableElement member) {
      if (!member.isStatic) {
        var name = new Name(libraryUri, member.name);
        map[name] = member.type;
      }
    }

    type.methods.forEach(addTypeMember);
    type.accessors.forEach(addTypeMember);
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

  Map<Name, List<FunctionType>> _computeCandidatesFromSuperinterfaces(
      Map<Name, FunctionType> declaredMembers,
      InterfaceType type,
      Uri libraryUri) {
    var namedCandidates = <Name, List<FunctionType>>{};

    void addSuperinterfaceMember(Name name, FunctionType candidate) {
      if (declaredMembers.containsKey(name)) {
        return;
      }

      if (!name.isAccessibleFor(libraryUri)) {
        return;
      }

      var candidates = namedCandidates[name];
      if (candidates == null) {
        candidates = <FunctionType>[];
        namedCandidates[name] = candidates;
      }

      candidates.add(candidate);
    }

    void addSuperinterfaceMembers(InterfaceType superinterface) {
      getInterface(superinterface).map.forEach(addSuperinterfaceMember);
    }

    addSuperinterfaceMembers(type.superclass);
    type.superclassConstraints.forEach(addSuperinterfaceMembers);
    type.mixins.forEach(addSuperinterfaceMembers);
    type.interfaces.forEach(addSuperinterfaceMembers);

    return namedCandidates;
  }
}

/// The instance interface of an [InterfaceType].
class Interface {
  final Map<Name, FunctionType> map;
  final List<Conflict> conflicts;

  const Interface(this.map, this.conflicts);
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
