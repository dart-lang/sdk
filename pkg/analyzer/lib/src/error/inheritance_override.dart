// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/type_system.dart';

class InheritanceOverrideVerifier {
  final StrongTypeSystemImpl _typeSystem;
  final InheritanceManager2 _inheritance;
  final ErrorReporter _reporter;

  InheritanceOverrideVerifier(
      this._typeSystem, this._inheritance, this._reporter);

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

  void _reportInconsistentInheritance(AstNode node, Conflict conflict) {
    var name = conflict.name;

    if (conflict.getter != null && conflict.method != null) {
      _reporter.reportErrorForNode(
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
        node,
        [
          name.name,
          conflict.getter.element.enclosingElement.name,
          conflict.method.element.enclosingElement.name
        ],
      );
    } else {
      var candidatesStr = conflict.candidates.map((candidate) {
        var className = candidate.element.enclosingElement.name;
        return '$className.${name.name} (${candidate.displayName})';
      }).join(', ');

      _reporter.reportErrorForNode(
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
        node,
        [name.name, candidatesStr],
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
    var interfaceMembers = _inheritance.getInterface(type);

    // Report conflicts between direct superinterfaces of the class.
    for (var conflict in interfaceMembers.conflicts) {
      _reportInconsistentInheritance(classNameNode, conflict);
    }

    if (!element.isAbstract) {
      var libraryUri = library.source.uri;
      for (var name in interfaceMembers.map.keys) {
        if (!name.isAccessibleFor(libraryUri)) {
          continue;
        }

        var concreteType = _inheritance.getMember(type, name, concrete: true);

        // TODO(scheglov) handle here instead of ErrorVerifier?
        if (concreteType == null) {
          continue;
        }

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
              name.name,
              concreteType.element.enclosingElement.name,
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
