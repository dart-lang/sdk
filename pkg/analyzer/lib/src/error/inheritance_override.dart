// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';

class InheritanceOverrideVerifier {
  static const _missingOverridesKey = 'missingOverrides';

  final TypeSystem _typeSystem;
  final TypeProvider _typeProvider;
  final InheritanceManager2 _inheritance;
  final ErrorReporter _reporter;

  InheritanceOverrideVerifier(
      this._typeSystem, this._inheritance, this._reporter)
      : _typeProvider = _typeSystem.typeProvider;

  void verifyUnit(CompilationUnit unit) {
    var library = unit.declaredElement.library;
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        new _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          library: library,
          classNameNode: declaration.name,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          superclass: declaration.extendsClause?.superclass,
          withClause: declaration.withClause,
        ).verify();
      } else if (declaration is ClassTypeAlias) {
        new _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          library: library,
          classNameNode: declaration.name,
          implementsClause: declaration.implementsClause,
          superclass: declaration.superclass,
          withClause: declaration.withClause,
        ).verify();
      } else if (declaration is MixinDeclaration) {
        new _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          library: library,
          classNameNode: declaration.name,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          onClause: declaration.onClause,
        ).verify();
      }
    }
  }

  /// Returns [FunctionType]s of members that are in the interface of the
  /// given class, but don't have concrete implementations.
  static List<FunctionType> missingOverrides(ClassDeclaration node) {
    return node.name.getProperty(_missingOverridesKey) ?? const [];
  }
}

class _ClassVerifier {
  final TypeSystem typeSystem;
  final TypeProvider typeProvider;
  final InheritanceManager2 inheritance;
  final ErrorReporter reporter;

  final LibraryElement library;
  final Uri libraryUri;
  final ClassElementImpl classElement;

  final SimpleIdentifier classNameNode;
  final List<ClassMember> members;
  final ImplementsClause implementsClause;
  final OnClause onClause;
  final TypeName superclass;
  final WithClause withClause;

  /// The set of unique supertypes of the current class.
  /// It is used to decide when to add a new element to [allSuperinterfaces].
  final Set<InterfaceType> allSupertypes = new Set<InterfaceType>();

  /// The list of all superinterfaces, collected so far.
  final List<Interface> allSuperinterfaces = [];

  _ClassVerifier({
    this.typeSystem,
    this.typeProvider,
    this.inheritance,
    this.reporter,
    this.library,
    this.classNameNode,
    this.implementsClause,
    this.members: const [],
    this.onClause,
    this.superclass,
    this.withClause,
  })  : libraryUri = library.source.uri,
        classElement =
            AbstractClassElementImpl.getImpl(classNameNode.staticElement);

