// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/correct_override.dart';
import 'package:analyzer/src/error/getter_setter_types_verifier.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

final _missingMustBeOverridden = Expando<List<ExecutableElement>>();
final _missingOverrides = Expando<List<InternalExecutableElement>>();

class InheritanceOverrideVerifier {
  final TypeSystemImpl _typeSystem;
  final TypeProvider _typeProvider;
  final InheritanceManager3 _inheritance;
  final DiagnosticReporter _reporter;

  InheritanceOverrideVerifier(
    this._typeSystem,
    this._inheritance,
    this._reporter,
  ) : _typeProvider = _typeSystem.typeProvider;

  void verifyUnit(CompilationUnitImpl unit) {
    var library = unit.declaredFragment!.element;
    for (var declaration in unit.declarations) {
      _ClassVerifier verifier;
      if (declaration is ClassDeclarationImpl) {
        var fragment = declaration.declaredFragment!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameToken: declaration.name,
          classElement: fragment.element,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          superclass: declaration.extendsClause?.superclass,
          withClause: declaration.withClause,
        );
        if (fragment.isAugmentation) {
          verifier._checkDirectSuperTypes();
          continue;
        }
      } else if (declaration is ClassTypeAliasImpl) {
        var fragment = declaration.declaredFragment!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameToken: declaration.name,
          classElement: fragment.element,
          implementsClause: declaration.implementsClause,
          superclass: declaration.superclass,
          withClause: declaration.withClause,
        );
        if (fragment.isAugmentation) {
          verifier._checkDirectSuperTypes();
          continue;
        }
      } else if (declaration is EnumDeclarationImpl) {
        var fragment = declaration.declaredFragment!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameToken: declaration.name,
          classElement: fragment.element,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          withClause: declaration.withClause,
        );
        if (fragment.isAugmentation) {
          verifier._checkDirectSuperTypes();
          continue;
        }
      } else if (declaration is MixinDeclarationImpl) {
        var fragment = declaration.declaredFragment!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: _reporter,
          featureSet: unit.featureSet,
          library: library,
          classNameToken: declaration.name,
          classElement: fragment.element,
          implementsClause: declaration.implementsClause,
          members: declaration.members,
          onClause: declaration.onClause,
        );
        if (fragment.isAugmentation) {
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

  /// Returns [ExecutableElement] members that are in the interface of the
  /// given class with `@mustBeOverridden`, but don't have implementations.
  static List<ExecutableElement> missingMustBeOverridden(
    NamedCompilationUnitMember node,
  ) {
    return _missingMustBeOverridden[node.name] ?? const [];
  }

  /// Returns [ExecutableElement] members that are in the interface of the
  /// given class, but don't have concrete implementations.
  static List<ExecutableElement> missingOverrides(
    NamedCompilationUnitMember node,
  ) {
    return _missingOverrides[node.name] ?? const [];
  }
}

class _ClassVerifier {
  final TypeSystemImpl typeSystem;
  final TypeProvider typeProvider;
  final InheritanceManager3 inheritance;
  final DiagnosticReporter reporter;

  final FeatureSet featureSet;
  final LibraryElementImpl library;
  final Uri libraryUri;
  final InterfaceElementImpl classElement;

  final Token classNameToken;
  final List<ClassMember> members;
  final ImplementsClause? implementsClause;
  final MixinOnClause? onClause;
  final NamedType? superclass;
  final WithClause? withClause;

  final List<InterfaceType> directSuperInterfaces = [];

