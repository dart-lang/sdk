// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/error/correct_override.dart';
import 'package:analyzer/src/generated/type_system.dart' show TypeSystemImpl;
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:meta/meta.dart';

/// Description of a failure to find a valid override from superinterfaces.
class Conflict {
  /// The name of an instance member for which we failed to find a valid
  /// override.
  final Name name;

  /// The list of candidates for a valid override for a member [name].  It has
  /// at least two items, because otherwise the only candidate is always valid.
  final List<ExecutableElement> candidates;

  /// The getter that conflicts with the [method], or `null`, if the conflict
  /// is inconsistent inheritance.
  final ExecutableElement getter;

  /// The method tha conflicts with the [getter], or `null`, if the conflict
  /// is inconsistent inheritance.
  final ExecutableElement method;

  Conflict(this.name, this.candidates, [this.getter, this.method]);
}

/// Manages knowledge about interface types and their members.
class InheritanceManager3 {
  static final _noSuchMethodName = Name(null, 'noSuchMethod');

  /// Cached instance interfaces for [InterfaceType].
  final Map<InterfaceType, Interface> _interfaces = {};

  /// The set of classes that are currently being processed, used to detect
  /// self-referencing cycles.
  final Set<ClassElement> _processingClasses = <ClassElement>{};

  InheritanceManager3([@deprecated TypeSystem typeSystem]);

  /// Return the most specific signature of the member with the given [name]
  /// that the [type] inherits from the mixins, superclasses, or interfaces;
  /// or `null` if no member is inherited because the member is not declared
  /// at all, or because there is no the most specific signature.
  ///
  /// This is equivalent to `getInheritedMap(type)[name]`.
  ExecutableElement getInherited(InterfaceType type, Name name) {
    return getInheritedMap(type)[name];
  }

  /// Return signatures of all concrete members that the given [type] inherits
  /// from the superclasses and mixins.
  Map<Name, ExecutableElement> getInheritedConcreteMap(InterfaceType type) {
    var interface = getInterface(type);
    return interface._superImplemented.last;
  }

