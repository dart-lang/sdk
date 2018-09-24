// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/type_system.dart';

class InheritanceOverrideVerifier {
  final StrongTypeSystemImpl _typeSystem;
  final ErrorReporter _reporter;

  /// Cached instance interfaces for [InterfaceType].
  final Map<InterfaceType, _Interface> _interfaces = {};

  InheritanceOverrideVerifier(this._typeSystem, this._reporter);

  void verifyUnit(CompilationUnit unit) {
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        _verifyClass(declaration.name,
            withClause: declaration.withClause, members: declaration.members);
      } else if (declaration is ClassTypeAlias) {
        _verifyClass(declaration.name, withClause: declaration.withClause);
      } else if (declaration is MixinDeclaration) {
        _verifyClass(declaration.name, members: declaration.members);
      }
    }
  }

  /// Check that the given [member] is a valid override of the corresponding
  /// instance members in each of [allSuperinterfaces].
  void _checkDeclaredMember(
    List<InterfaceType> allSuperinterfaces,
    AstNode node,
    ExecutableElement member,
  ) {
    if (member == null) return;
    if (member.isStatic) return;

    var name = member.name;
    for (var supertype in allSuperinterfaces) {
      var superMember = _getInstanceMember(supertype, name);
      if (superMember != null && superMember.isAccessibleIn(member.library)) {
        // The case when members have different kinds is reported in verifier.
        if (member.kind != superMember.kind) {
          continue;
        }

        if (!_typeSystem.isOverrideSubtypeOf(member.type, superMember.type)) {
          _reporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_OVERRIDE,
            node,
            [
              name,
              member.enclosingElement.name,
              member.type.displayName,
              superMember.enclosingElement.name,
              superMember.type.displayName
            ],
          );
        }
      }
    }
  }

  /// Check that instance members of [type] are valid overrides of the
  /// corresponding instance members in each of [allSuperinterfaces].
  void _checkDeclaredMembers(
    List<InterfaceType> allSuperinterfaces,
    AstNode node,
    InterfaceTypeImpl type,
  ) {
    for (var method in type.methods) {
      _checkDeclaredMember(allSuperinterfaces, node, method);
    }
    for (var accessor in type.accessors) {
      _checkDeclaredMember(allSuperinterfaces, node, accessor);
    }
  }

  /// Return the instance member given the [name], defined in the [type],
  /// or `null` if the [type] does not define a member with the [name], or
  /// if it is not an instance member.
  ExecutableElement _getInstanceMember(InterfaceType type, String name) {
    ExecutableElement result;
    if (name.endsWith('=')) {
      name = name.substring(0, name.length - 1);
      result = type.getSetter(name);
    } else {
      result = type.getMethod(name) ?? type.getGetter(name);
    }
    if (result != null && result.isStatic) {
      result = null;
    }
    return result;
  }

  /// Return the interface of the given [type], for the [consumerLibrary].
  _Interface _getInterface(InterfaceType type, LibraryElement consumerLibrary) {
    if (type == null) return new _Interface({}, []);

    var result = _interfaces[type];
    if (result != null) return result;

    var map = <String, FunctionType>{};
    var conflicts = <_Conflict>[];
    _interfaces[type] = new _Interface(map, conflicts);

    // If a class declaration has a member declaration, the signature of that
    // member declaration becomes the signature in the interface.
    {
      void addTypeMember(ExecutableElement member) {
        if (member.isAccessibleIn(consumerLibrary) && !member.isStatic) {
          map[member.name] = member.type;
        }
      }

      type.methods.forEach(addTypeMember);
      type.accessors.forEach(addTypeMember);
    }

    var inheritedCandidates = <String, List<FunctionType>>{};
    void addSuperinterfaceMember(String name, FunctionType candidate) {
      // If name is in the [map], then it is defined in the [type] itself.
      // Don't consider candidates from direct superinterfaces.
      // The version defined in the type might be invalid, we check elsewhere.
      if (map.containsKey(name)) return;

      var candidates = inheritedCandidates[name];
      if (candidates == null) {
        candidates = <FunctionType>[];
        inheritedCandidates[name] = candidates;
      }
      candidates.add(candidate);
    }

    var library = type.element.library;
    void addSuperinterfaceMembers(InterfaceType superinterface) {
      _getInterface(superinterface, library)
          .map
          .forEach(addSuperinterfaceMember);
    }

    // Fill candidates for each instance name.
    addSuperinterfaceMembers(type.superclass);
    type.superclassConstraints.forEach(addSuperinterfaceMembers);
    type.mixins.forEach(addSuperinterfaceMembers);
    type.interfaces.forEach(addSuperinterfaceMembers);

    // If a class declaration does not have a member declaration with a
    // particular name, but some super-interfaces do have a member with that
    // name, it's a compile-time error if there is no signature among the
    // super-interfaces that is a valid override of all the other
    // super-interface signatures with the same name. That "most specific"
    // signature becomes the signature of the class's interface.
    for (var name in inheritedCandidates.keys) {
      var candidates = inheritedCandidates[name];

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

      if (allSetters) {
        // OK, setters don't conflict with anything.
      } else if (!(allGetters || allMethods)) {
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
        conflicts.add(new _Conflict(name, candidates, getterType, methodType));
        continue;
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
        conflicts.add(new _Conflict(name, candidates));
      }
    }

    return new _Interface(map, conflicts);
  }

  void _reportInconsistentInheritance(AstNode node, _Conflict conflict) {
    var name = conflict.name;

    if (conflict.getter != null && conflict.method != null) {
      _reporter.reportErrorForNode(
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
        node,
        [
          name,
          conflict.getter.element.enclosingElement.name,
          conflict.method.element.enclosingElement.name
        ],
      );
    } else {
      var candidatesStr = conflict.candidates.map((candidate) {
        var className = candidate.element.enclosingElement.name;
        return '$className.$name (${candidate.displayName})';
      }).join(', ');

      _reporter.reportErrorForNode(
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
        node,
        [name, candidatesStr],
      );
    }
  }

  void _verifyClass(SimpleIdentifier classNameNode,
      {List<ClassMember> members: const [], WithClause withClause}) {
    ClassElement element = classNameNode.staticElement;
    LibraryElement library = element.library;
    InterfaceTypeImpl type = element.type;

    var allSuperinterfaces = <InterfaceType>[];

    // Add all superinterfaces of the direct supertype.
    if (type.superclass != null) {
      ClassElementImpl.collectAllSupertypes(
          allSuperinterfaces, type.superclass, null);
    }

    // Each mixin in `class C extends S with M0, M1, M2 {}` is equivalent to:
    //   class S&M0 extends S { ...members of M0... }
    //   class S&M1 extends S&M0 { ...members of M1... }
    //   class S&M2 extends S&M1 { ...members of M2... }
    //   class C extends S&M2 { ...members of C... }
    // So, we need to check members of each mixin against superinterfaces
    // of `S`, and superinterfaces of all previous mixins.
    var mixinNodes = withClause?.mixinTypes;
    var mixinTypes = type.mixins;
    for (var i = 0; i < mixinTypes.length; i++) {
      _checkDeclaredMembers(allSuperinterfaces, mixinNodes[i], mixinTypes[i]);
      ClassElementImpl.collectAllSupertypes(
          allSuperinterfaces, mixinTypes[i], null);
    }

    // Add all superinterfaces of the direct class interfaces.
    for (var interface in type.interfaces) {
      ClassElementImpl.collectAllSupertypes(
          allSuperinterfaces, interface, null);
    }

    // Check the members if the class itself, against all the previously
    // collected superinterfaces of the supertype, mixins, and interfaces.
    for (var member in members) {
      if (member is FieldDeclaration) {
        var fieldList = member.fields;
        for (var field in fieldList.variables) {
          FieldElement fieldElement = field.declaredElement;
          _checkDeclaredMember(
              allSuperinterfaces, fieldList, fieldElement.getter);
          _checkDeclaredMember(
              allSuperinterfaces, fieldList, fieldElement.setter);
        }
      } else if (member is MethodDeclaration) {
        _checkDeclaredMember(
            allSuperinterfaces, member, member.declaredElement);
      }
    }

    // Compute the interface of the class.
    var interfaceMembers = _getInterface(type, element.library);

    // Report conflicts between direct superinterfaces of the class.
    for (var conflict in interfaceMembers.conflicts) {
      _reportInconsistentInheritance(classNameNode, conflict);
    }

    // TODO(scheglov) isMixin must be also isAbstract.
    if (!element.isAbstract && !element.isMixin) {
      for (var name in interfaceMembers.map.keys) {
        var concreteElement = type.lookUpInheritedMember(name, library,
            concrete: true, thisType: true, setter: name.endsWith('='));

        // TODO(scheglov) handle here instead of ErrorVerifier?
        if (concreteElement == null) {
          continue;
        }
        // TODO(scheglov) Why InterfaceType even returns statics?
        if (concreteElement.isStatic) {
          continue;
        }

        var concreteType = concreteElement.type;
        var interfaceType = interfaceMembers.map[name];

        // The case when members have different kinds is reported in verifier.
        if (concreteType.element.kind != interfaceType.element.kind) {
          continue;
        }

        // If a class declaration is not abstract, and the interface has a
        // member declaration named `m`, then:
        // 1. if the class contains a non-overridden member whose signature is
        //    not a valid override of the interface member signature for `m`,
        //    then it's a compile-time error.
        // 2. if the class contains no member named `m`, and the class member
        //    for `noSuchMethod` is the one declared in `Object`, then it's a
        //    compile-time error. TODO(scheglov) implement this
        if (!_typeSystem.isOverrideSubtypeOf(concreteType, interfaceType)) {
          _reporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_OVERRIDE,
            classNameNode,
            [
              name,
              concreteElement.enclosingElement.name,
              concreteType.displayName,
              interfaceType.element.enclosingElement.name,
              interfaceType.displayName
            ],
          );
        }
      }
    }
  }
}

/// Description of a failure to find a valid override from superinterfaces.
class _Conflict {
  /// The name of an instance member for which we failed to find a valid
  /// override.
  final String name;

  /// The list of candidates for a valid override for a member [name].  It has
  /// at least two items, because otherwise the only candidate is always valid.
  final List<FunctionType> candidates;

  final FunctionType getter;
  final FunctionType method;

  _Conflict(this.name, this.candidates, [this.getter, this.method]);
}

/// The instance interface of an [InterfaceType].
class _Interface {
  final Map<String, FunctionType> map;
  final List<_Conflict> conflicts;

  _Interface(this.map, this.conflicts);
}
