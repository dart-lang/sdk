// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/correct_override.dart';
import 'package:analyzer/src/error/getter_setter_types_verifier.dart';
import 'package:analyzer/src/task/inference_error.dart';

final _missingMustBeOverridden = Expando<List<ExecutableElement>>();
final _missingOverrides = Expando<List<ExecutableElement>>();

class InheritanceOverrideVerifier {
  final TypeSystemImpl _typeSystem;
  final TypeProvider _typeProvider;
  final InheritanceManager3 _inheritance;
  final ErrorReporter _reporter;

  InheritanceOverrideVerifier(
    this._typeSystem,
    this._inheritance,
    this._reporter,
  ) : _typeProvider = _typeSystem.typeProvider;

  void verifyUnit(CompilationUnit unit) {
    var library = unit.declaredElement!.library as LibraryElementImpl;
    for (var declaration in unit.declarations) {
      _ClassVerifier verifier;
      if (declaration is ClassDeclaration) {
        var element = declaration.declaredElement!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameToken: declaration.name,
          classElement: element,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          superclass: declaration.extendsClause?.superclass,
          withClause: declaration.withClause,
        );
        if (element.isAugmentation) {
          verifier._checkDirectSuperTypes();
          continue;
        }
      } else if (declaration is ClassTypeAlias) {
        var element = declaration.declaredElement!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameToken: declaration.name,
          classElement: element,
          implementsClause: declaration.implementsClause,
          superclass: declaration.superclass,
          withClause: declaration.withClause,
        );
        if (element.isAugmentation) {
          verifier._checkDirectSuperTypes();
          continue;
        }
      } else if (declaration is EnumDeclaration) {
        var element = declaration.declaredElement!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameToken: declaration.name,
          classElement: element,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          withClause: declaration.withClause,
        );
        if (element.isAugmentation) {
          verifier._checkDirectSuperTypes();
          continue;
        }
      } else if (declaration is MixinDeclaration) {
        var element = declaration.declaredElement!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameToken: declaration.name,
          classElement: element,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          onClause: declaration.onClause,
        );
        if (element.isAugmentation) {
          verifier._checkDirectSuperTypes();
          continue;
        }
      } else {
        continue;
      }

      if (verifier.verify()) {
        continue;
      }

      verifier._verifyMustBeOverridden();
    }
  }

  /// Returns [Element] members that are in the interface of the
  /// given class with `@mustBeOverridden`, but don't have implementations.
  static List<ExecutableElement> missingMustBeOverridden(
      NamedCompilationUnitMember node) {
    return _missingMustBeOverridden[node.name] ?? const [];
  }

  /// Returns [ExecutableElement] members that are in the interface of the
  /// given class, but don't have concrete implementations.
  static List<ExecutableElement> missingOverrides(
      NamedCompilationUnitMember node) {
    return _missingOverrides[node.name] ?? const [];
  }
}

class _ClassVerifier {
  final TypeSystemImpl typeSystem;
  final TypeProvider typeProvider;
  final InheritanceManager3 inheritance;
  final ErrorReporter reporter;

  final FeatureSet featureSet;
  final LibraryElementImpl library;
  final Uri libraryUri;
  final InterfaceElement classElement;

  final Token classNameToken;
  final List<ClassMember> members;
  final ImplementsClause? implementsClause;
  final MixinOnClause? onClause;
  final NamedType? superclass;
  final WithClause? withClause;

  final List<InterfaceType> directSuperInterfaces = [];

  late final bool implementsDartCoreEnum =
      classElement.allSupertypes.any((e) => e.isDartCoreEnum);

  _ClassVerifier({
    required this.typeSystem,
    required this.typeProvider,
    required this.inheritance,
    required this.reporter,
    required this.featureSet,
    required this.library,
    required this.classNameToken,
    required this.classElement,
    this.implementsClause,
    this.members = const [],
    this.onClause,
    this.superclass,
    this.withClause,
  }) : libraryUri = library.source.uri;