  /// Return the mapping from names to most specific signatures of members
  /// inherited from the super-interfaces (superclasses, mixins, and
  /// interfaces).  If there is no most specific signature for a name, the
  /// corresponding name will not be included.
  Map<Name, ExecutableElement> getInheritedMap(InterfaceType type) {
    var interface = getInterface(type);
    if (interface._inheritedMap == null) {
      interface._inheritedMap = {};
      _findMostSpecificFromNamedCandidates(
        type.element,
        interface._inheritedMap,
        interface._overridden,
        doTopMerge: false,
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

    var classLibrary = classElement.library;
    var isNonNullableByDefault = classLibrary.isNonNullableByDefault;

    Map<Name, List<ExecutableElement>> namedCandidates = {};
    List<Map<Name, ExecutableElement>> superImplemented = [];
    Map<Name, ExecutableElement> declared;
    Interface superInterface;
    Map<Name, ExecutableElement> implemented;
    List<List<Conflict>> mixinsConflicts = [];
    try {
      // If a class declaration has a member declaration, the signature of that
      // member declaration becomes the signature in the interface.
      declared = _getTypeMembers(type);

      if (classElement.isMixin) {
        var superClassCandidates = <Name, List<ExecutableElement>>{};
        for (var constraint in type.superclassConstraints) {
          var interfaceObj = getInterface(constraint);
          _addCandidates(
            superClassCandidates,
            interfaceObj,
            isNonNullableByDefault: isNonNullableByDefault,
          );
          _addCandidates(
            namedCandidates,
            interfaceObj,
            isNonNullableByDefault: isNonNullableByDefault,
          );
        }

        implemented = {};

        // `mixin M on S1, S2 {}` can call using `super` any instance member
        // from its superclass constraints, whether it is abstract or concrete.
        var superClass = <Name, ExecutableElement>{};
        _findMostSpecificFromNamedCandidates(
          classElement,
          superClass,
          superClassCandidates,
          doTopMerge: true,
        );
        superImplemented.add(superClass);
      } else {
        if (type.superclass != null) {
          superInterface = getInterface(type.superclass);
          _addCandidates(
            namedCandidates,
            superInterface,
            isNonNullableByDefault: isNonNullableByDefault,
          );

          implemented = superInterface.implemented;
          superImplemented.add(implemented);
        } else {
          implemented = {};
        }

        // TODO(scheglov) Handling of members for super and mixins is not
        // optimal. We always have just one member for each name in super,
        // multiple candidates happen only when we merge super and multiple
        // interfaces. Consider using `Map<Name, ExecutableElement>` here.
        for (var mixin in type.mixins) {
          var mixinElement = mixin.element;
          var interfaceObj = getInterface(mixin);
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
          for (var name in interfaceObj.map.keys) {
            var candidate = interfaceObj.map[name];

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
                  Conflict(
                    name,
                    [current, candidate],
                    currentIsGetter ? current : candidate,
                    currentIsGetter ? candidate : current,
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
              classElement,
              map,
              candidatesFromSuperAndMixin,
              doTopMerge: true,
            );
            for (var entry in map.entries) {
              namedCandidates[entry.key] = [entry.value];
            }
          }

          mixinsConflicts.add(mixinConflicts);

          implemented = <Name, ExecutableElement>{}..addAll(implemented);
          implemented.addEntries(
            interfaceObj.implemented.entries.where((entry) {
              var executable = entry.value;
              if (executable.isAbstract) {
                return false;
              }
              var class_ = executable.enclosingElement;
              return class_ is ClassElement && !class_.isDartCoreObject;
            }),
          );

          superImplemented.add(implemented);
        }
      }

      for (var interface in type.interfaces) {
        var interfaceObj = getInterface(interface);
        _addCandidates(
          namedCandidates,
          interfaceObj,
          isNonNullableByDefault: isNonNullableByDefault,
        );
      }
    } finally {
      _processingClasses.remove(classElement);
    }

    implemented = <Name, ExecutableElement>{}..addAll(implemented);
    _addImplemented(implemented, type);

    // If a class declaration does not have a member declaration with a
    // particular name, but some super-interfaces do have a member with that
    // name, it's a compile-time error if there is no signature among the
    // super-interfaces that is a valid override of all the other
    // super-interface signatures with the same name. That "most specific"
    // signature becomes the signature of the class's interface.
    Map<Name, ExecutableElement> map = Map.of(declared);
    List<Conflict> conflicts = _findMostSpecificFromNamedCandidates(
      classElement,
      map,
      namedCandidates,
      doTopMerge: true,
    );

    var noSuchMethodForwarders = <Name>{};
    if (classElement.isAbstract) {
      if (superInterface != null) {
        noSuchMethodForwarders = superInterface._noSuchMethodForwarders;
      }
    } else {
      var noSuchMethod = implemented[_noSuchMethodName];
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

    /// TODO(scheglov) Instead of merging conflicts we could report them on
    /// the corresponding mixins applied in the class.
    for (var mixinConflicts in mixinsConflicts) {
      if (mixinConflicts.isNotEmpty) {
        conflicts ??= [];
        conflicts.addAll(mixinConflicts);
      }
    }

    var interface = Interface._(
      map,
      declared,
      implemented,
      noSuchMethodForwarders,
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
  ExecutableElement getMember(
    InterfaceType type,
    Name name, {
    bool concrete = false,
    int forMixinIndex = -1,
    bool forSuper = false,
  }) {
    var interface = getInterface(type);
    if (forSuper) {
      var superImplemented = interface._superImplemented;
      if (forMixinIndex >= 0) {
        return superImplemented[forMixinIndex][name];
      }
      if (superImplemented.isNotEmpty) {
        return superImplemented.last[name];
      } else {
        assert(type.element.name == 'Object');
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
  List<ExecutableElement> getOverridden(InterfaceType type, Name name) {
    var interface = getInterface(type);
    return interface._overridden[name];
  }

  void _addCandidate(
    Map<Name, List<ExecutableElement>> namedCandidates,
    Name name,
    ExecutableElement candidate, {
    @required bool isNonNullableByDefault,
  }) {
    var candidates = namedCandidates[name];
    if (candidates == null) {
      candidates = <ExecutableElement>[];
      namedCandidates[name] = candidates;
    }

    if (!isNonNullableByDefault) {
      candidate = Member.legacy(candidate);
    }

    candidates.add(candidate);
  }

  void _addCandidates(
    Map<Name, List<ExecutableElement>> namedCandidates,
    Interface interface, {
    @required bool isNonNullableByDefault,
  }) {
    var map = interface.map;
    for (var name in map.keys) {
      var candidate = map[name];
      _addCandidate(namedCandidates, name, candidate,
          isNonNullableByDefault: isNonNullableByDefault);
    }
  }

  void _addImplemented(
      Map<Name, ExecutableElement> implemented, InterfaceType type) {
    var libraryUri = type.element.librarySource.uri;

    void addMember(ExecutableElement member) {
      if (!member.isAbstract && !member.isStatic) {
        var name = Name(libraryUri, member.name);
        implemented[name] = member;
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
      Name name, List<ExecutableElement> candidates) {
    assert(candidates.length > 1);

    bool allGetters = true;
    bool allMethods = true;
    bool allSetters = true;
    for (var candidate in candidates) {
      var kind = candidate.kind;
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

    ExecutableElement getter;
    ExecutableElement method;
    for (var candidate in candidates) {
      var kind = candidate.kind;
      if (kind == ElementKind.GETTER) {
        getter ??= candidate;
      }
      if (kind == ElementKind.METHOD) {
        method ??= candidate;
      }
    }
    return Conflict(name, candidates, getter, method);
  }

  /// The given [namedCandidates] maps names to candidates from direct
  /// superinterfaces.  Find the most specific signature, and put it into the
  /// [map], if there is no one yet (from the class itself).  If there is no
  /// such single most specific signature (i.e. no valid override), then add a
  /// new conflict description.
  List<Conflict> _findMostSpecificFromNamedCandidates(
    ClassElement targetClass,
    Map<Name, ExecutableElement> map,
    Map<Name, List<ExecutableElement>> namedCandidates, {
    @required bool doTopMerge,
  }) {
    TypeSystemImpl typeSystem = targetClass.library.typeSystem;

    List<Conflict> conflicts;

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

      var validOverrides = <ExecutableElement>[];
      for (var i = 0; i < candidates.length; i++) {
        var validOverride = candidates[i];
        var overrideHelper = CorrectOverrideHelper(
          library: targetClass.library,
          thisMember: validOverride,
        );
        for (var j = 0; j < candidates.length; j++) {
          var candidate = candidates[j];
          if (!overrideHelper.isCorrectOverrideOf(superMember: candidate)) {
            validOverride = null;
            break;
          }
        }
        if (validOverride != null) {
          validOverrides.add(validOverride);
        }
      }

      if (validOverrides.isEmpty) {
        conflicts ??= <Conflict>[];
        conflicts.add(Conflict(name, candidates));
        continue;
      }

      if (doTopMerge) {
        map[name] = _topMerge(typeSystem, targetClass, validOverrides);
      } else {
        map[name] = validOverrides.first;
      }
    }

    return conflicts;
  }

  Map<Name, ExecutableElement> _getTypeMembers(InterfaceType type) {
    var declared = <Name, ExecutableElement>{};
    var libraryUri = type.element.librarySource.uri;

    var methods = type.methods;
    for (var i = 0; i < methods.length; i++) {
      var method = methods[i];
      if (!method.isStatic) {
        var name = Name(libraryUri, method.name);
        declared[name] = method;
      }
    }

    var accessors = type.accessors;
    for (var i = 0; i < accessors.length; i++) {
      var accessor = accessors[i];
      if (!accessor.isStatic) {
        var name = Name(libraryUri, accessor.name);
        declared[name] = accessor;
      }
    }

    return declared;
  }

  /// Given one or more [validOverrides], merge them into a single resulting
  /// signature. This signature always exists.
  ExecutableElement _topMerge(
    TypeSystemImpl typeSystem,
    ClassElement targetClass,
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

    FunctionType resultType;
    for (var executable in validOverrides) {
      var type = executable.type;
      var normalizedType = typeSystem.normalize(type);
      if (resultType == null) {
        resultType = normalizedType;
      } else {
        resultType = typeSystem.topMerge(resultType, normalizedType);
      }
    }

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
      var result = PropertyAccessorElementImpl(firstAccessor.name, -1);
      result.enclosingElement = targetClass;
      result.getter = firstAccessor.isGetter;
      result.returnType = resultType.returnType;
      result.parameters = resultType.parameters;
      return result;
    }
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
    <Name>{},
    const {},
    const [{}],
    const [],
  );

  /// The map of names to their signature in the interface.
  final Map<Name, ExecutableElement> map;

  /// The map of declared names to their signatures.
  final Map<Name, ExecutableElement> declared;

  /// The map of names to their concrete implementations.
  final Map<Name, ExecutableElement> implemented;

  /// The set of names that are `noSuchMethod` forwarders in [implemented].
  final Set<Name> _noSuchMethodForwarders;

  /// The map of names to their signatures from the mixins, superclasses,
  /// or interfaces.
  final Map<Name, List<ExecutableElement>> _overridden;

  /// Each item of this list maps names to their concrete implementations.
  /// The first item of the list is the nominal superclass, next the nominal
  /// superclass plus the first mixin, etc. So, for the class like
  /// `class C extends S with M1, M2`, we get `[S, S&M1, S&M1&M2]`.
  final List<Map<Name, ExecutableElement>> _superImplemented;

  /// The list of conflicts between superinterfaces - the nominal superclass,
  /// mixins, and interfaces.  Does not include conflicts with the declared
  /// members of the class.
  final List<Conflict> conflicts;

  /// The map of names to the most specific signatures from the mixins,
  /// superclasses, or interfaces.
  Map<Name, ExecutableElement> _inheritedMap;

  Interface._(
    this.map,
    this.declared,
    this.implemented,
    this._noSuchMethodForwarders,
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
  @override
  final int hashCode;

  factory Name(Uri libraryUri, String name) {
    if (name.startsWith('_')) {
      var hashCode = JenkinsSmiHash.hash2(libraryUri.hashCode, name.hashCode);
      return Name._internal(libraryUri, name, false, hashCode);
    } else {
      return Name._internal(null, name, true, name.hashCode);
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