  void verify() {
    if (_checkDirectSuperTypes()) {
      return;
    }

    if (_checkForRecursiveInterfaceInheritance(classElement)) {
      return;
    }

    InterfaceTypeImpl type = classElement.type;

    // Add all superinterfaces of the direct supertype.
    if (type.superclass != null) {
      _addSuperinterfaces(type.superclass);
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
      var mixinType = mixinTypes[i];
      _checkDeclaredMembers(mixinNodes[i], mixinType);
      _addSuperinterfaces(mixinType);
    }

    // Add all superinterfaces of the direct class interfaces.
    for (var interface in type.interfaces) {
      _addSuperinterfaces(interface);
    }

    // Check the members if the class itself, against all the previously
    // collected superinterfaces of the supertype, mixins, and interfaces.
    for (var member in members) {
      if (member is FieldDeclaration) {
        var fieldList = member.fields;
        for (var field in fieldList.variables) {
          FieldElement fieldElement = field.declaredElement;
          _checkDeclaredMember(fieldList, libraryUri, fieldElement.getter);
          _checkDeclaredMember(fieldList, libraryUri, fieldElement.setter);
        }
      } else if (member is MethodDeclaration) {
        _checkDeclaredMember(member, libraryUri, member.declaredElement,
            methodParameterNodes: member.parameters?.parameters);
      }
    }

    // Compute the interface of the class.
    var interface = inheritance.getInterface(type);

    // Report conflicts between direct superinterfaces of the class.
    for (var conflict in interface.conflicts) {
      _reportInconsistentInheritance(classNameNode, conflict);
    }

    _checkForMismatchedAccessorTypes(interface);

    if (!classElement.isAbstract) {
      List<FunctionType> inheritedAbstract = null;

      for (var name in interface.map.keys) {
        if (!name.isAccessibleFor(libraryUri)) {
          continue;
        }

        var interfaceType = interface.map[name];
        var concreteType = interface.implemented[name];

        // No concrete implementation of the name.
        if (concreteType == null) {
          if (!_reportConcreteClassWithAbstractMember(name.name)) {
            inheritedAbstract ??= [];
            inheritedAbstract.add(interfaceType);
          }
          continue;
        }

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
        //    compile-time error.
        if (!typeSystem.isOverrideSubtypeOf(concreteType, interfaceType)) {
          reporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_OVERRIDE,
            classNameNode,
            [
              name.name,
              concreteType.element.enclosingElement.name,
              concreteType.displayName,
              interfaceType.element.enclosingElement.name,
              interfaceType.displayName,
            ],
          );
        }
      }

      _reportInheritedAbstractMembers(inheritedAbstract);
    }
  }

  void _addSuperinterfaces(InterfaceType startingType) {
    var supertypes = <InterfaceType>[];
    ClassElementImpl.collectAllSupertypes(supertypes, startingType, null);
    for (int i = 0; i < supertypes.length; i++) {
      var supertype = supertypes[i];
      if (allSupertypes.add(supertype)) {
        var interface = inheritance.getInterface(supertype);
        allSuperinterfaces.add(interface);
      }
    }
  }

  /// Check that the given [member] is a valid override of the corresponding
  /// instance members in each of [allSuperinterfaces].  The [libraryUri] is
  /// the URI of the library containing the [member].
  void _checkDeclaredMember(
    AstNode node,
    Uri libraryUri,
    ExecutableElement member, {
    List<AstNode> methodParameterNodes,
  }) {
    if (member == null) return;
    if (member.isStatic) return;

    var name = new Name(libraryUri, member.name);
    for (var superInterface in allSuperinterfaces) {
      var superMemberType = superInterface.declared[name];
      if (superMemberType != null) {
        // The case when members have different kinds is reported in verifier.
        // TODO(scheglov) Do it here?
        if (member.kind != superMemberType.element.kind) {
          continue;
        }

        if (!typeSystem.isOverrideSubtypeOf(member.type, superMemberType)) {
          reporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_OVERRIDE,
            node,
            [
              name.name,
              member.enclosingElement.name,
              member.type.displayName,
              superMemberType.element.enclosingElement.name,
              superMemberType.displayName
            ],
          );
        }
        if (methodParameterNodes != null) {
          _checkForOptionalParametersDifferentDefaultValues(
            superMemberType.element,
            member,
            methodParameterNodes,
          );
        }
      }
    }
  }

  /// Check that instance members of [type] are valid overrides of the
  /// corresponding instance members in each of [allSuperinterfaces].
  void _checkDeclaredMembers(AstNode node, InterfaceTypeImpl type) {
    var libraryUri = type.element.library.source.uri;
    for (var method in type.methods) {
      _checkDeclaredMember(node, libraryUri, method);
    }
    for (var accessor in type.accessors) {
      _checkDeclaredMember(node, libraryUri, accessor);
    }
  }

  /// Verify that the given [typeName] does not extend, implement, or mixes-in
  /// types such as `num` or `String`.
  bool _checkDirectSuperType(TypeName typeName, ErrorCode errorCode) {
    if (typeName.isSynthetic) {
      return false;
    }

    // The SDK implementation may implement disallowed types. For example,
    // JSNumber in dart2js and _Smi in Dart VM both implement int.
    if (library.source.isInSystemLibrary) {
      return false;
    }

    DartType type = typeName.type;
    if (typeProvider.nonSubtypableTypes.contains(type)) {
      reporter.reportErrorForNode(errorCode, typeName, [type.displayName]);
      return true;
    }

    return false;
  }

  /// Verify that direct supertypes are valid, and return `false`.  If there
  /// are direct supertypes that are not valid, report corresponding errors,
  /// and return `true`.
  bool _checkDirectSuperTypes() {
    var hasError = false;
    if (implementsClause != null) {
      for (var typeName in implementsClause.interfaces) {
        if (_checkDirectSuperType(
          typeName,
          CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
      }
    }
    if (onClause != null) {
      for (var typeName in onClause.superclassConstraints) {
        if (_checkDirectSuperType(
          typeName,
          CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
      }
    }
    if (superclass != null) {
      if (_checkDirectSuperType(
        superclass,
        CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      )) {
        hasError = true;
      }
    }
    if (withClause != null) {
      for (var typeName in withClause.mixinTypes) {
        if (_checkDirectSuperType(
          typeName,
          CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
      }
    }
    return hasError;
  }

  void _checkForMismatchedAccessorTypes(Interface interface) {
    for (var name in interface.map.keys) {
      if (!name.isAccessibleFor(libraryUri)) continue;

      var getter = interface.map[name];
      if (getter.element.kind == ElementKind.GETTER) {
        // TODO(scheglov) We should separate getters and setters.
        var setter = interface.map[new Name(libraryUri, '${name.name}=')];
        if (setter != null && setter.parameters.length == 1) {
          var getterType = getter.returnType;
          var setterType = setter.parameters[0].type;
          if (!typeSystem.isAssignableTo(getterType, setterType)) {
            var getterElement = getter.element;
            var setterElement = setter.element;

            Element errorElement;
            if (getterElement.enclosingElement == classElement) {
              errorElement = getterElement;
            } else if (setterElement.enclosingElement == classElement) {
              errorElement = setterElement;
            } else {
              errorElement = classElement;
            }

            String getterName = getterElement.displayName;
            if (getterElement.enclosingElement != classElement) {
              var getterClassName = getterElement.enclosingElement.displayName;
              getterName = '$getterClassName.$getterName';
            }

            String setterName = setterElement.displayName;
            if (setterElement.enclosingElement != classElement) {
              var setterClassName = setterElement.enclosingElement.displayName;
              setterName = '$setterClassName.$setterName';
            }

            reporter.reportErrorForElement(
                StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES,
                errorElement,
                [getterName, getterType, setterType, setterName]);
          }
        }
      }
    }
  }

  void _checkForOptionalParametersDifferentDefaultValues(
    ExecutableElement baseExecutable,
    ExecutableElement derivedExecutable,
    List<AstNode> derivedParameterNodes,
  ) {
    var derivedOptionalNodes = <AstNode>[];
    var derivedOptionalElements = <ParameterElementImpl>[];
    var derivedParameterElements = derivedExecutable.parameters;
    for (var i = 0; i < derivedParameterElements.length; i++) {
      var parameterElement = derivedParameterElements[i];
      if (parameterElement.isOptional) {
        derivedOptionalNodes.add(derivedParameterNodes[i]);
        derivedOptionalElements.add(parameterElement);
      }
    }

    var baseOptionalElements = <ParameterElementImpl>[];
    var baseParameterElements = baseExecutable.parameters;
    for (var i = 0; i < baseParameterElements.length; ++i) {
      var baseParameter = baseParameterElements[i];
      if (baseParameter.isOptional) {
        baseOptionalElements.add(baseParameter);
      }
    }

    // Stop if no optional parameters.
    if (baseOptionalElements.isEmpty || derivedOptionalElements.isEmpty) {
      return;
    }

    if (derivedOptionalElements[0].isNamed) {
      for (int i = 0; i < derivedOptionalElements.length; i++) {
        var derivedElement = derivedOptionalElements[i];
        var name = derivedElement.name;
        for (var j = 0; j < baseOptionalElements.length; j++) {
          var baseParameter = baseOptionalElements[j];
          if (name == baseParameter.name && baseParameter.initializer != null) {
            var baseValue = baseParameter.computeConstantValue();
            var derivedResult = derivedElement.evaluationResult;
            if (!_constantValuesEqual(derivedResult.value, baseValue)) {
              reporter.reportErrorForNode(
                StaticWarningCode
                    .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED,
                derivedOptionalNodes[i],
                [
                  baseExecutable.enclosingElement.displayName,
                  baseExecutable.displayName,
                  name
                ],
              );
            }
          }
        }
      }
    } else {
      for (var i = 0;
          i < derivedOptionalElements.length && i < baseOptionalElements.length;
          i++) {
        var baseElement = baseOptionalElements[i];
        if (baseElement.initializer != null) {
          var baseValue = baseElement.computeConstantValue();
          var derivedResult = derivedOptionalElements[i].evaluationResult;
          if (!_constantValuesEqual(derivedResult.value, baseValue)) {
            reporter.reportErrorForNode(
              StaticWarningCode
                  .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
              derivedOptionalNodes[i],
              [
                baseExecutable.enclosingElement.displayName,
                baseExecutable.displayName
              ],
            );
          }
        }
      }
    }
  }

  /// Check that [classElement] is not a superinterface to itself.
  /// The [path] is a list containing the potentially cyclic implements path.
  ///
  /// See [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH].
  bool _checkForRecursiveInterfaceInheritance(ClassElement element,
      [List<ClassElement> path]) {
    path ??= <ClassElement>[];

    // Detect error condition.
    int size = path.length;
    // If this is not the base case (size > 0), and the enclosing class is the
    // given class element then report an error.
    if (size > 0 && classElement == element) {
      String className = classElement.displayName;
      if (size > 1) {
        // Construct a string showing the cyclic implements path:
        // "A, B, C, D, A"
        String separator = ", ";
        StringBuffer buffer = new StringBuffer();
        for (int i = 0; i < size; i++) {
          buffer.write(path[i].displayName);
          buffer.write(separator);
        }
        buffer.write(element.displayName);
        reporter.reportErrorForElement(
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            classElement,
            [className, buffer.toString()]);
        return true;
      } else {
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS or
        // RECURSIVE_INTERFACE_INHERITANCE_ON or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH
        reporter.reportErrorForElement(
            _getRecursiveErrorCode(element), classElement, [className]);
        return true;
      }
    }

    if (path.indexOf(element) > 0) {
      return false;
    }
    path.add(element);

    // n-case
    InterfaceType supertype = element.supertype;
    if (supertype != null &&
        _checkForRecursiveInterfaceInheritance(supertype.element, path)) {
      return true;
    }

    for (InterfaceType type in element.mixins) {
      if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
        return true;
      }
    }

    for (InterfaceType type in element.superclassConstraints) {
      if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
        return true;
      }
    }

    for (InterfaceType type in element.interfaces) {
      if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
        return true;
      }
    }

    path.removeAt(path.length - 1);
    return false;
  }

  /// Return the error code that should be used when the given class [element]
  /// references itself directly.
  ErrorCode _getRecursiveErrorCode(ClassElement element) {
    if (element.supertype?.element == classElement) {
      return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS;
    }

    for (InterfaceType type in element.superclassConstraints) {
      if (type.element == classElement) {
        return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON;
      }
    }

    for (InterfaceType type in element.mixins) {
      if (type.element == classElement) {
        return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH;
      }
    }

    return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS;
  }

  /// We identified that the current non-abstract class does not have the
  /// concrete implementation of a method with the given [name].  If this is
  /// because the class itself defines an abstract method with this [name],
  /// report the more specific error, and return `true`.
  bool _reportConcreteClassWithAbstractMember(String name) {
    for (var member in members) {
      if (member is MethodDeclaration) {
        var name2 = member.name.name;
        if (member.isSetter) {
          name2 += '=';
        }
        if (name2 == name) {
          reporter.reportErrorForNode(
              StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
              member,
              [name, classElement.name]);
          return true;
        }
      }
    }
    return false;
  }

  void _reportInconsistentInheritance(AstNode node, Conflict conflict) {
    var name = conflict.name;

    if (conflict.getter != null && conflict.method != null) {
      reporter.reportErrorForNode(
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

      reporter.reportErrorForNode(
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
        node,
        [name.name, candidatesStr],
      );
    }
  }

  void _reportInheritedAbstractMembers(List<FunctionType> types) {
    if (types == null) {
      return;
    }

    classNameNode.setProperty(
      InheritanceOverrideVerifier._missingOverridesKey,
      types,
    );

    var descriptions = <String>[];
    for (FunctionType type in types) {
      ExecutableElement element = type.element;

      String prefix = '';
      if (element is PropertyAccessorElement) {
        if (element.isGetter) {
          prefix = 'getter ';
        } else {
          prefix = 'setter ';
        }
      }

      String description;
      var elementName = element.displayName;
      var enclosingElement = element.enclosingElement;
      if (enclosingElement != null) {
        var enclosingName = enclosingElement.displayName;
        description = "$prefix$enclosingName.$elementName";
      } else {
        description = "$prefix$elementName";
      }

      descriptions.add(description);
    }
    descriptions.sort();

    if (descriptions.length == 1) {
      reporter.reportErrorForNode(
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
        classNameNode,
        [descriptions[0]],
      );
    } else if (descriptions.length == 2) {
      reporter.reportErrorForNode(
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
        classNameNode,
        [descriptions[0], descriptions[1]],
      );
    } else if (descriptions.length == 3) {
      reporter.reportErrorForNode(
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
        classNameNode,
        [descriptions[0], descriptions[1], descriptions[2]],
      );
    } else if (descriptions.length == 4) {
      reporter.reportErrorForNode(
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
        classNameNode,
        [descriptions[0], descriptions[1], descriptions[2], descriptions[3]],
      );
    } else {
      reporter.reportErrorForNode(
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
        classNameNode,
        [
          descriptions[0],
          descriptions[1],
          descriptions[2],
          descriptions[3],
          descriptions.length - 4
        ],
      );
    }
  }

  static bool _constantValuesEqual(DartObject x, DartObject y) {
    // If either constant value couldn't be computed due to an error, the
    // corresponding DartObject will be `null`.  Since an error has already been
    // reported, there's no need to report another.
    if (x == null || y == null) return true;
    return (x as DartObjectImpl).isEqualIgnoringTypesRecursively(y);
  }
}
