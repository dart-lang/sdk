// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/parser/util.dart' as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/non_covariant_type_parameter_position.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/well_bounded.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/const_argument_verifier.dart';
import 'package:analyzer/src/error/constructor_fields_verifier.dart';
import 'package:analyzer/src/error/correct_override.dart';
import 'package:analyzer/src/error/duplicate_definition_verifier.dart';
import 'package:analyzer/src/error/getter_setter_types_verifier.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/error/literal_element_verifier.dart';
import 'package:analyzer/src/error/required_parameters_verifier.dart';
import 'package:analyzer/src/error/return_type_verifier.dart';
import 'package:analyzer/src/error/super_formal_parameters_verifier.dart';
import 'package:analyzer/src/error/type_arguments_verifier.dart';
import 'package:analyzer/src/error/use_result_verifier.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';

/// Check that none of the type [parameters] references itself in its bound.
///
/// See [CompileTimeErrorCode.typeParameterSupertypeOfItsBound].
void checkForTypeParameterBoundRecursion(
  DiagnosticReporter diagnosticReporter,
  List<TypeParameter> parameters,
) {
  Map<TypeParameterElement, TypeParameter>? elementToNode;
  for (var parameter in parameters) {
    if (parameter.bound != null) {
      if (elementToNode == null) {
        elementToNode = {};
        for (var parameter in parameters) {
          elementToNode[parameter.declaredFragment!.element] = parameter;
        }
      }

      TypeParameter? current = parameter;
      for (var step = 0; current != null; step++) {
        var boundNode = current.bound;
        if (boundNode is NamedType) {
          var boundType = boundNode.typeOrThrow;
          boundType = boundType.extensionTypeErasure;
          current = elementToNode[boundType.element];
        } else {
          current = null;
        }
        if (step == parameters.length) {
          var element = parameter.declaredFragment!.element;
          // This error can only occur if there is a bound, so we can safely
          // assume `element.bound` is non-`null`.
          diagnosticReporter.atToken(
            parameter.name,
            CompileTimeErrorCode.typeParameterSupertypeOfItsBound,
            arguments: [element.displayName, element.bound!],
          );
          break;
        }
      }
    }
  }
}

class EnclosingExecutableContext {
  final InternalExecutableElement? element;
  final bool isAsynchronous;
  final bool isConstConstructor;
  final bool isGenerativeConstructor;
  final bool isGenerator;
  final bool inFactoryConstructor;
  final bool inStaticMethod;

  /// If this [EnclosingExecutableContext] is the first argument in a method
  /// invocation of [Future.catchError], returns the return type expected for
  /// `Future<T>.catchError`'s `onError` parameter, which is `FutureOr<T>`,
  /// otherwise `null`.
  final InterfaceTypeImpl? catchErrorOnErrorReturnType;

  /// The return statements that have a value.
  final List<ReturnStatement> _returnsWith = [];

  /// The return statements that do not have a value.
  final List<ReturnStatement> _returnsWithout = [];

  /// This flag is set to `false` when the declared return type is not legal
  /// for the kind of the function body, e.g. not `Future` for `async`.
  bool hasLegalReturnType = true;

  /// The number of enclosing [CatchClause] in this executable.
  int catchClauseLevel = 0;

  EnclosingExecutableContext(
    this.element, {
    required this.isAsynchronous,
    required this.isGenerator,
    this.catchErrorOnErrorReturnType,
  }) : isConstConstructor =
           element is InternalConstructorElement && element.isConst,
       isGenerativeConstructor =
           element is InternalConstructorElement && !element.isFactory,
       inFactoryConstructor = _inFactoryConstructor(element),
       inStaticMethod = _inStaticMethod(element);

  EnclosingExecutableContext.empty()
    : this(null, isAsynchronous: false, isGenerator: false);

  String? get displayName {
    return element?.displayName;
  }

  bool get isClosure => switch (element) {
    LocalFunctionElement(:var name) => name == null,
    _ => false,
  };

  bool get isConstructor => element is ConstructorElement;

  bool get isFunction => switch (element) {
    LocalFunctionElement(:var displayName) => displayName.isNotEmpty,
    TopLevelFunctionElement(:var displayName) => displayName.isNotEmpty,
    PropertyAccessorElement() => true,
    _ => false,
  };

  bool get isMethod => element is MethodElement;

  bool get isSynchronous => !isAsynchronous;

  TypeImpl get returnType {
    return catchErrorOnErrorReturnType ?? element!.returnType;
  }

  static bool _inFactoryConstructor(Element? element) {
    var enclosing = element?.firstFragment.enclosingFragment;
    if (enclosing == null) {
      return false;
    }
    if (element is ConstructorElement) {
      return element.isFactory;
    }
    return _inFactoryConstructor(enclosing.element);
  }

  static bool _inStaticMethod(Element? element) {
    var enclosing = element?.firstFragment.enclosingFragment;
    if (enclosing == null) {
      return false;
    }
    if (enclosing is InterfaceFragment || enclosing is ExtensionFragment) {
      if (element is ExecutableElement) {
        return element.isStatic;
      }
    }
    return _inStaticMethod(enclosing.element);
  }
}

