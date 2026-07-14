// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/correct_override.dart';
import 'package:analyzer/src/error/getter_setter_types_verifier.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

final _missingMustBeOverridden = Expando<List<ExecutableElement>>();
final _missingOverrides = Expando<List<InternalExecutableElement>>();

typedef DisallowedClassDiagnosticCode =
    DiagnosticWithArguments<
      LocatableDiagnostic Function({required DartType disallowedType})
    >;

class InheritanceOverrideVerifier {
  final TypeSystemImpl _typeSystem;
  final TypeProvider _typeProvider;
  final InheritanceManager3 _inheritance;

  final Map<InterfaceElementImpl, _InterfaceElementState>
  _interfaceElementStates = {};
  final Map<LibraryFragmentImpl, DiagnosticReporter>
  _diagnosticReportersByFragment;

  InheritanceOverrideVerifier(
    this._typeSystem,
    this._inheritance, {
    required Map<LibraryFragmentImpl, DiagnosticReporter>
    diagnosticReportersByFragment,
  }) : _typeProvider = _typeSystem.typeProvider,
       _diagnosticReportersByFragment = diagnosticReportersByFragment;

  void verifyUnit(CompilationUnitImpl unit, DiagnosticReporter reporter) {
    var library = unit.declaredFragment!.element;

    _InterfaceElementState interfaceElementState(InterfaceElementImpl element) {
      return _interfaceElementStates[element] ??= _InterfaceElementState();
    }

    for (var declaration in unit.declarations) {
      _ClassVerifier verifier;
      if (declaration is ClassDeclarationImpl) {
        var fragment = declaration.declaredFragment!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: reporter,
          featureSet: unit.featureSet,
          library: library,
          node: declaration,
          classNameToken: declaration.namePart.typeName,
          classElement: fragment.element,
          classFragment: fragment,
          diagnosticSource: unit.declaredFragment!.source,
          implementsClause: declaration.implementsClause,
          members: declaration.body.members,
          primaryConstructor: declaration.namePart.tryCast(),
          superclass: declaration.extendsClause?.superclass,
          withClause: declaration.withClause,
          interfaceElementState: interfaceElementState(fragment.element),
          reportInterfaceConflicts: _reportInterfaceConflicts,
          targetForElement: _targetForElement,
        );
      } else if (declaration is ClassTypeAliasImpl) {
        var fragment = declaration.declaredFragment!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: reporter,
          featureSet: unit.featureSet,
          library: library,
          node: declaration,
          classNameToken: declaration.name,
          classElement: fragment.element,
          classFragment: fragment,
          diagnosticSource: unit.declaredFragment!.source,
          implementsClause: declaration.implementsClause,
          superclass: declaration.superclass,
          withClause: declaration.withClause,
          interfaceElementState: interfaceElementState(fragment.element),
          reportInterfaceConflicts: _reportInterfaceConflicts,
          targetForElement: _targetForElement,
        );
      } else if (declaration is EnumDeclarationImpl) {
        var fragment = declaration.declaredFragment!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: reporter,
          featureSet: unit.featureSet,
          library: library,
          node: declaration,
          classNameToken: declaration.namePart.typeName,
          classElement: fragment.element,
          classFragment: fragment,
          diagnosticSource: unit.declaredFragment!.source,
          implementsClause: declaration.implementsClause,
          members: declaration.body.members,
          primaryConstructor: declaration.namePart.tryCast(),
          withClause: declaration.withClause,
          interfaceElementState: interfaceElementState(fragment.element),
          reportInterfaceConflicts: _reportInterfaceConflicts,
          targetForElement: _targetForElement,
        );
      } else if (declaration is MixinDeclarationImpl) {
        var fragment = declaration.declaredFragment!;
        verifier = _ClassVerifier(
          typeSystem: _typeSystem,
          typeProvider: _typeProvider,
          inheritance: _inheritance,
          reporter: reporter,
          featureSet: unit.featureSet,
          library: library,
          node: declaration,
          classNameToken: declaration.name,
          classElement: fragment.element,
          classFragment: fragment,
          diagnosticSource: unit.declaredFragment!.source,
          implementsClause: declaration.implementsClause,
          members: declaration.body.members,
          onClause: declaration.onClause,
          interfaceElementState: interfaceElementState(fragment.element),
          reportInterfaceConflicts: _reportInterfaceConflicts,
          targetForElement: _targetForElement,
        );
      } else {
        continue;
      }

      if (verifier.verify()) {
        continue;
      }

      verifier._verifyMustBeOverridden();
    }
  }

  void _reportInterfaceConflicts(
    InterfaceElementImpl element,
    Interface interface,
  ) {
    for (var conflict in interface.conflicts) {
      var interfaceTarget = _targetForElement(element);
      if (interfaceTarget == null) {
        continue;
      }

      var memberName = conflict.name.name;
      switch (conflict) {
        case GetterMethodConflict():
          var target = interfaceTarget;

          // Try to use a local declaration related to the conflict.
          if (interface.declared[conflict.name] case var declared?) {
            target = _targetForElement(declared) ?? target;
          }

          target.report(
            diag.inconsistentInheritanceGetterAndMethod.withArguments(
              memberName: memberName,
              getterInterface: conflict.getter.enclosingElement.name!,
              methodInterface: conflict.method.enclosingElement!.name!,
            ),
          );
        case CandidatesConflict():
          var inheritedSignatures = conflict.candidates
              .map((candidate) {
                var className = candidate.enclosingElement!.name;
                var typeStr = candidate.type.getDisplayString();
                return '$className.$memberName ($typeStr)';
              })
              .join(', ');
          interfaceTarget.report(
            diag.inconsistentInheritance.withArguments(
              name: memberName,
              inheritedSignatures: inheritedSignatures,
            ),
          );
        default:
          throw StateError('${conflict.runtimeType}');
      }
    }
  }

  _DiagnosticTarget? _targetForElement(Element element) {
    var nonSynthetic = element.nonSynthetic;
    if (nonSynthetic is! ElementImpl) {
      return null;
    }
    return _targetForFragment(nonSynthetic.firstFragment);
  }

  _DiagnosticTarget? _targetForFragment(FragmentImpl fragment) {
    var libraryFragment = fragment.libraryFragment;
    if (libraryFragment == null) {
      return null;
    }

    var reporter = _diagnosticReportersByFragment[libraryFragment];
    if (reporter == null) {
      return null;
    }

    var offset = fragment.nameOffset;
    var length = fragment.name?.length;
    if (offset == null || length == null) {
      return null;
    }

    return _DiagnosticTarget(
      reporter: reporter,
      offset: offset,
      length: length,
    );
  }

  /// Returns [ExecutableElement] members that are in the interface of the
  /// given class with `@mustBeOverridden`, but don't have implementations.
  static List<ExecutableElement> missingMustBeOverridden(
    CompilationUnitMember node,
  ) {
    return _missingMustBeOverridden[node] ?? const [];
  }

  /// Returns [ExecutableElement] members that are in the interface of the
  /// given class, but don't have concrete implementations.
  static List<ExecutableElement> missingOverrides(CompilationUnitMember node) {
    return _missingOverrides[node] ?? const [];
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
  final InterfaceFragmentImpl classFragment;

  final CompilationUnitMember node;
  final Token classNameToken;
  final List<ClassMember> members;
  final ImplementsClause? implementsClause;
  final MixinOnClause? onClause;
  final PrimaryConstructorDeclarationImpl? primaryConstructor;
  final NamedType? superclass;
  final WithClause? withClause;
  final _InterfaceElementState interfaceElementState;
  final void Function(InterfaceElementImpl element, Interface interface)
  reportInterfaceConflicts;
  final _DiagnosticTarget? Function(Element element) targetForElement;

  final List<InterfaceType> directSuperInterfaces = [];

  /// The source file for which diagnostics are being generated.
  final Source diagnosticSource;

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
    required this.node,
    required this.classNameToken,
    required this.classElement,
    required this.classFragment,
    required this.diagnosticSource,
    this.implementsClause,
    this.members = const [],
    this.onClause,
    this.primaryConstructor,
    this.superclass,
    this.withClause,
    required this.interfaceElementState,
    required this.reportInterfaceConflicts,
    required this.targetForElement,
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
      reporter.report(
        diag.concreteClassHasEnumSuperinterface.at(classNameToken),
      );
      return true;
    }

    if (_checkForRecursiveInterfaceInheritance(element)) {
      return true;
    }

    // Compute the interface of the class.
    var interface = inheritance.getInterface(element);

    if (identical(classFragment, element.firstFragment)) {
      reportInterfaceConflicts(element, interface);
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
    var mixinNodes = withClause?.mixinTypes ?? <NamedType>[];
    var mixinIndex = classFragment.withClauseMixinStartIndex;
    for (var mixinNode in mixinNodes) {
      var mixinType = mixinNode.type;
      // When building the element model, we skip incorrect types.
      // So, here we skip corresponding nodes to keep the index in sync.
      if (mixinType is InterfaceTypeImpl &&
          isInterfaceTypeInterface(mixinType)) {
        _checkDeclaredMembers(mixinNode, mixinType, mixinIndex: mixinIndex++);
        directSuperInterfaces.add(mixinType);
      }
    }

    directSuperInterfaces.addAll(element.interfaces);

    _checkDeclaringFormalParameterFields();

    // Check the members of the class itself, against all the previously
    // collected superinterfaces of the supertype, mixins, and interfaces.
    for (var member in members) {
      if (member is FieldDeclarationImpl) {
        var fieldList = member.fields;
        for (var field in fieldList.variables) {
          var fieldFragment = field.declaredFragment! as FieldFragmentImpl;
          _checkDeclaredField(field.name, fieldFragment.element);
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
          member.declaredFragment!.element,
          methodParameterNodes: member.parameters?.parameters,
        );
        if (!(member.isStatic || !member.isComplete || member.isSetter)) {
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
      diagnosticSource: diagnosticSource,
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
          if (interfaceElement
              .baseElement
              .isAugmentationWithoutAugmentedDeclaration) {
            continue;
          }
          if (_reportConcreteClassWithAbstractMember(name.name)) {
            continue;
          }
          if (interfaceElement.enclosingElement == classElement) {
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
              ? diag.invalidImplementationOverrideSetter
              : diag.invalidImplementationOverride,
        );
      }

      if (identical(classFragment, element.firstFragment)) {
        _reportInheritedAbstractMembers(inheritedAbstract);
      }
    }

    return false;
  }

  void _checkDeclaredField(Token name, FieldElementImpl field) {
    _checkDeclaredMember(name, libraryUri, field.getter);
    _checkDeclaredMember(name, libraryUri, field.setter);
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
            ? diag.invalidOverrideSetter
            : diag.invalidOverride,
      );
    }

    if (mixinIndex == -1) {
      CovariantParametersVerifier(
        thisMember: member,
      ).verify(diagnosticReporter: reporter, errorEntity: node);
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

  void _checkDeclaringFormalParameterFields() {
    var primaryConstructor = this.primaryConstructor;
    if (primaryConstructor == null) return;

    for (var formalParameter
        in primaryConstructor.formalParameters.parameters) {
      var formalParameterElement = formalParameter.declaredFragment?.element;
      if (formalParameterElement is FieldFormalParameterElementImpl &&
          formalParameterElement.isDeclaring) {
        var name = formalParameter.name;
        var field = formalParameterElement.field;
        if (name != null && field != null) {
          _checkDeclaredField(name, field);
        }
      }
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
    DisallowedClassDiagnosticCode diagnosticCode,
  ) {
    if (namedType.isSynthetic) {
      return false;
    }

    var type = namedType.typeOrThrow;
    return _checkDirectSuperType(
      type: type,
      hasEnum: () {
        reporter.report(diag.concreteClassHasEnumSuperinterface.at(namedType));
      },
      notSubtypable: () {
        reporter.report(
          diagnosticCode.withArguments(disallowedType: type).at(namedType),
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
          diag.implementsDisallowedClass,
        )) {
          hasError = true;
        }
      }
    }
    if (onClause != null) {
      for (var namedType in onClause!.superclassConstraints) {
        if (_checkDirectSuperTypeNode(
          namedType,
          diag.mixinSuperClassConstraintDisallowedClass,
        )) {
          hasError = true;
        }
      }
    }
    if (superclass != null) {
      if (_checkDirectSuperTypeNode(superclass!, diag.extendsDisallowedClass)) {
        hasError = true;
      }
    }
    if (withClause != null) {
      for (var namedType in withClause!.mixinTypes) {
        if (_checkDirectSuperTypeNode(namedType, diag.mixinOfDisallowedClass)) {
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
  /// See [diag.recursiveInterfaceInheritance],
  /// [diag.recursiveInterfaceInheritanceExtends],
  /// [diag.recursiveInterfaceInheritanceImplements],
  /// [diag.recursiveInterfaceInheritanceOn],
  /// [diag.recursiveInterfaceInheritanceWith].
  bool _checkForRecursiveInterfaceInheritance(InterfaceElementImpl element) {
    if (interfaceElementState.hasReportedRecursiveInterfaceInheritance) {
      return true;
    }

    var cycle = element.interfaceCycle;
    if (cycle == null) {
      return false;
    }

    if (superclass case var superclass?) {
      if (superclass.element == element) {
        reporter.report(
          diag.recursiveInterfaceInheritanceExtends
              .withArguments(className: element.displayName)
              .at(superclass),
        );
        interfaceElementState.hasReportedRecursiveInterfaceInheritance = true;
        return true;
      }
    }

    if (onClause case var onClause?) {
      for (var typeAnnotation in onClause.superclassConstraints) {
        if (typeAnnotation.element == element) {
          reporter.report(
            diag.recursiveInterfaceInheritanceOn
                .withArguments(mixinName: element.displayName)
                .at(typeAnnotation),
          );
          interfaceElementState.hasReportedRecursiveInterfaceInheritance = true;
          return true;
        }
      }
    }

    if (withClause case var withClause?) {
      for (var typeAnnotation in withClause.mixinTypes) {
        if (typeAnnotation.element == element) {
          reporter.report(
            diag.recursiveInterfaceInheritanceWith
                .withArguments(className: element.displayName)
                .at(typeAnnotation),
          );
          interfaceElementState.hasReportedRecursiveInterfaceInheritance = true;
          return true;
        }
      }
    }

    if (implementsClause case var implementsClause?) {
      for (var typeAnnotation in implementsClause.interfaces) {
        if (typeAnnotation.element == element) {
          reporter.report(
            diag.recursiveInterfaceInheritanceImplements
                .withArguments(className: element.displayName)
                .at(typeAnnotation),
          );
          interfaceElementState.hasReportedRecursiveInterfaceInheritance = true;
          return true;
        }
      }
    }

    // Earlier fragments can see cycles from clauses in later augmentations.
    // Wait for those clauses before reporting the generic cycle.
    if (classFragment.nextFragment != null) {
      return true;
    }

    targetForElement(element)?.report(
      diag.recursiveInterfaceInheritance.withArguments(
        className: element.displayName,
        loop: cycle.map((e) => e.displayName).join(', '),
      ),
    );
    interfaceElementState.hasReportedRecursiveInterfaceInheritance = true;
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
          reporter.report(
            diag.illegalConcreteEnumMemberDeclaration
                .withArguments(name: name.lexeme)
                .at(name),
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
              reporter.report(
                diag.illegalConcreteEnumMemberInheritance
                    .withArguments(
                      memberName: memberName,
                      className: enclosingClass.name!,
                    )
                    .at(classNameToken),
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
      reporter.report(diag.illegalEnumValuesDeclaration.at(name));
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
        reporter.report(
          diag.illegalEnumValuesInheritance
              .withArguments(className: inherited.enclosingElement!.name!)
              .at(classNameToken),
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

    if (interfaceElement.fields.every((e) {
      return e.isStatic ||
          e.isOriginGetterSetter ||
          e.isAbstract ||
          e.isExternal;
    })) {
      return false;
    }

    reporter.report(diag.enumMixinWithInstanceVariable.at(namedType));
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
        reporter.report(
          (classElement is EnumElement
                  ? diag.enumWithAbstractMember
                  : diag.concreteClassWithAbstractMember)
              .withArguments(
                methodName: displayName,
                enclosingClass: classElement.name ?? '',
              )
              .at(member),
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

  void _reportInheritedAbstractMembers(
    List<InternalExecutableElement>? elements,
  ) {
    if (elements == null) {
      return;
    }

    _missingOverrides[node] = elements;

    var descriptions = <String>[];
    for (var element in elements) {
      var prefix = switch (element) {
        GetterElement() => 'getter ',
        SetterElement() => 'setter ',
        _ => '',
      };

      var elementName = element.displayName;
      var enclosingElement = element.enclosingElement!;
      var enclosingName = enclosingElement.displayName;
      var description = "$prefix$enclosingName.$elementName";

      descriptions.add(description);
    }
    descriptions.sort();

    if (descriptions.length == 1) {
      reporter.report(
        diag.nonAbstractClassInheritsAbstractMemberOne
            .withArguments(name: descriptions[0])
            .at(classNameToken),
      );
    } else if (descriptions.length == 2) {
      reporter.report(
        diag.nonAbstractClassInheritsAbstractMemberTwo
            .withArguments(name1: descriptions[0], name2: descriptions[1])
            .at(classNameToken),
      );
    } else if (descriptions.length == 3) {
      reporter.report(
        diag.nonAbstractClassInheritsAbstractMemberThree
            .withArguments(
              name1: descriptions[0],
              name2: descriptions[1],
              name3: descriptions[2],
            )
            .at(classNameToken),
      );
    } else if (descriptions.length == 4) {
      reporter.report(
        diag.nonAbstractClassInheritsAbstractMemberFour
            .withArguments(
              name1: descriptions[0],
              name2: descriptions[1],
              name3: descriptions[2],
              name4: descriptions[3],
            )
            .at(classNameToken),
      );
    } else {
      reporter.report(
        diag.nonAbstractClassInheritsAbstractMemberFivePlus
            .withArguments(
              name1: descriptions[0],
              name2: descriptions[1],
              name3: descriptions[2],
              name4: descriptions[3],
              remainingCount: descriptions.length - 4,
            )
            .at(classNameToken),
      );
    }
  }

  bool _reportNoCombinedSuperSignature(MethodDeclarationImpl node) {
    var fragment = node.declaredFragment;
    if (fragment is MethodFragmentImpl) {
      var inferenceError = fragment.element.typeInferenceError;
      if (inferenceError is TopLevelInferenceErrorNoCombinedSuperSignature) {
        reporter.report(
          diag.noCombinedSuperSignature
              .withArguments(
                className: classElement.name ?? '',
                candidateSignatures: inferenceError.candidateSignatures,
              )
              .at(node.name),
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
          var methodDeclaration = classElement.getMethod(method.lookupName!);
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

    _missingMustBeOverridden[node] = notOverridden.toList();
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

    LocatableDiagnostic locatableDiagnostic;
    switch (namesForError) {
      case [var member]:
        locatableDiagnostic = diag.missingOverrideOfMustBeOverriddenOne
            .withArguments(member: member);
      case [var firstMember, var secondMember]:
        locatableDiagnostic = diag.missingOverrideOfMustBeOverriddenTwo
            .withArguments(
              firstMember: firstMember,
              secondMember: secondMember,
            );
      case [var firstMember, var secondMember, ...var remainingMembers]:
        locatableDiagnostic = diag.missingOverrideOfMustBeOverriddenThreePlus
            .withArguments(
              firstMember: firstMember,
              secondMember: secondMember,
              additionalCount: remainingMembers.length,
            );
      default:
        // Should be unreachable since the above cases cover all possible counts
        // other than zero, and this function has an early exit if
        // `notOverridden.isEmpty`.
        assert(false);
        return;
    }
    reporter.report(locatableDiagnostic.at(classNameToken));
  }
}

class _DiagnosticTarget {
  final DiagnosticReporter reporter;
  final int offset;
  final int length;

  _DiagnosticTarget({
    required this.reporter,
    required this.offset,
    required this.length,
  });

  void report(LocatableDiagnostic diagnostic) {
    reporter.report(diagnostic.atOffset(offset: offset, length: length));
  }
}

/// Maintains an [InterfaceElementImpl]'s mixin index across multiple fragments.
class _InterfaceElementState {
  bool hasReportedRecursiveInterfaceInheritance = false;

  _InterfaceElementState();
}