  /// Verify inheritance overrides, and return `true` if an error was
  /// reported which should prevent follow on diagnostics from being reported.
  bool verify() {
    if (_checkDirectSuperTypes()) {
      return true;
    }

    var fragment = classElement;
    var augmented = fragment.augmented;
    var declaration = augmented.declaration;

    if (declaration is! EnumElement &&
        declaration is ClassElement &&
        !declaration.isAbstract &&
        implementsDartCoreEnum) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE,
      );
      return true;
    }

    if (_checkForRecursiveInterfaceInheritance(declaration)) {
      return true;
    }

    // Compute the interface of the class.
    var interface = inheritance.getInterface(declaration);

    // Report conflicts between direct superinterfaces of the class.
    for (var conflict in interface.conflicts) {
      _reportInconsistentInheritance(classNameToken, conflict);
    }

    if (declaration.supertype != null) {
      directSuperInterfaces.add(declaration.supertype!);
    }
    if (augmented is AugmentedMixinElement) {
      directSuperInterfaces.addAll(augmented.superclassConstraints);
    }

    // Each mixin in `class C extends S with M0, M1, M2 {}` is equivalent to:
    //   class S&M0 extends S { ...members of M0... }
    //   class S&M1 extends S&M0 { ...members of M1... }
    //   class S&M2 extends S&M1 { ...members of M2... }
    //   class C extends S&M2 { ...members of C... }
    // So, we need to check members of each mixin against superinterfaces
    // of `S`, and superinterfaces of all previous mixins.
    var mixinNodes = withClause?.mixinTypes;
    var mixinTypes = declaration.mixins;
    for (var i = 0; i < mixinTypes.length; i++) {
      var mixinType = mixinTypes[i];
      _checkDeclaredMembers(mixinNodes![i], mixinType, mixinIndex: i);
      directSuperInterfaces.add(mixinType);
    }

    directSuperInterfaces.addAll(augmented.interfaces);

    // Check the members of the class itself, against all the previously
    // collected superinterfaces of the supertype, mixins, and interfaces.
    for (var member in members) {
      if (member is FieldDeclaration) {
        var fieldList = member.fields;
        for (var field in fieldList.variables) {
          var fieldElement = field.declaredElement as FieldElement;
          _checkDeclaredMember(field.name, libraryUri, fieldElement.getter);
          _checkDeclaredMember(field.name, libraryUri, fieldElement.setter);
          if (!member.isStatic && declaration is! EnumElement) {
            _checkIllegalEnumValuesDeclaration(field.name);
          }
          if (!member.isStatic) {
            _checkIllegalConcreteEnumMemberDeclaration(field.name);
          }
        }
      } else if (member is MethodDeclaration) {
        var hasError = _reportNoCombinedSuperSignature(member);
        if (hasError) {
          continue;
        }

        _checkDeclaredMember(member.name, libraryUri, member.declaredElement,
            methodParameterNodes: member.parameters?.parameters);
        if (!(member.isStatic || member.isAbstract || member.isSetter)) {
          _checkIllegalConcreteEnumMemberDeclaration(member.name);
        }
        if (!member.isStatic && declaration is! EnumElement) {
          _checkIllegalEnumValuesDeclaration(member.name);
        }
      }
    }

    _checkIllegalConcreteEnumMemberInheritance();
    _checkIllegalEnumValuesInheritance();

    GetterSetterTypesVerifier(
      typeSystem: typeSystem,
      errorReporter: reporter,
    ).checkInterface(declaration, interface);

    if (declaration is ClassElement && !declaration.isAbstract ||
        declaration is EnumElement) {
      List<ExecutableElement>? inheritedAbstract;

      for (var name in interface.map.keys) {
        if (!name.isAccessibleFor(libraryUri)) {
          continue;
        }

        var interfaceElement = interface.map[name]!;
        var concreteElement = interface.implemented[name];

        // No concrete implementation of the name.
        if (concreteElement == null) {
          if (_reportConcreteClassWithAbstractMember(name.name)) {
            continue;
          }
          if (_isNotImplementedInConcreteSuperClass(declaration, name)) {
            continue;
          }
          // We already reported ILLEGAL_ENUM_VALUES_INHERITANCE.
          if (declaration is EnumElement &&
              const {'values', 'values='}.contains(name.name)) {
            continue;
          }
          inheritedAbstract ??= [];
          inheritedAbstract.add(interfaceElement);
          continue;
        }

        // The case when members have different kinds is reported in verifier.
        if (concreteElement.kind != interfaceElement.kind) {
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
        // TODO(brianwilkerson): This code catches some cases not caught in
        //  _checkDeclaredMember, but also duplicates the diagnostic reported
        //  there in some other cases.
        // TODO(brianwilkerson): In the case of methods inherited via mixins, the
        //  diagnostic should be reported on the name of the mixin defining the
        //  method. In other cases, it should be reported on the name of the
        //  overriding method. The classNameNode is always wrong.
        CorrectOverrideHelper(
          typeSystem: typeSystem,
          thisMember: concreteElement,
        ).verify(
          superMember: interfaceElement,
          errorReporter: reporter,
          errorNode: classNameToken,
          errorCode: concreteElement is PropertyAccessorElement &&
                  concreteElement.isSetter
              ? CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE_SETTER
              : CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE,
        );
      }

      _reportInheritedAbstractMembers(inheritedAbstract);
    }

    return false;
  }

  /// Check that the given [member] is a valid override of the corresponding
  /// instance members in each of [directSuperInterfaces].  The [libraryUri] is
  /// the URI of the library containing the [member].
  void _checkDeclaredMember(
    SyntacticEntity node,
    Uri libraryUri,
    ExecutableElement? member, {
    List<FormalParameter>? methodParameterNodes,
    int mixinIndex = -1,
  }) {
    if (member == null) return;
    if (member.isStatic) return;

    var name = Name(libraryUri, member.name);
    var correctOverrideHelper = CorrectOverrideHelper(
      typeSystem: typeSystem,
      thisMember: member,
    );

    for (var superType in directSuperInterfaces) {
      var superMember = inheritance.getMember(
        superType,
        name,
        forMixinIndex: mixinIndex,
      );
      if (superMember == null) {
        continue;
      }

      // The case when members have different kinds is reported in verifier.
      // TODO(scheglov): Do it here?
      if (member.kind != superMember.kind) {
        continue;
      }

      correctOverrideHelper.verify(
          superMember: superMember,
          errorReporter: reporter,
          errorNode: node,
          errorCode: member is PropertyAccessorElement && member.isSetter
              ? CompileTimeErrorCode.INVALID_OVERRIDE_SETTER
              : CompileTimeErrorCode.INVALID_OVERRIDE);
    }

    if (mixinIndex == -1) {
      CovariantParametersVerifier(thisMember: member).verify(
        errorReporter: reporter,
        errorEntity: node,
      );
    }
  }

  /// Check that instance members of [type] are valid overrides of the
  /// corresponding instance members in each of [directSuperInterfaces].
  void _checkDeclaredMembers(AstNode node, InterfaceType type,
      {required int mixinIndex}) {
    var libraryUri = type.element.library.source.uri;
    for (var method in type.methods) {
      _checkDeclaredMember(node, libraryUri, method, mixinIndex: mixinIndex);
    }
    for (var accessor in type.accessors) {
      _checkDeclaredMember(node, libraryUri, accessor, mixinIndex: mixinIndex);
    }
  }

  /// If [type] cannot be subtyped, invokes a function and returns `true`.
  bool _checkDirectSuperType({
    required DartType type,
    void Function()? hasEnum,
    void Function()? notSubtypable,
  }) {
    // The SDK implementation may implement disallowed types. For example,
    // JSNumber in dart2js and _Smi in Dart VM both implement int.
    if (library.source.uri.isScheme('dart')) {
      return false;
    }

    if (type is! InterfaceType) {
      return false;
    }
    var typeElement = type.element;

    var classElement = this.classElement;
    if (typeElement is ClassElement &&
        typeElement.isDartCoreEnum &&
        library.featureSet.isEnabled(Feature.enhanced_enums)) {
      if (classElement is ClassElement && classElement.isAbstract ||
          classElement is EnumElement ||
          classElement is MixinElement) {
        return false;
      }
      hasEnum?.call();
      return true;
    }

    if (typeProvider.isNonSubtypableClass(typeElement)) {
      notSubtypable?.call();
      return true;
    }

    return false;
  }

  /// Verify that the given [namedType] does not extend, implement, or mixes-in
  /// types such as `num` or `String`.
  bool _checkDirectSuperTypeNode(NamedType namedType, ErrorCode errorCode) {
    if (namedType.isSynthetic) {
      return false;
    }

    var type = namedType.typeOrThrow;
    return _checkDirectSuperType(
      type: type,
      hasEnum: () {
        reporter.atNode(
          namedType,
          CompileTimeErrorCode.CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE,
        );
      },
      notSubtypable: () {
        reporter.atNode(
          namedType,
          errorCode,
          arguments: [type],
        );
      },
    );
  }

  /// Verify that direct supertypes are valid, and return `false`.  If there
  /// are direct supertypes that are not valid, report corresponding errors,
  /// and return `true`.
  bool _checkDirectSuperTypes() {
    var hasError = false;
    if (implementsClause != null) {
      for (var namedType in implementsClause!.interfaces) {
        if (_checkDirectSuperTypeNode(
          namedType,
          CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
      }
    }
    if (onClause != null) {
      for (var namedType in onClause!.superclassConstraints) {
        if (_checkDirectSuperTypeNode(
          namedType,
          CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
      }
    }
    if (superclass != null) {
      if (_checkDirectSuperTypeNode(
        superclass!,
        CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      )) {
        hasError = true;
      }
    }
    if (withClause != null) {
      for (var namedType in withClause!.mixinTypes) {
        if (_checkDirectSuperTypeNode(
          namedType,
          CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS,
        )) {
          hasError = true;
        }
        if (classElement is EnumElement && _checkMixinOfEnum(namedType)) {
          hasError = true;
        }
      }
    }

    if (hasError) {
      return true;
    }

    // The code below should return `true` to indicate that even though
    // the declaration itself does not have sub-typing violations, the merged
    // augmentation does. So that we stop other verifications in this case.

    // We are interested only in declarations.
    if (classElement.isAugmentation) {
      return false;
    }

    // If no augmentations, we have seen it all.
    if (classElement.augmentation == null) {
      return false;
    }

    if (classElement case ClassElement classElement) {
      var supertype = classElement.supertype;
      if (supertype != null) {
        if (_checkDirectSuperType(type: supertype)) {
          return true;
        }
      }
    }

    var augmented = classElement.augmented;

    for (var type in augmented.interfaces) {
      if (_checkDirectSuperType(type: type)) {
        return true;
      }
    }

    for (var type in augmented.mixins) {
      if (_checkDirectSuperType(type: type)) {
        return true;
      }
    }

    return false;
  }

  /// Check that [classElement] is not a superinterface to itself.
  /// The [path] is a list containing the potentially cyclic implements path.
  ///
  /// See [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON],
  /// [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH].
  bool _checkForRecursiveInterfaceInheritance(InterfaceElement element,
      [List<InterfaceElement>? path]) {
    path ??= <InterfaceElement>[];

    var augmented = element.augmented;

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
        StringBuffer buffer = StringBuffer();
        for (int i = 0; i < size; i++) {
          buffer.write(path[i].displayName);
          buffer.write(separator);
        }
        buffer.write(element.displayName);
        reporter.atElement(
          classElement,
          CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
          arguments: [className, buffer.toString()],
        );
        return true;
      } else {
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS or
        // RECURSIVE_INTERFACE_INHERITANCE_ON or
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH
        reporter.atElement(
          classElement,
          _getRecursiveErrorCode(element),
          arguments: [className],
        );
        return true;
      }
    }

    if (path.indexOf(element) > 0) {
      return false;
    }
    path.add(element);

    // n-case
    var supertype = element.supertype;
    if (supertype != null &&
        _checkForRecursiveInterfaceInheritance(supertype.element, path)) {
      return true;
    }

    for (InterfaceType type in augmented.mixins) {
      if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
        return true;
      }
    }

    if (augmented is AugmentedMixinElement) {
      for (InterfaceType type in augmented.superclassConstraints) {
        if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
          return true;
        }
      }
    }

    for (InterfaceType type in augmented.interfaces) {
      if (_checkForRecursiveInterfaceInheritance(type.element, path)) {
        return true;
      }
    }

    path.removeAt(path.length - 1);
    return false;
  }

  void _checkIllegalConcreteEnumMemberDeclaration(Token name) {
    if (implementsDartCoreEnum) {
      var classElement = this.classElement;
      if (classElement is ClassElementImpl &&
              !classElement.isDartCoreEnumImpl ||
          classElement is EnumElementImpl ||
          classElement is MixinElementImpl) {
        if (const {'index', 'hashCode', '=='}.contains(name.lexeme)) {
          reporter.atToken(
            name,
            CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION,
            arguments: [name.lexeme],
          );
        }
      }
    }
  }

  void _checkIllegalConcreteEnumMemberInheritance() {
    // We ignore mixins because they don't inherit and members.
    // But to support `super.foo()` invocations we put members from superclass
    // constraints into the `superImplemented` bucket, the same we look below.
    if (classElement is MixinElement) {
      return;
    }

    if (implementsDartCoreEnum) {
      var concreteMap = inheritance.getInheritedConcreteMap2(classElement);

      void checkSingle(
        String memberName,
        bool Function(ClassElement enclosingClass) filter,
      ) {
        var member = concreteMap[Name(libraryUri, memberName)];
        if (member != null) {
          var enclosingClass = member.enclosingElement3 as InterfaceElement;
          if (enclosingClass is! ClassElement || filter(enclosingClass)) {
            reporter.atToken(
              classNameToken,
              CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE,
              arguments: [memberName, enclosingClass.name],
            );
          }
        }
      }

      checkSingle('hashCode', (e) => !e.isDartCoreObject);
      checkSingle('==', (e) => !e.isDartCoreObject);
      checkSingle('index', (e) => !e.isDartCoreEnum);
    }
  }

  void _checkIllegalEnumValuesDeclaration(Token name) {
    if (implementsDartCoreEnum && name.lexeme == 'values') {
      reporter.atToken(
        name,
        CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION,
      );
    }
  }

  void _checkIllegalEnumValuesInheritance() {
    if (implementsDartCoreEnum) {
      var getter = inheritance.getInherited2(
        classElement,
        Name(libraryUri, 'values'),
      );
      var setter = inheritance.getInherited2(
        classElement,
        Name(libraryUri, 'values='),
      );
      var inherited = getter ?? setter;
      if (inherited != null) {
        reporter.atToken(
          classNameToken,
          CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE,
          arguments: [inherited.enclosingElement3.name!],
        );
      }
    }
  }

  bool _checkMixinOfEnum(NamedType namedType) {
    DartType type = namedType.typeOrThrow;
    if (type is! InterfaceType) {
      return false;
    }

    var interfaceElement = type.element;
    if (interfaceElement is EnumElement ||
        interfaceElement is ExtensionTypeElement) {
      return false;
    }

    if (interfaceElement.fields.every((e) => e.isStatic || e.isSynthetic)) {
      return false;
    }

    reporter.atNode(
      namedType,
      CompileTimeErrorCode.ENUM_MIXIN_WITH_INSTANCE_VARIABLE,
    );
    return true;
  }

  /// Return the error code that should be used when the given class [element]
  /// references itself directly.
  ErrorCode _getRecursiveErrorCode(InterfaceElement element) {
    var augmented = element.augmented;

    if (element.supertype?.element == classElement) {
      return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS;
    }

    if (augmented is AugmentedMixinElement) {
      for (InterfaceType type in augmented.superclassConstraints) {
        if (type.element == classElement) {
          return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON;
        }
      }
    }

    for (InterfaceType type in augmented.mixins) {
      if (type.element == classElement) {
        return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH;
      }
    }

    return CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS;
  }

  /// If [name] is not implemented in the extended concrete class, the
  /// issue should be fixed there, and then [element] will not have it too.
  bool _isNotImplementedInConcreteSuperClass(
    InterfaceElement element,
    Name name,
  ) {
    var superElement = classElement.supertype?.element;
    if (superElement is ClassElement && !superElement.isAbstract) {
      var superInterface = inheritance.getInterface(superElement);
      return superInterface.map.containsKey(name);
    }
    return false;
  }

  /// We identified that the current non-abstract class does not have the
  /// concrete implementation of a method with the given [name].  If this is
  /// because the class itself defines an abstract method with this [name],
  /// report the more specific error, and return `true`.
  bool _reportConcreteClassWithAbstractMember(String name) {
    bool checkMemberNameCombo(
        ClassMember member, String memberName, String displayName) {
      if (memberName == name) {
        reporter.atNode(
          member,
          classElement is EnumElement
              ? CompileTimeErrorCode.ENUM_WITH_ABSTRACT_MEMBER
              : CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
          arguments: [displayName, classElement.name],
        );
        return true;
      } else {
        return false;
      }
    }

    for (var member in members) {
      if (member is MethodDeclaration) {
        var displayName = member.name.lexeme;
        var name = displayName;
        if (member.isSetter) {
          name += '=';
        }
        if (checkMemberNameCombo(member, name, displayName)) return true;
      } else if (member is FieldDeclaration) {
        for (var variableDeclaration in member.fields.variables) {
          var name = variableDeclaration.name.lexeme;
          if (checkMemberNameCombo(member, name, name)) return true;
          if (!variableDeclaration.isFinal) {
            if (checkMemberNameCombo(member, '$name=', name)) return true;
          }
        }
      }
    }
    return false;
  }

  void _reportInconsistentInheritance(Token token, Conflict conflict) {
    var name = conflict.name;

    if (conflict is GetterMethodConflict) {
      // Members that participate in inheritance are always enclosed in named
      // elements so it is safe to assume that
      // `conflict.getter.enclosingElement.name` and
      // `conflict.method.enclosingElement.name` are both non-`null`.
      reporter.atToken(
        token,
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
        arguments: [
          name.name,
          conflict.getter.enclosingElement3.name!,
          conflict.method.enclosingElement3.name!
        ],
      );
    } else if (conflict is CandidatesConflict) {
      var candidatesStr = conflict.candidates.map((candidate) {
        var className = candidate.enclosingElement3.name;
        var typeStr = candidate.type.getDisplayString();
        return '$className.${name.name} ($typeStr)';
      }).join(', ');

      reporter.atToken(
        token,
        CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
        arguments: [name.name, candidatesStr],
      );
    } else {
      throw StateError('${conflict.runtimeType}');
    }
  }

  void _reportInheritedAbstractMembers(List<ExecutableElement>? elements) {
    if (elements == null) {
      return;
    }

    _missingOverrides[classNameToken] = elements;

    var descriptions = <String>[];
    for (var element in elements) {
      var prefix = '';
      if (element is PropertyAccessorElement) {
        if (element.isGetter) {
          prefix = 'getter ';
        } else {
          prefix = 'setter ';
        }
      }

      var elementName = element.displayName;
      var enclosingElement = element.enclosingElement3;
      var enclosingName = enclosingElement.displayName;
      var description = "$prefix$enclosingName.$elementName";

      descriptions.add(description);
    }
    descriptions.sort();

    if (descriptions.length == 1) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
        arguments: [descriptions[0]],
      );
    } else if (descriptions.length == 2) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
        arguments: [descriptions[0], descriptions[1]],
      );
    } else if (descriptions.length == 3) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
        arguments: [descriptions[0], descriptions[1], descriptions[2]],
      );
    } else if (descriptions.length == 4) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
        arguments: [
          descriptions[0],
          descriptions[1],
          descriptions[2],
          descriptions[3]
        ],
      );
    } else {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode
            .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
        arguments: [
          descriptions[0],
          descriptions[1],
          descriptions[2],
          descriptions[3],
          descriptions.length - 4
        ],
      );
    }
  }

  bool _reportNoCombinedSuperSignature(MethodDeclaration node) {
    var element = node.declaredElement;
    if (element is MethodElementImpl) {
      var inferenceError = element.typeInferenceError;
      if (inferenceError?.kind ==
          TopLevelInferenceErrorKind.overrideNoCombinedSuperSignature) {
        reporter.atToken(
          node.name,
          CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE,
          arguments: [
            classElement.name,
            inferenceError!.arguments[0],
          ],
        );
        return true;
      }
    }
    return false;
  }

  /// Verify that [classElement] complies with all `@mustBeOverridden`-annotated
  /// members in all of its supertypes.
  void _verifyMustBeOverridden() {
    var classElement = this.classElement;
    if (classElement is! ClassElement ||
        classElement.isAbstract ||
        classElement.isSealed) {
      // We only care about concrete classes.
      return;
    }

    var noSuchMethodDeclaration =
        classElement.getMethod(FunctionElement.NO_SUCH_METHOD_METHOD_NAME);
    if (noSuchMethodDeclaration != null &&
        !noSuchMethodDeclaration.isAbstract) {
      return;
    }
    var notOverridden = <ExecutableElement>[];
    for (var supertype in classElement.allSupertypes) {
      // TODO(srawlins): This looping may be expensive. Since the vast majority
      // of classes will have zero elements annotated with `@mustBeOverridden`,
      // we could store a bit on ClassElement (included in summaries) which
      // denotes whether any declared element has been so annotated. Then the
      // expensive looping is deferred until we have such a class.
      for (var method in supertype.methods) {
        if (method.isPrivate && method.library != classElement.library) {
          continue;
        }
        if (method.isStatic) {
          continue;
        }
        if (method.hasMustBeOverridden) {
          var methodDeclaration = classElement.getMethod(method.name);
          if (methodDeclaration == null || methodDeclaration.isAbstract) {
            notOverridden.add(method.declaration);
          }
        }
      }
      for (var accessor in supertype.accessors) {
        if (accessor.isPrivate && accessor.library != classElement.library) {
          continue;
        }
        if (accessor.isStatic) {
          continue;
        }
        if (accessor.hasMustBeOverridden ||
            (accessor.variable2?.hasMustBeOverridden ?? false)) {
          PropertyAccessorElement? accessorDeclaration;
          if (accessor.isGetter) {
            accessorDeclaration = classElement.getGetter(accessor.name);
          } else if (accessor.isSetter) {
            accessorDeclaration = classElement.getSetter(accessor.name);
          } else {
            continue;
          }
          if (accessorDeclaration == null || accessorDeclaration.isAbstract) {
            notOverridden.add(accessor);
          }
        }
      }
    }
    if (notOverridden.isEmpty) {
      return;
    }

    _missingMustBeOverridden[classNameToken] = notOverridden.toList();
    var namesForError = notOverridden
        .map((e) {
          var name = e.name;
          if (name.endsWith('=')) {
            name = name.substring(0, name.length - 1);
          }
          return name;
        })
        .toSet()
        .toList();

    if (namesForError.length == 1) {
      reporter.atToken(
        classNameToken,
        WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE,
        arguments: namesForError,
      );
    } else if (namesForError.length == 2) {
      reporter.atToken(
        classNameToken,
        WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO,
        arguments: namesForError,
      );
    } else {
      reporter.atToken(
        classNameToken,
        WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_THREE_PLUS,
        arguments: [
          namesForError[0],
          namesForError[1],
          (namesForError.length - 2).toString(),
        ],
      );
    }
  }
}