  late final bool implementsDartCoreEnum = classElement.allSupertypes.any(
    (e) => e.isDartCoreEnum,
  );

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
  }) : libraryUri = library.uri;

  /// Verify inheritance overrides, and return `true` if an error was
  /// reported which should prevent follow on diagnostics from being reported.
  bool verify() {
    if (_checkDirectSuperTypes()) {
      return true;
    }

    var element = classElement;
    if (element is! EnumElementImpl &&
        element is ClassElementImpl &&
        !element.isAbstract &&
        implementsDartCoreEnum) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.concreteClassHasEnumSuperinterface,
      );
      return true;
    }

    if (_checkForRecursiveInterfaceInheritance(element)) {
      return true;
    }

    // Compute the interface of the class.
    var interface = inheritance.getInterface(element);

    // Report conflicts between direct superinterfaces of the class.
    for (var conflict in interface.conflicts) {
      _reportInconsistentInheritance(classNameToken, conflict);
    }

    if (element.supertype != null) {
      directSuperInterfaces.add(element.supertype!);
    }
    if (element is MixinElementImpl) {
      directSuperInterfaces.addAll(element.superclassConstraints);
    }

    // Each mixin in `class C extends S with M0, M1, M2 {}` is equivalent to:
    //   class S&M0 extends S { ...members of M0... }
    //   class S&M1 extends S&M0 { ...members of M1... }
    //   class S&M2 extends S&M1 { ...members of M2... }
    //   class C extends S&M2 { ...members of C... }
    // So, we need to check members of each mixin against superinterfaces
    // of `S`, and superinterfaces of all previous mixins.
    var mixinNodes = withClause?.mixinTypes;
    var mixinTypes = element.mixins;
    for (var i = 0; i < mixinTypes.length; i++) {
      var mixinType = mixinTypes[i];
      _checkDeclaredMembers(mixinNodes![i], mixinType, mixinIndex: i);
      directSuperInterfaces.add(mixinType);
    }

    directSuperInterfaces.addAll(element.interfaces);

    // Check the members of the class itself, against all the previously
    // collected superinterfaces of the supertype, mixins, and interfaces.
    for (var member in members) {
      if (member is FieldDeclarationImpl) {
        var fieldList = member.fields;
        for (var field in fieldList.variables) {
          var fieldElement = field.declaredFragment! as FieldFragmentImpl;
          _checkDeclaredMember(
            field.name,
            libraryUri,
            fieldElement.element.getter,
          );
          _checkDeclaredMember(
            field.name,
            libraryUri,
            fieldElement.element.setter,
          );
          if (!member.isStatic && element is! EnumElementImpl) {
            _checkIllegalEnumValuesDeclaration(field.name);
          }
          if (!member.isStatic) {
            _checkIllegalConcreteEnumMemberDeclaration(field.name);
          }
        }
      } else if (member is MethodDeclarationImpl) {
        var hasError = _reportNoCombinedSuperSignature(member);
        if (hasError) {
          continue;
        }

        _checkDeclaredMember(
          member.name,
          libraryUri,
          member.declaredFragment!.asElement2,
          methodParameterNodes: member.parameters?.parameters,
        );
        if (!(member.isStatic || member.isAbstract || member.isSetter)) {
          _checkIllegalConcreteEnumMemberDeclaration(member.name);
        }
        if (!member.isStatic && element is! EnumElementImpl) {
          _checkIllegalEnumValuesDeclaration(member.name);
        }
      }
    }

    _checkIllegalConcreteEnumMemberInheritance();
    _checkIllegalEnumValuesInheritance();

    GetterSetterTypesVerifier(
      library: library,
      diagnosticReporter: reporter,
    ).checkInterface(element, interface);

    if (element is ClassElementImpl && !element.isAbstract ||
        element is EnumElementImpl) {
      List<InternalExecutableElement>? inheritedAbstract;

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
          if (_isNotImplementedInConcreteSuperClass(name)) {
            continue;
          }
          // We already reported ILLEGAL_ENUM_VALUES_INHERITANCE.
          if (element is EnumElementImpl &&
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
          diagnosticReporter: reporter,
          errorNode: classNameToken,
          diagnosticCode: concreteElement is InternalSetterElement
              ? CompileTimeErrorCode.invalidImplementationOverrideSetter
              : CompileTimeErrorCode.invalidImplementationOverride,
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
    InternalExecutableElement? member, {
    List<FormalParameter>? methodParameterNodes,
    int mixinIndex = -1,
  }) {
    if (member == null) return;
    if (member.isStatic) return;

    var name = Name.forElement(member);
    if (name == null) return;

    var correctOverrideHelper = CorrectOverrideHelper(
      typeSystem: typeSystem,
      thisMember: member,
    );

    for (var superType in directSuperInterfaces) {
      var superMember = inheritance.getMember3(
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
        diagnosticReporter: reporter,
        errorNode: node,
        diagnosticCode: member is SetterElement
            ? CompileTimeErrorCode.invalidOverrideSetter
            : CompileTimeErrorCode.invalidOverride,
      );
    }

    if (mixinIndex == -1) {
      CovariantParametersVerifier(
        thisMember: member,
      ).verify(errorReporter: reporter, errorEntity: node);
    }
  }

  /// Check that instance members of [type] are valid overrides of the
  /// corresponding instance members in each of [directSuperInterfaces].
  void _checkDeclaredMembers(
    AstNode node,
    InterfaceTypeImpl type, {
    required int mixinIndex,
  }) {
    var libraryUri = type.element.library.uri;
    for (var method in type.methods) {
      _checkDeclaredMember(node, libraryUri, method, mixinIndex: mixinIndex);
    }
    for (var getter in type.getters) {
      _checkDeclaredMember(node, libraryUri, getter, mixinIndex: mixinIndex);
    }
    for (var setter in type.setters) {
      _checkDeclaredMember(node, libraryUri, setter, mixinIndex: mixinIndex);
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
    if (library.uri.isScheme('dart')) {
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
      if (classElement is ClassElementImpl && classElement.isAbstract ||
          classElement is EnumElementImpl ||
          classElement is MixinElementImpl) {
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
  bool _checkDirectSuperTypeNode(
    NamedType namedType,
    DiagnosticCode diagnosticCode,
  ) {
    if (namedType.isSynthetic) {
      return false;
    }

    var type = namedType.typeOrThrow;
    return _checkDirectSuperType(
      type: type,
      hasEnum: () {
        reporter.atNode(
          namedType,
          CompileTimeErrorCode.concreteClassHasEnumSuperinterface,
        );
      },
      notSubtypable: () {
        reporter.atNode(namedType, diagnosticCode, arguments: [type]);
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
          CompileTimeErrorCode.implementsDisallowedClass,
        )) {
          hasError = true;
        }
      }
    }
    if (onClause != null) {
      for (var namedType in onClause!.superclassConstraints) {
        if (_checkDirectSuperTypeNode(
          namedType,
          CompileTimeErrorCode.mixinSuperClassConstraintDisallowedClass,
        )) {
          hasError = true;
        }
      }
    }
    if (superclass != null) {
      if (_checkDirectSuperTypeNode(
        superclass!,
        CompileTimeErrorCode.extendsDisallowedClass,
      )) {
        hasError = true;
      }
    }
    if (withClause != null) {
      for (var namedType in withClause!.mixinTypes) {
        if (_checkDirectSuperTypeNode(
          namedType,
          CompileTimeErrorCode.mixinOfDisallowedClass,
        )) {
          hasError = true;
        }
        if (classElement is EnumElementImpl && _checkMixinOfEnum(namedType)) {
          hasError = true;
        }
      }
    }

    return hasError;
  }

  /// Check that [classElement] is not a superinterface to itself.
  ///
  /// See [CompileTimeErrorCode.recursiveInterfaceInheritance],
  /// [CompileTimeErrorCode.recursiveInterfaceInheritanceExtends],
  /// [CompileTimeErrorCode.recursiveInterfaceInheritanceImplements],
  /// [CompileTimeErrorCode.recursiveInterfaceInheritanceOn],
  /// [CompileTimeErrorCode.recursiveInterfaceInheritanceWith].
  bool _checkForRecursiveInterfaceInheritance(InterfaceElementImpl element) {
    var cycle = element.interfaceCycle;
    if (cycle == null) {
      return false;
    }

    if (superclass case var superclass?) {
      if (superclass.element == element) {
        reporter.atElement2(
          element,
          CompileTimeErrorCode.recursiveInterfaceInheritanceExtends,
          arguments: [element.displayName],
        );
        return true;
      }
    }

    if (onClause case var onClause?) {
      for (var typeAnnotation in onClause.superclassConstraints) {
        if (typeAnnotation.element == element) {
          reporter.atElement2(
            element,
            CompileTimeErrorCode.recursiveInterfaceInheritanceOn,
            arguments: [element.displayName],
          );
          return true;
        }
      }
    }

    if (withClause case var withClause?) {
      for (var typeAnnotation in withClause.mixinTypes) {
        if (typeAnnotation.element == element) {
          reporter.atElement2(
            element,
            CompileTimeErrorCode.recursiveInterfaceInheritanceWith,
            arguments: [element.displayName],
          );
          return true;
        }
      }
    }

    if (implementsClause case var implementsClause?) {
      for (var typeAnnotation in implementsClause.interfaces) {
        if (typeAnnotation.element == element) {
          reporter.atElement2(
            element,
            CompileTimeErrorCode.recursiveInterfaceInheritanceImplements,
            arguments: [element.displayName],
          );
          return true;
        }
      }
    }

    reporter.atElement2(
      classElement,
      CompileTimeErrorCode.recursiveInterfaceInheritance,
      arguments: [
        element.displayName,
        cycle.map((e) => e.displayName).join(', '),
      ],
    );
    return true;
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
            CompileTimeErrorCode.illegalConcreteEnumMemberDeclaration,
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
    if (classElement is MixinElementImpl) {
      return;
    }

    if (implementsDartCoreEnum) {
      void checkSingle(
        String memberName,
        bool Function(ClassElement enclosingClass) filter,
      ) {
        var member = classElement.getInheritedConcreteMember(
          Name(libraryUri, memberName),
        );
        if (member != null) {
          var enclosingClass = member.enclosingElement;
          if (enclosingClass != null) {
            if (enclosingClass is! ClassElement || filter(enclosingClass)) {
              reporter.atToken(
                classNameToken,
                CompileTimeErrorCode.illegalConcreteEnumMemberInheritance,
                arguments: [memberName, enclosingClass.name!],
              );
            }
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
      reporter.atToken(name, CompileTimeErrorCode.illegalEnumValuesDeclaration);
    }
  }

  void _checkIllegalEnumValuesInheritance() {
    if (implementsDartCoreEnum) {
      var getter = inheritance.getInherited(
        classElement,
        Name(libraryUri, 'values'),
      );
      var setter = inheritance.getInherited(
        classElement,
        Name(libraryUri, 'values='),
      );
      var inherited = getter ?? setter;
      if (inherited != null) {
        reporter.atToken(
          classNameToken,
          CompileTimeErrorCode.illegalEnumValuesInheritance,
          arguments: [inherited.enclosingElement!.name!],
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
      CompileTimeErrorCode.enumMixinWithInstanceVariable,
    );
    return true;
  }

  /// If [name] is not implemented in the extended concrete class, the
  /// issue should be fixed there, and then [classElement] will not have it too.
  bool _isNotImplementedInConcreteSuperClass(Name name) {
    var superElement = classElement.supertype?.element;
    if (superElement is ClassElementImpl && !superElement.isAbstract) {
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
      ClassMember member,
      String memberName,
      String displayName,
    ) {
      if (memberName == name) {
        reporter.atNode(
          member,
          classElement is EnumElement
              ? CompileTimeErrorCode.enumWithAbstractMember
              : CompileTimeErrorCode.concreteClassWithAbstractMember,
          arguments: [displayName, classElement.name ?? ''],
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
        CompileTimeErrorCode.inconsistentInheritanceGetterAndMethod,
        arguments: [
          name.name,
          conflict.getter.enclosingElement!.name!,
          conflict.method.enclosingElement!.name!,
        ],
      );
    } else if (conflict is CandidatesConflict) {
      var candidatesStr = conflict.candidates
          .map((candidate) {
            var className = candidate.enclosingElement!.name;
            var typeStr = candidate.type.getDisplayString();
            return '$className.${name.name} ($typeStr)';
          })
          .join(', ');

      reporter.atToken(
        token,
        CompileTimeErrorCode.inconsistentInheritance,
        arguments: [name.name, candidatesStr],
      );
    } else {
      throw StateError('${conflict.runtimeType}');
    }
  }

  void _reportInheritedAbstractMembers(
    List<InternalExecutableElement>? elements,
  ) {
    if (elements == null) {
      return;
    }

    _missingOverrides[classNameToken] = elements;

    var descriptions = <String>[];
    for (var element in elements) {
      var prefix = switch (element) {
        GetterElement() => 'getter ',
        SetterElement() => 'setter ',
        _ => '',
      };

      var elementName = element.displayName;
      var enclosingElement = element.enclosingElement!;
      var enclosingName = enclosingElement.displayString();
      var description = "$prefix$enclosingName.$elementName";

      descriptions.add(description);
    }
    descriptions.sort();

    if (descriptions.length == 1) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberOne,
        arguments: [descriptions[0]],
      );
    } else if (descriptions.length == 2) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberTwo,
        arguments: [descriptions[0], descriptions[1]],
      );
    } else if (descriptions.length == 3) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberThree,
        arguments: [descriptions[0], descriptions[1], descriptions[2]],
      );
    } else if (descriptions.length == 4) {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberFour,
        arguments: [
          descriptions[0],
          descriptions[1],
          descriptions[2],
          descriptions[3],
        ],
      );
    } else {
      reporter.atToken(
        classNameToken,
        CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberFivePlus,
        arguments: [
          descriptions[0],
          descriptions[1],
          descriptions[2],
          descriptions[3],
          descriptions.length - 4,
        ],
      );
    }
  }

  bool _reportNoCombinedSuperSignature(MethodDeclarationImpl node) {
    var fragment = node.declaredFragment;
    if (fragment is MethodFragmentImpl) {
      var inferenceError = fragment.element.typeInferenceError;
      if (inferenceError?.kind ==
          TopLevelInferenceErrorKind.overrideNoCombinedSuperSignature) {
        reporter.atToken(
          node.name,
          CompileTimeErrorCode.noCombinedSuperSignature,
          arguments: [classElement.name ?? '', inferenceError!.arguments[0]],
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
    if (classElement is! ClassElementImpl ||
        classElement.isAbstract ||
        classElement.isSealed) {
      // We only care about concrete classes.
      return;
    }

    var noSuchMethodDeclaration = classElement.getMethod(
      MethodElement.NO_SUCH_METHOD_METHOD_NAME,
    );
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
        if (method.metadata.hasMustBeOverridden) {
          var methodDeclaration = classElement.getMethod(method.name!);
          if (methodDeclaration == null || methodDeclaration.isAbstract) {
            notOverridden.add(method.baseElement);
          }
        }
      }
      for (var getter in supertype.getters) {
        if (getter.isPrivate && getter.library != classElement.library) {
          continue;
        }
        if (getter.isStatic) {
          continue;
        }
        if (getter.metadata.hasMustBeOverridden ||
            (getter.variable.metadata.hasMustBeOverridden)) {
          var declaration = classElement.getGetter(getter.name!);
          if (declaration == null || declaration.isAbstract) {
            notOverridden.add(getter);
          }
        }
      }
      for (var setter in supertype.setters) {
        if (setter.isPrivate && setter.library != classElement.library) {
          continue;
        }
        if (setter.isStatic) {
          continue;
        }
        if (setter.metadata.hasMustBeOverridden ||
            (setter.variable.metadata.hasMustBeOverridden)) {
          var declaration = classElement.getSetter(setter.name!);
          if (declaration == null || declaration.isAbstract) {
            notOverridden.add(setter);
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
          var name = e.name!;
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
        WarningCode.missingOverrideOfMustBeOverriddenOne,
        arguments: namesForError,
      );
    } else if (namesForError.length == 2) {
      reporter.atToken(
        classNameToken,
        WarningCode.missingOverrideOfMustBeOverriddenTwo,
        arguments: namesForError,
      );
    } else {
      reporter.atToken(
        classNameToken,
        WarningCode.missingOverrideOfMustBeOverriddenThreePlus,
        arguments: [
          namesForError[0],
          namesForError[1],
          (namesForError.length - 2).toString(),
        ],
      );
    }
  }
}