/// A visitor used to traverse an AST structure looking for additional errors
/// and warnings not covered by the parser and resolver.
class ErrorVerifier extends RecursiveAstVisitor<void>
    with ErrorDetectionHelpers {
  /// The factory used to create diagnostic messages.
  static final _diagnosticFactory = DiagnosticFactory();

  /// The error reporter by which errors will be reported.
  @override
  final DiagnosticReporter diagnosticReporter;

  /// The current library that is being analyzed.
  final LibraryElementImpl _currentLibrary;

  /// The current unit that is being analyzed.
  final LibraryFragmentImpl _currentUnit;

  /// The type representing the type 'int'.
  late final InterfaceTypeImpl _intType;

  /// The options for verification.
  final AnalysisOptions options;

  /// The object providing access to the types defined by the language.
  final TypeProviderImpl _typeProvider;

  /// The type system primitives
  @override
  late final TypeSystemImpl typeSystem;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 _inheritanceManager;

  /// A flag indicating whether the visitor is currently within a comment.
  bool _isInComment = false;

  /// The stack of flags, where `true` at the top (last) of the stack indicates
  /// that the visitor is in the initializer of a lazy local variable. When the
  /// top is `false`, we might be not in a local variable, or it is not `lazy`,
  /// etc.
  final List<bool> _isInLateLocalVariable = [false];

  /// A flag indicating whether the visitor is currently within a native class
  /// declaration.
  bool _isInNativeClass = false;

  /// A flag indicating whether the visitor is currently within a static
  /// variable declaration.
  bool _isInStaticVariableDeclaration = false;

  /// A flag indicating whether the visitor is currently within an instance
  /// variable declaration, which is not `late`.
  bool _isInInstanceNotLateVariableDeclaration = false;

  /// A flag indicating whether the visitor is currently within a constructor
  /// initializer.
  bool _isInConstructorInitializer = false;

  /// This is set to `true` iff the visitor is currently within a function typed
  /// formal parameter.
  bool _isInFunctionTypedFormalParameter = false;

  /// A flag indicating whether the visitor is currently within code in the SDK.
  bool _isInSystemLibrary = false;

  /// The class containing the AST nodes being visited, or `null` if we are not
  /// in the scope of a class.
  InterfaceElementImpl? _enclosingClass;

  /// The element of the extension being visited, or `null` if we are not
  /// in the scope of an extension.
  ExtensionElement? _enclosingExtension;

  /// Whether the current location has access to `this`.
  bool _hasAccessToThis = false;

  /// The context of the method or function that we are currently visiting, or
  /// `null` if we are not inside a method or function.
  EnclosingExecutableContext _enclosingExecutable =
      EnclosingExecutableContext.empty();

  /// A set of the names of the variable initializers we are visiting now.
  final HashSet<String> _namesForReferenceToDeclaredVariableInInitializer =
      HashSet<String>();

  /// The elements that will be defined later in the current scope, but right
  /// now are not declared.
  HiddenElements? _hiddenElements;

  final _UninstantiatedBoundChecker _uninstantiatedBoundChecker;

  /// The features enabled in the unit currently being checked for errors.
  FeatureSet? _featureSet;

  final LibraryVerificationContext libraryContext;
  final RequiredParametersVerifier _requiredParametersVerifier;
  final ConstArgumentsVerifier _constArgumentsVerifier;
  final DuplicateDefinitionVerifier _duplicateDefinitionVerifier;
  final UseResultVerifier _checkUseVerifier;
  late final TypeArgumentsVerifier _typeArgumentsVerifier;
  late final ReturnTypeVerifier _returnTypeVerifier;
  final TypeSystemOperations typeSystemOperations;

  /// Initialize a newly created error verifier.
  ErrorVerifier(
    this.diagnosticReporter,
    this._currentLibrary,
    this._currentUnit,
    this._typeProvider,
    this._inheritanceManager,
    this.libraryContext,
    this.options, {
    required this.typeSystemOperations,
  }) : _uninstantiatedBoundChecker = _UninstantiatedBoundChecker(
         diagnosticReporter,
       ),
       _checkUseVerifier = UseResultVerifier(diagnosticReporter),
       _requiredParametersVerifier = RequiredParametersVerifier(
         diagnosticReporter,
       ),
       _constArgumentsVerifier = ConstArgumentsVerifier(diagnosticReporter),
       _duplicateDefinitionVerifier = DuplicateDefinitionVerifier(
         _currentLibrary,
         diagnosticReporter,
         libraryContext.duplicationDefinitionContext,
       ) {
    _isInSystemLibrary = _currentLibrary.uri.isScheme('dart');
    _isInStaticVariableDeclaration = false;
    _isInConstructorInitializer = false;
    _intType = _typeProvider.intType;
    typeSystem = _currentLibrary.typeSystem;
    _typeArgumentsVerifier = TypeArgumentsVerifier(
      options,
      _currentLibrary,
      diagnosticReporter,
    );
    _returnTypeVerifier = ReturnTypeVerifier(
      typeProvider: _typeProvider,
      typeSystem: typeSystem,
      diagnosticReporter: diagnosticReporter,
      strictCasts: strictCasts,
    );
  }

  @override
  InheritanceManager3 get inheritance => _inheritanceManager;

  @override
  bool get strictCasts => options.strictCasts;

  /// The language team is thinking about adding abstract fields, or external
  /// fields. But for now we will ignore such fields in `Struct` subtypes.
  bool get _isEnclosingClassFfiStruct {
    var superClass = _enclosingClass?.supertype?.element;
    return superClass != null &&
        _isDartFfiLibrary(superClass.library) &&
        superClass.name == 'Struct';
  }

  /// The language team is thinking about adding abstract fields, or external
  /// fields. But for now we will ignore such fields in `Struct` subtypes.
  bool get _isEnclosingClassFfiUnion {
    var superClass = _enclosingClass?.supertype?.element;
    return superClass != null &&
        _isDartFfiLibrary(superClass.library) &&
        superClass.name == 'Union';
  }

  @override
  List<DiagnosticMessage> computeWhyNotPromotedMessages(
    SyntacticEntity errorEntity,
    Map<SharedTypeView, NonPromotionReason>? whyNotPromoted,
  ) {
    return [];
  }

  @override
  void visitAnnotation(Annotation node) {
    _checkForInvalidAnnotationFromDeferredLibrary(node);
    _requiredParametersVerifier.visitAnnotation(node);
    super.visitAnnotation(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _isInConstructorInitializer = true;
    try {
      super.visitAssertInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitAssignmentExpression(covariant AssignmentExpressionImpl node) {
    TokenType operatorType = node.operator.type;
    Expression lhs = node.leftHandSide;
    if (operatorType == TokenType.QUESTION_QUESTION_EQ) {
      _checkForDeadNullCoalesce(node.readType!, node.rightHandSide);
    }
    _checkForAssignmentToFinal(lhs);

    _constArgumentsVerifier.visitAssignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (!_enclosingExecutable.isAsynchronous) {
      diagnosticReporter.atToken(
        node.awaitKeyword,
        CompileTimeErrorCode.awaitInWrongContext,
      );
    }
    checkForUseOfVoidResult(node.expression);
    _checkForAwaitInLateLocalVariableInitializer(node);
    _checkForAwaitOfIncompatibleType(node);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(covariant BinaryExpressionImpl node) {
    Token operator = node.operator;
    TokenType type = operator.type;
    if (type == TokenType.AMPERSAND_AMPERSAND || type == TokenType.BAR_BAR) {
      checkForUseOfVoidResult(node.rightOperand);
    } else {
      // Assignability checking is done by the resolver.
    }

    if (type == TokenType.QUESTION_QUESTION) {
      _checkForDeadNullCoalesce(
        node.leftOperand.staticType!,
        node.rightOperand,
      );
    }

    checkForUseOfVoidResult(node.leftOperand);
    _constArgumentsVerifier.visitBinaryExpression(node);

    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(covariant BlockImpl node) {
    _withHiddenElements(node.statements, () {
      _duplicateDefinitionVerifier.checkStatements(node.statements);
      super.visitBlock(node);
    });
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    var oldHasAccessToThis = _hasAccessToThis;
    try {
      _hasAccessToThis = _computeThisAccessForFunctionBody(node);
      super.visitBlockFunctionBody(node);
    } finally {
      _hasAccessToThis = oldHasAccessToThis;
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    var labelNode = node.label;
    if (labelNode != null) {
      var labelElement = labelNode.element;
      if (labelElement is LabelElementImpl && labelElement.isOnSwitchMember) {
        diagnosticReporter.atNode(
          labelNode,
          CompileTimeErrorCode.breakLabelOnSwitchMember,
        );
      }
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    _duplicateDefinitionVerifier.checkCatchClause(node);
    try {
      _enclosingExecutable.catchClauseLevel++;
      _checkForTypeAnnotationDeferredClass(node.exceptionType);
      super.visitCatchClause(node);
    } finally {
      _enclosingExecutable.catchClauseLevel--;
    }
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    try {
      var declaredFragment = node.declaredFragment!;

      _isInNativeClass = node.nativeClause != null;

      var augmented = declaredFragment.element;
      var declarationElement = augmented.firstFragment;
      _enclosingClass = declarationElement.asElement2;

      List<ClassMember> members = node.members;
      if (!declarationElement.element.isDartCoreFunction) {
        _checkForBuiltInIdentifierAsName(
          node.name,
          CompileTimeErrorCode.builtInIdentifierAsTypeName,
        );
      }
      _checkForConflictingClassTypeVariableErrorCodes();
      var superclass = node.extendsClause?.superclass;
      var implementsClause = node.implementsClause;
      var withClause = node.withClause;

      // Only do error checks on the clause nodes if there is a non-null clause
      if (implementsClause != null ||
          superclass != null ||
          withClause != null) {
        var moreChecks = _checkClassInheritance(
          declarationElement,
          node,
          superclass,
          withClause,
          implementsClause,
        );
        if (moreChecks) {
          _checkForNoDefaultSuperConstructorImplicit(declaredFragment);
        }
      }

      if (node.nativeClause == null) {
        libraryContext.constructorFieldsVerifier.addConstructors(
          diagnosticReporter,
          augmented,
          members,
        );
      }

      _checkForConflictingClassMembers(declaredFragment);
      _checkForFinalNotInitializedInClass(declaredFragment, members);
      _checkForBadFunctionUse(
        superclass: node.extendsClause?.superclass,
        withClause: node.withClause,
        implementsClause: node.implementsClause,
      );
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
      _checkForMainFunction1(node.name, node.declaredFragment!);
      _checkForMixinClassErrorCodes(node, members, superclass, withClause);

      GetterSetterTypesVerifier(
        library: _currentLibrary,
        diagnosticReporter: diagnosticReporter,
      ).checkStaticGetters(augmented.getters);

      super.visitClassDeclaration(node);
    } finally {
      _isInNativeClass = false;
      _enclosingClass = null;
    }
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    var firstFragment = element.firstFragment;

    _checkForBuiltInIdentifierAsName(
      node.name,
      CompileTimeErrorCode.builtInIdentifierAsTypedefName,
    );
    try {
      _enclosingClass = firstFragment.asElement2;
      _checkClassInheritance(
        firstFragment,
        node,
        node.superclass,
        node.withClause,
        node.implementsClause,
      );
      _checkForMainFunction1(node.name, node.declaredFragment!);
      _checkForMixinClassErrorCodes(
        node,
        List.empty(),
        node.superclass,
        node.withClause,
      );
      _checkForBadFunctionUse(
        superclass: node.superclass,
        withClause: node.withClause,
        implementsClause: node.implementsClause,
      );
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
    } finally {
      _enclosingClass = null;
    }
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    _isInComment = true;
    try {
      super.visitComment(node);
    } finally {
      _isInComment = false;
    }
  }

  @override
  void visitCompilationUnit(covariant CompilationUnitImpl node) {
    var fragment = node.declaredFragment!;
    _featureSet = node.featureSet;
    _duplicateDefinitionVerifier.checkUnit(node);
    _checkForDeferredPrefixCollisions(node);
    _checkForIllegalLanguageOverride(node);

    GetterSetterTypesVerifier(
      library: _currentLibrary,
      diagnosticReporter: diagnosticReporter,
    ).checkStaticGetters(fragment.element.getters);

    super.visitCompilationUnit(node);
    _featureSet = null;
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    _withEnclosingExecutable(
      element,
      () {
        _checkForNonConstGenerativeEnumConstructor(node);
        _checkForInvalidModifierOnBody(
          node.body,
          CompileTimeErrorCode.invalidModifierOnConstructor,
        );
        if (!_checkForConstConstructorWithNonConstSuper(node)) {
          _checkForConstConstructorWithNonFinalField(node, element);
        }
        _checkForRedirectingConstructorErrorCodes(node);
        _checkForConflictingInitializerErrorCodes(node);
        _checkForRecursiveConstructorRedirect(node, element);
        if (!_checkForRecursiveFactoryRedirect(node, element)) {
          _checkForAllRedirectConstructorErrorCodes(node);
        }
        _checkForUndefinedConstructorInInitializerImplicit(node);
        _checkForReturnInGenerativeConstructor(node);
        super.visitConstructorDeclaration(node);
      },
      isAsynchronous: fragment.isAsynchronous,
      isGenerator: fragment.isGenerator,
    );
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _isInConstructorInitializer = true;
    try {
      SimpleIdentifier fieldName = node.fieldName;
      var element = fieldName.element;
      _checkForInvalidField(node, fieldName, element);
      if (element is FieldElement) {
        _checkForAbstractOrExternalFieldConstructorInitializer(
          node.fieldName.token,
          element,
        );
      }
      super.visitConstructorFieldInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitConstructorReference(covariant ConstructorReferenceImpl node) {
    _typeArgumentsVerifier.checkConstructorReference(node);
    _checkForInvalidGenerativeConstructorReference(
      node.constructorName,
      node.constructorName.element,
    );
  }

  @override
  void visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      checkForAssignableExpressionAtType(
        defaultValue,
        defaultValue.typeOrThrow,
        node.declaredFragment!.element.type,
        CompileTimeErrorCode.invalidAssignment,
      );
    }

    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    var constructorElement = node.constructorName.element;
    if (constructorElement is ConstructorElement?) {
      if (node.isConst) {
        _checkForConstWithNonConst(node, constructorElement, node.constKeyword);
      }
      _checkForInvalidGenerativeConstructorReference(
        node.constructorName,
        constructorElement,
      );
    }
    _requiredParametersVerifier.visitDotShorthandConstructorInvocation(node);
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    _requiredParametersVerifier.visitDotShorthandInvocation(node);
    super.visitDotShorthandInvocation(node);
  }

  @override
  void visitEnumConstantDeclaration(
    covariant EnumConstantDeclarationImpl node,
  ) {
    _requiredParametersVerifier.visitEnumConstantDeclaration(node);
    _typeArgumentsVerifier.checkEnumConstantDeclaration(node);
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    try {
      var declaredFragment = node.declaredFragment!;
      var declaredElement = declaredFragment.element;
      var firstFragment = declaredElement.firstFragment;

      var element = declaredFragment.element;
      _enclosingClass = element;

      _checkForBuiltInIdentifierAsName(
        node.name,
        CompileTimeErrorCode.builtInIdentifierAsTypeName,
      );
      _checkForConflictingEnumTypeVariableErrorCodes(declaredFragment);
      var implementsClause = node.implementsClause;
      var withClause = node.withClause;

      if (implementsClause != null || withClause != null) {
        _checkClassInheritance(
          firstFragment,
          node,
          null,
          withClause,
          implementsClause,
        );
      }

      if (!declaredFragment.isAugmentation) {
        if (element.constants.isEmpty) {
          diagnosticReporter.atToken(
            node.name,
            CompileTimeErrorCode.enumWithoutConstants,
          );
        }
      }

      var members = node.members;
      libraryContext.constructorFieldsVerifier.addConstructors(
        diagnosticReporter,
        element,
        members,
      );
      _checkForFinalNotInitializedInClass(declaredFragment, members);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
      _checkForMainFunction1(node.name, node.declaredFragment!);
      _checkForEnumInstantiatedToBoundsIsNotWellBounded(node, declaredElement);

      GetterSetterTypesVerifier(
        library: _currentLibrary,
        diagnosticReporter: diagnosticReporter,
      ).checkStaticGetters(declaredElement.getters);

      super.visitEnumDeclaration(node);
    } finally {
      _enclosingClass = null;
    }
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var libraryExport = node.libraryExport;
    if (libraryExport != null) {
      var exportedLibrary = libraryExport.exportedLibrary;
      _checkForAmbiguousExport(node, libraryExport, exportedLibrary);
      _checkForExportInternalLibrary(node, libraryExport);
    }
    _reportForMultipleCombinators(node);
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    var oldHasAccessToThis = _hasAccessToThis;
    try {
      _hasAccessToThis = _computeThisAccessForFunctionBody(node);
      _returnTypeVerifier.verifyExpressionFunctionBody(node);
      super.visitExpressionFunctionBody(node);
    } finally {
      _hasAccessToThis = oldHasAccessToThis;
    }
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var declaredFragment = node.declaredFragment!;
    var declaredElement = declaredFragment.element;

    _enclosingExtension = declaredFragment.asElement2;
    _checkForConflictingExtensionTypeVariableErrorCodes();
    _checkForFinalNotInitializedInClass(declaredFragment, node.members);

    GetterSetterTypesVerifier(
      library: _currentLibrary,
      diagnosticReporter: diagnosticReporter,
    ).checkExtension(declaredElement);

    var name = node.name;
    if (name != null) {
      _checkForBuiltInIdentifierAsName(
        name,
        CompileTimeErrorCode.builtInIdentifierAsExtensionName,
      );
    }
    super.visitExtensionDeclaration(node);
    _enclosingExtension = null;
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    try {
      var declaredFragment = node.declaredFragment!;
      var declaredElement = declaredFragment.element;
      var firstFragment = declaredElement.firstFragment;

      _enclosingClass = firstFragment.asElement2;

      _checkForBuiltInIdentifierAsName(
        node.name,
        CompileTimeErrorCode.builtInIdentifierAsExtensionTypeName,
      );
      _checkForConflictingExtensionTypeTypeVariableErrorCodes(declaredFragment);

      var members = node.members;
      _checkForRepeatedType(
        libraryContext.setOfImplements(firstFragment.asElement2),
        node.implementsClause?.interfaces,
        CompileTimeErrorCode.implementsRepeated,
      );
      _checkForConflictingClassMembers(declaredFragment);
      _checkForConflictingGenerics(node);
      libraryContext.constructorFieldsVerifier.addConstructors(
        diagnosticReporter,
        declaredElement,
        members,
      );
      _checkForNonCovariantTypeParameterPositionInRepresentationType(
        node,
        declaredFragment,
      );
      _checkForExtensionTypeRepresentationDependsOnItself(
        node,
        declaredFragment,
      );
      _checkForExtensionTypeRepresentationTypeBottom(node, declaredFragment);
      _checkForExtensionTypeImplementsDeferred(node);
      _checkForExtensionTypeImplementsItself(node, declaredFragment);
      _checkForExtensionTypeMemberConflicts(
        node: node,
        element: declaredElement,
      );
      _checkForExtensionTypeWithAbstractMember(node);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();

      var interface = _inheritanceManager.getInterface(declaredElement);
      GetterSetterTypesVerifier(
        library: _currentLibrary,
        diagnosticReporter: diagnosticReporter,
      ).checkExtensionType(declaredElement, interface);

      super.visitExtensionTypeDeclaration(node);
    } finally {
      _enclosingClass = null;
    }
  }

  @override
  void visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    var fields = node.fields;
    _isInStaticVariableDeclaration = node.isStatic;
    _isInInstanceNotLateVariableDeclaration =
        !node.isStatic && !node.fields.isLate;
    if (!_isInStaticVariableDeclaration) {
      if (fields.isConst) {
        diagnosticReporter.atToken(
          fields.keyword!,
          CompileTimeErrorCode.constInstanceField,
        );
      }
    }
    var oldHasAccessToThis = _hasAccessToThis;
    try {
      _hasAccessToThis = !node.isStatic && node.fields.isLate;
      _checkForExtensionDeclaresInstanceField(node);
      _checkForExtensionTypeDeclaresInstanceField(node);
      _checkForNotInitializedNonNullableStaticField(node);
      _checkForWrongTypeParameterVarianceInField(node);
      _checkForLateFinalFieldWithConstConstructor(node);
      _checkForNonFinalFieldInEnum(node);

      super.visitFieldDeclaration(node);
    } finally {
      _isInStaticVariableDeclaration = false;
      _isInInstanceNotLateVariableDeclaration = false;
      _hasAccessToThis = oldHasAccessToThis;
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkForValidField(node);
    _checkForPrivateOptionalParameter(node);
    _checkForFieldInitializingFormalRedirectingConstructor(node);
    _checkForTypeAnnotationDeferredClass(node.type);
    var fieldElement = node.declaredFragment?.element.field;
    if (fieldElement != null) {
      _checkForAbstractOrExternalFieldConstructorInitializer(
        node.name,
        fieldElement,
      );
    }
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (_checkForEachParts(node, loopVariable.declaredFragment?.element)) {
      if (loopVariable.isConst) {
        diagnosticReporter.atToken(
          loopVariable.keyword!,
          CompileTimeErrorCode.forInWithConstVariable,
        );
      }
    }
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    SimpleIdentifier identifier = node.identifier;
    if (_checkForEachParts(node, identifier.element)) {
      _checkForAssignmentToFinal(identifier);
    }
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitFormalParameterList(covariant FormalParameterListImpl node) {
    _duplicateDefinitionVerifier.checkParameters(node);
    _checkUseOfCovariantInParameters(node);
    _checkUseOfDefaultValuesInParameters(node);
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(
    covariant ForPartsWithDeclarationsImpl node,
  ) {
    _duplicateDefinitionVerifier.checkForVariables(node.variables);
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    if (element.enclosingElement is! LibraryElement) {
      _hiddenElements!.declare(element);
    }

    _withEnclosingExecutable(
      element,
      () {
        TypeAnnotation? returnType = node.returnType;
        if (node.isSetter) {
          _checkForNonVoidReturnTypeForSetter(returnType);
        }
        _checkForTypeAnnotationDeferredClass(returnType);
        _returnTypeVerifier.verifyReturnType(returnType);
        _checkForMainFunction1(node.name, fragment);
        _checkForMainFunction2(node);
        super.visitFunctionDeclaration(node);
      },
      isAsynchronous: fragment.isAsynchronous,
      isGenerator: fragment.isGenerator,
    );
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node) {
    _isInLateLocalVariable.add(false);

    if (node.parent is FunctionDeclarationImpl) {
      super.visitFunctionExpression(node);
    } else {
      var fragment = node.declaredFragment!;
      _withEnclosingExecutable(
        fragment.element,
        () {
          super.visitFunctionExpression(node);
        },
        isAsynchronous: fragment.isAsynchronous,
        isGenerator: fragment.isGenerator,
      );
    }

    _isInLateLocalVariable.removeLast();
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var functionExpression = node.function;

    if (functionExpression is ExtensionOverride) {
      return super.visitFunctionExpressionInvocation(node);
    }

    _typeArgumentsVerifier.checkFunctionExpressionInvocation(node);
    _requiredParametersVerifier.visitFunctionExpressionInvocation(node);
    _constArgumentsVerifier.visitFunctionExpressionInvocation(node);
    _checkUseVerifier.checkFunctionExpressionInvocation(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _typeArgumentsVerifier.checkFunctionReference(node);
    super.visitFunctionReference(node);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    _checkForBuiltInIdentifierAsName(
      node.name,
      CompileTimeErrorCode.builtInIdentifierAsTypedefName,
    );
    _checkForMainFunction1(node.name, node.declaredFragment!);
    _checkForTypeAliasCannotReferenceItself(
      node.name,
      node.declaredFragment as TypeAliasFragmentImpl,
    );
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    bool old = _isInFunctionTypedFormalParameter;
    _isInFunctionTypedFormalParameter = true;
    try {
      _checkForTypeAnnotationDeferredClass(node.returnType);

      super.visitFunctionTypedFormalParameter(node);
    } finally {
      _isInFunctionTypedFormalParameter = old;
    }
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var fragment = node.declaredFragment!;

    _checkForBuiltInIdentifierAsName(
      node.name,
      CompileTimeErrorCode.builtInIdentifierAsTypedefName,
    );
    _checkForMainFunction1(node.name, node.declaredFragment!);
    _checkForTypeAliasCannotReferenceItself(node.name, fragment);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitGuardedPattern(covariant GuardedPatternImpl node) {
    _withHiddenElementsGuardedPattern(node, () {
      node.pattern.accept(this);
    });
    node.whenClause?.accept(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var importElement = node.libraryImport;
    if (node.prefix != null) {
      _checkForBuiltInIdentifierAsName(
        node.prefix!.token,
        CompileTimeErrorCode.builtInIdentifierAsPrefixName,
      );
    }
    if (importElement != null) {
      _checkForImportInternalLibrary(node, importElement);
      if (importElement.prefix?.isDeferred ?? false) {
        _checkForDeferredImportOfExtensions(node, importElement);
      }
    }

    _reportForMultipleCombinators(node);
    super.visitImportDirective(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _checkForReferenceBeforeDeclaration(
      nameToken: node.name,
      element: node.element,
    );
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.isNullAware) {
      _checkForUnnecessaryNullAware(
        node.realTarget,
        node.question ?? node.period ?? node.leftBracket,
      );
    }

    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    NamedType namedType = constructorName.type;
    DartType type = namedType.typeOrThrow;
    if (type is InterfaceType) {
      _checkForConstOrNewWithAbstractClass(node, namedType, type);
      _checkForInvalidGenerativeConstructorReference(
        constructorName,
        constructorName.element,
      );
      _checkForConstOrNewWithMixin(node, namedType, type);
      _requiredParametersVerifier.visitInstanceCreationExpression(node);
      _constArgumentsVerifier.visitInstanceCreationExpression(node);
      _checkUseVerifier.checkInstanceCreationExpression(node);
      if (node.isConst) {
        _checkForConstWithNonConst(
          node,
          node.constructorName.element,
          node.keyword,
        );
        _checkForConstWithUndefinedConstructor(
          node,
          constructorName,
          namedType,
        );
        _checkForConstDeferredClass(node, constructorName, namedType);
      } else {
        _checkForNewWithUndefinedConstructor(node, constructorName, namedType);
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(covariant IntegerLiteralImpl node) {
    _checkForOutOfRange(node);
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    checkForUseOfVoidResult(node.expression);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    checkForUseOfVoidResult(node.expression);
    super.visitIsExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _typeArgumentsVerifier.checkListLiteral(node);
    _checkForListElementTypeNotAssignable(node);

    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    if (node.keyQuestion != null) {
      _checkForUnnecessaryNullAware(
        node.key,
        node.keyQuestion!,
        nullAwareElementOrMapEntryKind:
            _NullAwareElementOrMapEntryKind.mapEntryKey,
      );
    }
    if (node.valueQuestion != null) {
      _checkForUnnecessaryNullAware(
        node.value,
        node.valueQuestion!,
        nullAwareElementOrMapEntryKind:
            _NullAwareElementOrMapEntryKind.mapEntryValue,
      );
    }
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    _withEnclosingExecutable(
      fragment.element,
      () {
        var returnType = node.returnType;
        if (node.isSetter) {
          _checkForNonVoidReturnTypeForSetter(returnType);
        } else if (node.isOperator) {
          var hasWrongNumberOfParameters =
              _checkForWrongNumberOfParametersForOperator(node);
          if (!hasWrongNumberOfParameters) {
            // If the operator has too many parameters including one or more
            // optional parameters, only report one error.
            _checkForOptionalParameterInOperator(node);
          }
          _checkForNonVoidReturnTypeForOperator(node);
        }
        _checkForExtensionDeclaresMemberOfObject(node);
        _checkForTypeAnnotationDeferredClass(returnType);
        _returnTypeVerifier.verifyReturnType(returnType);
        _checkForWrongTypeParameterVarianceInMethod(node);
        super.visitMethodDeclaration(node);
      },
      isAsynchronous: fragment.isAsynchronous,
      isGenerator: fragment.isGenerator,
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var target = node.realTarget;
    SimpleIdentifier methodName = node.methodName;
    if (target != null) {
      var typeReference = getTypeReference(target);
      _checkForStaticAccessToInstanceMember(typeReference, methodName);
      _checkForInstanceAccessToStaticMember(
        typeReference,
        node.target,
        methodName,
      );
      _checkForUnnecessaryNullAware(target, node.operator!);
    } else {
      _checkForUnqualifiedReferenceToNonLocalStaticMember(methodName);
    }
    _typeArgumentsVerifier.checkMethodInvocation(node);
    _requiredParametersVerifier.visitMethodInvocation(node);
    _constArgumentsVerifier.visitMethodInvocation(node);
    _checkUseVerifier.checkMethodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    // TODO(scheglov): Verify for all mixin errors.
    try {
      var declaredFragment = node.declaredFragment!;
      var declaredElement = declaredFragment.element;
      var firstFragment = declaredElement.firstFragment;

      _enclosingClass = declaredElement;

      List<ClassMember> members = node.members;
      _checkForBuiltInIdentifierAsName(
        node.name,
        CompileTimeErrorCode.builtInIdentifierAsTypeName,
      );
      _checkForConflictingClassTypeVariableErrorCodes();

      var onClause = node.onClause;
      var implementsClause = node.implementsClause;

      // Only do error checks only if there is a non-null clause.
      if (onClause != null || implementsClause != null) {
        _checkMixinInheritance(firstFragment, node, onClause, implementsClause);
      }

      _checkForConflictingClassMembers(declaredFragment);
      _checkForFinalNotInitializedInClass(declaredFragment, members);
      _checkForMainFunction1(node.name, firstFragment);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
      //      _checkForBadFunctionUse(node);
      super.visitMixinDeclaration(node);
    } finally {
      _enclosingClass = null;
    }
  }

  @override
  void visitNamedType(covariant NamedTypeImpl node) {
    _checkForAmbiguousImport(name: node.name, element: node.element);
    _checkForTypeParameterReferencedByStatic(
      name: node.name,
      element: node.element,
    );
    _typeArgumentsVerifier.checkNamedType(node);
    super.visitNamedType(node);
  }

  @override
  void visitNativeClause(NativeClause node) {
    // TODO(brianwilkerson): Figure out the right rule for when 'native' is
    // allowed.
    if (!_isInSystemLibrary) {
      diagnosticReporter.atNode(node, ParserErrorCode.nativeClauseInNonSdkCode);
    }
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _checkForNativeFunctionBodyInNonSdkCode(node);
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitNullAwareElement(NullAwareElement node) {
    _checkForUnnecessaryNullAware(
      node.value,
      node.question,
      nullAwareElementOrMapEntryKind: _NullAwareElementOrMapEntryKind.element,
    );
    super.visitNullAwareElement(node);
  }

  @override
  void visitPatternVariableDeclarationStatement(
    covariant PatternVariableDeclarationStatementImpl node,
  ) {
    super.visitPatternVariableDeclarationStatement(node);
    for (var variable in node.declaration.elements) {
      _hiddenElements?.declare(variable);
    }
  }

  @override
  void visitPostfixExpression(covariant PostfixExpressionImpl node) {
    var operand = node.operand;
    if (node.operator.type == TokenType.BANG) {
      checkForUseOfVoidResult(node);
      _checkForUnnecessaryNullAware(operand, node.operator);
    } else {
      _checkForAssignmentToFinal(operand);
      _checkForIntNotAssignable(operand);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.parent is! Annotation) {
      var typeReference = getTypeReference(node.prefix);
      SimpleIdentifier name = node.identifier;
      _checkForStaticAccessToInstanceMember(typeReference, name);
      _checkForInstanceAccessToStaticMember(typeReference, node.prefix, name);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(covariant PrefixExpressionImpl node) {
    var operatorType = node.operator.type;
    var operand = node.operand;
    if (operatorType != TokenType.BANG) {
      if (operatorType.isIncrementOperator) {
        _checkForAssignmentToFinal(operand);
      }
      checkForUseOfVoidResult(operand);
      _checkForIntNotAssignable(operand);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var target = node.realTarget;
    var typeReference = getTypeReference(target);
    SimpleIdentifier propertyName = node.propertyName;
    _checkForStaticAccessToInstanceMember(typeReference, propertyName);
    _checkForInstanceAccessToStaticMember(
      typeReference,
      node.target,
      propertyName,
    );
    _checkForUnnecessaryNullAware(target, node.operator);
    _checkUseVerifier.checkPropertyAccess(node);
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _requiredParametersVerifier.visitRedirectingConstructorInvocation(node);
    _constArgumentsVerifier.visitRedirectingConstructorInvocation(node);
    _isInConstructorInitializer = true;
    try {
      super.visitRedirectingConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _checkForRethrowOutsideCatch(node);
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      _enclosingExecutable._returnsWithout.add(node);
    } else {
      _enclosingExecutable._returnsWith.add(node);
    }
    _returnTypeVerifier.verifyReturnStatement(node);
    super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isMap) {
      _typeArgumentsVerifier.checkMapLiteral(node);
      _checkForMapTypeNotAssignable(node);
      _checkForNonConstMapAsExpressionStatement3(node);
    } else if (node.isSet) {
      _typeArgumentsVerifier.checkSetLiteral(node);
      _checkForSetElementTypeNotAssignable3(node);
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _checkForPrivateOptionalParameter(node);
    _checkForTypeAnnotationDeferredClass(node.type);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _checkForAmbiguousImport(
      name: node.token,
      element: node.writeOrReadElement,
    );
    _checkForReferenceBeforeDeclaration(
      nameToken: node.token,
      element: node.element,
    );
    _checkForInvalidInstanceMemberAccess(node);
    _checkForTypeParameterReferencedByStatic(
      name: node.token,
      element: node.element,
    );
    if (!_isUnqualifiedReferenceToNonLocalStaticMemberAllowed(node)) {
      _checkForUnqualifiedReferenceToNonLocalStaticMember(node);
    }
    _checkUseVerifier.checkSimpleIdentifier(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    if (node.isNullAware) {
      _checkForUnnecessaryNullAware(node.expression, node.spreadOperator);
    }
    super.visitSpreadElement(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _requiredParametersVerifier.visitSuperConstructorInvocation(
      node,
      enclosingConstructor: _enclosingExecutable.element.ifTypeOrNull(),
    );
    _constArgumentsVerifier.visitSuperConstructorInvocation(node);
    _isInConstructorInitializer = true;
    try {
      _checkForExtensionTypeConstructorWithSuperInvocation(node);
      super.visitSuperConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    super.visitSuperFormalParameter(node);

    if (_enclosingClass is ExtensionTypeElement) {
      diagnosticReporter.atToken(
        node.superKeyword,
        CompileTimeErrorCode.extensionTypeConstructorWithSuperFormalParameter,
      );
      return;
    }

    var constructor = node.parentFormalParameterList.parent;
    if (!(constructor is ConstructorDeclaration &&
        constructor.isNonRedirectingGenerative)) {
      diagnosticReporter.atToken(
        node.superKeyword,
        CompileTimeErrorCode.invalidSuperFormalParameterLocation,
      );
      return;
    }

    var element =
        node.declaredFragment?.element as SuperFormalParameterElementImpl;
    var superParameter = element.superConstructorParameter;

    if (superParameter == null) {
      diagnosticReporter.atToken(
        node.name,
        node.isNamed
            ? CompileTimeErrorCode.superFormalParameterWithoutAssociatedNamed
            : CompileTimeErrorCode
                  .superFormalParameterWithoutAssociatedPositional,
      );
      return;
    }

    if (!_currentLibrary.typeSystem.isSubtypeOf(
      element.type,
      superParameter.type,
    )) {
      diagnosticReporter.atToken(
        node.name,
        CompileTimeErrorCode.superFormalParameterTypeIsNotSubtypeOfAssociated,
        arguments: [element.type, superParameter.type],
      );
    }
  }

  @override
  void visitSwitchCase(covariant SwitchCaseImpl node) {
    _withHiddenElements(node.statements, () {
      _duplicateDefinitionVerifier.checkStatements(node.statements);
      super.visitSwitchCase(node);
    });
  }

  @override
  void visitSwitchDefault(covariant SwitchDefaultImpl node) {
    _withHiddenElements(node.statements, () {
      _duplicateDefinitionVerifier.checkStatements(node.statements);
      super.visitSwitchDefault(node);
    });
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    checkForUseOfVoidResult(node.expression);
    super.visitSwitchExpression(node);
  }

  @override
  void visitSwitchPatternCase(covariant SwitchPatternCaseImpl node) {
    _withHiddenElements(node.statements, () {
      _duplicateDefinitionVerifier.checkStatements(node.statements);
      super.visitSwitchPatternCase(node);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    checkForUseOfVoidResult(node.expression);
    _checkForMissingEnumConstantInSwitch(node);
    super.visitSwitchStatement(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _checkForInvalidReferenceToThis(node);
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _checkForConstEvalThrowsException(node);
    checkForUseOfVoidResult(node.expression);
    _checkForThrowOfInvalidType(node);
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _checkForFinalNotInitialized(node.variables);
    _checkForNotInitializedNonNullableVariable(node.variables, true);

    for (var variable in node.variables.variables) {
      var fragment = variable.declaredFragment;
      fragment as TopLevelVariableFragmentImpl;
      _checkForMainFunction1(variable.name, fragment);
    }

    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    NodeList<TypeAnnotation> list = node.arguments;
    for (TypeAnnotation type in list) {
      _checkForTypeAnnotationDeferredClass(type);
    }
    super.visitTypeArgumentList(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _checkForBuiltInIdentifierAsName(
      node.name,
      CompileTimeErrorCode.builtInIdentifierAsTypeParameterName,
    );
    _checkForTypeAnnotationDeferredClass(node.bound);
    _checkForGenericFunctionType(node.bound);
    node.bound?.accept(_uninstantiatedBoundChecker);
    super.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(covariant TypeParameterListImpl node) {
    _duplicateDefinitionVerifier.checkTypeParameters(node);
    _checkForTypeParameterBoundRecursion(node.typeParameters);
    super.visitTypeParameterList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var nameToken = node.name;
    var initializerNode = node.initializer;
    // do checks
    _checkForAbstractOrExternalVariableInitializer(node);
    // visit initializer
    String name = nameToken.lexeme;
    _namesForReferenceToDeclaredVariableInInitializer.add(name);
    try {
      if (initializerNode != null) {
        initializerNode.accept(this);
      }
    } finally {
      _namesForReferenceToDeclaredVariableInInitializer.remove(name);
    }
    // declare the variable
    AstNode grandparent = node.parent!.parent!;
    if (grandparent is! TopLevelVariableDeclaration &&
        grandparent is! FieldDeclaration) {
      var element = node.declaredFragment!.element;
      // There is no hidden elements if we are outside of a function body,
      // which will happen for variables declared in control flow elements.
      _hiddenElements?.declare(element);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _isInLateLocalVariable.add(node.variables.isLate);

    _checkForFinalNotInitialized(node.variables);
    super.visitVariableDeclarationStatement(node);

    _isInLateLocalVariable.removeLast();
  }

  /// Checks the class for problems with the superclass, mixins, or implemented
  /// interfaces.
  ///
  /// Returns `false` if a severe hierarchy error was found, so that further
  /// checking is not useful.
  bool _checkClassInheritance(
    InterfaceFragmentImpl declarationElement,
    NamedCompilationUnitMember node,
    NamedType? superclass,
    WithClauseImpl? withClause,
    ImplementsClause? implementsClause,
  ) {
    // Only check for all of the inheritance logic around clauses if there
    // isn't an error code such as "Cannot extend double" already on the
    // class.
    if (!_checkForExtendsDisallowedClass(superclass) &&
        !_checkForImplementsClauseErrorCodes(implementsClause) &&
        !_checkForAllMixinErrorCodes(withClause) &&
        !_checkForNoGenerativeConstructorsInSuperclass(superclass)) {
      _checkForExtendsDeferredClass(superclass);
      _checkForRepeatedType(
        libraryContext.setOfImplements(declarationElement.asElement2),
        implementsClause?.interfaces,
        CompileTimeErrorCode.implementsRepeated,
      );
      _checkImplementsSuperClass(implementsClause);
      _checkMixinsSuperClass(withClause);
      _checkForMixinWithConflictingPrivateMember(withClause, superclass);
      _checkForConflictingGenerics(node);
      _checkForBaseClassOrMixinImplementedOutsideOfLibrary(implementsClause);
      _checkForInterfaceClassOrMixinSuperclassOutsideOfLibrary(
        superclass,
        withClause,
      );
      _checkForFinalSupertypeOutsideOfLibrary(
        superclass,
        withClause,
        implementsClause,
        null,
      );
      _checkForClassUsedAsMixin(withClause);
      _checkForSealedSupertypeOutsideOfLibrary([
        if (superclass != null) superclass,
        ...?withClause?.mixinTypes,
        ...?implementsClause?.interfaces,
      ]);
      return true;
    }
    return false;
  }

  /// Given a list of [directives] that have the same prefix, generate an error
  /// if there is more than one import and any of those imports is deferred.
  ///
  /// See [CompileTimeErrorCode.sharedDeferredPrefix].
  void _checkDeferredPrefixCollision(List<ImportDirective> directives) {
    int count = directives.length;
    if (count > 1) {
      for (int i = 0; i < count; i++) {
        var deferredToken = directives[i].deferredKeyword;
        if (deferredToken != null) {
          diagnosticReporter.atToken(
            deferredToken,
            CompileTimeErrorCode.sharedDeferredPrefix,
          );
        }
      }
    }
  }

  void _checkForAbstractOrExternalFieldConstructorInitializer(
    Token identifier,
    FieldElement fieldElement,
  ) {
    if (fieldElement.isAbstract) {
      diagnosticReporter.report(
        CompileTimeErrorCode.abstractFieldConstructorInitializer.at(identifier),
      );
    }
    if (fieldElement.isExternal) {
      diagnosticReporter.atToken(
        identifier,
        CompileTimeErrorCode.externalFieldConstructorInitializer,
      );
    }
  }

  void _checkForAbstractOrExternalVariableInitializer(
    VariableDeclaration node,
  ) {
    var declaredElement = node.declaredFragment?.element;
    if (node.initializer != null) {
      if (declaredElement is FieldElement) {
        if (declaredElement.isAbstract) {
          diagnosticReporter.atToken(
            node.name,
            CompileTimeErrorCode.abstractFieldInitializer,
          );
        }
        if (declaredElement.isExternal) {
          diagnosticReporter.atToken(
            node.name,
            CompileTimeErrorCode.externalFieldInitializer,
          );
        }
      } else if (declaredElement is TopLevelVariableElement) {
        if (declaredElement.isExternal) {
          diagnosticReporter.atToken(
            node.name,
            CompileTimeErrorCode.externalVariableInitializer,
          );
        }
      }
    }
  }

  /// Verify that all classes of the given [withClause] are valid.
  ///
  /// See [CompileTimeErrorCode.mixinClassDeclaresConstructor],
  /// [CompileTimeErrorCode.mixinInheritsFromNotObject].
  bool _checkForAllMixinErrorCodes(WithClauseImpl? withClause) {
    if (withClause == null) {
      return false;
    }
    bool problemReported = false;
    int mixinTypeIndex = -1;
    for (
      int mixinNameIndex = 0;
      mixinNameIndex < withClause.mixinTypes.length;
      mixinNameIndex++
    ) {
      var mixinName = withClause.mixinTypes[mixinNameIndex];
      DartType mixinType = mixinName.typeOrThrow;
      if (mixinType is InterfaceType) {
        mixinTypeIndex++;
        if (_checkForExtendsOrImplementsDisallowedClass(
          mixinName,
          CompileTimeErrorCode.mixinOfDisallowedClass,
        )) {
          problemReported = true;
        } else {
          var mixinElement = mixinType.element;
          if (_checkForExtendsOrImplementsDeferredClass(
            mixinName,
            CompileTimeErrorCode.mixinDeferredClass,
          )) {
            problemReported = true;
          }
          if (mixinType.element is ExtensionTypeElement) {
            // Already reported.
          } else if (mixinElement is MixinElement) {
            if (_checkForMixinSuperclassConstraints(
              mixinNameIndex,
              mixinName,
            )) {
              problemReported = true;
            } else if (_checkForMixinSuperInvokedMembers(
              mixinTypeIndex,
              mixinName,
              mixinElement,
              mixinType,
            )) {
              problemReported = true;
            }
          } else {
            bool isMixinClass =
                mixinElement is ClassElementImpl && mixinElement.isMixinClass;
            if (!isMixinClass &&
                _checkForMixinClassDeclaresConstructor(
                  mixinName,
                  mixinElement,
                )) {
              problemReported = true;
            }
            if (_checkForMixinInheritsNotFromObject(mixinName, mixinElement)) {
              problemReported = true;
            }
          }
        }
      }
    }
    return problemReported;
  }

  /// Check for errors related to the redirected constructors.
  void _checkForAllRedirectConstructorErrorCodes(
    ConstructorDeclarationImpl declaration,
  ) {
    // Prepare redirected constructor node
    var redirectedConstructor = declaration.redirectedConstructor;
    if (redirectedConstructor == null) {
      return;
    }

    // Prepare redirected constructor type
    var redirectedElement = redirectedConstructor.element;
    if (redirectedElement == null) {
      // If the element is null, we check for the
      // REDIRECT_TO_MISSING_CONSTRUCTOR case
      NamedType constructorNamedType = redirectedConstructor.type;
      DartType redirectedType = constructorNamedType.typeOrThrow;
      if (!(redirectedType is DynamicType || redirectedType is InvalidType)) {
        // Prepare the constructor name
        String constructorStrName = constructorNamedType.qualifiedName;
        if (redirectedConstructor.name != null) {
          constructorStrName += ".${redirectedConstructor.name!.name}";
        }
        diagnosticReporter.atNode(
          redirectedConstructor,
          CompileTimeErrorCode.redirectToMissingConstructor,
          arguments: [constructorStrName, redirectedType],
        );
      }
      return;
    }
    var redirectedType = redirectedElement.type;
    var redirectedReturnType = redirectedType.returnType;

    // Report specific problem when return type is incompatible
    var constructorType = declaration.declaredFragment!.element.type;
    var constructorReturnType = constructorType.returnType;
    if (!typeSystem.isAssignableTo(
      redirectedReturnType,
      constructorReturnType,
      strictCasts: strictCasts,
    )) {
      diagnosticReporter.atNode(
        redirectedConstructor,
        CompileTimeErrorCode.redirectToInvalidReturnType,
        arguments: [redirectedReturnType, constructorReturnType],
      );
      return;
    } else if (!typeSystem.isSubtypeOf(redirectedType, constructorType)) {
      // Check parameters.
      diagnosticReporter.atNode(
        redirectedConstructor,
        CompileTimeErrorCode.redirectToInvalidFunctionType,
        arguments: [redirectedType, constructorType],
      );
    }
  }

  /// Verify that the export namespace of the given export [directive] does not
  /// export any name already exported by another export directive. The
  /// [libraryExport] is the [LibraryExport] retrieved from the node. If the
  /// element in the node was `null`, then this method is not called. The
  /// [exportedLibrary] is the library element containing the exported element.
  ///
  /// See [CompileTimeErrorCode.ambiguousExport].
  void _checkForAmbiguousExport(
    ExportDirectiveImpl directive,
    LibraryExportImpl libraryExport,
    LibraryElementImpl? exportedLibrary,
  ) {
    if (exportedLibrary == null) {
      return;
    }
    // check exported names
    Namespace namespace = NamespaceBuilder().createExportNamespaceForDirective2(
      libraryExport,
    );
    Map<String, Element> definedNames = namespace.definedNames2;
    for (String name in definedNames.keys) {
      var element = definedNames[name]!;
      var prevElement = libraryContext._exportedElements[name];
      if (prevElement != null && prevElement != element) {
        diagnosticReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.ambiguousExport,
          arguments: [name, prevElement.library!.uri, element.library!.uri],
        );
        return;
      } else {
        libraryContext._exportedElements[name] = element;
      }
    }
  }

  /// Check the given node to see whether it was ambiguous because the name was
  /// imported from two or more imports.
  void _checkForAmbiguousImport({
    required Token name,
    required Element? element,
  }) {
    if (element is MultiplyDefinedElementImpl) {
      var conflictingMembers = element.conflictingElements;
      var libraryNames = conflictingMembers
          .map((e) => _getLibraryName(e))
          .toList();
      libraryNames.sort();
      diagnosticReporter.atToken(
        name,
        CompileTimeErrorCode.ambiguousImport,
        arguments: [name.lexeme, libraryNames.quotedAndCommaSeparatedWithAnd],
      );
    }
  }

  /// Verify that the given [expression] is not final.
  ///
  /// See [CompileTimeErrorCode.assignmentToConst],
  /// [CompileTimeErrorCode.assignmentToFinal], and
  /// [CompileTimeErrorCode.assignmentToMethod].
  void _checkForAssignmentToFinal(Expression expression) {
    // TODO(scheglov): Check SimpleIdentifier(s) as all other nodes.
    if (expression is! SimpleIdentifier) return;

    // Already handled in the assignment resolver.
    if (expression.parent is AssignmentExpression) {
      return;
    }

    // prepare element
    var highlightedNode = expression;
    var element = expression.element;
    if (expression is PrefixedIdentifier) {
      var prefixedIdentifier = expression as PrefixedIdentifier;
      highlightedNode = prefixedIdentifier.identifier;
    }
    // check if element is assignable
    if (element is VariableElement) {
      if (element.isConst) {
        diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.assignmentToConst,
        );
      }
    } else if (element is GetterElement) {
      var variable = element.variable;
      if (variable.isConst) {
        diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.assignmentToConst,
        );
      } else if (variable is FieldElement && variable.isSynthetic) {
        diagnosticReporter.atNode(
          highlightedNode,
          CompileTimeErrorCode.assignmentToFinalNoSetter,
          arguments: [variable.name!, variable.enclosingElement.displayName],
        );
      } else {
        diagnosticReporter.atNode(
          highlightedNode,
          CompileTimeErrorCode.assignmentToFinal,
          arguments: [variable.name!],
        );
      }
    } else if (element is LocalFunctionElement ||
        element is TopLevelFunctionElement) {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.assignmentToFunction,
      );
    } else if (element is MethodElement) {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.assignmentToMethod,
      );
    } else if (element is InterfaceElement ||
        element is DynamicElementImpl ||
        element is TypeParameterElement) {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.assignmentToType,
      );
    }
  }

  void _checkForAwaitInLateLocalVariableInitializer(AwaitExpression node) {
    if (_isInLateLocalVariable.last) {
      diagnosticReporter.atToken(
        node.awaitKeyword,
        CompileTimeErrorCode.awaitInLateLocalVariableInitializer,
      );
    }
  }

  void _checkForAwaitOfIncompatibleType(AwaitExpression node) {
    var expression = node.expression;
    var expressionType = expression.typeOrThrow;
    if (typeSystem.isIncompatibleWithAwait(expressionType)) {
      diagnosticReporter.atToken(
        node.awaitKeyword,
        CompileTimeErrorCode.awaitOfIncompatibleType,
      );
    }
  }

  /// Verifies that the nodes don't reference `Function` from `dart:core`.
  void _checkForBadFunctionUse({
    required NamedType? superclass,
    required ImplementsClause? implementsClause,
    required WithClause? withClause,
  }) {
    // With the `class_modifiers` feature `Function` is final.
    if (_featureSet!.isEnabled(Feature.class_modifiers)) {
      return;
    }

    if (superclass != null) {
      var type = superclass.type;
      if (type != null && type.isDartCoreFunction) {
        diagnosticReporter.atNode(
          superclass,
          WarningCode.deprecatedExtendsFunction,
        );
      }
    }

    if (implementsClause != null) {
      for (var interface in implementsClause.interfaces) {
        var type = interface.type;
        if (type != null && type.isDartCoreFunction) {
          diagnosticReporter.atNode(
            interface,
            WarningCode.deprecatedImplementsFunction,
          );
          break;
        }
      }
    }

    if (withClause != null) {
      for (NamedType mixin in withClause.mixinTypes) {
        var type = mixin.type;
        if (type != null && type.isDartCoreFunction) {
          diagnosticReporter.atNode(mixin, WarningCode.deprecatedMixinFunction);
        }
      }
    }
  }

  /// Verify that if a class is implementing a base class or mixin, it must be
  /// within the same library as that class or mixin.
  ///
  /// See [CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary],
  /// [CompileTimeErrorCode.baseMixinImplementedOutsideOfLibrary].
  void _checkForBaseClassOrMixinImplementedOutsideOfLibrary(
    ImplementsClause? implementsClause,
  ) {
    if (implementsClause == null) return;
    for (NamedType interface in implementsClause.interfaces) {
      var interfaceType = interface.type;
      if (interfaceType is InterfaceType) {
        var implementedInterfaces = [
          interfaceType,
          ...interfaceType.element.allSupertypes,
        ].map((e) => e.element).toList();
        for (var interfaceElement in implementedInterfaces) {
          if ((interfaceElement is ClassElementImpl &&
                      interfaceElement.isBase ||
                  interfaceElement is MixinElementImpl &&
                      interfaceElement.isBase) &&
              interfaceElement.library != _currentLibrary &&
              !_mayIgnoreClassModifiers(interfaceElement.library)) {
            // Should this be combined with _checkForImplementsClauseErrorCodes
            // to avoid double errors if implementing `int`.
            if (interfaceElement is ClassElementImpl &&
                !interfaceElement.isSealed) {
              diagnosticReporter.report(
                CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary
                    .withArguments(implementedClassName: interfaceElement.name!)
                    .at(interface),
              );
            } else if (interfaceElement is MixinElement) {
              diagnosticReporter.report(
                CompileTimeErrorCode.baseMixinImplementedOutsideOfLibrary
                    .withArguments(implementedMixinName: interfaceElement.name!)
                    .at(interface),
              );
            }
            break;
          }
        }
      }
    }
  }

  /// Verify that the given [token] is not a keyword, and generates the
  /// given [code] on the identifier if it is a keyword.
  ///
  /// See [CompileTimeErrorCode.builtInIdentifierAsExtensionName],
  /// [CompileTimeErrorCode.builtInIdentifierAsTypeName],
  /// [CompileTimeErrorCode.builtInIdentifierAsTypeParameterName], and
  /// [CompileTimeErrorCode.builtInIdentifierAsTypedefName].
  void _checkForBuiltInIdentifierAsName(Token token, DiagnosticCode code) {
    if (token.type.isKeyword && token.keyword?.isPseudo != true) {
      diagnosticReporter.atToken(token, code, arguments: [token.lexeme]);
    }
  }

  /// Verify that if a class is being mixed in and class modifiers are enabled
  /// in that class' library, then it must be a mixin class.
  ///
  /// See [CompileTimeErrorCode.classUsedAsMixin].
  void _checkForClassUsedAsMixin(WithClause? withClause) {
    if (withClause != null) {
      for (NamedType withMixin in withClause.mixinTypes) {
        var withType = withMixin.type;
        if (withType is InterfaceType) {
          var withElement = withType.element;
          if (withElement is ClassElementImpl &&
              !withElement.isMixinClass &&
              withElement.library.featureSet.isEnabled(
                Feature.class_modifiers,
              ) &&
              !_mayIgnoreClassModifiers(withElement.library)) {
            diagnosticReporter.atNode(
              withMixin,
              CompileTimeErrorCode.classUsedAsMixin,
              arguments: [withElement.name!],
            );
          }
        }
      }
    }
  }

  /// Verify that the [_enclosingClass] does not have a method and getter pair
  /// with the same name, via inheritance.
  ///
  /// See [CompileTimeErrorCode.conflictingStaticAndInstance],
  /// [CompileTimeErrorCode.conflictingMethodAndField], and
  /// [CompileTimeErrorCode.conflictingFieldAndMethod].
  void _checkForConflictingClassMembers(InterfaceFragmentImpl fragment) {
    var enclosingClass = _enclosingClass;
    if (enclosingClass == null) {
      return;
    }

    Uri libraryUri = _currentLibrary.uri;
    var conflictingDeclaredNames = <String>{};

    // method declared in the enclosing class vs. inherited getter/setter
    for (var method in fragment.methods) {
      if (method.libraryFragment.source != _currentUnit.source) {
        continue;
      }

      String name = method.name ?? '';

      // find inherited property accessors
      var getter = _inheritanceManager.getInherited(
        enclosingClass,
        Name(libraryUri, name),
      );
      var setter = _inheritanceManager.getInherited(
        enclosingClass,
        Name(libraryUri, '$name='),
      );

      if (method.isStatic) {
        void reportStaticConflict(InternalExecutableElement inherited) {
          diagnosticReporter.atElement2(
            method.asElement2,
            CompileTimeErrorCode.conflictingStaticAndInstance,
            arguments: [
              enclosingClass.displayName,
              name,
              inherited.enclosingElement!.displayName,
            ],
          );
        }

        if (getter != null) {
          reportStaticConflict(getter);
          continue;
        }

        if (setter != null) {
          reportStaticConflict(setter);
          continue;
        }
      }

      // Extension type methods preclude accessors.
      if (enclosingClass is ExtensionTypeElementImpl) {
        continue;
      }

      void reportFieldConflict(InternalPropertyAccessorElement inherited) {
        diagnosticReporter.atElement2(
          method.asElement2,
          CompileTimeErrorCode.conflictingMethodAndField,
          arguments: [
            enclosingClass.displayName,
            name,
            inherited.enclosingElement.displayName,
          ],
        );
      }

      if (getter is InternalGetterElement) {
        reportFieldConflict(getter);
        continue;
      }

      if (setter is InternalSetterElement) {
        reportFieldConflict(setter);
        continue;
      }
    }

    // getter declared in the enclosing class vs. inherited method
    for (var accessor in fragment.accessors) {
      String name = accessor.displayName;

      // find inherited method or property accessor
      var inherited = _inheritanceManager.getInherited(
        enclosingClass,
        Name(libraryUri, name),
      );
      inherited ??= _inheritanceManager.getInherited(
        enclosingClass,
        Name(libraryUri, '$name='),
      );

      if (accessor.isStatic && inherited != null) {
        diagnosticReporter.atElement2(
          accessor.asElement2,
          CompileTimeErrorCode.conflictingStaticAndInstance,
          arguments: [
            enclosingClass.displayName,
            name,
            inherited.enclosingElement!.displayName,
          ],
        );
        conflictingDeclaredNames.add(name);
      } else if (inherited is InternalMethodElement) {
        // Extension type accessors preclude inherited accessors/methods.
        if (enclosingClass is ExtensionTypeElementImpl) {
          continue;
        }
        diagnosticReporter.atElement2(
          accessor.asElement2,
          CompileTimeErrorCode.conflictingFieldAndMethod,
          arguments: [
            enclosingClass.displayName,
            name,
            inherited.enclosingElement!.displayName,
          ],
        );
        conflictingDeclaredNames.add(name);
      }
    }

    // Inherited method and setter with the same name.
    var inherited = _inheritanceManager.getInheritedMap(enclosingClass);
    for (var entry in inherited.entries) {
      var method = entry.value;
      if (method is InternalMethodElement) {
        var methodName = entry.key;
        if (conflictingDeclaredNames.contains(methodName.name)) {
          continue;
        }
        var setterName = methodName.forSetter;
        var setter = inherited[setterName];
        if (setter is InternalPropertyAccessorElement) {
          diagnosticReporter.atElement2(
            enclosingClass,
            CompileTimeErrorCode.conflictingInheritedMethodAndSetter,
            arguments: [
              enclosingClass.kind.displayName,
              enclosingClass.displayName,
              methodName.name,
            ],
            contextMessages: [
              DiagnosticMessageImpl(
                filePath: method.firstFragment.libraryFragment.source.fullName,
                message:
                    formatList("The method is inherited from the {0} '{1}'.", [
                      method.enclosingElement!.kind.displayName,
                      method.enclosingElement!.name,
                    ]),
                offset: method.firstFragment.nameOffset!,
                length: method.firstFragment.name!.length,
                url: null,
              ),
              DiagnosticMessageImpl(
                filePath: setter.firstFragment.libraryFragment.source.fullName,
                message:
                    formatList("The setter is inherited from the {0} '{1}'.", [
                      setter.enclosingElement.kind.displayName,
                      setter.enclosingElement.name,
                    ]),
                offset: setter.firstFragment.nameOffset!,
                length: setter.firstFragment.name!.length,
                url: null,
              ),
            ],
          );
        }
      }
    }
  }

  /// Verify all conflicts between type variable and enclosing class.
  void _checkForConflictingClassTypeVariableErrorCodes() {
    var enclosingClass = _enclosingClass!;
    for (TypeParameterElement typeParameter in enclosingClass.typeParameters) {
      if (typeParameter.isWildcardVariable) continue;

      var name = typeParameter.name;
      if (name == null) continue;

      // name is same as the name of the enclosing class
      if (enclosingClass.name == name) {
        var code = enclosingClass is MixinElement
            ? CompileTimeErrorCode.conflictingTypeVariableAndMixin
            : CompileTimeErrorCode.conflictingTypeVariableAndClass;
        diagnosticReporter.atElement2(typeParameter, code, arguments: [name]);
      }
      // check members
      if (enclosingClass.getNamedConstructor(name) != null ||
          enclosingClass.getMethod(name) != null ||
          enclosingClass.getGetter(name) != null ||
          enclosingClass.getSetter(name) != null) {
        var code = enclosingClass is MixinElement
            ? CompileTimeErrorCode.conflictingTypeVariableAndMemberMixin
            : CompileTimeErrorCode.conflictingTypeVariableAndMemberClass;
        diagnosticReporter.atElement2(typeParameter, code, arguments: [name]);
      }
    }
  }

  void _checkForConflictingEnumTypeVariableErrorCodes(
    EnumFragmentImpl fragment,
  ) {
    for (var typeParameter in fragment.typeParameters) {
      var name = typeParameter.name ?? '';
      // name is same as the name of the enclosing enum
      if (fragment.name == name) {
        diagnosticReporter.atElement2(
          typeParameter.asElement2,
          CompileTimeErrorCode.conflictingTypeVariableAndEnum,
          arguments: [name],
        );
      }
      // check members
      var element = fragment.element;
      if (element.getMethod(name) != null ||
          element.getGetter(name) != null ||
          element.getSetter(name) != null) {
        diagnosticReporter.atElement2(
          typeParameter.asElement2,
          CompileTimeErrorCode.conflictingTypeVariableAndMemberEnum,
          arguments: [name],
        );
      }
    }
  }

  void _checkForConflictingExtensionTypeTypeVariableErrorCodes(
    ExtensionTypeFragmentImpl fragment,
  ) {
    for (var typeParameter in fragment.typeParameters) {
      if (typeParameter.element.isWildcardVariable) continue;

      var name = typeParameter.name ?? '';
      // name is same as the name of the enclosing class
      if (fragment.name == name) {
        diagnosticReporter.atElement2(
          typeParameter.asElement2,
          CompileTimeErrorCode.conflictingTypeVariableAndExtensionType,
          arguments: [name],
        );
      }
      // check members
      var element = fragment.element;
      if (element.getNamedConstructor(name) != null ||
          element.getMethod(name) != null ||
          element.getGetter(name) != null ||
          element.getSetter(name) != null) {
        diagnosticReporter.atElement2(
          typeParameter.asElement2,
          CompileTimeErrorCode.conflictingTypeVariableAndMemberExtensionType,
          arguments: [name],
        );
      }
    }
  }

  /// Verify all conflicts between type variable and enclosing extension.
  ///
  /// See [CompileTimeErrorCode.conflictingTypeVariableAndExtension], and
  /// [CompileTimeErrorCode.conflictingTypeVariableAndMemberExtension].
  void _checkForConflictingExtensionTypeVariableErrorCodes() {
    for (TypeParameterElement typeParameter
        in _enclosingExtension!.typeParameters) {
      var name = typeParameter.name;
      if (name == null) continue;

      // name is same as the name of the enclosing class
      if (_enclosingExtension!.name == name) {
        diagnosticReporter.atElement2(
          typeParameter,
          CompileTimeErrorCode.conflictingTypeVariableAndExtension,
          arguments: [name],
        );
      }
      // check members
      if (_enclosingExtension!.getMethod(name) != null ||
          _enclosingExtension!.getGetter(name) != null ||
          _enclosingExtension!.getSetter(name) != null) {
        diagnosticReporter.atElement2(
          typeParameter,
          CompileTimeErrorCode.conflictingTypeVariableAndMemberExtension,
          arguments: [name],
        );
      }
    }
  }

  void _checkForConflictingGenerics(NamedCompilationUnitMember node) {
    var fragment = node.declaredFragment as InterfaceFragmentImpl;

    // Report only on the declaration.
    if (fragment.isAugmentation) {
      return;
    }

    var analysisSession = _currentLibrary.session;
    var errors = analysisSession.classHierarchy.errors(fragment.asElement2);

    for (var error in errors) {
      if (error is IncompatibleInterfacesClassHierarchyError) {
        diagnosticReporter.atToken(
          node.name,
          CompileTimeErrorCode.conflictingGenericInterfaces,
          arguments: [
            _enclosingClass!.kind.displayName,
            _enclosingClass!.name!,
            error.first.getDisplayString(),
            error.second.getDisplayString(),
          ],
        );
      } else {
        throw UnimplementedError('${error.runtimeType}');
      }
    }
  }

  /// Check that the given constructor [declaration] has a valid combination of
  /// redirecting constructor invocation(s), super constructor invocation(s),
  /// field initializers, and assert initializers.
  void _checkForConflictingInitializerErrorCodes(
    ConstructorDeclaration declaration,
  ) {
    var enclosingClass = _enclosingClass;
    if (enclosingClass == null) {
      return;
    }
    // Count and check each redirecting initializer.
    var redirectingInitializerCount = 0;
    var superInitializerCount = 0;
    late SuperConstructorInvocation superInitializer;
    for (ConstructorInitializer initializer in declaration.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (redirectingInitializerCount > 0) {
          diagnosticReporter.atNode(
            initializer,
            CompileTimeErrorCode.multipleRedirectingConstructorInvocations,
          );
        }
        if (declaration.factoryKeyword == null) {
          RedirectingConstructorInvocation invocation = initializer;
          var redirectingElement = invocation.element;
          if (redirectingElement == null) {
            String enclosingNamedType = enclosingClass.displayName;
            String constructorStrName = enclosingNamedType;
            if (invocation.constructorName != null) {
              constructorStrName += ".${invocation.constructorName!.name}";
            }
            diagnosticReporter.atNode(
              invocation,
              CompileTimeErrorCode.redirectGenerativeToMissingConstructor,
              arguments: [constructorStrName, enclosingNamedType],
            );
          } else {
            if (redirectingElement.isFactory) {
              diagnosticReporter.atNode(
                initializer,
                CompileTimeErrorCode
                    .redirectGenerativeToNonGenerativeConstructor,
              );
            }
          }
        }
        // [declaration] is a redirecting constructor via a redirecting
        // initializer.
        _checkForRedirectToNonConstConstructor(
          declaration.declaredFragment!.element,
          initializer.element,
          initializer.constructorName ?? initializer.thisKeyword,
        );
        redirectingInitializerCount++;
      } else if (initializer is SuperConstructorInvocation) {
        if (enclosingClass is EnumElement) {
          diagnosticReporter.atToken(
            initializer.superKeyword,
            CompileTimeErrorCode.superInEnumConstructor,
          );
        } else if (superInitializerCount == 1) {
          // Only report the second (first illegal) superinitializer.
          diagnosticReporter.atNode(
            initializer,
            CompileTimeErrorCode.multipleSuperInitializers,
          );
        }
        superInitializer = initializer;
        superInitializerCount++;
      }
    }
    // Check for initializers which are illegal when alongside a redirecting
    // initializer.
    if (redirectingInitializerCount > 0) {
      for (ConstructorInitializer initializer in declaration.initializers) {
        if (initializer is SuperConstructorInvocation) {
          if (enclosingClass is! EnumElement) {
            diagnosticReporter.atNode(
              initializer,
              CompileTimeErrorCode.superInRedirectingConstructor,
            );
          }
        }
        if (initializer is ConstructorFieldInitializer) {
          diagnosticReporter.atNode(
            initializer,
            CompileTimeErrorCode.fieldInitializerRedirectingConstructor,
          );
        }
        if (initializer is AssertInitializer) {
          diagnosticReporter.atNode(
            initializer,
            CompileTimeErrorCode.assertInRedirectingConstructor,
          );
        }
      }
    }
    if (enclosingClass is! EnumElement &&
        redirectingInitializerCount == 0 &&
        superInitializerCount == 1 &&
        superInitializer != declaration.initializers.last) {
      var superType = enclosingClass.supertype;
      if (superType != null) {
        var superNamedType = superType.element.displayName;
        var constructorStrName = superNamedType;
        var constructorName = superInitializer.constructorName;
        if (constructorName != null) {
          constructorStrName += '.${constructorName.name}';
        }
        diagnosticReporter.atToken(
          superInitializer.superKeyword,
          CompileTimeErrorCode.superInvocationNotLast,
          arguments: [constructorStrName],
        );
      }
    }
  }

  /// Verify that if the given [constructor] declaration is 'const' then there
  /// are no invocations of non-'const' super constructors, and that there are
  /// no instance variables mixed in.
  ///
  /// Return `true` if an error is reported here, and the caller should stop
  /// checking the constructor for constant-related errors.
  ///
  /// See [CompileTimeErrorCode.constConstructorWithNonConstSuper], and
  /// [CompileTimeErrorCode.constConstructorWithMixinWithField].
  bool _checkForConstConstructorWithNonConstSuper(
    ConstructorDeclaration constructor,
  ) {
    var enclosingClass = _enclosingClass;
    if (enclosingClass == null || !_enclosingExecutable.isConstConstructor) {
      return false;
    }

    // OK, const factory, checked elsewhere
    if (constructor.factoryKeyword != null) {
      return false;
    }

    // check for mixins
    var instanceFields = <FieldElement>[];
    for (var mixin in enclosingClass.mixins) {
      instanceFields.addAll(
        mixin.element.fields.where((field) {
          if (field.isStatic) {
            return false;
          }
          if (field.isSynthetic) {
            return false;
          }
          // From the abstract and external fields specification:
          // > An abstract instance variable declaration D is treated as an
          // > abstract getter declaration and possibly an abstract setter
          // > declaration. The setter is included if and only if D is non-final.
          if (field.isAbstract && field.isFinal) {
            return false;
          }
          return true;
        }),
      );
    }
    if (instanceFields.length == 1) {
      var field = instanceFields.single;
      diagnosticReporter.atNode(
        constructor.returnType,
        CompileTimeErrorCode.constConstructorWithMixinWithField,
        arguments: ["'${field.enclosingElement.name}.${field.name}'"],
      );
      return true;
    } else if (instanceFields.length > 1) {
      var fieldNames = instanceFields
          .map((field) => "'${field.enclosingElement.name}.${field.name}'")
          .join(', ');
      diagnosticReporter.atNode(
        constructor.returnType,
        CompileTimeErrorCode.constConstructorWithMixinWithFields,
        arguments: [fieldNames],
      );
      return true;
    }

    // Enum(s) always call a const super-constructor.
    if (enclosingClass is EnumElement) {
      return false;
    }

    var element = constructor.declaredFragment?.element;
    if (element == null) {
      return false;
    }

    // Redirecting constructors are checked to be const elsewhere.
    if (element.redirectedConstructor != null) {
      return false;
    }

    var invokedSuper = element.superConstructor;
    if (invokedSuper == null || invokedSuper.isConst) {
      return false;
    }

    // Often there is an explicit `super()` invocation, report on it.
    var superInvocation = constructor.initializers
        .whereType<SuperConstructorInvocation>()
        .firstOrNull;
    var errorNode = superInvocation ?? constructor.returnType;

    diagnosticReporter.atNode(
      errorNode,
      CompileTimeErrorCode.constConstructorWithNonConstSuper,
      arguments: [element.enclosingElement.displayName],
    );
    return true;
  }

  /// Verify that if the given [constructor] declaration is 'const' then there
  /// are no non-final instance variable. The [constructorElement] is the
  /// constructor element.
  void _checkForConstConstructorWithNonFinalField(
    ConstructorDeclaration constructor,
    ConstructorElement constructorElement,
  ) {
    if (!_enclosingExecutable.isConstConstructor) {
      return;
    }
    if (!_enclosingExecutable.isGenerativeConstructor) {
      return;
    }
    // check if there is non-final field
    var classElement = constructorElement.enclosingElement;
    if (classElement is! ClassElement || !classElement.hasNonFinalField) {
      return;
    }
    diagnosticReporter.atConstructorDeclaration(
      constructor,
      CompileTimeErrorCode.constConstructorWithNonFinalField,
    );
  }

  /// Verify that the given 'const' instance creation [expression] is not
  /// creating a deferred type. The [constructorName] is the constructor name,
  /// always non-`null`. The [namedType] is the name of the type defining the
  /// constructor, always non-`null`.
  ///
  /// See [CompileTimeErrorCode.constDeferredClass].
  void _checkForConstDeferredClass(
    InstanceCreationExpression expression,
    ConstructorName constructorName,
    NamedType namedType,
  ) {
    if (namedType.isDeferred) {
      diagnosticReporter.atNode(
        constructorName,
        CompileTimeErrorCode.constDeferredClass,
      );
    }
  }

  /// Verify that the given throw [expression] is not enclosed in a 'const'
  /// constructor declaration.
  ///
  /// See [CompileTimeErrorCode.constConstructorThrowsException].
  void _checkForConstEvalThrowsException(ThrowExpression expression) {
    if (_enclosingExecutable.isConstConstructor) {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.constConstructorThrowsException,
      );
    }
  }

  /// Verify that the given instance creation [expression] is not being invoked
  /// on an abstract class. The [namedType] is the [NamedType] of the
  /// [ConstructorName] from the [InstanceCreationExpression], this is the AST
  /// node that the error is attached to. The [type] is the type being
  /// constructed with this [InstanceCreationExpression].
  void _checkForConstOrNewWithAbstractClass(
    InstanceCreationExpression expression,
    NamedType namedType,
    InterfaceType type,
  ) {
    var element = type.element;
    if (element is ClassElement && element.isAbstract) {
      var constructorElement = expression.constructorName.element;
      if (constructorElement != null && !constructorElement.isFactory) {
        diagnosticReporter.atNode(
          namedType,
          CompileTimeErrorCode.instantiateAbstractClass,
        );
      }
    }
  }

  /// Verify that the given [expression] is not a mixin instantiation.
  void _checkForConstOrNewWithMixin(
    InstanceCreationExpression expression,
    NamedType namedType,
    InterfaceType type,
  ) {
    if (type.element is MixinElement) {
      diagnosticReporter.atNode(
        namedType,
        CompileTimeErrorCode.mixinInstantiate,
      );
    }
  }

  /// Verify that the given 'const' instance creation [expression] is not being
  /// invoked on a constructor that is not 'const'.
  ///
  /// This method assumes that the instance creation or dot shorthand
  /// constructor invocation was tested to be 'const' before being called.
  ///
  /// See [CompileTimeErrorCode.constWithNonConst].
  void _checkForConstWithNonConst(
    Expression expression,
    ConstructorElement? constructorElement,
    Token? keyword,
  ) {
    if (constructorElement != null && !constructorElement.isConst) {
      if (keyword != null) {
        diagnosticReporter.atToken(
          keyword,
          CompileTimeErrorCode.constWithNonConst,
        );
      } else {
        diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.constWithNonConst,
        );
      }
    }
  }

  /// Verify that if the given 'const' instance creation [expression] is being
  /// invoked on the resolved constructor. The [constructorName] is the
  /// constructor name, always non-`null`. The [namedType] is the name of the
  /// type defining the constructor, always non-`null`.
  ///
  /// This method assumes that the instance creation was tested to be 'const'
  /// before being called.
  ///
  /// See [CompileTimeErrorCode.constWithUndefinedConstructor], and
  /// [CompileTimeErrorCode.constWithUndefinedConstructorDefault].
  void _checkForConstWithUndefinedConstructor(
    InstanceCreationExpression expression,
    ConstructorName constructorName,
    NamedType namedType,
  ) {
    // OK if resolved
    if (constructorName.element != null) {
      return;
    }
    // report as named or default constructor absence
    var name = constructorName.name;
    if (name != null) {
      diagnosticReporter.atNode(
        name,
        CompileTimeErrorCode.constWithUndefinedConstructor,
        arguments: [namedType.qualifiedName, name.name],
      );
    } else {
      diagnosticReporter.atNode(
        constructorName,
        CompileTimeErrorCode.constWithUndefinedConstructorDefault,
        arguments: [namedType.qualifiedName],
      );
    }
  }

  void _checkForDeadNullCoalesce(TypeImpl lhsType, Expression rhs) {
    if (typeSystem.isStrictlyNonNullable(lhsType)) {
      diagnosticReporter.atNode(rhs, StaticWarningCode.deadNullAwareExpression);
    }
  }

  /// Report a diagnostic if there are any extensions in the imported library
  /// that are not hidden.
  void _checkForDeferredImportOfExtensions(
    ImportDirective directive,
    LibraryImport importElement,
  ) {
    for (var element in importElement.namespace.definedNames2.values) {
      if (element is ExtensionElement) {
        diagnosticReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.deferredImportOfExtension,
        );
        return;
      }
    }
  }

  /// Verify that any deferred imports in the given compilation [unit] have a
  /// unique prefix.
  ///
  /// See [CompileTimeErrorCode.sharedDeferredPrefix].
  void _checkForDeferredPrefixCollisions(CompilationUnit unit) {
    NodeList<Directive> directives = unit.directives;
    int count = directives.length;
    if (count > 0) {
      var prefixToDirectivesMap = <PrefixElement, List<ImportDirective>>{};
      for (int i = 0; i < count; i++) {
        Directive directive = directives[i];
        if (directive is ImportDirective) {
          var prefix = directive.prefix;
          if (prefix != null) {
            var element = prefix.element;
            if (element is PrefixElement) {
              var elements = prefixToDirectivesMap[element];
              if (elements == null) {
                elements = <ImportDirective>[];
                prefixToDirectivesMap[element] = elements;
              }
              elements.add(directive);
            }
          }
        }
      }
      for (List<ImportDirective> imports in prefixToDirectivesMap.values) {
        _checkDeferredPrefixCollision(imports);
      }
    }
  }

  /// Return `true` if the caller should continue checking the rest of the
  /// information in the for-each part.
  bool _checkForEachParts(ForEachParts node, Element? variableElement) {
    if (checkForUseOfVoidResult(node.iterable)) {
      return false;
    }

    var iterableType = node.iterable.typeOrThrow;

    Token? awaitKeyword;
    var parent = node.parent;
    if (parent is ForStatement) {
      awaitKeyword = parent.awaitKeyword;
    } else if (parent is ForElement) {
      awaitKeyword = parent.awaitKeyword;
    }

    // Use an explicit string instead of [loopType] to remove the "<E>".
    String loopNamedType = awaitKeyword != null ? 'Stream' : 'Iterable';

    if (iterableType is DynamicType && strictCasts) {
      diagnosticReporter.atNode(
        node.iterable,
        CompileTimeErrorCode.forInOfInvalidType,
        arguments: [iterableType, loopNamedType],
      );
      return false;
    }

    // TODO(scheglov): use NullableDereferenceVerifier
    if (typeSystem.isNullable(iterableType)) {
      return false;
    }

    // The type of the loop variable.
    TypeImpl variableType;
    if (variableElement is VariableElementImpl) {
      variableType = variableElement.type;
    } else {
      return false;
    }

    // The object being iterated has to implement Iterable<T> for some T that
    // is assignable to the variable's type.
    // TODO(rnystrom): Move this into mostSpecificTypeArgument()?
    iterableType = typeSystem.resolveToBound(iterableType);

    var requiredSequenceType = awaitKeyword != null
        ? _typeProvider.streamDynamicType
        : _typeProvider.iterableDynamicType;

    if (typeSystem.isTop(iterableType)) {
      iterableType = requiredSequenceType;
    }

    if (!typeSystem.isAssignableTo(
      iterableType,
      requiredSequenceType,
      strictCasts: strictCasts,
    )) {
      diagnosticReporter.atNode(
        node.iterable,
        CompileTimeErrorCode.forInOfInvalidType,
        arguments: [iterableType, loopNamedType],
      );
      return false;
    }

    TypeImpl? sequenceElementType;
    {
      var sequenceElement = awaitKeyword != null
          ? _typeProvider.streamElement
          : _typeProvider.iterableElement;
      var sequenceType = iterableType.asInstanceOf(sequenceElement);
      if (sequenceType != null) {
        sequenceElementType = sequenceType.typeArguments[0];
      }
    }

    if (sequenceElementType == null) {
      return true;
    }

    if (!typeSystem.isAssignableTo(
      sequenceElementType,
      variableType,
      strictCasts: strictCasts,
    )) {
      // Use an explicit string instead of [loopType] to remove the "<E>".
      String loopNamedType = awaitKeyword != null ? 'Stream' : 'Iterable';

      // A for-in loop is specified to desugar to a different set of statements
      // which include an assignment of the sequence element's `iterator`'s
      // `current` value, at which point "implicit tear-off conversion" may be
      // performed. We do not perform this desugaring; instead we allow a
      // special assignability here.
      var implicitCallMethod = getImplicitCallMethod(
        sequenceElementType,
        variableType,
        node.iterable,
      );
      if (implicitCallMethod == null) {
        diagnosticReporter.atNode(
          node.iterable,
          CompileTimeErrorCode.forInOfInvalidElementType,
          arguments: [iterableType, loopNamedType, variableType],
        );
      } else {
        var tearoffType = implicitCallMethod.type;
        // An implicit tear-off conversion does occur on the values of the
        // iterator, but this does not guarantee their assignability.

        if (_featureSet?.isEnabled(Feature.constructor_tearoffs) ?? true) {
          var typeArguments = typeSystem.inferFunctionTypeInstantiation(
            variableType as FunctionTypeImpl,
            tearoffType,
            diagnosticReporter: diagnosticReporter,
            errorNode: node.iterable,
            genericMetadataIsEnabled: true,
            inferenceUsingBoundsIsEnabled:
                _featureSet?.isEnabled(Feature.inference_using_bounds) ?? true,
            strictInference: options.strictInference,
            strictCasts: options.strictCasts,
            typeSystemOperations: typeSystemOperations,
            dataForTesting: null,
            nodeForTesting: null,
          );
          if (typeArguments.isNotEmpty) {
            tearoffType = tearoffType.instantiate(typeArguments);
          }
        }

        if (!typeSystem.isAssignableTo(
          tearoffType,
          variableType,
          strictCasts: strictCasts,
        )) {
          diagnosticReporter.atNode(
            node.iterable,
            CompileTimeErrorCode.forInOfInvalidElementType,
            arguments: [iterableType, loopNamedType, variableType],
          );
        }
      }
    }

    return true;
  }

  void _checkForEnumInstantiatedToBoundsIsNotWellBounded(
    EnumDeclaration node,
    EnumElementImpl element,
  ) {
    var valuesFieldType = element.valuesField?.type;
    if (valuesFieldType is InterfaceTypeImpl) {
      var isWellBounded = typeSystem.isWellBounded(
        valuesFieldType.typeArguments.single,
        allowSuperBounded: true,
      );
      if (isWellBounded is NotWellBoundedTypeResult) {
        diagnosticReporter.atToken(
          node.name,
          CompileTimeErrorCode.enumInstantiatedToBoundsIsNotWellBounded,
        );
      }
    }
  }

  /// Check that if the visiting library is not system, then any given library
  /// should not be SDK internal library. The [libraryExport] is the
  /// [LibraryExport] retrieved from the node, if the element in the node was
  /// `null`, then this method is not called.
  ///
  /// See [CompileTimeErrorCode.exportInternalLibrary].
  void _checkForExportInternalLibrary(
    ExportDirective directive,
    LibraryExport libraryExport,
  ) {
    if (_isInSystemLibrary) {
      return;
    }

    var exportedLibrary = libraryExport.exportedLibrary;
    if (exportedLibrary == null) {
      return;
    }

    // should be private
    if (!(exportedLibrary as LibraryElementImpl).isInternalSdkLibrary) {
      return;
    }

    // It is safe to assume that `directive.uri.stringValue` is non-`null`,
    // because the only time it is `null` is if the URI contains a string
    // interpolation, in which case the export would never have resolved in the
    // first place.
    diagnosticReporter.atNode(
      directive,
      CompileTimeErrorCode.exportInternalLibrary,
      arguments: [directive.uri.stringValue!],
    );
  }

  /// Verifies that the given [superclass], found in an extends-clause, is not a
  /// deferred class.
  ///
  /// See [CompileTimeErrorCode.extendsDeferredClass].
  void _checkForExtendsDeferredClass(NamedType? superclass) {
    if (superclass == null) {
      return;
    }
    _checkForExtendsOrImplementsDeferredClass(
      superclass,
      CompileTimeErrorCode.extendsDeferredClass,
    );
  }

  /// Verifies that the given [superclass], found in an extends-clause, is not a
  /// class such as 'num' or 'String'.
  ///
  /// See [CompileTimeErrorCode.extendsDisallowedClass].
  bool _checkForExtendsDisallowedClass(NamedType? superclass) {
    if (superclass == null) {
      return false;
    }
    return _checkForExtendsOrImplementsDisallowedClass(
      superclass,
      CompileTimeErrorCode.extendsDisallowedClass,
    );
  }

  /// Verify that the given [namedType] does not extend, implement or mixin
  /// classes that are deferred.
  ///
  /// See [_checkForExtendsDeferredClass],
  /// [_checkForAllMixinErrorCodes],
  /// [CompileTimeErrorCode.extendsDeferredClass],
  /// [CompileTimeErrorCode.implementsDeferredClass], and
  /// [CompileTimeErrorCode.mixinDeferredClass].
  bool _checkForExtendsOrImplementsDeferredClass(
    NamedType namedType,
    DiagnosticCode code,
  ) {
    if (namedType.isSynthetic) {
      return false;
    }
    if (namedType.isDeferred) {
      diagnosticReporter.atNode(namedType, code);
      return true;
    }
    return false;
  }

  /// Verify that the given [namedType] does not extend, implement or mixin
  /// classes such as 'num' or 'String'.
  ///
  // TODO(scheglov): Remove this method, when all inheritance / override
  // is concentrated. We keep it for now only because we need to know when
  // inheritance is completely wrong, so that we don't need to check anything
  // else.
  bool _checkForExtendsOrImplementsDisallowedClass(
    NamedType namedType,
    DiagnosticCode code,
  ) {
    if (namedType.isSynthetic) {
      return false;
    }
    // The SDK implementation may implement disallowed types. For example,
    // JSNumber in dart2js and _Smi in Dart VM both implement int.
    if (_currentLibrary.uri.isScheme('dart')) {
      return false;
    }
    var type = namedType.type;
    return type is InterfaceType &&
        _typeProvider.isNonSubtypableClass(type.element);
  }

  void _checkForExtensionDeclaresInstanceField(FieldDeclaration node) {
    if (node.parent is! ExtensionDeclaration) {
      return;
    }

    if (node.isStatic || node.externalKeyword != null) {
      return;
    }

    for (var field in node.fields.variables) {
      diagnosticReporter.atToken(
        field.name,
        CompileTimeErrorCode.extensionDeclaresInstanceField,
      );
    }
  }

  void _checkForExtensionDeclaresMemberOfObject(MethodDeclaration node) {
    if (_enclosingExtension != null) {
      if (node.hasObjectMemberName) {
        diagnosticReporter.atToken(
          node.name,
          CompileTimeErrorCode.extensionDeclaresMemberOfObject,
        );
      }
    }

    if (_enclosingClass is ExtensionTypeElement) {
      if (node.hasObjectMemberName) {
        diagnosticReporter.atToken(
          node.name,
          CompileTimeErrorCode.extensionTypeDeclaresMemberOfObject,
        );
      }
    }
  }

  void _checkForExtensionTypeConstructorWithSuperInvocation(
    SuperConstructorInvocation node,
  ) {
    if (_enclosingClass is ExtensionTypeElement) {
      diagnosticReporter.atToken(
        node.superKeyword,
        CompileTimeErrorCode.extensionTypeConstructorWithSuperInvocation,
      );
    }
  }

  void _checkForExtensionTypeDeclaresInstanceField(FieldDeclaration node) {
    if (_enclosingClass is! ExtensionTypeElement) {
      return;
    }

    if (node.isStatic || node.externalKeyword != null) {
      return;
    }

    for (var field in node.fields.variables) {
      diagnosticReporter.atToken(
        field.name,
        CompileTimeErrorCode.extensionTypeDeclaresInstanceField,
      );
    }
  }

  void _checkForExtensionTypeImplementsDeferred(
    ExtensionTypeDeclarationImpl node,
  ) {
    var clause = node.implementsClause;
    if (clause == null) {
      return;
    }

    for (var type in clause.interfaces) {
      _checkForExtendsOrImplementsDeferredClass(
        type,
        CompileTimeErrorCode.implementsDeferredClass,
      );
    }
  }

  void _checkForExtensionTypeImplementsItself(
    ExtensionTypeDeclarationImpl node,
    ExtensionTypeFragmentImpl fragment,
  ) {
    if (fragment.element.hasImplementsSelfReference) {
      diagnosticReporter.atToken(
        node.name,
        CompileTimeErrorCode.extensionTypeImplementsItself,
      );
    }
  }

  void _checkForExtensionTypeMemberConflicts({
    required ExtensionTypeDeclaration node,
    required ExtensionTypeElementImpl element,
  }) {
    void report(String memberName, List<ExecutableElement> candidates) {
      var contextMessages = candidates.map<DiagnosticMessage>((executable) {
        var nonSynthetic = executable.nonSynthetic;
        var container = executable.enclosingElement as InterfaceElement;
        return DiagnosticMessageImpl(
          filePath: executable.firstFragment.libraryFragment.source.fullName,
          offset: nonSynthetic.firstFragment.nameOffset!,
          length: nonSynthetic.firstFragment.name!.length,
          message: "Inherited from '${container.name}'",
          url: null,
        );
      }).toList();
      diagnosticReporter.atToken(
        node.name,
        CompileTimeErrorCode.extensionTypeInheritedMemberConflict,
        arguments: [node.name.lexeme, memberName],
        contextMessages: contextMessages,
      );
    }

    var interface = _inheritanceManager.getInterface(element);
    for (var conflict in interface.conflicts) {
      switch (conflict) {
        case CandidatesConflict _:
          report(conflict.name.name, conflict.candidates);
        case HasNonExtensionAndExtensionMemberConflict _:
          report(conflict.name.name, [
            ...conflict.nonExtension,
            ...conflict.extension,
          ]);
        case NotUniqueExtensionMemberConflict _:
          report(conflict.name.name, conflict.candidates);
      }
    }
  }

  void _checkForExtensionTypeRepresentationDependsOnItself(
    ExtensionTypeDeclarationImpl node,
    ExtensionTypeFragmentImpl fragment,
  ) {
    if (fragment.element.hasRepresentationSelfReference) {
      diagnosticReporter.atToken(
        node.name,
        CompileTimeErrorCode.extensionTypeRepresentationDependsOnItself,
      );
    }
  }

  void _checkForExtensionTypeRepresentationTypeBottom(
    ExtensionTypeDeclarationImpl node,
    ExtensionTypeFragmentImpl fragment,
  ) {
    var element = fragment.element;
    var representationType = element.representation.type;
    if (representationType.isBottom) {
      diagnosticReporter.atNode(
        node.representation.fieldType,
        CompileTimeErrorCode.extensionTypeRepresentationTypeBottom,
      );
    }
  }

  void _checkForExtensionTypeWithAbstractMember(
    ExtensionTypeDeclarationImpl node,
  ) {
    for (var member in node.members) {
      if (member is MethodDeclarationImpl && !member.isStatic) {
        if (member.isAbstract) {
          diagnosticReporter.atNode(
            member,
            CompileTimeErrorCode.extensionTypeWithAbstractMember,
            arguments: [member.name.lexeme, node.name.lexeme],
          );
        }
      }
    }
  }

  /// Verify that the given field formal [parameter] is in a constructor
  /// declaration.
  ///
  /// See [CompileTimeErrorCode.fieldInitializerOutsideConstructor].
  void _checkForFieldInitializingFormalRedirectingConstructor(
    FieldFormalParameter parameter,
  ) {
    // prepare the node that should be a ConstructorDeclaration
    var formalParameterList = parameter.parent;
    if (formalParameterList is! FormalParameterList) {
      formalParameterList = formalParameterList?.parent;
    }
    var constructor = formalParameterList?.parent;
    // now check whether the node is actually a ConstructorDeclaration
    if (constructor is ConstructorDeclaration) {
      // constructor cannot be a factory
      if (constructor.factoryKeyword != null) {
        diagnosticReporter.atNode(
          parameter,
          CompileTimeErrorCode.fieldInitializerFactoryConstructor,
        );
        return;
      }
      // constructor cannot have a redirection
      for (ConstructorInitializer initializer in constructor.initializers) {
        if (initializer is RedirectingConstructorInvocation) {
          diagnosticReporter.atNode(
            parameter,
            CompileTimeErrorCode.fieldInitializerRedirectingConstructor,
          );
          return;
        }
      }
    } else {
      diagnosticReporter.atNode(
        parameter,
        CompileTimeErrorCode.fieldInitializerOutsideConstructor,
      );
    }
  }

  /// Verify that the given variable declaration [list] has only initialized
  /// variables if the list is final or const.
  ///
  /// See [CompileTimeErrorCode.constNotInitialized], and
  /// [CompileTimeErrorCode.finalNotInitialized].
  void _checkForFinalNotInitialized(VariableDeclarationList list) {
    if (_isInNativeClass || list.isSynthetic) {
      return;
    }

    // Handled during resolution, with flow analysis.
    if (list.isFinal && list.parent is VariableDeclarationStatement) {
      return;
    }

    bool isConst = list.isConst;
    if (!(isConst || list.isFinal)) {
      return;
    }
    NodeList<VariableDeclaration> variables = list.variables;
    for (VariableDeclaration variable in variables) {
      if (variable.initializer == null) {
        if (isConst) {
          diagnosticReporter.atToken(
            variable.name,
            CompileTimeErrorCode.constNotInitialized,
            arguments: [variable.name.lexeme],
          );
        } else {
          var variableElement = variable.declaredFragment?.element;
          if (variableElement is FieldElement &&
              (variableElement.isAbstract || variableElement.isExternal)) {
            // Abstract and external fields can't be initialized, so no error.
          } else if (variableElement is TopLevelVariableElement &&
              variableElement.isExternal) {
            // External top level variables can't be initialized, so no error.
          } else if (!variable.isLate) {
            diagnosticReporter.atToken(
              variable.name,
              CompileTimeErrorCode.finalNotInitialized,
              arguments: [variable.name.lexeme],
            );
          }
        }
      }
    }
  }

  /// If there are no constructors in the given [members], verify that all
  /// final fields are initialized.  Cases in which there is at least one
  /// constructor are handled in [_checkForFinalNotInitialized].
  ///
  /// See [CompileTimeErrorCode.constNotInitialized], and
  /// [CompileTimeErrorCode.finalNotInitialized].
  void _checkForFinalNotInitializedInClass(
    InstanceFragmentImpl fragment,
    List<ClassMember> members,
  ) {
    if (fragment is InterfaceFragmentImpl) {
      var element = fragment.element;
      for (var constructor in element.constructors) {
        if (constructor.isGenerative && !constructor.isSynthetic) {
          return;
        }
      }
    }

    for (ClassMember classMember in members) {
      if (classMember is FieldDeclaration) {
        var fields = classMember.fields;
        _checkForFinalNotInitialized(fields);
        _checkForNotInitializedNonNullableInstanceFields(classMember);
      }
    }
  }

  /// Check that if a direct supertype of a node is final, then it must be in
  /// the same library.
  ///
  /// See [CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary],
  /// [CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary],
  /// [CompileTimeErrorCode.
  /// FINAL_CLASS_USED_AS_MIXIN_CONSTRAINT_OUTSIDE_OF_LIBRARY].
  void _checkForFinalSupertypeOutsideOfLibrary(
    NamedType? superclass,
    WithClause? withClause,
    ImplementsClause? implementsClause,
    MixinOnClause? onClause,
  ) {
    if (superclass != null) {
      var type = superclass.type;
      if (type is InterfaceType) {
        var element = type.element;
        if (element is ClassElementImpl &&
            element.isFinal &&
            !element.isSealed &&
            element.library != _currentLibrary &&
            !_mayIgnoreClassModifiers(element.library)) {
          diagnosticReporter.atNode(
            superclass,
            CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary,
            arguments: [element.name!],
          );
        }
      }
    }
    if (implementsClause != null) {
      for (NamedType namedType in implementsClause.interfaces) {
        var type = namedType.type;
        if (type is InterfaceType) {
          var implementedInterfaces = [
            type,
            ...type.element.allSupertypes,
          ].map((e) => e.element).toList();
          for (var element in implementedInterfaces) {
            if (element is ClassElement &&
                element.isFinal &&
                !element.isSealed &&
                element.library != _currentLibrary &&
                !_mayIgnoreClassModifiers(element.library)) {
              // If the final interface is an indirect interface and is in a
              // different library that has class modifiers enabled, there is a
              // nearer declaration that would emit an error, if any.
              if (element != type.element &&
                  type.element.library.featureSet.isEnabled(
                    Feature.class_modifiers,
                  )) {
                continue;
              }

              diagnosticReporter.atNode(
                namedType,
                CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
                arguments: [element.name!],
              );
              break;
            }
          }
        }
      }
    }
    if (onClause != null) {
      for (NamedType namedType in onClause.superclassConstraints) {
        var type = namedType.type;
        if (type is InterfaceType) {
          var element = type.element;
          if (element is ClassElement &&
              element.isFinal &&
              !element.isSealed &&
              element.library != _currentLibrary &&
              !_mayIgnoreClassModifiers(element.library)) {
            diagnosticReporter.atNode(
              namedType,
              CompileTimeErrorCode
                  .finalClassUsedAsMixinConstraintOutsideOfLibrary,
              arguments: [element.name!],
            );
          }
        }
      }
    }
  }

  void _checkForGenericFunctionType(TypeAnnotation? node) {
    if (node == null) {
      return;
    }
    if (_featureSet?.isEnabled(Feature.generic_metadata) ?? false) {
      return;
    }
    DartType type = node.typeOrThrow;
    if (type is FunctionType && type.typeParameters.isNotEmpty) {
      diagnosticReporter.atNode(
        node,
        CompileTimeErrorCode.genericFunctionTypeCannotBeBound,
      );
    }
  }

  void _checkForIllegalLanguageOverride(CompilationUnit node) {
    var sourceLanguageConstraint =
        (options as AnalysisOptionsImpl).sourceLanguageConstraint;
    if (sourceLanguageConstraint == null) {
      return;
    }

    var languageVersion = _currentLibrary.languageVersion.effective;
    if (sourceLanguageConstraint.allows(languageVersion)) {
      return;
    }

    var languageVersionToken = node.languageVersionToken;
    if (languageVersionToken != null) {
      diagnosticReporter.atToken(
        languageVersionToken,
        CompileTimeErrorCode.illegalLanguageVersionOverride,
        arguments: ['$sourceLanguageConstraint'],
      );
    }
  }

  /// Verify that the given implements [clause] does not implement classes such
  /// as 'num' or 'String'.
  ///
  /// See [CompileTimeErrorCode.implementsDisallowedClass],
  /// [CompileTimeErrorCode.implementsDeferredClass].
  bool _checkForImplementsClauseErrorCodes(ImplementsClause? clause) {
    if (clause == null) {
      return false;
    }
    bool foundError = false;
    for (NamedType type in clause.interfaces) {
      if (_checkForExtendsOrImplementsDisallowedClass(
        type,
        CompileTimeErrorCode.implementsDisallowedClass,
      )) {
        foundError = true;
      } else if (_checkForExtendsOrImplementsDeferredClass(
        type,
        CompileTimeErrorCode.implementsDeferredClass,
      )) {
        foundError = true;
      }
    }
    return foundError;
  }

  /// Check that if the visiting library is not system, then any given library
  /// should not be SDK internal library. The [importElement] is the
  /// [LibraryImport] retrieved from the node, if the element in the node
  /// was `null`, then this method is not called.
  void _checkForImportInternalLibrary(
    ImportDirective directive,
    LibraryImport importElement,
  ) {
    if (_isInSystemLibrary || _isWasm(importElement)) {
      return;
    }

    var importedLibrary = importElement.importedLibrary;
    if (importedLibrary == null) {
      return;
    }

    // should be private
    if (!(importedLibrary as LibraryElementImpl).isInternalSdkLibrary) {
      return;
    }
    // The only way an import URI's `stringValue` can be `null` is if the string
    // contained interpolations, in which case the import would have failed to
    // resolve, and we would never reach here.  So it is safe to assume that
    // `directive.uri.stringValue` is non-`null`.
    diagnosticReporter.atNode(
      directive.uri,
      CompileTimeErrorCode.importInternalLibrary,
      arguments: [directive.uri.stringValue!],
    );
  }

  /// Check that the given [typeReference] is not a type reference and that then
  /// the [name] is reference to an instance member.
  ///
  /// See [CompileTimeErrorCode.instanceAccessToStaticMember].
  void _checkForInstanceAccessToStaticMember(
    InterfaceElement? typeReference,
    Expression? target,
    SimpleIdentifier name,
  ) {
    if (_isInComment) {
      // OK, in comment
      return;
    }
    // prepare member Element
    var element = name.writeOrReadElement;
    if (element is ExecutableElement) {
      if (!element.isStatic) {
        // OK, instance member
        return;
      }
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is ExtensionElement) {
        if (target is ExtensionOverride) {
          // OK, target is an extension override
          return;
        } else if (target is SimpleIdentifier &&
            target.element is ExtensionElement) {
          return;
        } else if (target is PrefixedIdentifier &&
            target.element is ExtensionElement) {
          return;
        }
      } else {
        if (typeReference != null) {
          // OK, target is a type
          return;
        }
        if (enclosingElement is! InterfaceElement) {
          // OK, top-level element
          return;
        }
      }
    }
  }

  /// Verify that if a class is extending an interface class or mixing in an
  /// interface mixin, it must be within the same library as that class or
  /// mixin.
  ///
  /// See
  /// [CompileTimeErrorCode.interfaceClassExtendedOutsideOfLibrary].
  void _checkForInterfaceClassOrMixinSuperclassOutsideOfLibrary(
    NamedType? superclass,
    WithClause? withClause,
  ) {
    if (superclass != null) {
      var superclassType = superclass.type;
      if (superclassType is InterfaceType) {
        var superclassElement = superclassType.element;
        if (superclassElement is ClassElementImpl &&
            superclassElement.isInterface &&
            !superclassElement.isSealed &&
            superclassElement.library != _currentLibrary &&
            !_mayIgnoreClassModifiers(superclassElement.library)) {
          diagnosticReporter.atNode(
            superclass,
            CompileTimeErrorCode.interfaceClassExtendedOutsideOfLibrary,
            arguments: [superclassElement.name!],
          );
        }
      }
    }
  }

  /// Verify that an 'int' can be assigned to the parameter corresponding to the
  /// given [argument]. This is used for prefix and postfix expressions where
  /// the argument value is implicit.
  ///
  /// See [CompileTimeErrorCode.argumentTypeNotAssignable].
  void _checkForIntNotAssignable(ExpressionImpl argument) {
    var parameterElement = argument.correspondingParameter;
    var parameterType = parameterElement?.type;
    if (parameterType != null) {
      checkForArgumentTypeNotAssignable(
        argument,
        parameterType,
        _intType,
        CompileTimeErrorCode.argumentTypeNotAssignable,
      );
    }
  }

  /// Verify that the given [annotation] isn't defined in a deferred library.
  ///
  /// See [CompileTimeErrorCode.invalidAnnotationFromDeferredLibrary].
  void _checkForInvalidAnnotationFromDeferredLibrary(Annotation annotation) {
    Identifier nameIdentifier = annotation.name;
    if (nameIdentifier is PrefixedIdentifier && nameIdentifier.isDeferred) {
      diagnosticReporter.atNode(
        annotation.name,
        CompileTimeErrorCode.invalidAnnotationFromDeferredLibrary,
      );
    }
  }

  /// Check the given [initializer] to ensure that the field being initialized
  /// is a valid field. The [fieldName] is the field name from the
  /// [ConstructorFieldInitializer]. The [staticElement] is the static element
  /// from the name in the [ConstructorFieldInitializer].
  void _checkForInvalidField(
    ConstructorFieldInitializer initializer,
    SimpleIdentifier fieldName,
    Element? staticElement,
  ) {
    if (staticElement is FieldElement) {
      if (staticElement.isSynthetic) {
        diagnosticReporter.atNode(
          initializer,
          CompileTimeErrorCode.initializerForNonExistentField,
          arguments: [fieldName.name],
        );
      } else if (staticElement.isStatic) {
        diagnosticReporter.atNode(
          initializer,
          CompileTimeErrorCode.initializerForStaticField,
          arguments: [fieldName.name],
        );
      }
    } else {
      diagnosticReporter.atNode(
        initializer,
        CompileTimeErrorCode.initializerForNonExistentField,
        arguments: [fieldName.name],
      );
      return;
    }
  }

  /// Verify that we're not using an enum constructor anywhere other than to
  /// create an enum constant or as a target of constructor redirection.
  void _checkForInvalidGenerativeConstructorReference(
    AstNode node,
    ConstructorElement? constructorElement,
  ) {
    if (constructorElement != null &&
        constructorElement.isGenerative &&
        constructorElement.enclosingElement is EnumElement) {
      if (_currentLibrary.featureSet.isEnabled(Feature.enhanced_enums)) {
        diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.invalidReferenceToGenerativeEnumConstructor,
        );
      } else {
        diagnosticReporter.atNode(node, CompileTimeErrorCode.instantiateEnum);
      }
    }
  }

  /// Verify that if the given [identifier] is part of a constructor
  /// initializer, then it does not implicitly reference 'this' expression.
  ///
  /// See [CompileTimeErrorCode.implicitThisReferenceInInitializer],
  /// [CompileTimeErrorCode.instanceMemberAccessFromFactory], and
  /// [CompileTimeErrorCode.instanceMemberAccessFromStatic].
  void _checkForInvalidInstanceMemberAccess(SimpleIdentifier identifier) {
    if (_isInComment) {
      return;
    }
    if (!_isInConstructorInitializer &&
        !_enclosingExecutable.inStaticMethod &&
        !_enclosingExecutable.inFactoryConstructor &&
        !_isInInstanceNotLateVariableDeclaration &&
        !_isInStaticVariableDeclaration) {
      return;
    }
    // prepare element
    var element = identifier.writeOrReadElement;
    if (!(element is MethodElement || element is PropertyAccessorElement)) {
      return;
    }
    // static element
    ExecutableElement executableElement = element as ExecutableElement;
    if (executableElement.isStatic) {
      return;
    }
    // not a class member
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement &&
        enclosingElement is! ExtensionElement) {
      return;
    }
    // qualified method invocation
    var parent = identifier.parent;
    if (parent is MethodInvocation) {
      if (identical(parent.methodName, identifier) &&
          parent.realTarget != null) {
        return;
      }
    }
    // qualified property access
    if (parent is PropertyAccess) {
      if (identical(parent.propertyName, identifier)) {
        return;
      }
    }
    if (parent is PrefixedIdentifier) {
      if (identical(parent.identifier, identifier)) {
        return;
      }
    }

    if (_enclosingExecutable.inStaticMethod) {
      diagnosticReporter.atNode(
        identifier,
        CompileTimeErrorCode.instanceMemberAccessFromStatic,
      );
    } else if (_enclosingExecutable.inFactoryConstructor) {
      diagnosticReporter.atNode(
        identifier,
        CompileTimeErrorCode.instanceMemberAccessFromFactory,
      );
    } else {
      diagnosticReporter.atNode(
        identifier,
        CompileTimeErrorCode.implicitThisReferenceInInitializer,
        arguments: [identifier.name],
      );
    }
  }

  /// Check to see whether the given function [body] has a modifier associated
  /// with it, and report it as an error if it does.
  void _checkForInvalidModifierOnBody(
    FunctionBody body,
    CompileTimeErrorCode errorCode,
  ) {
    var keyword = body.keyword;
    if (keyword != null) {
      diagnosticReporter.atToken(
        keyword,
        errorCode,
        arguments: [keyword.lexeme],
      );
    }
  }

  /// Verify that the usage of the given 'this' is valid.
  ///
  /// See [CompileTimeErrorCode.invalidReferenceToThis].
  void _checkForInvalidReferenceToThis(ThisExpression expression) {
    if (!_hasAccessToThis) {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.invalidReferenceToThis,
      );
    }
  }

  void _checkForLateFinalFieldWithConstConstructor(FieldDeclaration node) {
    if (node.isStatic) return;

    var variableList = node.fields;
    if (!variableList.isFinal) return;

    var lateKeyword = variableList.lateKeyword;
    if (lateKeyword == null) return;

    var enclosingClass = _enclosingClass;
    if (enclosingClass == null) {
      // The field is in an extension and should be handled elsewhere.
      return;
    }

    var hasGenerativeConstConstructor = enclosingClass.constructors.any(
      (c) => c.isConst && !c.isFactory,
    );
    if (!hasGenerativeConstConstructor) return;

    diagnosticReporter.atToken(
      lateKeyword,
      CompileTimeErrorCode.lateFinalFieldWithConstConstructor,
    );
  }

  /// Verify that the elements of the given list [literal] are subtypes of the
  /// list's static type.
  ///
  /// See [CompileTimeErrorCode.listElementTypeNotAssignable].
  void _checkForListElementTypeNotAssignable(ListLiteral literal) {
    // Determine the list's element type. We base this on the static type and
    // not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType listType = literal.typeOrThrow;
    assert(listType is InterfaceTypeImpl);

    var typeArguments = (listType as InterfaceTypeImpl).typeArguments;
    assert(typeArguments.length == 1);

    var listElementType = typeArguments[0];

    // Check every list element.
    var verifier = LiteralElementVerifier(
      _typeProvider,
      typeSystem,
      diagnosticReporter,
      this,
      forList: true,
      elementType: listElementType,
      featureSet: _featureSet!,
    );
    for (CollectionElement element in literal.elements) {
      verifier.verify(element);
    }
  }

  void _checkForMainFunction1(Token nameToken, Fragment declaredFragment) {
    // We should only check exported declarations, i.e. top-level.
    if (declaredFragment.enclosingFragment is! LibraryFragment) {
      return;
    }

    if (declaredFragment.name != 'main') {
      return;
    }

    if (declaredFragment is! TopLevelFunctionFragment) {
      diagnosticReporter.atToken(
        nameToken,
        CompileTimeErrorCode.mainIsNotFunction,
      );
    }
  }

  void _checkForMainFunction2(FunctionDeclarationImpl functionDeclaration) {
    if (functionDeclaration.name.lexeme != 'main') {
      return;
    }

    if (functionDeclaration.parent is! CompilationUnit) {
      return;
    }

    var parameterList = functionDeclaration.functionExpression.parameters;
    if (parameterList == null) {
      return;
    }

    var parameters = parameterList.parameters;
    var positional = parameters.where((e) => e.isPositional).toList();
    var requiredPositional = parameters
        .where((e) => e.isRequiredPositional)
        .toList();

    if (requiredPositional.length > 2) {
      diagnosticReporter.atToken(
        functionDeclaration.name,
        CompileTimeErrorCode.mainHasTooManyRequiredPositionalParameters,
      );
    }

    if (parameters.any((e) => e.isRequiredNamed)) {
      diagnosticReporter.atToken(
        functionDeclaration.name,
        CompileTimeErrorCode.mainHasRequiredNamedParameters,
      );
    }

    if (positional.isNotEmpty) {
      var first = positional.first;
      var type = first.declaredFragment!.element.type;
      var listOfString = _typeProvider.listType(_typeProvider.stringType);
      if (!typeSystem.isSubtypeOf(listOfString, type)) {
        diagnosticReporter.atNode(
          first.notDefault.typeOrSelf,
          CompileTimeErrorCode.mainFirstPositionalParameterType,
        );
      }
    }
  }

  void _checkForMapTypeNotAssignable(SetOrMapLiteral literal) {
    // Determine the map's key and value types. We base this on the static type
    // and not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType mapType = literal.typeOrThrow;
    assert(mapType is InterfaceTypeImpl);

    var typeArguments = (mapType as InterfaceTypeImpl).typeArguments;
    // It is possible for the number of type arguments to be inconsistent when
    // the literal is ambiguous and a non-map type was selected.
    // TODO(brianwilkerson): Unify this and _checkForSetElementTypeNotAssignable3
    //  to better handle recovery situations.
    if (typeArguments.length == 2) {
      var keyType = typeArguments[0];
      var valueType = typeArguments[1];

      var verifier = LiteralElementVerifier(
        _typeProvider,
        typeSystem,
        diagnosticReporter,
        this,
        forMap: true,
        mapKeyType: keyType,
        mapValueType: valueType,
        featureSet: _featureSet!,
      );
      for (CollectionElement element in literal.elements) {
        verifier.verify(element);
      }
    }
  }

  /// Check to make sure that the given switch [statement] whose static type is
  /// an enum type either have a default case or include all of the enum
  /// constants.
  void _checkForMissingEnumConstantInSwitch(SwitchStatement statement) {
    if (_currentLibrary.featureSet.isEnabled(Feature.patterns)) {
      // Exhaustiveness checking cover this warning.
      return;
    }

    // TODO(brianwilkerson): This needs to be checked after constant values have
    // been computed.
    var expressionType = statement.expression.staticType;

    var hasCaseNull = false;
    if (expressionType is InterfaceType) {
      var enumElement = expressionType.element;
      if (enumElement is EnumElement) {
        var constantNames = enumElement.fields
            .where((field) => field.isEnumConstant)
            .map((field) => field.name)
            .toSet();

        for (var member in statement.members) {
          Expression? caseConstant;
          if (member is SwitchCase) {
            caseConstant = member.expression;
          } else if (member is SwitchPatternCase) {
            var guardedPattern = member.guardedPattern;
            if (guardedPattern.whenClause == null) {
              var pattern = guardedPattern.pattern.unParenthesized;
              if (pattern is ConstantPattern) {
                caseConstant = pattern.expression;
              }
            }
          }
          if (caseConstant != null) {
            var expression = caseConstant.unParenthesized;
            if (expression is NullLiteral) {
              hasCaseNull = true;
            } else {
              var constantName = _getConstantName(expression);
              constantNames.remove(constantName);
            }
          }
          if (member is SwitchDefault) {
            return;
          }
        }

        for (var constantName in constantNames) {
          int offset = statement.offset;
          int end = statement.rightParenthesis.end;
          diagnosticReporter.atOffset(
            offset: offset,
            length: end - offset,
            diagnosticCode: StaticWarningCode.missingEnumConstantInSwitch,
            arguments: [constantName!],
          );
        }

        if (typeSystem.isNullable(expressionType) && !hasCaseNull) {
          int offset = statement.offset;
          int end = statement.rightParenthesis.end;
          diagnosticReporter.atOffset(
            offset: offset,
            length: end - offset,
            diagnosticCode: StaticWarningCode.missingEnumConstantInSwitch,
            arguments: ['null'],
          );
        }
      }
    }
  }

  /// Verify that the given mixin does not have an explicitly declared
  /// constructor. The [mixinName] is the node to report problem on. The
  /// [mixinElement] is the mixing to evaluate.
  ///
  /// See [CompileTimeErrorCode.mixinClassDeclaresConstructor].
  bool _checkForMixinClassDeclaresConstructor(
    NamedType mixinName,
    InterfaceElement mixinElement,
  ) {
    for (var constructor in mixinElement.constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        diagnosticReporter.atNode(
          mixinName,
          CompileTimeErrorCode.mixinClassDeclaresConstructor,
          arguments: [mixinElement.name!],
        );
        return true;
      }
    }
    return false;
  }

  /// Verify that mixin classes must have 'Object' as their superclass and that
  /// they do not have a constructor.
  ///
  /// See [CompileTimeErrorCode.mixinClassDeclaresConstructor],
  /// [CompileTimeErrorCode.mixinInheritsFromNotObject].
  void _checkForMixinClassErrorCodes(
    NamedCompilationUnitMember node,
    List<ClassMember> members,
    NamedType? superclass,
    WithClause? withClause,
  ) {
    var element = node.declaredFragment?.element;
    if (element is ClassElementImpl && element.isMixinClass) {
      // Check that the class does not have a constructor.
      for (ClassMember member in members) {
        if (member is ConstructorDeclarationImpl) {
          if (!member.isSynthetic && member.factoryKeyword == null) {
            // Report errors on non-trivial generative constructors on mixin
            // classes.
            if (!member.isTrivial) {
              diagnosticReporter.atNode(
                member.returnType,
                CompileTimeErrorCode.mixinClassDeclaresConstructor,
                arguments: [element.name!],
              );
            }
          }
        }
      }
      // Check that the class has 'Object' as their superclass.
      if (superclass != null && !superclass.typeOrThrow.isDartCoreObject) {
        diagnosticReporter.atNode(
          superclass,
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          arguments: [element.name!],
        );
      } else if (withClause != null &&
          !(element.isMixinApplication && withClause.mixinTypes.length < 2)) {
        diagnosticReporter.atNode(
          withClause,
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          arguments: [element.name!],
        );
      }
    }
  }

  /// Verify that the given mixin has the 'Object' superclass.
  ///
  /// The [mixinName] is the node to report problem on. The [mixinElement] is
  /// the mixing to evaluate.
  ///
  /// See [CompileTimeErrorCode.mixinInheritsFromNotObject].
  bool _checkForMixinInheritsNotFromObject(
    NamedType mixinName,
    InterfaceElement mixinElement,
  ) {
    if (mixinElement is! ClassElement) {
      return false;
    }

    var mixinSupertype = mixinElement.supertype;
    if (mixinSupertype == null || mixinSupertype.isDartCoreObject) {
      var mixins = mixinElement.mixins;
      if (mixins.isEmpty ||
          mixinElement.isMixinApplication && mixins.length < 2) {
        return false;
      }
    }

    diagnosticReporter.atNode(
      mixinName,
      CompileTimeErrorCode.mixinInheritsFromNotObject,
      arguments: [mixinElement.name!],
    );
    return true;
  }

  /// Check that superclass constrains for the mixin type of [mixinName] at
  /// the [mixinIndex] position in the mixins list are satisfied by the
  /// [_enclosingClass], or a previous mixin.
  bool _checkForMixinSuperclassConstraints(
    int mixinIndex,
    NamedTypeImpl mixinName,
  ) {
    var mixinType = mixinName.type as InterfaceTypeImpl;
    for (var constraint in mixinType.superclassConstraints) {
      var superType = _enclosingClass!.supertype as InterfaceTypeImpl;
      superType = superType.withNullability(NullabilitySuffix.none);

      bool isSatisfied = typeSystem.isSubtypeOf(superType, constraint);
      if (!isSatisfied) {
        for (int i = 0; i < mixinIndex && !isSatisfied; i++) {
          isSatisfied = typeSystem.isSubtypeOf(
            _enclosingClass!.mixins[i],
            constraint,
          );
        }
      }
      if (!isSatisfied) {
        // This error can only occur if [mixinName] resolved to an actual mixin,
        // so we can safely rely on `mixinName.type` being non-`null`.
        diagnosticReporter.atToken(
          mixinName.name,
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          arguments: [mixinName.type!, superType, constraint],
        );
        return true;
      }
    }
    return false;
  }

  /// Check that the superclass of the given [mixinElement] at the given
  /// [mixinIndex] in the list of mixins of [_enclosingClass] has concrete
  /// implementations of all the super-invoked members of the [mixinElement].
  bool _checkForMixinSuperInvokedMembers(
    int mixinIndex,
    NamedType mixinName,
    InterfaceElement mixinElement,
    InterfaceType mixinType,
  ) {
    var mixinElementImpl = mixinElement as MixinElementImpl;
    if (mixinElementImpl.superInvokedNames.isEmpty) {
      return false;
    }

    Uri mixinLibraryUri = mixinElement.library.uri;
    for (var name in mixinElementImpl.superInvokedNames) {
      var nameObject = Name(mixinLibraryUri, name);

      var superMember = _inheritanceManager.getMember(
        _enclosingClass!,
        nameObject,
        forMixinIndex: mixinIndex,
        concrete: true,
        forSuper: true,
      );

      if (superMember == null) {
        var isSetter = name.endsWith('=');

        var errorCode = isSetter
            ? CompileTimeErrorCode.mixinApplicationNoConcreteSuperInvokedSetter
            : CompileTimeErrorCode.mixinApplicationNoConcreteSuperInvokedMember;

        if (isSetter) {
          name = name.substring(0, name.length - 1);
        }

        diagnosticReporter.atNode(mixinName, errorCode, arguments: [name]);
        return true;
      }

      var mixinMember = _inheritanceManager.getMember3(
        mixinType,
        nameObject,
        forSuper: true,
      );

      if (mixinMember != null) {
        var isCorrect = CorrectOverrideHelper(
          typeSystem: typeSystem,
          thisMember: superMember,
        ).isCorrectOverrideOf(superMember: mixinMember);
        if (!isCorrect) {
          diagnosticReporter.atNode(
            mixinName,
            CompileTimeErrorCode.mixinApplicationConcreteSuperInvokedMemberType,
            arguments: [name, mixinMember.type, superMember.type],
          );
          return true;
        }
      }
    }
    return false;
  }

  /// Check for the declaration of a mixin from a library other than the current
  /// library that defines a private member that conflicts with a private name
  /// from the same library but from a superclass or a different mixin.
  void _checkForMixinWithConflictingPrivateMember(
    WithClause? withClause,
    NamedType? superclassName,
  ) {
    if (withClause == null) {
      return;
    }
    var declaredSupertype = superclassName?.type ?? _typeProvider.objectType;
    if (declaredSupertype is! InterfaceType) {
      return;
    }
    var mixedInNames = <LibraryElement, Map<String, String>>{};

    /// Report an error and return `true` if the given [name] is a private name
    /// (which is defined in the given [library]) and it conflicts with another
    /// definition of that name inherited from the superclass.
    bool isConflictingName(
      String name,
      LibraryElement library,
      NamedType namedType,
    ) {
      if (Identifier.isPrivateName(name)) {
        Map<String, String> names = mixedInNames.putIfAbsent(library, () => {});
        var conflictingName = names[name];
        if (conflictingName != null) {
          if (name.endsWith('=')) {
            name = name.substring(0, name.length - 1);
          }
          diagnosticReporter.atNode(
            namedType,
            CompileTimeErrorCode.privateCollisionInMixinApplication,
            arguments: [name, namedType.name.lexeme, conflictingName],
          );
          return true;
        }
        names[name] = namedType.name.lexeme;
        var inheritedMember = _inheritanceManager.getMember(
          declaredSupertype.element,
          Name(library.uri, name),
          concrete: true,
        );
        if (inheritedMember != null) {
          if (name.endsWith('=')) {
            name = name.substring(0, name.length - 1);
          }
          // Inherited members are always contained inside named elements, so we
          // can safely assume `inheritedMember.enclosingElement3.name` is
          // non-`null`.
          diagnosticReporter.atNode(
            namedType,
            CompileTimeErrorCode.privateCollisionInMixinApplication,
            arguments: [
              name,
              namedType.name.lexeme,
              inheritedMember.enclosingElement!.name!,
            ],
          );
          return true;
        }
      }
      return false;
    }

    for (NamedType mixinType in withClause.mixinTypes) {
      DartType type = mixinType.typeOrThrow;
      if (type is InterfaceType) {
        var library = type.element.library;
        if (library != _currentLibrary) {
          for (var getter in type.getters) {
            if (getter.isStatic) {
              continue;
            }
            if (isConflictingName(getter.lookupName!, library, mixinType)) {
              return;
            }
          }
          for (var setter in type.setters) {
            if (setter.isStatic) {
              continue;
            }
            if (isConflictingName(setter.lookupName!, library, mixinType)) {
              return;
            }
          }
          for (var method in type.methods) {
            if (method.isStatic) {
              continue;
            }
            if (isConflictingName(method.lookupName!, library, mixinType)) {
              return;
            }
          }
        }
      }
    }
  }

  /// Checks to ensure that the given native function [body] is in SDK code.
  ///
  /// See [ParserErrorCode.nativeFunctionBodyInNonSdkCode].
  void _checkForNativeFunctionBodyInNonSdkCode(NativeFunctionBody body) {
    if (!_isInSystemLibrary) {
      diagnosticReporter.atNode(
        body,
        ParserErrorCode.nativeFunctionBodyInNonSdkCode,
      );
    }
  }

  /// Verify that the given instance creation [expression] invokes an existing
  /// constructor. The [constructorName] is the constructor name.
  /// The [namedType] is the name of the type defining the constructor.
  ///
  /// This method assumes that the instance creation was tested to be 'new'
  /// before being called.
  ///
  /// See [CompileTimeErrorCode.newWithUndefinedConstructor].
  void _checkForNewWithUndefinedConstructor(
    InstanceCreationExpression expression,
    ConstructorName constructorName,
    NamedType namedType,
  ) {
    // OK if resolved
    if (constructorName.element != null) {
      return;
    }
    DartType type = namedType.typeOrThrow;
    if (type is InterfaceType) {
      var element = type.element;
      if (element is EnumElement || element is MixinElement) {
        // We have already reported the error.
        return;
      }
    }
    // report as named or default constructor absence
    var name = constructorName.name;
    if (name != null) {
      diagnosticReporter.atNode(
        name,
        CompileTimeErrorCode.newWithUndefinedConstructor,
        arguments: [namedType.qualifiedName, name.name],
      );
    } else {
      diagnosticReporter.atNode(
        constructorName,
        CompileTimeErrorCode.newWithUndefinedConstructorDefault,
        arguments: [namedType.qualifiedName],
      );
    }
  }

  /// Check that if the given class [fragment] implicitly calls default
  /// constructor of its superclass, there should be such default constructor -
  /// implicit or explicit.
  ///
  /// See [CompileTimeErrorCode.noDefaultSuperConstructorImplicit].
  void _checkForNoDefaultSuperConstructorImplicit(ClassFragmentImpl fragment) {
    // do nothing if there is explicit constructor
    var constructors = fragment.element.constructors;
    if (!constructors[0].isSynthetic) {
      return;
    }
    // prepare super
    var superType = fragment.element.supertype;
    if (superType == null) {
      return;
    }
    var superElement = superType.element;
    // try to find default generative super constructor
    var superUnnamedConstructor = superElement.unnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        diagnosticReporter.atElement2(
          fragment.asElement2,
          CompileTimeErrorCode.nonGenerativeImplicitConstructor,
          arguments: [
            superElement.name ?? '',
            fragment.name ?? '',
            superUnnamedConstructor,
          ],
        );
        return;
      }
      if (superUnnamedConstructor.isDefaultConstructor) {
        return;
      }
    }

    if (!_typeProvider.isNonSubtypableClass(superType.element)) {
      // Don't report this diagnostic for non-subtypable classes because the
      // real problem was already reported.
      diagnosticReporter.atElement2(
        fragment.asElement2,
        CompileTimeErrorCode.noDefaultSuperConstructorImplicit,
        arguments: [superType, fragment.displayName],
      );
    }
  }

  bool _checkForNoGenerativeConstructorsInSuperclass(NamedType? superclass) {
    var superType = _enclosingClass!.supertype;
    if (superType == null) {
      return false;
    }
    if (_enclosingClass!.constructors.every(
      (constructor) => constructor.isFactory,
    )) {
      // A class with no generative constructors *can* be extended if the
      // subclass has only factory constructors.
      return false;
    }
    var superElement = superType.element;
    if (superElement.constructors.isEmpty) {
      // Exclude empty constructor set, which indicates other errors occurred.
      return false;
    }
    if (superElement.constructors.every(
      (constructor) => constructor.isFactory,
    )) {
      // For `E extends Exception`, etc., this will never work, because it has
      // no generative constructors. State this clearly to users.
      diagnosticReporter.atNode(
        superclass!,
        CompileTimeErrorCode.noGenerativeConstructorsInSuperclass,
        arguments: [_enclosingClass!.name!, superElement.name!],
      );
      return true;
    }
    return false;
  }

  void _checkForNonConstGenerativeEnumConstructor(ConstructorDeclaration node) {
    if (_enclosingClass is EnumElement &&
        node.constKeyword == null &&
        node.factoryKeyword == null) {
      diagnosticReporter.atConstructorDeclaration(
        node,
        CompileTimeErrorCode.nonConstGenerativeEnumConstructor,
      );
    }
  }

  /// Verify the given map [literal] either:
  /// * has `const modifier`
  /// * has explicit type arguments
  /// * is not start of the statement
  ///
  /// See [CompileTimeErrorCode.nonConstMapAsExpressionStatement].
  void _checkForNonConstMapAsExpressionStatement3(SetOrMapLiteral literal) {
    // "const"
    if (literal.constKeyword != null) {
      return;
    }
    // has type arguments
    if (literal.typeArguments != null) {
      return;
    }
    // prepare statement
    var statement = literal.thisOrAncestorOfType<ExpressionStatement>();
    if (statement == null) {
      return;
    }
    // OK, statement does not start with map
    if (!identical(statement.beginToken, literal.beginToken)) {
      return;
    }

    // TODO(srawlins): Add any tests showing this is reported.
    diagnosticReporter.atNode(
      literal,
      CompileTimeErrorCode.nonConstMapAsExpressionStatement,
    );
  }

  void _checkForNonCovariantTypeParameterPositionInRepresentationType(
    ExtensionTypeDeclaration node,
    ExtensionTypeFragmentImpl fragment,
  ) {
    var typeParameters = node.typeParameters?.typeParameters;
    if (typeParameters == null) {
      return;
    }

    var element = fragment.element;
    var representationType = element.representation.type;

    for (var typeParameterNode in typeParameters) {
      var typeParameterElement = typeParameterNode.declaredFragment!.element;
      var nonCovariant = representationType.accept(
        NonCovariantTypeParameterPositionVisitor([
          typeParameterElement,
        ], initialVariance: Variance.covariant),
      );
      if (nonCovariant) {
        diagnosticReporter.atNode(
          typeParameterNode,
          CompileTimeErrorCode
              .nonCovariantTypeParameterPositionInRepresentationType,
        );
      }
    }
  }

  void _checkForNonFinalFieldInEnum(FieldDeclaration node) {
    if (node.isStatic) return;

    var variableList = node.fields;
    if (variableList.isFinal) return;

    var enclosingClass = _enclosingClass;
    if (enclosingClass == null || enclosingClass is! EnumElement) {
      return;
    }

    diagnosticReporter.atToken(
      variableList.variables.first.name,
      CompileTimeErrorCode.nonFinalFieldInEnum,
    );
  }

  /// Verify that the given method [declaration] of operator `[]=`, has `void`
  /// return type.
  ///
  /// See [CompileTimeErrorCode.nonVoidReturnForOperator].
  void _checkForNonVoidReturnTypeForOperator(MethodDeclaration declaration) {
    // check that []= operator
    if (declaration.name.lexeme != "[]=") {
      return;
    }
    // check return type
    var annotation = declaration.returnType;
    if (annotation != null) {
      DartType type = annotation.typeOrThrow;
      if (type is! VoidType) {
        diagnosticReporter.atNode(
          annotation,
          CompileTimeErrorCode.nonVoidReturnForOperator,
        );
      }
    }
  }

  /// Verify the [namedType], used as the return type of a setter, is valid
  /// (either `null` or the type 'void').
  ///
  /// See [CompileTimeErrorCode.nonVoidReturnForSetter].
  void _checkForNonVoidReturnTypeForSetter(TypeAnnotation? namedType) {
    if (namedType != null) {
      DartType type = namedType.typeOrThrow;
      if (type is! VoidType) {
        diagnosticReporter.atNode(
          namedType,
          CompileTimeErrorCode.nonVoidReturnForSetter,
        );
      }
    }
  }

  void _checkForNotInitializedNonNullableInstanceFields(
    FieldDeclaration fieldDeclaration,
  ) {
    if (fieldDeclaration.isStatic) return;
    var fields = fieldDeclaration.fields;

    if (fields.isLate) return;
    if (fields.isFinal) return;

    if (_isEnclosingClassFfiStruct) return;
    if (_isEnclosingClassFfiUnion) return;

    for (var field in fields.variables) {
      var fieldElement = field.declaredFragment?.element as FieldElement;
      if (fieldElement.isAbstract || fieldElement.isExternal) continue;
      if (field.initializer != null) continue;

      var type = fieldElement.type;
      if (!typeSystem.isPotentiallyNonNullable(type)) continue;

      diagnosticReporter.atNode(
        field,
        CompileTimeErrorCode.notInitializedNonNullableInstanceField,
        arguments: [field.name.lexeme],
      );
    }
  }

  void _checkForNotInitializedNonNullableStaticField(FieldDeclaration node) {
    if (!node.isStatic) {
      return;
    }
    _checkForNotInitializedNonNullableVariable(node.fields, false);
  }

  void _checkForNotInitializedNonNullableVariable(
    VariableDeclarationList node,
    bool topLevel,
  ) {
    // Checked separately.
    if (node.isConst || (topLevel && node.isFinal)) {
      return;
    }

    if (node.isLate) {
      return;
    }

    var parent = node.parent;
    if (parent is FieldDeclaration) {
      if (parent.externalKeyword != null) {
        return;
      }
    } else if (parent is TopLevelVariableDeclaration) {
      if (parent.externalKeyword != null) {
        return;
      }
    }

    if (node.type == null) {
      return;
    }
    var type = node.type!.typeOrThrow;

    if (!typeSystem.isPotentiallyNonNullable(type)) {
      return;
    }

    for (var variable in node.variables) {
      if (variable.initializer == null) {
        diagnosticReporter.atToken(
          variable.name,
          CompileTimeErrorCode.notInitializedNonNullableVariable,
          arguments: [variable.name.lexeme],
        );
      }
    }
  }

  /// Verify that all classes of the given [onClause] are valid.
  ///
  /// See [CompileTimeErrorCode.mixinSuperClassConstraintDisallowedClass],
  /// [CompileTimeErrorCode.mixinSuperClassConstraintDeferredClass].
  bool _checkForOnClauseErrorCodes(MixinOnClause? onClause) {
    if (onClause == null) {
      return false;
    }
    bool problemReported = false;
    for (NamedType namedType in onClause.superclassConstraints) {
      DartType type = namedType.typeOrThrow;
      if (type is InterfaceType) {
        if (_checkForExtendsOrImplementsDisallowedClass(
          namedType,
          CompileTimeErrorCode.mixinSuperClassConstraintDisallowedClass,
        )) {
          problemReported = true;
        } else {
          if (_checkForExtendsOrImplementsDeferredClass(
            namedType,
            CompileTimeErrorCode.mixinSuperClassConstraintDeferredClass,
          )) {
            problemReported = true;
          }
        }
      }
    }
    return problemReported;
  }

  /// Verify the given operator-method [declaration], does not have an optional
  /// parameter.
  ///
  /// This method assumes that the method declaration was tested to be an
  /// operator declaration before being called.
  ///
  /// See [CompileTimeErrorCode.optionalParameterInOperator].
  void _checkForOptionalParameterInOperator(MethodDeclaration declaration) {
    var parameterList = declaration.parameters;
    if (parameterList == null) {
      return;
    }

    NodeList<FormalParameter> formalParameters = parameterList.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      if (formalParameter.isOptional) {
        diagnosticReporter.atNode(
          formalParameter,
          CompileTimeErrorCode.optionalParameterInOperator,
        );
      }
    }
  }

  /// Via informal specification: dart-lang/language/issues/4
  ///
  /// If e is an integer literal which is not the operand of a unary minus
  /// operator, then:
  ///   - If the context type is double, it is a compile-time error if the
  ///   numerical value of e is not precisely representable by a double.
  ///   Otherwise the static type of e is double and the result of evaluating e
  ///   is a double instance representing that value.
  ///   - Otherwise (the current behavior of e, with a static type of int).
  ///
  /// and
  ///
  /// If e is -n and n is an integer literal, then
  ///   - If the context type is double, it is a compile-time error if the
  ///   numerical value of n is not precisely representable by a double.
  ///   Otherwise the static type of e is double and the result of evaluating e
  ///   is the result of calling the unary minus operator on a double instance
  ///   representing the numerical value of n.
  ///   - Otherwise (the current behavior of -n)
  void _checkForOutOfRange(IntegerLiteralImpl node) {
    var source = node.literal.lexeme;
    if (node.beginToken.type == TokenType.INT_WITH_SEPARATORS ||
        node.beginToken.type == TokenType.HEXADECIMAL_WITH_SEPARATORS) {
      source = shared.stripSeparators(source);
    }
    bool isNegated = node.immediatelyNegated;

    bool treatedAsDouble = node.staticType == _typeProvider.doubleType;
    bool valid = treatedAsDouble
        ? IntegerLiteralImpl.isValidAsDouble(source)
        : IntegerLiteralImpl.isValidAsInteger(source, isNegated);

    if (!valid) {
      var lexeme = node.literal.lexeme;
      var messageArguments = [
        isNegated ? '-$lexeme' : lexeme,
        if (treatedAsDouble)
          // Suggest the nearest valid double (as a BigInt, for printing).
          // TODO(srawlins): Insert digit separators at the same positions as
          // the input. This should be tested code, and a shared impl when we
          // have an assist that adds digit separators to a number literal.
          BigInt.from(IntegerLiteralImpl.nearestValidDouble(source)).toString(),
      ];

      diagnosticReporter.atNode(
        node,
        treatedAsDouble
            ? CompileTimeErrorCode.integerLiteralImpreciseAsDouble
            : CompileTimeErrorCode.integerLiteralOutOfRange,
        arguments: messageArguments,
      );
    }
  }

  /// Check that the given named optional [parameter] does not begin with '_'.
  void _checkForPrivateOptionalParameter(FormalParameter parameter) {
    // should be named parameter
    if (!parameter.isNamed) {
      return;
    }
    // name should start with '_'
    var name = parameter.name;
    if (name == null || name.isSynthetic || !name.lexeme.startsWith('_')) {
      return;
    }

    diagnosticReporter.atToken(
      name,
      CompileTimeErrorCode.privateOptionalParameter,
    );
  }

  /// Check whether the given constructor [declaration] is the redirecting
  /// generative constructor and references itself directly or indirectly. The
  /// [constructorElement] is the constructor element.
  ///
  /// See [CompileTimeErrorCode.recursiveConstructorRedirect].
  void _checkForRecursiveConstructorRedirect(
    ConstructorDeclaration declaration,
    ConstructorElement constructorElement,
  ) {
    // we check generative constructor here
    if (declaration.factoryKeyword != null) {
      return;
    }
    // try to find redirecting constructor invocation and analyze it for
    // recursion
    for (ConstructorInitializer initializer in declaration.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (_hasRedirectingFactoryConstructorCycle(constructorElement)) {
          diagnosticReporter.atNode(
            initializer,
            CompileTimeErrorCode.recursiveConstructorRedirect,
          );
        }
        return;
      }
    }
  }

  /// Check whether the given constructor [declaration] has redirected
  /// constructor and references itself directly or indirectly. The
  /// constructor [element] is the element introduced by the declaration.
  ///
  /// See [CompileTimeErrorCode.recursiveFactoryRedirect].
  bool _checkForRecursiveFactoryRedirect(
    ConstructorDeclaration declaration,
    ConstructorElement element,
  ) {
    // prepare redirected constructor
    var redirectedConstructorNode = declaration.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    // OK if no cycle
    if (!_hasRedirectingFactoryConstructorCycle(element)) {
      return false;
    }
    // report error
    diagnosticReporter.atNode(
      redirectedConstructorNode,
      CompileTimeErrorCode.recursiveFactoryRedirect,
    );
    return true;
  }

  /// Check that the given constructor [declaration] has a valid redirected
  /// constructor.
  void _checkForRedirectingConstructorErrorCodes(
    ConstructorDeclaration declaration,
  ) {
    // Check for default values in the parameters.
    var redirectedConstructor = declaration.redirectedConstructor;
    if (redirectedConstructor == null) {
      return;
    }
    for (FormalParameter parameter in declaration.parameters.parameters) {
      if (parameter is DefaultFormalParameter &&
          parameter.defaultValue != null) {
        diagnosticReporter.atToken(
          parameter.name!,
          CompileTimeErrorCode.defaultValueInRedirectingFactoryConstructor,
        );
      }
    }
    var redirectedElement = redirectedConstructor.element;
    _checkForRedirectToNonConstConstructor(
      declaration.declaredFragment!.element,
      redirectedElement,
      redirectedConstructor,
    );
    var redirectedClass = redirectedElement?.enclosingElement;
    if (redirectedClass is ClassElement &&
        redirectedClass.isAbstract &&
        redirectedElement != null &&
        !redirectedElement.isFactory) {
      String enclosingNamedType = _enclosingClass!.displayName;
      String constructorStrName = enclosingNamedType;
      if (declaration.name != null) {
        constructorStrName += ".${declaration.name!.lexeme}";
      }
      diagnosticReporter.atNode(
        redirectedConstructor,
        CompileTimeErrorCode.redirectToAbstractClassConstructor,
        arguments: [constructorStrName, redirectedClass.name!],
      );
    }
    _checkForInvalidGenerativeConstructorReference(
      redirectedConstructor,
      redirectedElement,
    );
  }

  /// Check whether the redirecting constructor, [element], is const, and
  /// [redirectedElement], its redirectee, is not const.
  ///
  /// See [CompileTimeErrorCode.redirectToNonConstConstructor].
  void _checkForRedirectToNonConstConstructor(
    ConstructorElement element,
    ConstructorElement? redirectedElement,
    SyntacticEntity errorEntity,
  ) {
    // This constructor is const, but it redirects to a non-const constructor.
    if (redirectedElement != null &&
        element.isConst &&
        !redirectedElement.isConst) {
      diagnosticReporter.atEntity(
        errorEntity,
        CompileTimeErrorCode.redirectToNonConstConstructor,
      );
    }
  }

  void _checkForReferenceBeforeDeclaration({
    required Token nameToken,
    required Element? element,
  }) {
    if (element != null &&
        _hiddenElements != null &&
        _hiddenElements!.contains(element)) {
      _hiddenElements!.contains(element);
      diagnosticReporter.reportError(
        _diagnosticFactory.referencedBeforeDeclaration(
          diagnosticReporter.source,
          nameToken: nameToken,
          element2: element,
        ),
      );
    }
  }

  void _checkForRepeatedType(
    Set<InstanceElement> accumulatedElements,
    List<NamedType>? namedTypes,
    DiagnosticCode code,
  ) {
    if (namedTypes == null) {
      return;
    }

    for (var namedType in namedTypes) {
      var type = namedType.type;
      if (type is InterfaceType) {
        var element = type.element;
        var added = accumulatedElements.add(element);
        if (!added) {
          diagnosticReporter.atNode(
            namedType,
            code,
            arguments: [element.name!],
          );
        }
      }
    }
  }

  /// Check that the given rethrow [expression] is inside of a catch clause.
  ///
  /// See [CompileTimeErrorCode.rethrowOutsideCatch].
  void _checkForRethrowOutsideCatch(RethrowExpression expression) {
    if (_enclosingExecutable.catchClauseLevel == 0) {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.rethrowOutsideCatch,
      );
    }
  }

  /// Check that if the given constructor [declaration] is generative, then
  /// it does not have an expression function body.
  ///
  /// See [CompileTimeErrorCode.returnInGenerativeConstructor].
  void _checkForReturnInGenerativeConstructor(
    ConstructorDeclaration declaration,
  ) {
    // ignore factory
    if (declaration.factoryKeyword != null) {
      return;
    }
    // block body (with possible return statement) is checked elsewhere
    FunctionBody body = declaration.body;
    if (body is! ExpressionFunctionBody) {
      return;
    }

    diagnosticReporter.atNode(
      body,
      CompileTimeErrorCode.returnInGenerativeConstructor,
    );
  }

  /// Checks that every supertype which is sealed is also declared in the
  /// current library.
  ///
  /// See [CompileTimeErrorCode.sealedClassSubtypeOutsideOfLibrary].
  void _checkForSealedSupertypeOutsideOfLibrary(List<NamedType> supertypes) {
    for (NamedType namedType in supertypes) {
      if (namedType.type case InterfaceType(:ClassElement element)) {
        if (element.isSealed && element.library != _currentLibrary) {
          diagnosticReporter.atNode(
            namedType,
            CompileTimeErrorCode.sealedClassSubtypeOutsideOfLibrary,
            arguments: [element.name!],
          );
        }
      }
    }
  }

  /// Verify that the elements in the given set [literal] are subtypes of the
  /// set's static type.
  ///
  /// See [CompileTimeErrorCode.setElementTypeNotAssignable].
  void _checkForSetElementTypeNotAssignable3(SetOrMapLiteral literal) {
    // Determine the set's element type. We base this on the static type and
    // not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    var setType = literal.typeOrThrow;
    assert(setType is InterfaceTypeImpl);

    var typeArguments = (setType as InterfaceTypeImpl).typeArguments;
    // It is possible for the number of type arguments to be inconsistent when
    // the literal is ambiguous and a non-set type was selected.
    // TODO(brianwilkerson): Unify this and _checkForMapTypeNotAssignable3 to
    //  better handle recovery situations.
    if (typeArguments.length == 1) {
      var setElementType = typeArguments[0];

      // Check every set element.
      var verifier = LiteralElementVerifier(
        _typeProvider,
        typeSystem,
        diagnosticReporter,
        this,
        forSet: true,
        elementType: setElementType,
        featureSet: _featureSet!,
      );
      for (CollectionElement element in literal.elements) {
        verifier.verify(element);
      }
    }
  }

  /// Check the given [typeReference] and that the [name] is not a reference to
  /// an instance member.
  ///
  /// See [CompileTimeErrorCode.staticAccessToInstanceMember].
  void _checkForStaticAccessToInstanceMember(
    InterfaceElement? typeReference,
    SimpleIdentifier name,
  ) {
    // OK, in comment
    if (_isInComment) {
      return;
    }
    // OK, target is not a type
    if (typeReference == null) {
      return;
    }
    // prepare member Element
    var element = name.element;
    if (element is ExecutableElement) {
      // OK, static
      if (element.isStatic || element is ConstructorElement) {
        return;
      }
      diagnosticReporter.atNode(
        name,
        CompileTimeErrorCode.staticAccessToInstanceMember,
        arguments: [name.name],
      );
    }
  }

  void _checkForThrowOfInvalidType(ThrowExpression node) {
    var expression = node.expression;
    var type = node.expression.typeOrThrow;

    if (!typeSystem.isAssignableTo(
      type,
      typeSystem.objectNone,
      strictCasts: strictCasts,
    )) {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.throwOfInvalidType,
        arguments: [type],
      );
    }
  }

  /// Verify that the given [element] does not reference itself directly.
  /// If it does, report the error on the [nameToken].
  ///
  /// See [CompileTimeErrorCode.typeAliasCannotReferenceItself].
  void _checkForTypeAliasCannotReferenceItself(
    Token nameToken,
    TypeAliasFragmentImpl element,
  ) {
    if (element.hasSelfReference) {
      diagnosticReporter.atToken(
        nameToken,
        CompileTimeErrorCode.typeAliasCannotReferenceItself,
      );
    }
  }

  /// Verify that the [type] is not a deferred type.
  ///
  /// See [CompileTimeErrorCode.typeAnnotationDeferredClass].
  void _checkForTypeAnnotationDeferredClass(TypeAnnotation? type) {
    if (type is NamedType && type.isDeferred) {
      diagnosticReporter.atNode(
        type,
        CompileTimeErrorCode.typeAnnotationDeferredClass,
        arguments: [type.qualifiedName],
      );
    }
  }

  /// Check that none of the type [parameters] references itself in its bound.
  ///
  /// See [CompileTimeErrorCode.typeParameterSupertypeOfItsBound].
  void _checkForTypeParameterBoundRecursion(List<TypeParameter> parameters) {
    checkForTypeParameterBoundRecursion(diagnosticReporter, parameters);
  }

  void _checkForTypeParameterReferencedByStatic({
    required Token name,
    required Element? element,
  }) {
    if (_enclosingExecutable.inStaticMethod || _isInStaticVariableDeclaration) {
      if (element is TypeParameterElement &&
          element.enclosingElement is InstanceElement) {
        // The class's type parameters are not in scope for static methods.
        // However all other type parameters are legal (e.g. the static method's
        // type parameters, or a local function's type parameters).
        diagnosticReporter.atToken(
          name,
          CompileTimeErrorCode.typeParameterReferencedByStatic,
        );
      }
    }
  }

  /// Check that if the given generative [constructor] has neither an explicit
  /// super constructor invocation nor a redirecting constructor invocation,
  /// that the superclass has a default generative constructor.
  ///
  /// See [CompileTimeErrorCode.undefinedConstructorInInitializerDefault],
  /// [CompileTimeErrorCode.nonGenerativeConstructor], and
  /// [CompileTimeErrorCode.noDefaultSuperConstructorExplicit].
  void _checkForUndefinedConstructorInInitializerImplicit(
    ConstructorDeclaration constructor,
  ) {
    if (_enclosingClass == null) {
      return;
    }

    // Ignore if the constructor is not generative.
    if (constructor.factoryKeyword != null) {
      return;
    }

    // Ignore if the constructor is external. See
    // https://github.com/dart-lang/language/issues/869.
    if (constructor.externalKeyword != null) {
      return;
    }

    // Ignore if the constructor has either an implicit super constructor
    // invocation or a redirecting constructor invocation.
    for (ConstructorInitializer constructorInitializer
        in constructor.initializers) {
      if (constructorInitializer is SuperConstructorInvocation ||
          constructorInitializer is RedirectingConstructorInvocation) {
        return;
      }
    }

    // Check to see whether the superclass has a non-factory unnamed
    // constructor.
    var superType = _enclosingClass!.supertype;
    if (superType == null) {
      return;
    }
    var superElement = superType.element;

    if (superElement.constructors.every(
      (constructor) => constructor.isFactory,
    )) {
      // Already reported [NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS].
      return;
    }

    var superUnnamedConstructor = superElement.unnamedConstructor;
    if (superUnnamedConstructor == null) {
      diagnosticReporter.atNode(
        constructor.returnType,
        CompileTimeErrorCode.undefinedConstructorInInitializerDefault,
        arguments: [superElement.name!],
      );
      return;
    }

    if (superUnnamedConstructor.isFactory) {
      diagnosticReporter.atNode(
        constructor.returnType,
        CompileTimeErrorCode.nonGenerativeConstructor,
        arguments: [superUnnamedConstructor],
      );
      return;
    }

    var requiredPositionalParameterCount = superUnnamedConstructor
        .formalParameters
        .where((parameter) => parameter.isRequiredPositional)
        .length;
    var requiredNamedParameters = superUnnamedConstructor.formalParameters
        .where((parameter) => parameter.isRequiredNamed)
        .map((parameter) => parameter.name)
        .toSet();

    void reportError(DiagnosticCode code, List<Object> arguments) {
      Identifier returnType = constructor.returnType;
      var name = constructor.name;
      int offset = returnType.offset;
      int length = (name != null ? name.end : returnType.end) - offset;
      diagnosticReporter.atOffset(
        offset: offset,
        length: length,
        diagnosticCode: code,
        arguments: arguments,
      );
    }

    if (!_currentLibrary.featureSet.isEnabled(Feature.super_parameters)) {
      if (requiredPositionalParameterCount != 0 ||
          requiredNamedParameters.isNotEmpty) {
        reportError(CompileTimeErrorCode.noDefaultSuperConstructorExplicit, [
          superType,
        ]);
      }
      return;
    }

    var superParametersResult = verifySuperFormalParameters(
      constructor: constructor,
      diagnosticReporter: diagnosticReporter,
    );
    requiredNamedParameters.removeAll(superParametersResult.namedArgumentNames);

    if (requiredPositionalParameterCount >
            superParametersResult.positionalArgumentCount ||
        requiredNamedParameters.isNotEmpty) {
      reportError(
        CompileTimeErrorCode.implicitSuperInitializerMissingArguments,
        [superType],
      );
    }
  }

  void _checkForUnnecessaryNullAware(
    Expression target,
    Token operator, {
    _NullAwareElementOrMapEntryKind? nullAwareElementOrMapEntryKind,
  }) {
    if (target is SuperExpression) {
      return;
    }

    DiagnosticCode code;
    Token endToken = operator;
    List<Object> arguments = const [];
    if (operator.type == TokenType.QUESTION) {
      if (nullAwareElementOrMapEntryKind == null) {
        code = StaticWarningCode.invalidNullAwareOperator;
        endToken = operator.next!;
        arguments = ['?[', '['];
      } else {
        switch (nullAwareElementOrMapEntryKind) {
          case _NullAwareElementOrMapEntryKind.element:
            code = StaticWarningCode.invalidNullAwareElement;
          case _NullAwareElementOrMapEntryKind.mapEntryKey:
            code = StaticWarningCode.invalidNullAwareMapEntryKey;
          case _NullAwareElementOrMapEntryKind.mapEntryValue:
            code = StaticWarningCode.invalidNullAwareMapEntryValue;
        }
      }
    } else if (operator.type == TokenType.QUESTION_PERIOD) {
      code = StaticWarningCode.invalidNullAwareOperator;
      arguments = [operator.lexeme, '.'];
    } else if (operator.type == TokenType.QUESTION_PERIOD_PERIOD) {
      code = StaticWarningCode.invalidNullAwareOperator;
      arguments = [operator.lexeme, '..'];
    } else if (operator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION) {
      code = StaticWarningCode.invalidNullAwareOperator;
      arguments = [operator.lexeme, '...'];
    } else if (operator.type == TokenType.BANG) {
      code = StaticWarningCode.unnecessaryNonNullAssertion;
    } else {
      return;
    }

    /// If the operator is not valid because the target already makes use of a
    /// null aware operator, return the null aware operator from the target.
    Token? previousShortCircuitingOperator(Expression? target) {
      if (target is PropertyAccess) {
        var operator = target.operator;
        var type = operator.type;
        if (type == TokenType.QUESTION_PERIOD) {
          var realTarget = target.realTarget;
          return previousShortCircuitingOperator(realTarget) ?? operator;
        }
      } else if (target is IndexExpression) {
        if (target.question != null) {
          var realTarget = target.realTarget;
          return previousShortCircuitingOperator(realTarget) ?? target.question;
        }
      } else if (target is MethodInvocation) {
        var operator = target.operator;
        var type = operator?.type;
        if (type == TokenType.QUESTION_PERIOD) {
          var realTarget = target.realTarget;
          return previousShortCircuitingOperator(realTarget) ?? operator;
        }
      }
      return null;
    }

    var targetType = target.staticType;
    if (target is ExtensionOverride) {
      var arguments = target.argumentList.arguments;
      if (arguments.length == 1) {
        targetType = arguments[0].typeOrThrow;
      } else {
        return;
      }
    } else if (targetType == null) {
      if (target is Identifier) {
        var targetElement = target.element;
        if (targetElement is InterfaceElement ||
            targetElement is ExtensionElement ||
            targetElement is TypeAliasElement) {
          diagnosticReporter.atOffset(
            offset: operator.offset,
            length: endToken.end - operator.offset,
            diagnosticCode: code,
            arguments: arguments,
          );
        }
      }
      return;
    }

    if (typeSystem.isStrictlyNonNullable(targetType)) {
      if (code == StaticWarningCode.invalidNullAwareOperator) {
        var previousOperator = previousShortCircuitingOperator(target);
        if (previousOperator != null) {
          diagnosticReporter.reportError(
            _diagnosticFactory.invalidNullAwareAfterShortCircuit(
              diagnosticReporter.source,
              operator.offset,
              endToken.end - operator.offset,
              arguments,
              previousOperator,
            ),
          );
          return;
        }
      }
      diagnosticReporter.atOffset(
        offset: operator.offset,
        length: endToken.end - operator.offset,
        diagnosticCode: code,
        arguments: arguments,
      );
    }
  }

  /// Check that if the given [name] is a reference to a static member it is
  /// defined in the enclosing class rather than in a superclass.
  ///
  /// See
  /// [CompileTimeErrorCode.unqualifiedReferenceToNonLocalStaticMember].
  void _checkForUnqualifiedReferenceToNonLocalStaticMember(
    SimpleIdentifier name,
  ) {
    if (name.parent is DotShorthandPropertyAccessImpl ||
        name.parent is DotShorthandInvocationImpl) {
      return;
    }

    var element = name.writeOrReadElement;
    if (element == null || element is TypeParameterElement) {
      return;
    }

    var enclosingElement = element.enclosingElement;
    if (enclosingElement == null) {
      return;
    }

    if (identical(enclosingElement, _enclosingClass)) {
      return;
    }
    if (enclosingElement is! InterfaceElement) {
      return;
    }
    if (element is ExecutableElement && !element.isStatic) {
      return;
    }
    if (name.parent case MethodInvocation(
      :var methodName,
    ) when name == methodName) {
      // Invalid methods are reported in
      // [MethodInvocationResolver._reportInstanceAccessToStaticMember].
      return;
    }
    if (_enclosingExtension != null) {
      diagnosticReporter.atNode(
        name,
        CompileTimeErrorCode.unqualifiedReferenceToStaticMemberOfExtendedType,
        arguments: [enclosingElement.displayName],
      );
    } else {
      diagnosticReporter.atNode(
        name,
        CompileTimeErrorCode.unqualifiedReferenceToNonLocalStaticMember,
        arguments: [enclosingElement.displayName],
      );
    }
  }

  void _checkForValidField(FieldFormalParameter parameter) {
    var parent2 = parameter.parent?.parent;
    if (parent2 is! ConstructorDeclaration &&
        parent2?.parent is! ConstructorDeclaration) {
      return;
    }
    var element = parameter.declaredFragment?.element;
    if (element is FieldFormalParameterElementImpl) {
      var fieldElement = element.field;
      if (fieldElement == null || fieldElement.isSynthetic) {
        diagnosticReporter.atNode(
          parameter,
          CompileTimeErrorCode.initializingFormalForNonExistentField,
          arguments: [parameter.name.lexeme],
        );
      } else {
        var parameterElement = parameter.declaredFragment?.element;
        if (parameterElement is FieldFormalParameterElementImpl) {
          var declaredType = parameterElement.type;
          var fieldType = fieldElement.type;
          if (fieldElement.isSynthetic) {
            diagnosticReporter.atNode(
              parameter,
              CompileTimeErrorCode.initializingFormalForNonExistentField,
              arguments: [parameter.name.lexeme],
            );
          } else if (fieldElement.isStatic) {
            diagnosticReporter.atNode(
              parameter,
              CompileTimeErrorCode.initializerForStaticField,
              arguments: [parameter.name.lexeme],
            );
          } else if (!typeSystem.isSubtypeOf(declaredType, fieldType)) {
            diagnosticReporter.atNode(
              parameter,
              CompileTimeErrorCode.fieldInitializingFormalNotAssignable,
              arguments: [declaredType, fieldType],
            );
          }
        } else {
          if (fieldElement.isSynthetic) {
            diagnosticReporter.atNode(
              parameter,
              CompileTimeErrorCode.initializingFormalForNonExistentField,
              arguments: [parameter.name.lexeme],
            );
          } else if (fieldElement.isStatic) {
            diagnosticReporter.atNode(
              parameter,
              CompileTimeErrorCode.initializerForStaticField,
              arguments: [parameter.name.lexeme],
            );
          }
        }
      }
    }
    //        else {
    // TODO(jwren): Report error, constructor initializer variable is a top level element
    // (Either here or in ErrorVerifier.checkForAllFinalInitializedErrorCodes)
    //        }
  }

  /// Verify the given operator-method [declaration], has correct number of
  /// parameters.
  ///
  /// This method assumes that the method declaration was tested to be an
  /// operator declaration before being called.
  ///
  /// See [CompileTimeErrorCode.wrongNumberOfParametersForOperator].
  bool _checkForWrongNumberOfParametersForOperator(
    MethodDeclaration declaration,
  ) {
    // prepare number of parameters
    var parameterList = declaration.parameters;
    if (parameterList == null) {
      return false;
    }
    int numParameters = parameterList.parameters.length;
    // prepare operator name
    var nameToken = declaration.name;
    var name = nameToken.lexeme;
    // check for exact number of parameters
    int expected = -1;
    if ("[]=" == name) {
      expected = 2;
    } else if ("<" == name ||
        ">" == name ||
        "<=" == name ||
        ">=" == name ||
        "==" == name ||
        "+" == name ||
        "/" == name ||
        "~/" == name ||
        "*" == name ||
        "%" == name ||
        "|" == name ||
        "^" == name ||
        "&" == name ||
        "<<" == name ||
        ">>" == name ||
        ">>>" == name ||
        "[]" == name) {
      expected = 1;
    } else if ("~" == name) {
      expected = 0;
    }
    if (expected != -1 && numParameters != expected) {
      diagnosticReporter.atToken(
        nameToken,
        CompileTimeErrorCode.wrongNumberOfParametersForOperator,
        arguments: [name, expected, numParameters],
      );
      return true;
    } else if ("-" == name && numParameters > 1) {
      diagnosticReporter.atToken(
        nameToken,
        CompileTimeErrorCode.wrongNumberOfParametersForOperatorMinus,
        arguments: [numParameters],
      );
      return true;
    }
    return false;
  }

  void _checkForWrongTypeParameterVarianceInField(FieldDeclarationImpl node) {
    if (_enclosingClass != null) {
      for (var typeParameter in _enclosingClass!.typeParameters) {
        if (!typeParameter.isLegacyCovariant) {
          var fields = node.fields;
          var fieldFragment = fields.variables.first.declaredFragment!;
          var fieldElement = fieldFragment.element;
          var fieldName = fields.variables.first.name;
          Variance fieldVariance = typeParameter.computeVarianceInType(
            fieldElement.type,
          );

          _checkForWrongVariancePosition(
            fieldVariance,
            typeParameter,
            fieldName,
          );
          if (!fields.isFinal && node.covariantKeyword == null) {
            _checkForWrongVariancePosition(
              Variance.contravariant.combine(fieldVariance),
              typeParameter,
              fieldName,
            );
          }
        }
      }
    }
  }

  void _checkForWrongTypeParameterVarianceInMethod(
    MethodDeclarationImpl method,
  ) {
    // Only need to report errors for parameters with explicitly defined type
    // parameters in classes or mixins.
    if (_enclosingClass == null) {
      return;
    }

    for (var typeParameter in _enclosingClass!.typeParameters) {
      if (typeParameter.isLegacyCovariant) {
        continue;
      }

      var methodTypeParameters = method.typeParameters?.typeParameters;
      if (methodTypeParameters != null) {
        for (var methodTypeParameter in methodTypeParameters) {
          if (methodTypeParameter.bound == null) {
            continue;
          }
          var methodTypeParameterVariance = Variance.invariant.combine(
            typeParameter.computeVarianceInType(
              methodTypeParameter.bound!.typeOrThrow,
            ),
          );
          _checkForWrongVariancePosition(
            methodTypeParameterVariance,
            typeParameter,
            methodTypeParameter,
          );
        }
      }

      var methodParameters = method.parameters?.parameters;
      if (methodParameters != null) {
        for (var methodParameter in methodParameters) {
          var methodParameterFragment = methodParameter.declaredFragment!;
          var methodParameterElement = methodParameterFragment.element;
          if (methodParameterElement.isCovariant) {
            continue;
          }
          var methodParameterVariance = Variance.contravariant.combine(
            typeParameter.computeVarianceInType(methodParameterElement.type),
          );
          _checkForWrongVariancePosition(
            methodParameterVariance,
            typeParameter,
            methodParameter,
          );
        }
      }

      var returnType = method.returnType;
      if (returnType != null) {
        var methodReturnTypeVariance = typeParameter.computeVarianceInType(
          returnType.typeOrThrow,
        );
        _checkForWrongVariancePosition(
          methodReturnTypeVariance,
          typeParameter,
          returnType,
        );
      }
    }
  }

  void _checkForWrongTypeParameterVarianceInSuperinterfaces() {
    void checkOne(DartType? superInterface) {
      if (superInterface != null) {
        for (var typeParameter in _enclosingClass!.typeParameters) {
          var superVariance = typeParameter.computeVarianceInType(
            superInterface,
          );
          // Let `D` be a class or mixin declaration, let `S` be a direct
          // superinterface of `D`, and let `X` be a type parameter declared by
          // `D`.
          // If `X` is an `out` type parameter, it can only occur in `S` in an
          // covariant or unrelated position.
          // If `X` is an `in` type parameter, it can only occur in `S` in an
          // contravariant or unrelated position.
          // If `X` is an `inout` type parameter, it can occur in `S` in any
          // position.
          if (!superVariance.greaterThanOrEqual(typeParameter.variance)) {
            if (!typeParameter.isLegacyCovariant) {
              diagnosticReporter.atElement2(
                typeParameter,
                CompileTimeErrorCode
                    .wrongExplicitTypeParameterVarianceInSuperinterface,
                arguments: [
                  typeParameter.name ?? '',
                  typeParameter.variance.keyword,
                  superVariance.keyword,
                  superInterface,
                ],
              );
            } else {
              diagnosticReporter.atElement2(
                typeParameter,
                CompileTimeErrorCode.wrongTypeParameterVarianceInSuperinterface,
                arguments: [typeParameter.name ?? '', superInterface],
              );
            }
          }
        }
      }
    }

    checkOne(_enclosingClass!.supertype);
    _enclosingClass!.interfaces.forEach(checkOne);
    _enclosingClass!.mixins.forEach(checkOne);

    var enclosingClass = _enclosingClass;
    if (enclosingClass is MixinElementImpl) {
      enclosingClass.superclassConstraints.forEach(checkOne);
    }
  }

  /// Check for invalid variance positions in members of a class or mixin.
  ///
  /// Let `C` be a class or mixin declaration with type parameter `T`.
  /// If `T` is an `out` type parameter then `T` can only appear in covariant
  /// positions within the accessors and methods of `C`.
  /// If `T` is an `in` type parameter then `T` can only appear in contravariant
  /// positions within the accessors and methods of `C`.
  /// If `T` is an `inout` type parameter or a type parameter with no explicit
  /// variance modifier then `T` can appear in any variant position within the
  /// accessors and methods of `C`.
  ///
  /// Errors should only be reported in classes and mixins since those are the
  /// only components that allow explicit variance modifiers.
  void _checkForWrongVariancePosition(
    Variance variance,
    TypeParameterElementImpl typeParameter,
    SyntacticEntity errorTarget,
  ) {
    if (!variance.greaterThanOrEqual(typeParameter.variance)) {
      diagnosticReporter.atEntity(
        errorTarget,
        CompileTimeErrorCode.wrongTypeParameterVariancePosition,
        arguments: [
          typeParameter.variance.keyword,
          typeParameter.name ?? '',
          variance.keyword,
        ],
      );
    }
  }

  /// Verify that the current class does not have the same class in the
  /// 'extends' and 'implements' clauses.
  ///
  /// See [CompileTimeErrorCode.implementsSuperClass].
  void _checkImplementsSuperClass(ImplementsClause? implementsClause) {
    if (implementsClause == null) {
      return;
    }

    var superElement = _enclosingClass!.supertype?.element;
    if (superElement == null) {
      return;
    }

    for (var interfaceNode in implementsClause.interfaces) {
      var type = interfaceNode.type;
      if (type is InterfaceType && type.element == superElement) {
        diagnosticReporter.atNode(
          interfaceNode,
          CompileTimeErrorCode.implementsSuperClass,
          arguments: [superElement],
        );
      }
    }
  }

  /// Checks the class for problems with the superclass, mixins, or implemented
  /// interfaces.
  void _checkMixinInheritance(
    MixinFragmentImpl declarationFragment,
    MixinDeclaration node,
    MixinOnClause? onClause,
    ImplementsClause? implementsClause,
  ) {
    // Only check for all of the inheritance logic around clauses if there
    // isn't an error code such as "Cannot implement double" already.
    if (!_checkForOnClauseErrorCodes(onClause) &&
        !_checkForImplementsClauseErrorCodes(implementsClause)) {
      //      _checkForImplicitDynamicType(superclass);
      _checkForRepeatedType(
        libraryContext.setOfOn(declarationFragment.asElement2),
        onClause?.superclassConstraints,
        CompileTimeErrorCode.onRepeated,
      );
      _checkForRepeatedType(
        libraryContext.setOfImplements(declarationFragment.asElement2),
        implementsClause?.interfaces,
        CompileTimeErrorCode.implementsRepeated,
      );
      _checkForConflictingGenerics(node);
      _checkForBaseClassOrMixinImplementedOutsideOfLibrary(implementsClause);
      _checkForFinalSupertypeOutsideOfLibrary(
        null,
        null,
        implementsClause,
        onClause,
      );
      _checkForSealedSupertypeOutsideOfLibrary([
        ...?implementsClause?.interfaces,
        ...?onClause?.superclassConstraints,
      ]);
    }
  }

  /// Verify that the current class does not have the same class in the
  /// 'extends' and 'with' clauses.
  ///
  /// See [CompileTimeErrorCode.implementsSuperClass].
  void _checkMixinsSuperClass(WithClause? withClause) {
    if (withClause == null) {
      return;
    }

    var superElement = _enclosingClass!.supertype?.element;
    if (superElement == null) {
      return;
    }

    for (var mixinNode in withClause.mixinTypes) {
      var type = mixinNode.type;
      if (type is InterfaceType && type.element == superElement) {
        diagnosticReporter.atNode(
          mixinNode,
          CompileTimeErrorCode.mixinsSuperClass,
          arguments: [superElement],
        );
      }
    }
  }

  void _checkUseOfCovariantInParameters(FormalParameterList node) {
    var parent = node.parent;
    if (_enclosingClass != null && parent is MethodDeclaration) {
      // Either [parent] is a static method, in which case `EXTRANEOUS_MODIFIER`
      // is reported by the parser, or [parent] is an instance method, in which
      // case any use of `covariant` is legal.
      return;
    }

    if (_enclosingExtension != null) {
      // `INVALID_USE_OF_COVARIANT_IN_EXTENSION` is reported by the parser.
      return;
    }

    if (parent is FunctionExpression) {
      var parent2 = parent.parent;
      if (parent2 is FunctionDeclaration && parent2.parent is CompilationUnit) {
        // `EXTRANEOUS_MODIFIER` is reported by the parser, for library-level
        // functions.
        return;
      }
    }

    NodeList<FormalParameter> parameters = node.parameters;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      var parameter = parameters[i].notDefault;
      var keyword = parameter.covariantKeyword;
      if (keyword != null) {
        diagnosticReporter.atToken(
          keyword,
          CompileTimeErrorCode.invalidUseOfCovariant,
        );
      }
    }
  }

  void _checkUseOfDefaultValuesInParameters(FormalParameterList node) {
    var defaultValuesAreExpected = () {
      var parent = node.parent;
      if (parent is ConstructorDeclaration) {
        if (parent.externalKeyword != null) {
          return false;
        } else if (parent.factoryKeyword != null &&
            parent.redirectedConstructor != null) {
          return false;
        }
        return true;
      } else if (parent is FunctionExpression) {
        var parent2 = parent.parent;
        if (parent2 is FunctionDeclaration && parent2.externalKeyword != null) {
          return false;
        } else if (parent.body is NativeFunctionBody) {
          return false;
        }
        return true;
      } else if (parent is MethodDeclaration) {
        if (parent.isAbstract) {
          return false;
        } else if (parent.externalKeyword != null) {
          return false;
        } else if (parent.body is NativeFunctionBody) {
          return false;
        }
        return true;
      }
      return false;
    }();

    for (var parameter in node.parameters) {
      if (parameter is DefaultFormalParameter) {
        if (parameter.isRequiredNamed) {
          if (parameter.defaultValue != null) {
            var errorTarget = _parameterName(parameter) ?? parameter;
            diagnosticReporter.atEntity(
              errorTarget,
              CompileTimeErrorCode.defaultValueOnRequiredParameter,
            );
          }
        } else if (defaultValuesAreExpected) {
          var parameterElement = parameter.declaredFragment!.element;
          if (!parameterElement.hasDefaultValue) {
            var type = parameterElement.type;
            if (typeSystem.isPotentiallyNonNullable(type)) {
              var parameterName = _parameterName(parameter);
              var errorTarget = parameterName ?? parameter;
              if (parameterElement.metadata.hasRequired) {
                diagnosticReporter.atEntity(
                  errorTarget,
                  CompileTimeErrorCode
                      .missingDefaultValueForParameterWithAnnotation,
                );
              } else {
                if (!_isWildcardSuperFormalPositionalParameter(parameter)) {
                  diagnosticReporter.atEntity(
                    errorTarget,
                    parameterElement.isPositional
                        ? CompileTimeErrorCode
                              .missingDefaultValueForParameterPositional
                        : CompileTimeErrorCode.missingDefaultValueForParameter,
                    arguments: [parameterName?.lexeme ?? '?'],
                  );
                }
              }
            }
          }
        }
      }
    }
  }

  bool _computeThisAccessForFunctionBody(FunctionBody node) =>
      switch (node.parent) {
        ConstructorDeclaration(:var factoryKeyword) => factoryKeyword == null,
        MethodDeclaration(:var isStatic) => !isStatic,
        _ => _hasAccessToThis,
      };

  /// Given an [expression] in a switch case whose value is expected to be an
  /// enum constant, return the name of the constant.
  String? _getConstantName(Expression expression) {
    // TODO(brianwilkerson): Convert this to return the element representing the
    // constant.
    if (expression is SimpleIdentifier) {
      return expression.name;
    } else if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.name;
    }
    return null;
  }

  /// Return the name of the library that defines given [element].
  String _getLibraryName(Element? element) {
    if (element == null) {
      return '';
    }
    var library = element.library;
    if (library == null) {
      return '';
    }
    var name = element.name;
    if (name == null) {
      return '';
    }
    var imports = _currentUnit.withEnclosing
        .expand((fragment) => fragment.libraryImports)
        .toList();
    int count = imports.length;
    for (int i = 0; i < count; i++) {
      if (identical(imports[i].importedLibrary, library)) {
        return library.uri.toString();
      }
    }
    List<String> indirectSources = <String>[];
    for (var import in imports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null) {
        if (import.namespace.get2(name) == element) {
          indirectSources.add(importedLibrary.uri.toString());
        }
      }
    }
    int indirectCount = indirectSources.length;
    StringBuffer buffer = StringBuffer();
    buffer.write(library.uri.toString());
    if (indirectCount > 0) {
      buffer.write(" (via ");
      if (indirectCount > 1) {
        indirectSources.sort();
        buffer.write(indirectSources.quotedAndCommaSeparatedWithAnd);
      } else {
        buffer.write(indirectSources[0]);
      }
      buffer.write(")");
    }
    return buffer.toString();
  }

  /// Return `true` if the given [constructor] redirects to itself, directly or
  /// indirectly.
  bool _hasRedirectingFactoryConstructorCycle(ConstructorElement constructor) {
    Set<ConstructorElement> constructors = HashSet<ConstructorElement>();
    ConstructorElement? current = constructor;
    while (current != null) {
      if (constructors.contains(current)) {
        return identical(current, constructor);
      }
      constructors.add(current);
      current = current.redirectedConstructor?.baseElement;
    }
    return false;
  }

  /// Returns `true` if the given [library] is the `dart:ffi` library.
  bool _isDartFfiLibrary(LibraryElement library) => library.name == 'dart.ffi';

  /// Return `true` if the given [identifier] is in a location where it is
  /// allowed to resolve to a static member of a supertype.
  bool _isUnqualifiedReferenceToNonLocalStaticMemberAllowed(
    SimpleIdentifier identifier,
  ) {
    if (identifier.inDeclarationContext()) {
      return true;
    }
    var parent = identifier.parent;
    if (parent is Annotation) {
      return identical(parent.constructorName, identifier);
    }
    if (parent is CommentReference) {
      return true;
    }
    if (parent is ConstructorName) {
      return identical(parent.name, identifier);
    }
    if (parent is MethodInvocation) {
      return identical(parent.methodName, identifier);
    }
    if (parent is PrefixedIdentifier) {
      return identical(parent.identifier, identifier);
    }
    if (parent is PropertyAccess) {
      return identical(parent.propertyName, identifier);
    }
    if (parent is SuperConstructorInvocation) {
      return identical(parent.constructorName, identifier);
    }
    return false;
  }

  /// Return `true` if the [importElement] is the internal library `dart:_wasm`
  /// and the current library is either `package:js/js.dart` or is in
  /// `package:ui`.
  bool _isWasm(LibraryImport importElement) {
    var importedUri = importElement.importedLibrary?.uri.toString();
    if (importedUri != 'dart:_wasm') {
      return false;
    }
    var importingUri = _currentLibrary.uri.toString();
    if (importingUri == 'package:js/js.dart') {
      return true;
    } else if (importingUri.startsWith('package:ui/')) {
      return true;
    }
    return false;
  }

  bool _isWildcardSuperFormalPositionalParameter(
    DefaultFormalParameter parameter,
  ) =>
      parameter.parameter is SuperFormalParameter &&
      parameter.isPositional &&
      parameter.name?.lexeme == '_' &&
      _currentLibrary.featureSet.isEnabled(Feature.wildcard_variables);

  /// Checks whether a `final`, `base` or `interface` modifier can be ignored.
  ///
  /// Checks whether a subclass in the current library
  /// can ignore a class modifier of a declaration in [superLibrary].
  ///
  /// Only true if the supertype library is a platform library, and
  /// either the current library is also a platform library,
  /// or the current library has a language version which predates
  /// class modifiers
  bool _mayIgnoreClassModifiers(LibraryElement superLibrary) {
    // Only modifiers in platform libraries can be ignored.
    if (!superLibrary.isInSdk) return false;

    // Modifiers in 'dart:ffi' can't be ignored in pre-feature code.
    if (_isDartFfiLibrary(superLibrary)) {
      return false;
    }

    // Other platform libraries can ignore modifiers.
    if (_currentLibrary.isInSdk) return true;

    // Libraries predating class modifiers can ignore platform modifiers.
    return !_currentLibrary.featureSet.isEnabled(Feature.class_modifiers);
  }

  /// Return the name of the [parameter], or `null` if the parameter does not
  /// have a name.
  Token? _parameterName(FormalParameter parameter) {
    if (parameter is NormalFormalParameter) {
      return parameter.name;
    } else if (parameter is DefaultFormalParameter) {
      return parameter.parameter.name;
    }
    return null;
  }

  void _reportForMultipleCombinators(NamespaceDirective node) {
    var combinators = node.combinators;
    if (combinators.length > 1) {
      var offset = combinators.beginToken!.offset;
      var length = combinators.endToken!.end - offset;
      diagnosticReporter.atOffset(
        offset: offset,
        length: length,
        diagnosticCode: WarningCode.multipleCombinators,
      );
    }
  }

  void _withEnclosingExecutable(
    InternalExecutableElement element,
    void Function() operation, {
    required bool isAsynchronous,
    required bool isGenerator,
  }) {
    var current = _enclosingExecutable;
    try {
      _enclosingExecutable = EnclosingExecutableContext(
        element,
        isAsynchronous: isAsynchronous,
        isGenerator: isGenerator,
      );
      _returnTypeVerifier.enclosingExecutable = _enclosingExecutable;
      operation();
    } finally {
      _enclosingExecutable = current;
      _returnTypeVerifier.enclosingExecutable = _enclosingExecutable;
    }
  }

  void _withHiddenElements(List<Statement> statements, void Function() f) {
    _hiddenElements = HiddenElements(_hiddenElements, statements);
    try {
      f();
    } finally {
      _hiddenElements = _hiddenElements!.outerElements;
    }
  }

  void _withHiddenElementsGuardedPattern(
    GuardedPatternImpl guardedPattern,
    void Function() f,
  ) {
    _hiddenElements = HiddenElements.forGuardedPattern(
      _hiddenElements,
      guardedPattern,
    );
    try {
      f();
    } finally {
      _hiddenElements = _hiddenElements!.outerElements;
    }
  }

  /// Return [FieldElement]s that are declared in the [ClassDeclaration] with
  /// the given [constructor], but are not initialized.
  static List<FieldElement> computeNotInitializedFields(
    ConstructorDeclaration constructor,
  ) {
    var fields = <FieldElement>{};
    var classDeclaration = constructor.parent as ClassDeclaration;
    for (ClassMember fieldDeclaration in classDeclaration.members) {
      if (fieldDeclaration is FieldDeclaration) {
        for (VariableDeclaration field in fieldDeclaration.fields.variables) {
          if (field.initializer == null) {
            fields.add((field.declaredFragment as FieldFragment).element);
          }
        }
      }
    }

    List<FormalParameter> parameters = constructor.parameters.parameters;
    for (FormalParameter parameter in parameters) {
      parameter = parameter.notDefault;
      if (parameter is FieldFormalParameter) {
        var element =
            (parameter.declaredFragment as FieldFormalParameterFragment)
                .element;
        fields.remove(element.field);
      }
    }

    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        fields.remove(initializer.fieldName.element);
      }
    }

    return fields.toList();
  }

  /// Checks whether the given [expression] is a reference to a class. If it is
  /// then the element representing the class is returned, otherwise `null` is
  /// returned.
  static InterfaceElement? getTypeReference(Expression expression) {
    if (expression is Identifier) {
      var element = expression.element;
      if (element is InterfaceElement) {
        return element;
      } else if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        if (aliasedType is InterfaceType) {
          return aliasedType.element;
        }
      }
    }
    return null;
  }
}

/// A record of the elements that will be declared in some scope (block), but
/// are not yet declared.
class HiddenElements {
  /// The elements hidden in outer scopes, or `null` if this is the outermost
  /// scope.
  final HiddenElements? outerElements;

  /// A set containing the elements that will be declared in this scope, but are
  /// not yet declared.
  final Set<Element> _elements = {};

  /// Initialize a newly created set of hidden elements to include all of the
  /// elements defined in the set of [outerElements] and all of the elements
  /// declared in the given [statements].
  HiddenElements(this.outerElements, List<Statement> statements) {
    _initializeElements(statements);
  }

  /// Initialize a newly created set of hidden elements to include all of the
  /// elements defined in the set of [outerElements] and all of the elements
  /// declared in the given [guardedPattern].
  HiddenElements.forGuardedPattern(
    this.outerElements,
    GuardedPatternImpl guardedPattern,
  ) {
    _elements.addAll(guardedPattern.variables.values);
  }

  /// Return `true` if this set of elements contains the given [element].
  bool contains(Element element) {
    if (_elements.contains(element)) {
      return true;
    } else if (outerElements != null) {
      return outerElements!.contains(element);
    }
    return false;
  }

  /// Record that the given [element] has been declared, so it is no longer
  /// hidden.
  void declare(Element element) {
    _elements.remove(element);
  }

  /// Initialize the list of elements that are not yet declared to be all of the
  /// elements declared somewhere in the given [statements].
  void _initializeElements(List<Statement> statements) {
    _elements.addAll(BlockScope.elementsInStatements(statements));
  }
}

/// Information to pass from from the defining unit to augmentations.
class LibraryVerificationContext {
  final duplicationDefinitionContext = DuplicationDefinitionContext();
  final LibraryFileKind libraryKind;
  final ConstructorFieldsVerifier constructorFieldsVerifier;

  /// A table mapping names to the exported elements.
  final Map<String, Element> _exportedElements = {};

  /// Elements referenced in `implements` clauses.
  /// Key: the declaration element.
  final Map<InstanceElement, Set<InstanceElement>> _setOfImplementsMap =
      Map.identity();

  /// Elements referenced in `on` clauses.
  /// Key: the declaration element.
  final Map<MixinElement, Set<InterfaceElement>> _setOfOnMaps = Map.identity();

  LibraryVerificationContext({
    required this.libraryKind,
    required this.constructorFieldsVerifier,
  });

  bool libraryCycleContains(Uri uri) {
    return libraryKind.libraryCycle.libraryUris.contains(uri);
  }

  Set<InstanceElement> setOfImplements(InstanceElement declaration) {
    return _setOfImplementsMap[declaration] ??= Set.identity();
  }

  Set<InterfaceElement> setOfOn(MixinElement declaration) {
    return _setOfOnMaps[declaration] ??= Set.identity();
  }
}

/// Signals the kind of the null-aware element or entry observed in list, set,
/// or map literals.
enum _NullAwareElementOrMapEntryKind { element, mapEntryKey, mapEntryValue }

/// Recursively visits a type annotation, looking uninstantiated bounds.
class _UninstantiatedBoundChecker extends RecursiveAstVisitor<void> {
  final DiagnosticReporter _diagnosticReporter;

  _UninstantiatedBoundChecker(this._diagnosticReporter);

  @override
  void visitNamedType(NamedType node) {
    var typeArgs = node.typeArguments;
    if (typeArgs != null) {
      typeArgs.accept(this);
      return;
    }

    var element = node.element;
    if (element is TypeParameterizedElement && !element.isSimplyBounded) {
      // TODO(srawlins): Don't report this if TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
      //  has been reported.
      _diagnosticReporter.atNode(
        node,
        CompileTimeErrorCode.notInstantiatedBound,
      );
    }
  }
}
