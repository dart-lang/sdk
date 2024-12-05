// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/parser/util.dart' as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    show Variance;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/file_analysis.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
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
import 'package:analyzer/src/error/literal_element_verifier.dart';
import 'package:analyzer/src/error/required_parameters_verifier.dart';
import 'package:analyzer/src/error/return_type_verifier.dart';
import 'package:analyzer/src/error/super_formal_parameters_verifier.dart';
import 'package:analyzer/src/error/type_arguments_verifier.dart';
import 'package:analyzer/src/error/use_result_verifier.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/macro_type_location.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart' as macro;

class EnclosingExecutableContext {
  final ExecutableElement? element;
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
  final InterfaceType? catchErrorOnErrorReturnType;

  /// The return statements that have a value.
  final List<ReturnStatement> _returnsWith = [];

  /// The return statements that do not have a value.
  final List<ReturnStatement> _returnsWithout = [];

  /// This flag is set to `false` when the declared return type is not legal
  /// for the kind of the function body, e.g. not `Future` for `async`.
  bool hasLegalReturnType = true;

  /// The number of enclosing [CatchClause] in this executable.
  int catchClauseLevel = 0;

  EnclosingExecutableContext(this.element,
      {bool? isAsynchronous, this.catchErrorOnErrorReturnType})
      : isAsynchronous =
            isAsynchronous ?? (element != null && element.isAsynchronous),
        isConstConstructor = element is ConstructorElement && element.isConst,
        isGenerativeConstructor =
            element is ConstructorElement && !element.isFactory,
        isGenerator = element != null && element.isGenerator,
        inFactoryConstructor = _inFactoryConstructor(element),
        inStaticMethod = _inStaticMethod(element);

  EnclosingExecutableContext.empty() : this(null);

  String? get displayName {
    return element?.displayName;
  }

  bool get isClosure {
    return element is FunctionElement && element!.displayName.isEmpty;
  }

  bool get isConstructor => element is ConstructorElement;

  bool get isFunction {
    if (element is FunctionElement) {
      return element!.displayName.isNotEmpty;
    }
    return element is PropertyAccessorElement;
  }

  bool get isMethod => element is MethodElement;

  bool get isSynchronous => !isAsynchronous;

  DartType get returnType {
    return catchErrorOnErrorReturnType ?? element!.returnType;
  }

  static bool _inFactoryConstructor(Element? element) {
    var enclosing = element?.enclosingElement3;
    if (enclosing == null) {
      return false;
    }
    if (element is ConstructorElement) {
      return element.isFactory;
    }
    return _inFactoryConstructor(enclosing);
  }

  static bool _inStaticMethod(Element? element) {
    var enclosing = element?.enclosingElement3;
    if (enclosing == null) {
      return false;
    }
    if (enclosing is InterfaceElement || enclosing is ExtensionElement) {
      if (element is ExecutableElement) {
        return element.isStatic;
      }
    }
    return _inStaticMethod(enclosing);
  }
}

/// A visitor used to traverse an AST structure looking for additional errors
/// and warnings not covered by the parser and resolver.
class ErrorVerifier extends RecursiveAstVisitor<void>
    with ErrorDetectionHelpers {
  /// The error reporter by which errors will be reported.
  @override
  final ErrorReporter errorReporter;

  /// The current library that is being analyzed.
  final LibraryElementImpl _currentLibrary;

  /// The current unit that is being analyzed.
  final CompilationUnitElementImpl _currentUnit;

  /// The type representing the type 'int'.
  late final InterfaceType _intType;

  /// The options for verification.
  final AnalysisOptionsImpl options;

  /// The object providing access to the types defined by the language.
  final TypeProvider _typeProvider;

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
  InterfaceElement? _enclosingClass;

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
    this.errorReporter,
    this._currentLibrary,
    this._currentUnit,
    this._typeProvider,
    this._inheritanceManager,
    this.libraryContext,
    this.options, {
    required this.typeSystemOperations,
  })  : _uninstantiatedBoundChecker =
            _UninstantiatedBoundChecker(errorReporter),
        _checkUseVerifier = UseResultVerifier(errorReporter),
        _requiredParametersVerifier = RequiredParametersVerifier(errorReporter),
        _constArgumentsVerifier = ConstArgumentsVerifier(errorReporter),
        _duplicateDefinitionVerifier = DuplicateDefinitionVerifier(
          _currentLibrary,
          errorReporter,
          libraryContext.duplicationDefinitionContext,
        ) {
    _isInSystemLibrary = _currentLibrary.source.uri.isScheme('dart');
    _isInStaticVariableDeclaration = false;
    _isInConstructorInitializer = false;
    _intType = _typeProvider.intType;
    typeSystem = _currentLibrary.typeSystem;
    _typeArgumentsVerifier =
        TypeArgumentsVerifier(options, _currentLibrary, errorReporter);
    _returnTypeVerifier = ReturnTypeVerifier(
      typeProvider: _typeProvider as TypeProviderImpl,
      typeSystem: typeSystem,
      errorReporter: errorReporter,
      strictCasts: strictCasts,
    );
  }

  InterfaceElement? get enclosingClass => _enclosingClass;

  /// For consumers of error verification as a library, (currently just the
  /// angular plugin), expose a setter that can make the errors reported more
  /// accurate when dangling code snippets are being resolved from a class
  /// context. Note that this setter is very defensive for potential misuse; it
  /// should not be modified in the middle of visiting a tree and requires an
  /// analyzer-provided Impl instance to work.
  set enclosingClass(InterfaceElement? interfaceElement) {
    assert(_enclosingClass == null);
    assert(_enclosingExecutable.element == null);
  }

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
      Map<SharedTypeView<DartType>, NonPromotionReason>? whyNotPromoted) {
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
  void visitAssignmentExpression(AssignmentExpression node) {
    TokenType operatorType = node.operator.type;
    Expression lhs = node.leftHandSide;
    if (operatorType == TokenType.QUESTION_QUESTION_EQ) {
      _checkForDeadNullCoalesce(node.readType as TypeImpl, node.rightHandSide);
    }
    _checkForAssignmentToFinal(lhs);

    _constArgumentsVerifier.visitAssignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (!_enclosingExecutable.isAsynchronous) {
      errorReporter.atToken(
        node.awaitKeyword,
        CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT,
      );
    }
    checkForUseOfVoidResult(node.expression);
    _checkForAwaitInLateLocalVariableInitializer(node);
    _checkForAwaitOfIncompatibleType(node);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    TokenType type = operator.type;
    if (type == TokenType.AMPERSAND_AMPERSAND || type == TokenType.BAR_BAR) {
      checkForUseOfVoidResult(node.rightOperand);
    } else {
      // Assignability checking is done by the resolver.
    }

    if (type == TokenType.QUESTION_QUESTION) {
      _checkForDeadNullCoalesce(
          node.leftOperand.staticType as TypeImpl, node.rightOperand);
    }

    checkForUseOfVoidResult(node.leftOperand);
    _constArgumentsVerifier.visitBinaryExpression(node);

    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
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
      var labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl && labelElement.isOnSwitchMember) {
        errorReporter.atNode(
          labelNode,
          CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER,
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
      var element = node.declaredElement!;

      _checkAugmentations(
        augmentKeyword: node.augmentKeyword,
        element: element,
      );

      _checkClassAugmentationModifiers(
        augmentKeyword: node.augmentKeyword,
        augmentationNode: node,
        augmentationElement: element,
      );

      if (element.augmentedIfReally case var augmented?) {
        _checkAugmentationTypeParameters(
          nameToken: node.name,
          typeParameterList: node.typeParameters,
          declarationTypeParameters: augmented.declaration.typeParameters,
        );
      }

      _checkClassAugmentationTargetAlreadyHasExtendsClause(
        node: node,
        augmentationTarget: element.augmentationTarget,
      );

      _isInNativeClass = node.nativeClause != null;

      var augmented = element.augmented;
      var declarationElement = augmented.declaration;
      _enclosingClass = declarationElement;

      List<ClassMember> members = node.members;
      if (!declarationElement.isDartCoreFunctionImpl) {
        _checkForBuiltInIdentifierAsName(
            node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
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
            declarationElement, node, superclass, withClause, implementsClause);
        if (moreChecks) {
          _checkForNoDefaultSuperConstructorImplicit(element, augmented);
        }
      }

      if (node.nativeClause == null) {
        libraryContext.constructorFieldsVerifier
            .addConstructors(errorReporter, augmented, members);
      }

      _checkForConflictingClassMembers(element);
      _checkForFinalNotInitializedInClass(element, members);
      _checkForBadFunctionUse(
        superclass: node.extendsClause?.superclass,
        withClause: node.withClause,
        implementsClause: node.implementsClause,
      );
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
      _checkForMainFunction1(node.name, node.declaredElement!);
      _checkForMixinClassErrorCodes(node, members, superclass, withClause);
      _reportMacroDiagnostics(element);

      GetterSetterTypesVerifier(
        typeSystem: typeSystem,
        errorReporter: errorReporter,
      ).checkStaticAccessors(declarationElement.accessors);

      super.visitClassDeclaration(node);
    } finally {
      _isInNativeClass = false;
      _enclosingClass = null;
    }
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var element = node.declaredElement!;
    var augmented = element.augmented;
    var declarationElement = augmented.declaration;

    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    try {
      _enclosingClass = declarationElement;
      _checkClassInheritance(declarationElement, node, node.superclass,
          node.withClause, node.implementsClause);
      _checkForMainFunction1(node.name, node.declaredElement!);
      _checkForMixinClassErrorCodes(
          node, List.empty(), node.superclass, node.withClause);
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
    var element = node.declaredElement as CompilationUnitElement;
    _featureSet = node.featureSet;
    _duplicateDefinitionVerifier.checkUnit(node);
    _checkForDeferredPrefixCollisions(node);
    _checkForIllegalLanguageOverride(node);

    GetterSetterTypesVerifier(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
    ).checkStaticAccessors(element.accessors);

    super.visitCompilationUnit(node);
    _featureSet = null;
  }

  @override
  void visitConstructorDeclaration(
    covariant ConstructorDeclarationImpl node,
  ) {
    var element = node.declaredElement!;
    _withEnclosingExecutable(element, () {
      _checkForNonConstGenerativeEnumConstructor(node);
      _checkForInvalidModifierOnBody(
          node.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR);
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
      _checkAugmentations(
        augmentKeyword: node.augmentKeyword,
        element: element,
      );
      _reportMacroDiagnostics(element);
      super.visitConstructorDeclaration(node);
    });
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _isInConstructorInitializer = true;
    try {
      SimpleIdentifier fieldName = node.fieldName;
      var staticElement = fieldName.staticElement;
      _checkForInvalidField(node, fieldName, staticElement);
      if (staticElement is FieldElement) {
        _checkForAbstractOrExternalFieldConstructorInitializer(
            node.fieldName.token, staticElement);
      }
      super.visitConstructorFieldInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _typeArgumentsVerifier.checkConstructorReference(node);
    _checkForInvalidGenerativeConstructorReference(node.constructorName);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      checkForAssignableExpressionAtType(
        defaultValue,
        defaultValue.typeOrThrow,
        node.declaredElement!.type,
        CompileTimeErrorCode.INVALID_ASSIGNMENT,
      );
    }

    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    var element = node.declaredElement as FieldElementImpl;

    _checkAugmentations(
      augmentKeyword: node.augmentKeyword,
      element: element,
    );

    _requiredParametersVerifier.visitEnumConstantDeclaration(node);
    _typeArgumentsVerifier.checkEnumConstantDeclaration(node);
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    try {
      var element = node.declaredElement as EnumElementImpl;

      _checkAugmentations(
        augmentKeyword: node.augmentKeyword,
        element: element,
      );

      if (element.augmentedIfReally case var augmented?) {
        _checkAugmentationTypeParameters(
          nameToken: node.name,
          typeParameterList: node.typeParameters,
          declarationTypeParameters: augmented.declaration.typeParameters,
        );
      }

      var augmented = element.augmented;
      var declarationElement = augmented.declaration;
      _enclosingClass = declarationElement;

      _checkForBuiltInIdentifierAsName(
          node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      _checkForConflictingEnumTypeVariableErrorCodes(element);
      var implementsClause = node.implementsClause;
      var withClause = node.withClause;

      if (implementsClause != null || withClause != null) {
        _checkClassInheritance(
            declarationElement, node, null, withClause, implementsClause);
      }

      if (!element.isAugmentation) {
        if (element.augmented.constants.isEmpty) {
          errorReporter.atToken(
            node.name,
            CompileTimeErrorCode.ENUM_WITHOUT_CONSTANTS,
          );
        }
      }

      var members = node.members;
      libraryContext.constructorFieldsVerifier
          .addConstructors(errorReporter, augmented, members);
      _checkForFinalNotInitializedInClass(element, members);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
      _checkForMainFunction1(node.name, node.declaredElement!);
      _checkForEnumInstantiatedToBoundsIsNotWellBounded(node, element);

      GetterSetterTypesVerifier(
        typeSystem: typeSystem,
        errorReporter: errorReporter,
      ).checkStaticAccessors(element.accessors);

      super.visitEnumDeclaration(node);
    } finally {
      _enclosingClass = null;
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var exportElement = node.element;
    if (exportElement != null) {
      var exportedLibrary = exportElement.exportedLibrary;
      _checkForAmbiguousExport(node, exportElement, exportedLibrary);
      _checkForExportInternalLibrary(node, exportElement);
    }
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
    var element = node.declaredElement!;

    _checkAugmentations(
      augmentKeyword: node.augmentKeyword,
      element: element,
    );

    if (element.augmentedIfReally case var augmented?) {
      if (node.name case var nameToken?) {
        _checkAugmentationTypeParameters(
          nameToken: nameToken,
          typeParameterList: node.typeParameters,
          declarationTypeParameters: augmented.declaration.typeParameters,
        );
      }
    }

    _enclosingExtension = element;
    _checkForConflictingExtensionTypeVariableErrorCodes();
    _checkForFinalNotInitializedInClass(element, node.members);

    GetterSetterTypesVerifier(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
    ).checkExtension(element);

    var name = node.name;
    if (name != null) {
      _checkForBuiltInIdentifierAsName(
          name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME);
    }
    super.visitExtensionDeclaration(node);
    _enclosingExtension = null;
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    try {
      var element = node.declaredElement!;
      var augmented = element.augmented;
      var declarationElement = augmented.declaration;

      _checkAugmentations(
        augmentKeyword: node.augmentKeyword,
        element: element,
      );

      if (element.augmentedIfReally case var augmented?) {
        _checkAugmentationTypeParameters(
          nameToken: node.name,
          typeParameterList: node.typeParameters,
          declarationTypeParameters: augmented.declaration.typeParameters,
        );
      }

      _enclosingClass = declarationElement;

      _checkForBuiltInIdentifierAsName(node.name,
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_TYPE_NAME);
      _checkForConflictingExtensionTypeTypeVariableErrorCodes(element);

      var members = node.members;
      _checkForRepeatedType(
        libraryContext.setOfImplements(declarationElement),
        node.implementsClause?.interfaces,
        CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      );
      _checkForConflictingClassMembers(element);
      _checkForConflictingGenerics(node);
      libraryContext.constructorFieldsVerifier
          .addConstructors(errorReporter, augmented, members);
      _checkForNonCovariantTypeParameterPositionInRepresentationType(
          node, element);
      _checkForExtensionTypeRepresentationDependsOnItself(node, element);
      _checkForExtensionTypeRepresentationTypeBottom(node, element);
      _checkForExtensionTypeImplementsDeferred(node);
      _checkForExtensionTypeImplementsItself(node, element);
      _checkForExtensionTypeMemberConflicts(
        node: node,
        element: declarationElement,
      );
      _checkForExtensionTypeWithAbstractMember(node);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();

      var interface = _inheritanceManager.getInterface(declarationElement);
      GetterSetterTypesVerifier(
        typeSystem: typeSystem,
        errorReporter: errorReporter,
      ).checkExtensionType(element, interface);

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
        errorReporter.atToken(
          fields.keyword!,
          CompileTimeErrorCode.CONST_INSTANCE_FIELD,
        );
      }
    }
    var oldHasAccessToThis = _hasAccessToThis;
    try {
      _hasAccessToThis = !node.isStatic && node.fields.isLate;
      _checkForExtensionTypeDeclaresInstanceField(node);
      _checkForNotInitializedNonNullableStaticField(node);
      _checkForWrongTypeParameterVarianceInField(node);
      _checkForLateFinalFieldWithConstConstructor(node);
      _checkForNonFinalFieldInEnum(node);

      for (var field in fields.variables) {
        var element = field.declaredElement;
        element as FieldElementImpl;
        _checkAugmentations(
          augmentKeyword: node.augmentKeyword,
          element: element,
        );
        _reportMacroDiagnostics(element);
      }

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
    ParameterElement element = node.declaredElement!;
    if (element is FieldFormalParameterElement) {
      var fieldElement = element.field;
      if (fieldElement != null) {
        _checkForAbstractOrExternalFieldConstructorInitializer(
            node.name, fieldElement);
      }
    }
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (_checkForEachParts(node, loopVariable.declaredElement)) {
      if (loopVariable.isConst) {
        errorReporter.atToken(
          loopVariable.keyword!,
          CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE,
        );
      }
    }
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    SimpleIdentifier identifier = node.identifier;
    if (_checkForEachParts(node, identifier.staticElement)) {
      _checkForAssignmentToFinal(identifier);
    }
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _duplicateDefinitionVerifier.checkParameters(node);
    _checkUseOfCovariantInParameters(node);
    _checkUseOfDefaultValuesInParameters(node);
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _duplicateDefinitionVerifier.checkForVariables(node.variables);
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var element = node.declaredElement!;
    if (element.enclosingElement3 is! CompilationUnitElement) {
      _hiddenElements!.declare(element);
    }

    _withEnclosingExecutable(element, () {
      TypeAnnotation? returnType = node.returnType;
      if (node.isSetter) {
        FunctionExpression functionExpression = node.functionExpression;
        _checkForWrongNumberOfParametersForSetter(
            node.name, functionExpression.parameters);
        _checkForNonVoidReturnTypeForSetter(returnType);
      }
      _checkForTypeAnnotationDeferredClass(returnType);
      _returnTypeVerifier.verifyReturnType(returnType);
      _checkForMainFunction1(node.name, node.declaredElement!);
      _checkForMainFunction2(node);
      _checkAugmentations(
        augmentKeyword: node.augmentKeyword,
        element: element,
      );
      _reportMacroDiagnostics(element);
      super.visitFunctionDeclaration(node);
    });
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _isInLateLocalVariable.add(false);

    if (node.parent is FunctionDeclaration) {
      super.visitFunctionExpression(node);
    } else {
      _withEnclosingExecutable(node.declaredElement!, () {
        super.visitFunctionExpression(node);
      });
    }

    _isInLateLocalVariable.removeLast();
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    Expression functionExpression = node.function;

    if (functionExpression is ExtensionOverride) {
      return super.visitFunctionExpressionInvocation(node);
    }

    DartType expressionType = functionExpression.typeOrThrow;
    if (expressionType is FunctionType) {
      _typeArgumentsVerifier.checkFunctionExpressionInvocation(node);
    }
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
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    _checkForMainFunction1(node.name, node.declaredElement!);
    _checkForTypeAliasCannotReferenceItself(
        node.name, node.declaredElement as TypeAliasElementImpl);
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
    var element = node.declaredElement as TypeAliasElementImpl;

    _checkAugmentations(
      augmentKeyword: node.augmentKeyword,
      element: element,
    );

    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    _checkForMainFunction1(node.name, node.declaredElement!);
    _checkForTypeAliasCannotReferenceItself(
        node.name, node.declaredElement as TypeAliasElementImpl);
    _reportMacroDiagnostics(element);
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
    var importElement = node.element;
    if (node.prefix != null) {
      _checkForBuiltInIdentifierAsName(node.prefix!.token,
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME);
    }
    if (importElement != null) {
      _checkForImportInternalLibrary(node, importElement);
      if (importElement.prefix is DeferredImportElementPrefix) {
        _checkForDeferredImportOfExtensions(node, importElement);
      }
    }
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
      _checkForInvalidGenerativeConstructorReference(constructorName);
      _checkForConstOrNewWithMixin(node, namedType, type);
      _requiredParametersVerifier.visitInstanceCreationExpression(node);
      _constArgumentsVerifier.visitInstanceCreationExpression(node);
      _checkUseVerifier.checkInstanceCreationExpression(node);
      if (node.isConst) {
        _checkForConstWithNonConst(node);
        _checkForConstWithUndefinedConstructor(
            node, constructorName, namedType);
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
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {
    if (node.element case var element?) {
      _reportMacroDiagnostics(element);
    }

    super.visitLibraryDirective(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _typeArgumentsVerifier.checkListLiteral(node);
    _checkForListElementTypeNotAssignable(node);

    super.visitListLiteral(node);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var element = node.declaredElement!;
    _withEnclosingExecutable(element, () {
      var returnType = node.returnType;
      if (node.isSetter) {
        _checkForWrongNumberOfParametersForSetter(node.name, node.parameters);
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
      _checkAugmentations(
        augmentKeyword: node.augmentKeyword,
        element: element,
      );
      _reportMacroDiagnostics(element);
      super.visitMethodDeclaration(node);
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var target = node.realTarget;
    SimpleIdentifier methodName = node.methodName;
    if (target != null) {
      var typeReference = ElementResolver.getTypeReference(target);
      _checkForStaticAccessToInstanceMember(typeReference, methodName);
      _checkForInstanceAccessToStaticMember(
          typeReference, node.target, methodName);
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
      var element = node.declaredElement!;

      _checkAugmentations(
        augmentKeyword: node.augmentKeyword,
        element: element,
      );

      _checkMixinAugmentationModifiers(
        augmentKeyword: node.augmentKeyword,
        augmentationNode: node,
        augmentationElement: element,
      );

      if (element.augmentedIfReally case var augmented?) {
        _checkAugmentationTypeParameters(
          nameToken: node.name,
          typeParameterList: node.typeParameters,
          declarationTypeParameters: augmented.declaration.typeParameters,
        );
      }

      var augmented = element.augmented;
      var declarationElement = augmented.declaration;
      _enclosingClass = declarationElement;

      List<ClassMember> members = node.members;
      _checkForBuiltInIdentifierAsName(
          node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      _checkForConflictingClassTypeVariableErrorCodes();

      var onClause = node.onClause;
      var implementsClause = node.implementsClause;

      // Only do error checks only if there is a non-null clause.
      if (onClause != null || implementsClause != null) {
        _checkMixinInheritance(
            declarationElement, node, onClause, implementsClause);
      }

      _checkForConflictingClassMembers(element);
      _checkForFinalNotInitializedInClass(element, members);
      _checkForMainFunction1(node.name, declarationElement);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
      _reportMacroDiagnostics(element);
      //      _checkForBadFunctionUse(node);
      super.visitMixinDeclaration(node);
    } finally {
      _enclosingClass = null;
    }
  }

  @override
  void visitNamedType(NamedType node) {
    _checkForAmbiguousImport(
      name: node.name2,
      element: node.element,
    );
    _checkForTypeParameterReferencedByStatic(
      name: node.name2,
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
      errorReporter.atNode(
        node,
        ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE,
      );
    }
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _checkForNativeFunctionBodyInNonSdkCode(node);
    super.visitNativeFunctionBody(node);
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
  void visitPostfixExpression(PostfixExpression node) {
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
      var typeReference = ElementResolver.getTypeReference(node.prefix);
      SimpleIdentifier name = node.identifier;
      _checkForStaticAccessToInstanceMember(typeReference, name);
      _checkForInstanceAccessToStaticMember(typeReference, node.prefix, name);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    TokenType operatorType = node.operator.type;
    Expression operand = node.operand;
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
    var typeReference = ElementResolver.getTypeReference(target);
    SimpleIdentifier propertyName = node.propertyName;
    _checkForStaticAccessToInstanceMember(typeReference, propertyName);
    _checkForInstanceAccessToStaticMember(
        typeReference, node.target, propertyName);
    _checkForUnnecessaryNullAware(target, node.operator);
    _checkUseVerifier.checkPropertyAccess(node);
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
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
      element: node.staticElement,
    );
    _checkForInvalidInstanceMemberAccess(node);
    _checkForTypeParameterReferencedByStatic(
      name: node.token,
      element: node.staticElement,
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
      errorReporter.atToken(
        node.superKeyword,
        CompileTimeErrorCode
            .EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER,
      );
      return;
    }

    var constructor = node.parentFormalParameterList.parent;
    if (!(constructor is ConstructorDeclaration &&
        constructor.isNonRedirectingGenerative)) {
      errorReporter.atToken(
        node.superKeyword,
        CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION,
      );
      return;
    }

    var element = node.declaredElement as SuperFormalParameterElementImpl;
    var superParameter = element.superConstructorParameter;

    if (superParameter == null) {
      errorReporter.atToken(
        node.name,
        node.isNamed
            ? CompileTimeErrorCode
                .SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED
            : CompileTimeErrorCode
                .SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL,
      );
      return;
    }

    if (!_currentLibrary.typeSystem
        .isSubtypeOf(element.type, superParameter.type)) {
      errorReporter.atToken(
        node.name,
        CompileTimeErrorCode
            .SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED,
        arguments: [element.type, superParameter.type],
      );
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _withHiddenElements(node.statements, () {
      _duplicateDefinitionVerifier.checkStatements(node.statements);
      super.visitSwitchCase(node);
    });
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
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
  void visitSwitchPatternCase(SwitchPatternCase node) {
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
      var element = variable.declaredElement;
      element as TopLevelVariableElementImpl;
      _checkForMainFunction1(variable.name, element);
      _checkAugmentations(
        augmentKeyword: node.augmentKeyword,
        element: element,
      );
      _reportMacroDiagnostics(element);
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
    _checkForBuiltInIdentifierAsName(node.name,
        CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME);
    _checkForTypeAnnotationDeferredClass(node.bound);
    _checkForGenericFunctionType(node.bound);
    node.bound?.accept(_uninstantiatedBoundChecker);
    super.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
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
      VariableElement element = node.declaredElement!;
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

  void _checkAugmentations<T extends ElementImpl>({
    required Token? augmentKeyword,
    required T element,
  }) {
    if (augmentKeyword == null) {
      return;
    }

    if (element is! AugmentableElement<T>) {
      return;
    }

    // OK
    if (element.augmentationTarget != null) {
      return;
    }

    // Not the same kind.
    if (element.augmentationTargetAny case var target?) {
      errorReporter.atToken(
        augmentKeyword,
        CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND,
        arguments: [
          target.kind.displayName,
          element.kind.displayName,
        ],
      );
      return;
    }

    errorReporter.atToken(
      augmentKeyword,
      CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION,
    );
  }

  void _checkAugmentationTypeParameters({
    required Token nameToken,
    required TypeParameterList? typeParameterList,
    required List<TypeParameterElement> declarationTypeParameters,
  }) {
    if (declarationTypeParameters.isEmpty) {
      if (typeParameterList != null) {
        errorReporter.atToken(
          typeParameterList.leftBracket,
          CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT,
        );
      }
    } else {
      if (typeParameterList == null) {
        errorReporter.atToken(
          nameToken,
          CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT,
        );
      } else {
        var declarationCount = declarationTypeParameters.length;
        var typeParameters = typeParameterList.typeParameters;
        switch (typeParameters.length.compareTo(declarationCount)) {
          case < 0:
            errorReporter.atToken(
              typeParameterList.rightBracket,
              CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT,
            );
          case > 0:
            errorReporter.atToken(
              typeParameters[declarationCount].name,
              CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT,
            );
          default:
            for (var index = 0; index < declarationCount; index++) {
              var ofDeclaration = declarationTypeParameters[index];
              var ofAugmentation = typeParameters[index];

              if (ofAugmentation.name.lexeme != ofDeclaration.name) {
                errorReporter.atToken(
                  ofAugmentation.name,
                  CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_NAME,
                );
                continue;
              }

              var declarationBound = ofDeclaration.bound;
              var augmentationBound = ofAugmentation.bound;
              switch ((declarationBound, augmentationBound)) {
                case (null, var augmentationBound?):
                  errorReporter.atNode(
                    augmentationBound,
                    CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND,
                  );
                case (_?, null):
                  errorReporter.atToken(
                    ofAugmentation.name,
                    CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND,
                  );
                case (var declarationBound?, var augmentationBound?):
                  var augmentationType = augmentationBound.typeOrThrow;
                  if (!typeSystem.isEqualTo(
                    declarationBound,
                    augmentationType,
                  )) {
                    errorReporter.atNode(
                      augmentationBound,
                      CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND,
                    );
                  }
              }
            }
        }
      }
    }
  }

  void _checkClassAugmentationModifiers({
    required Token? augmentKeyword,
    required ClassDeclarationImpl augmentationNode,
    required ClassElementImpl augmentationElement,
  }) {
    if (augmentKeyword == null) {
      return;
    }

    var target = augmentationElement.augmentationTarget;
    if (target == null) {
      return;
    }

    var declaration = target.augmented.declaration;

    void singleModifier({
      required String modifierName,
      required bool declarationFlag,
      required Token? augmentationModifier,
    }) {
      if (declarationFlag) {
        if (augmentationModifier == null) {
          errorReporter.atToken(
            augmentKeyword,
            CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING,
            arguments: [modifierName],
          );
        }
      } else {
        if (augmentationModifier != null) {
          errorReporter.atToken(
            augmentationModifier,
            CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA,
            arguments: [modifierName],
          );
        }
      }
    }

    // Sealed classes are also abstract, report just `sealed` mismatch.
    if (!declaration.isSealed) {
      singleModifier(
        modifierName: 'abstract',
        declarationFlag: declaration.isAbstract,
        augmentationModifier: augmentationNode.abstractKeyword,
      );
    }

    singleModifier(
      modifierName: 'base',
      declarationFlag: declaration.isBase,
      augmentationModifier: augmentationNode.baseKeyword,
    );

    singleModifier(
      modifierName: 'final',
      declarationFlag: declaration.isFinal,
      augmentationModifier: augmentationNode.finalKeyword,
    );

    singleModifier(
      modifierName: 'interface',
      declarationFlag: declaration.isInterface,
      augmentationModifier: augmentationNode.interfaceKeyword,
    );

    singleModifier(
      modifierName: 'mixin',
      declarationFlag: declaration.isMixinClass,
      augmentationModifier: augmentationNode.mixinKeyword,
    );

    singleModifier(
      modifierName: 'sealed',
      declarationFlag: declaration.isSealed,
      augmentationModifier: augmentationNode.sealedKeyword,
    );
  }

  void _checkClassAugmentationTargetAlreadyHasExtendsClause({
    required ClassDeclarationImpl node,
    required ClassElementImpl? augmentationTarget,
  }) {
    var extendsClause = node.extendsClause;
    if (extendsClause == null) {
      return;
    }

    while (augmentationTarget != null) {
      if (augmentationTarget.hasExtendsClause) {
        errorReporter.atToken(
          extendsClause.extendsKeyword,
          CompileTimeErrorCode.AUGMENTATION_EXTENDS_CLAUSE_ALREADY_PRESENT,
          contextMessages: [
            DiagnosticMessageImpl(
              filePath: augmentationTarget.source.fullName,
              offset: augmentationTarget.nameOffset,
              length: augmentationTarget.nameLength,
              message: 'The extends clause is included here.',
              url: null,
            ),
          ],
        );
        return;
      }
      augmentationTarget = augmentationTarget.augmentationTarget;
    }
  }

  /// Checks the class for problems with the superclass, mixins, or implemented
  /// interfaces.
  ///
  /// Returns `false` if a severe hierarchy error was found, so that further
  /// checking is not useful.
  bool _checkClassInheritance(
      InterfaceElementImpl declarationElement,
      NamedCompilationUnitMember node,
      NamedType? superclass,
      WithClause? withClause,
      ImplementsClause? implementsClause) {
    // Only check for all of the inheritance logic around clauses if there
    // isn't an error code such as "Cannot extend double" already on the
    // class.
    if (!_checkForExtendsDisallowedClass(superclass) &&
        !_checkForImplementsClauseErrorCodes(implementsClause) &&
        !_checkForAllMixinErrorCodes(withClause) &&
        !_checkForNoGenerativeConstructorsInSuperclass(superclass)) {
      _checkForExtendsDeferredClass(superclass);
      _checkForRepeatedType(
        libraryContext.setOfImplements(declarationElement),
        implementsClause?.interfaces,
        CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      );
      _checkImplementsSuperClass(implementsClause);
      _checkMixinsSuperClass(withClause);
      _checkForMixinWithConflictingPrivateMember(withClause, superclass);
      _checkForConflictingGenerics(node);
      _checkForBaseClassOrMixinImplementedOutsideOfLibrary(implementsClause);
      _checkForInterfaceClassOrMixinSuperclassOutsideOfLibrary(
          superclass, withClause);
      _checkForFinalSupertypeOutsideOfLibrary(
          superclass, withClause, implementsClause, null);
      _checkForClassUsedAsMixin(withClause);
      _checkForSealedSupertypeOutsideOfLibrary(
          superclass, withClause, implementsClause, null);
      return true;
    }
    return false;
  }

  /// Given a list of [directives] that have the same prefix, generate an error
  /// if there is more than one import and any of those imports is deferred.
  ///
  /// See [CompileTimeErrorCode.SHARED_DEFERRED_PREFIX].
  void _checkDeferredPrefixCollision(List<ImportDirective> directives) {
    int count = directives.length;
    if (count > 1) {
      for (int i = 0; i < count; i++) {
        var deferredToken = directives[i].deferredKeyword;
        if (deferredToken != null) {
          errorReporter.atToken(
            deferredToken,
            CompileTimeErrorCode.SHARED_DEFERRED_PREFIX,
          );
        }
      }
    }
  }

  void _checkForAbstractOrExternalFieldConstructorInitializer(
      Token identifier, FieldElement fieldElement) {
    if (fieldElement.isAbstract) {
      errorReporter.atToken(
        identifier,
        CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER,
      );
    }
    if (fieldElement.isExternal) {
      errorReporter.atToken(
        identifier,
        CompileTimeErrorCode.EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER,
      );
    }
  }

  void _checkForAbstractOrExternalVariableInitializer(
      VariableDeclaration node) {
    var declaredElement = node.declaredElement;
    if (node.initializer != null) {
      if (declaredElement is FieldElement) {
        if (declaredElement.isAbstract) {
          errorReporter.atToken(
            node.name,
            CompileTimeErrorCode.ABSTRACT_FIELD_INITIALIZER,
          );
        }
        if (declaredElement.isExternal) {
          errorReporter.atToken(
            node.name,
            CompileTimeErrorCode.EXTERNAL_FIELD_INITIALIZER,
          );
        }
      } else if (declaredElement is TopLevelVariableElement) {
        if (declaredElement.isExternal) {
          errorReporter.atToken(
            node.name,
            CompileTimeErrorCode.EXTERNAL_VARIABLE_INITIALIZER,
          );
        }
      }
    }
  }

  /// Verify that all classes of the given [withClause] are valid.
  ///
  /// See [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR],
  /// [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT].
  bool _checkForAllMixinErrorCodes(WithClause? withClause) {
    if (withClause == null) {
      return false;
    }
    bool problemReported = false;
    int mixinTypeIndex = -1;
    for (int mixinNameIndex = 0;
        mixinNameIndex < withClause.mixinTypes.length;
        mixinNameIndex++) {
      NamedType mixinName = withClause.mixinTypes[mixinNameIndex];
      DartType mixinType = mixinName.typeOrThrow;
      if (mixinType is InterfaceType) {
        mixinTypeIndex++;
        if (_checkForExtendsOrImplementsDisallowedClass(
            mixinName, CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS)) {
          problemReported = true;
        } else {
          var mixinElement = mixinType.element;
          if (_checkForExtendsOrImplementsDeferredClass(
              mixinName, CompileTimeErrorCode.MIXIN_DEFERRED_CLASS)) {
            problemReported = true;
          }
          if (mixinType.element is ExtensionTypeElement) {
            // Already reported.
          } else if (mixinElement is MixinElement) {
            if (_checkForMixinSuperclassConstraints(
                mixinNameIndex, mixinName)) {
              problemReported = true;
            } else if (_checkForMixinSuperInvokedMembers(
                mixinTypeIndex, mixinName, mixinElement, mixinType)) {
              problemReported = true;
            }
          } else {
            bool isMixinClass =
                mixinElement is ClassElementImpl && mixinElement.isMixinClass;
            if (!isMixinClass &&
                _checkForMixinClassDeclaresConstructor(
                    mixinName, mixinElement)) {
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
      ConstructorDeclaration declaration) {
    // Prepare redirected constructor node
    var redirectedConstructor = declaration.redirectedConstructor;
    if (redirectedConstructor == null) {
      return;
    }

    // Prepare redirected constructor type
    var redirectedElement = redirectedConstructor.staticElement;
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
        errorReporter.atNode(
          redirectedConstructor,
          CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR,
          arguments: [constructorStrName, redirectedType],
        );
      }
      return;
    }
    FunctionType redirectedType = redirectedElement.type;
    DartType redirectedReturnType = redirectedType.returnType;

    // Report specific problem when return type is incompatible
    FunctionType constructorType = declaration.declaredElement!.type;
    DartType constructorReturnType = constructorType.returnType;
    if (!typeSystem.isAssignableTo(redirectedReturnType, constructorReturnType,
        strictCasts: strictCasts)) {
      errorReporter.atNode(
        redirectedConstructor,
        CompileTimeErrorCode.REDIRECT_TO_INVALID_RETURN_TYPE,
        arguments: [redirectedReturnType, constructorReturnType],
      );
      return;
    } else if (!typeSystem.isSubtypeOf(redirectedType, constructorType)) {
      // Check parameters.
      errorReporter.atNode(
        redirectedConstructor,
        CompileTimeErrorCode.REDIRECT_TO_INVALID_FUNCTION_TYPE,
        arguments: [redirectedType, constructorType],
      );
    }
  }

  /// Verify that the export namespace of the given export [directive] does not
  /// export any name already exported by another export directive. The
  /// [exportElement] is the [LibraryExportElement] retrieved from the node. If the
  /// element in the node was `null`, then this method is not called. The
  /// [exportedLibrary] is the library element containing the exported element.
  ///
  /// See [CompileTimeErrorCode.AMBIGUOUS_EXPORT].
  void _checkForAmbiguousExport(ExportDirective directive,
      LibraryExportElement exportElement, LibraryElement? exportedLibrary) {
    if (exportedLibrary == null) {
      return;
    }
    // check exported names
    Namespace namespace =
        NamespaceBuilder().createExportNamespaceForDirective(exportElement);
    Map<String, Element> definedNames = namespace.definedNames;
    for (String name in definedNames.keys) {
      var element = definedNames[name]!;
      var prevElement = libraryContext._exportedElements[name];
      if (prevElement != null && prevElement != element) {
        errorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.AMBIGUOUS_EXPORT,
          arguments: [
            name,
            prevElement.library!.definingCompilationUnit.source.uri,
            element.library!.definingCompilationUnit.source.uri
          ],
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
      var libraryNames =
          conflictingMembers.map((e) => _getLibraryName(e)).toList();
      libraryNames.sort();
      errorReporter.atToken(
        name,
        CompileTimeErrorCode.AMBIGUOUS_IMPORT,
        arguments: [name.lexeme, libraryNames.quotedAndCommaSeparatedWithAnd],
      );
    }
  }

  /// Verify that the given [expression] is not final.
  ///
  /// See [CompileTimeErrorCode.ASSIGNMENT_TO_CONST],
  /// [CompileTimeErrorCode.ASSIGNMENT_TO_FINAL], and
  /// [CompileTimeErrorCode.ASSIGNMENT_TO_METHOD].
  void _checkForAssignmentToFinal(Expression expression) {
    // TODO(scheglov): Check SimpleIdentifier(s) as all other nodes.
    if (expression is! SimpleIdentifier) return;

    // Already handled in the assignment resolver.
    if (expression.parent is AssignmentExpression) {
      return;
    }

    // prepare element
    var highlightedNode = expression;
    var element = expression.staticElement;
    if (expression is PrefixedIdentifier) {
      var prefixedIdentifier = expression as PrefixedIdentifier;
      highlightedNode = prefixedIdentifier.identifier;
    }
    // check if element is assignable
    if (element is VariableElement) {
      if (element.isConst) {
        errorReporter.atNode(
          expression,
          CompileTimeErrorCode.ASSIGNMENT_TO_CONST,
        );
      }
    } else if (element is PropertyAccessorElement && element.isGetter) {
      var variable = element.variable2;
      if (variable == null) {
        return;
      }
      if (variable.isConst) {
        errorReporter.atNode(
          expression,
          CompileTimeErrorCode.ASSIGNMENT_TO_CONST,
        );
      } else if (variable is FieldElement && variable.isSynthetic) {
        errorReporter.atNode(
          highlightedNode,
          CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER,
          arguments: [variable.name, variable.enclosingElement3.displayName],
        );
      } else {
        errorReporter.atNode(
          highlightedNode,
          CompileTimeErrorCode.ASSIGNMENT_TO_FINAL,
          arguments: [variable.name],
        );
      }
    } else if (element is FunctionElement) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.ASSIGNMENT_TO_FUNCTION,
      );
    } else if (element is MethodElement) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.ASSIGNMENT_TO_METHOD,
      );
    } else if (element is InterfaceElement ||
        element is DynamicElementImpl ||
        element is TypeParameterElement) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.ASSIGNMENT_TO_TYPE,
      );
    }
  }

  void _checkForAwaitInLateLocalVariableInitializer(AwaitExpression node) {
    if (_isInLateLocalVariable.last) {
      errorReporter.atToken(
        node.awaitKeyword,
        CompileTimeErrorCode.AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER,
      );
    }
  }

  void _checkForAwaitOfIncompatibleType(AwaitExpression node) {
    var expression = node.expression;
    var expressionType = expression.typeOrThrow;
    if (typeSystem.isIncompatibleWithAwait(expressionType)) {
      errorReporter.atToken(
        node.awaitKeyword,
        CompileTimeErrorCode.AWAIT_OF_INCOMPATIBLE_TYPE,
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
        errorReporter.atNode(
          superclass,
          WarningCode.DEPRECATED_EXTENDS_FUNCTION,
        );
      }
    }

    if (implementsClause != null) {
      for (var interface in implementsClause.interfaces) {
        var type = interface.type;
        if (type != null && type.isDartCoreFunction) {
          errorReporter.atNode(
            interface,
            WarningCode.DEPRECATED_IMPLEMENTS_FUNCTION,
          );
          break;
        }
      }
    }

    if (withClause != null) {
      for (NamedType mixin in withClause.mixinTypes) {
        var type = mixin.type;
        if (type != null && type.isDartCoreFunction) {
          errorReporter.atNode(
            mixin,
            WarningCode.DEPRECATED_MIXIN_FUNCTION,
          );
        }
      }
    }
  }

  /// Verify that if a class is implementing a base class or mixin, it must be
  /// within the same library as that class or mixin.
  ///
  /// See [CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY],
  /// [CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY].
  void _checkForBaseClassOrMixinImplementedOutsideOfLibrary(
      ImplementsClause? implementsClause) {
    if (implementsClause == null) return;
    for (NamedType interface in implementsClause.interfaces) {
      var interfaceType = interface.type;
      if (interfaceType is InterfaceType) {
        var implementedInterfaces = [
          interfaceType,
          ...interfaceType.element.allSupertypes,
        ].map((e) => e.element).toList();
        for (var interfaceElement in implementedInterfaces) {
          if (interfaceElement is ClassOrMixinElementImpl &&
              interfaceElement.isBase &&
              interfaceElement.library != _currentLibrary &&
              !_mayIgnoreClassModifiers(interfaceElement.library)) {
            // Should this be combined with _checkForImplementsClauseErrorCodes
            // to avoid double errors if implementing `int`.
            if (interfaceElement is ClassElementImpl &&
                !interfaceElement.isSealed) {
              errorReporter.atNode(
                interface,
                CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY,
                arguments: [interfaceElement.name],
              );
            } else if (interfaceElement is MixinElement) {
              errorReporter.atNode(
                interface,
                CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY,
                arguments: [interfaceElement.name],
              );
            }
            break;
          }
        }
      }
    }
  }

  /// Verify that the given [token] is not a keyword, and generates the
  /// given [errorCode] on the identifier if it is a keyword.
  ///
  /// See [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME],
  /// [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME],
  /// [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME], and
  /// [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME].
  void _checkForBuiltInIdentifierAsName(Token token, ErrorCode errorCode) {
    if (token.type.isKeyword && token.keyword?.isPseudo != true) {
      errorReporter.atToken(
        token,
        errorCode,
        arguments: [token.lexeme],
      );
    }
  }

  /// Verify that if a class is being mixed in and class modifiers are enabled
  /// in that class' library, then it must be a mixin class.
  ///
  /// See [CompileTimeErrorCode.CLASS_USED_AS_MIXIN].
  void _checkForClassUsedAsMixin(WithClause? withClause) {
    if (withClause != null) {
      for (NamedType withMixin in withClause.mixinTypes) {
        var withType = withMixin.type;
        if (withType is InterfaceType) {
          var withElement = withType.element;
          if (withElement is ClassElementImpl &&
              !withElement.isMixinClass &&
              withElement.library.featureSet
                  .isEnabled(Feature.class_modifiers) &&
              !_mayIgnoreClassModifiers(withElement.library)) {
            errorReporter.atNode(
              withMixin,
              CompileTimeErrorCode.CLASS_USED_AS_MIXIN,
              arguments: [withElement.name],
            );
          }
        }
      }
    }
  }

  /// Verify that the [_enclosingClass] does not have a method and getter pair
  /// with the same name, via inheritance.
  ///
  /// See [CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE],
  /// [CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD], and
  /// [CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD].
  void _checkForConflictingClassMembers(InterfaceElement fragment) {
    var enclosingClass = _enclosingClass;
    if (enclosingClass == null) {
      return;
    }

    Uri libraryUri = _currentLibrary.source.uri;
    var conflictingDeclaredNames = <String>{};

    // method declared in the enclosing class vs. inherited getter/setter
    for (MethodElement method in fragment.methods) {
      if (method.source != _currentUnit.source) {
        continue;
      }

      String name = method.name;

      // find inherited property accessors
      var getter = _inheritanceManager.getInherited2(
          enclosingClass, Name(libraryUri, name));
      var setter = _inheritanceManager.getInherited2(
          enclosingClass, Name(libraryUri, '$name='));

      if (method.isStatic) {
        void reportStaticConflict(ExecutableElement inherited) {
          errorReporter.atElement(
            method,
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
            arguments: [
              enclosingClass.displayName,
              name,
              inherited.enclosingElement3.displayName,
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
      if (enclosingClass is ExtensionTypeElement) {
        continue;
      }

      void reportFieldConflict(PropertyAccessorElement inherited) {
        errorReporter.atElement(
          method,
          CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD,
          arguments: [
            enclosingClass.displayName,
            name,
            inherited.enclosingElement3.displayName
          ],
        );
      }

      if (getter is PropertyAccessorElement) {
        reportFieldConflict(getter);
        continue;
      }

      if (setter is PropertyAccessorElement) {
        reportFieldConflict(setter);
        continue;
      }
    }

    // getter declared in the enclosing class vs. inherited method
    for (PropertyAccessorElement accessor in fragment.accessors) {
      String name = accessor.displayName;

      // find inherited method or property accessor
      var inherited = _inheritanceManager.getInherited2(
          enclosingClass, Name(libraryUri, name));
      inherited ??= _inheritanceManager.getInherited2(
          enclosingClass, Name(libraryUri, '$name='));

      if (accessor.isStatic && inherited != null) {
        errorReporter.atElement(
          accessor,
          CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
          arguments: [
            enclosingClass.displayName,
            name,
            inherited.enclosingElement3.displayName,
          ],
        );
        conflictingDeclaredNames.add(name);
      } else if (inherited is MethodElement) {
        // Extension type accessors preclude inherited accessors/methods.
        if (enclosingClass is ExtensionTypeElement) {
          continue;
        }
        errorReporter.atElement(
          accessor,
          CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD,
          arguments: [
            enclosingClass.displayName,
            name,
            inherited.enclosingElement3.displayName
          ],
        );
        conflictingDeclaredNames.add(name);
      }
    }

    // Inherited method and setter with the same name.
    var inherited = _inheritanceManager.getInheritedMap2(enclosingClass);
    for (var entry in inherited.entries) {
      var method = entry.value;
      if (method is MethodElement) {
        var methodName = entry.key;
        if (conflictingDeclaredNames.contains(methodName.name)) {
          continue;
        }
        var setterName = methodName.forSetter;
        var setter = inherited[setterName];
        if (setter is PropertyAccessorElement) {
          errorReporter.atElement(
            enclosingClass,
            CompileTimeErrorCode.CONFLICTING_INHERITED_METHOD_AND_SETTER,
            arguments: [
              enclosingClass.kind.displayName,
              enclosingClass.displayName,
              methodName.name,
            ],
            contextMessages: [
              DiagnosticMessageImpl(
                filePath: method.source.fullName,
                message: formatList(
                  "The method is inherited from the {0} '{1}'.",
                  [
                    method.enclosingElement3.kind.displayName,
                    method.enclosingElement3.name,
                  ],
                ),
                offset: method.nameOffset,
                length: method.nameLength,
                url: null,
              ),
              DiagnosticMessageImpl(
                filePath: setter.source.fullName,
                message: formatList(
                  "The setter is inherited from the {0} '{1}'.",
                  [
                    setter.enclosingElement3.kind.displayName,
                    setter.enclosingElement3.name,
                  ],
                ),
                offset: setter.nameOffset,
                length: setter.nameLength,
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

      String name = typeParameter.name;
      // name is same as the name of the enclosing class
      if (enclosingClass.name == name) {
        var code = enclosingClass is MixinElement
            ? CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MIXIN
            : CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS;
        errorReporter.atElement(
          typeParameter,
          code,
          arguments: [name],
        );
      }
      // check members
      if (enclosingClass.getNamedConstructor(name) != null ||
          enclosingClass.getMethod(name) != null ||
          enclosingClass.getGetter(name) != null ||
          enclosingClass.getSetter(name) != null) {
        var code = enclosingClass is MixinElement
            ? CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN
            : CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS;
        errorReporter.atElement(
          typeParameter,
          code,
          arguments: [name],
        );
      }
    }
  }

  void _checkForConflictingEnumTypeVariableErrorCodes(
    EnumElementImpl element,
  ) {
    for (var typeParameter in element.typeParameters) {
      var name = typeParameter.name;
      // name is same as the name of the enclosing enum
      if (element.name == name) {
        errorReporter.atElement(
          typeParameter,
          CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_ENUM,
          arguments: [name],
        );
      }
      // check members
      if (element.getMethod(name) != null ||
          element.getGetter(name) != null ||
          element.getSetter(name) != null) {
        errorReporter.atElement(
          typeParameter,
          CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_ENUM,
          arguments: [name],
        );
      }
    }
  }

  void _checkForConflictingExtensionTypeTypeVariableErrorCodes(
    ExtensionTypeElementImpl element,
  ) {
    for (var typeParameter in element.typeParameters) {
      if (typeParameter.isWildcardVariable) continue;

      var name = typeParameter.name;
      // name is same as the name of the enclosing class
      if (element.name == name) {
        errorReporter.atElement(
          typeParameter,
          CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION_TYPE,
          arguments: [name],
        );
      }
      // check members
      if (element.getNamedConstructor(name) != null ||
          element.getMethod(name) != null ||
          element.getGetter(name) != null ||
          element.getSetter(name) != null) {
        errorReporter.atElement(
          typeParameter,
          CompileTimeErrorCode
              .CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION_TYPE,
          arguments: [name],
        );
      }
    }
  }

  /// Verify all conflicts between type variable and enclosing extension.
  ///
  /// See [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION], and
  /// [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION_MEMBER].
  void _checkForConflictingExtensionTypeVariableErrorCodes() {
    for (TypeParameterElement typeParameter
        in _enclosingExtension!.typeParameters) {
      String name = typeParameter.name;
      // name is same as the name of the enclosing class
      if (_enclosingExtension!.name == name) {
        errorReporter.atElement(
          typeParameter,
          CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION,
          arguments: [name],
        );
      }
      // check members
      if (_enclosingExtension!.getMethod(name) != null ||
          _enclosingExtension!.getGetter(name) != null ||
          _enclosingExtension!.getSetter(name) != null) {
        errorReporter.atElement(
          typeParameter,
          CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION,
          arguments: [name],
        );
      }
    }
  }

  void _checkForConflictingGenerics(NamedCompilationUnitMember node) {
    var element = node.declaredElement as InterfaceElementImpl;

    // Report only on the declaration.
    if (element.isAugmentation) {
      return;
    }

    var analysisSession = _currentLibrary.session;
    var errors = analysisSession.classHierarchy.errors(element);

    for (var error in errors) {
      if (error is IncompatibleInterfacesClassHierarchyError) {
        errorReporter.atToken(
          node.name,
          CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES,
          arguments: [
            _enclosingClass!.kind.displayName,
            _enclosingClass!.name,
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
      ConstructorDeclaration declaration) {
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
          errorReporter.atNode(
            initializer,
            CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS,
          );
        }
        if (declaration.factoryKeyword == null) {
          RedirectingConstructorInvocation invocation = initializer;
          var redirectingElement = invocation.staticElement;
          if (redirectingElement == null) {
            String enclosingNamedType = enclosingClass.displayName;
            String constructorStrName = enclosingNamedType;
            if (invocation.constructorName != null) {
              constructorStrName += ".${invocation.constructorName!.name}";
            }
            errorReporter.atNode(
              invocation,
              CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR,
              arguments: [constructorStrName, enclosingNamedType],
            );
          } else {
            if (redirectingElement.isFactory) {
              errorReporter.atNode(
                initializer,
                CompileTimeErrorCode
                    .REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR,
              );
            }
          }
        }
        // [declaration] is a redirecting constructor via a redirecting
        // initializer.
        _checkForRedirectToNonConstConstructor(
          declaration.declaredElement!,
          initializer.staticElement,
          initializer.constructorName ?? initializer.thisKeyword,
        );
        redirectingInitializerCount++;
      } else if (initializer is SuperConstructorInvocation) {
        if (enclosingClass is EnumElement) {
          errorReporter.atToken(
            initializer.superKeyword,
            CompileTimeErrorCode.SUPER_IN_ENUM_CONSTRUCTOR,
          );
        } else if (superInitializerCount == 1) {
          // Only report the second (first illegal) superinitializer.
          errorReporter.atNode(
            initializer,
            CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS,
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
            errorReporter.atNode(
              initializer,
              CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR,
            );
          }
        }
        if (initializer is ConstructorFieldInitializer) {
          errorReporter.atNode(
            initializer,
            CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
          );
        }
        if (initializer is AssertInitializer) {
          errorReporter.atNode(
            initializer,
            CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR,
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
        errorReporter.atToken(
          superInitializer.superKeyword,
          CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST,
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
  /// See [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER], and
  /// [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD].
  bool _checkForConstConstructorWithNonConstSuper(
      ConstructorDeclaration constructor) {
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
      instanceFields.addAll(mixin.element.fields.where((field) {
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
      }));
    }
    if (instanceFields.length == 1) {
      var field = instanceFields.single;
      errorReporter.atNode(
        constructor.returnType,
        CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD,
        arguments: ["'${field.enclosingElement3.name}.${field.name}'"],
      );
      return true;
    } else if (instanceFields.length > 1) {
      var fieldNames = instanceFields
          .map((field) => "'${field.enclosingElement3.name}.${field.name}'")
          .join(', ');
      errorReporter.atNode(
        constructor.returnType,
        CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS,
        arguments: [fieldNames],
      );
      return true;
    }

    // Enum(s) always call a const super-constructor.
    if (enclosingClass is EnumElement) {
      return false;
    }

    var element = constructor.declaredElement;
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

    errorReporter.atNode(
      errorNode,
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER,
      arguments: [element.enclosingElement3.displayName],
    );
    return true;
  }

  /// Verify that if the given [constructor] declaration is 'const' then there
  /// are no non-final instance variable. The [constructorElement] is the
  /// constructor element.
  void _checkForConstConstructorWithNonFinalField(
      ConstructorDeclaration constructor,
      ConstructorElement constructorElement) {
    if (!_enclosingExecutable.isConstConstructor) {
      return;
    }
    if (!_enclosingExecutable.isGenerativeConstructor) {
      return;
    }
    // check if there is non-final field
    var classElement = constructorElement.enclosingElement3;
    if (classElement is! ClassElement || !classElement.hasNonFinalField) {
      return;
    }
    errorReporter.atConstructorDeclaration(
      constructor,
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
    );
  }

  /// Verify that the given 'const' instance creation [expression] is not
  /// creating a deferred type. The [constructorName] is the constructor name,
  /// always non-`null`. The [namedType] is the name of the type defining the
  /// constructor, always non-`null`.
  ///
  /// See [CompileTimeErrorCode.CONST_DEFERRED_CLASS].
  void _checkForConstDeferredClass(InstanceCreationExpression expression,
      ConstructorName constructorName, NamedType namedType) {
    if (namedType.isDeferred) {
      errorReporter.atNode(
        constructorName,
        CompileTimeErrorCode.CONST_DEFERRED_CLASS,
      );
    }
  }

  /// Verify that the given throw [expression] is not enclosed in a 'const'
  /// constructor declaration.
  ///
  /// See [CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION].
  void _checkForConstEvalThrowsException(ThrowExpression expression) {
    if (_enclosingExecutable.isConstConstructor) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION,
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
      InterfaceType type) {
    var element = type.element;
    if (element is ClassElement && element.isAbstract) {
      var element = expression.constructorName.staticElement;
      if (element != null && !element.isFactory) {
        bool isImplicit =
            (expression as InstanceCreationExpressionImpl).isImplicit;
        if (!isImplicit) {
          errorReporter.atNode(
            namedType,
            CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS,
          );
        } else {
          errorReporter.atNode(
            namedType,
            CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS,
          );
        }
      }
    }
  }

  /// Verify that the given [expression] is not a mixin instantiation.
  void _checkForConstOrNewWithMixin(InstanceCreationExpression expression,
      NamedType namedType, InterfaceType type) {
    if (type.element is MixinElement) {
      errorReporter.atNode(
        namedType,
        CompileTimeErrorCode.MIXIN_INSTANTIATE,
      );
    }
  }

  /// Verify that the given 'const' instance creation [expression] is not being
  /// invoked on a constructor that is not 'const'.
  ///
  /// This method assumes that the instance creation was tested to be 'const'
  /// before being called.
  ///
  /// See [CompileTimeErrorCode.CONST_WITH_NON_CONST].
  void _checkForConstWithNonConst(InstanceCreationExpression expression) {
    var constructorElement = expression.constructorName.staticElement;
    if (constructorElement != null && !constructorElement.isConst) {
      if (expression.keyword != null) {
        errorReporter.atToken(
          expression.keyword!,
          CompileTimeErrorCode.CONST_WITH_NON_CONST,
        );
      } else {
        errorReporter.atNode(
          expression,
          CompileTimeErrorCode.CONST_WITH_NON_CONST,
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
  /// See [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR], and
  /// [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT].
  void _checkForConstWithUndefinedConstructor(
      InstanceCreationExpression expression,
      ConstructorName constructorName,
      NamedType namedType) {
    // OK if resolved
    if (constructorName.staticElement != null) {
      return;
    }
    // report as named or default constructor absence
    var name = constructorName.name;
    if (name != null) {
      errorReporter.atNode(
        name,
        CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR,
        arguments: [namedType.qualifiedName, name.name],
      );
    } else {
      errorReporter.atNode(
        constructorName,
        CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
        arguments: [namedType.qualifiedName],
      );
    }
  }

  void _checkForDeadNullCoalesce(TypeImpl lhsType, Expression rhs) {
    if (typeSystem.isStrictlyNonNullable(lhsType)) {
      errorReporter.atNode(
        rhs,
        StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION,
      );
    }
  }

  /// Report a diagnostic if there are any extensions in the imported library
  /// that are not hidden.
  void _checkForDeferredImportOfExtensions(
      ImportDirective directive, LibraryImportElement importElement) {
    for (var element in importElement.namespace.definedNames.values) {
      if (element is ExtensionElement) {
        errorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.DEFERRED_IMPORT_OF_EXTENSION,
        );
        return;
      }
    }
  }

  /// Verify that any deferred imports in the given compilation [unit] have a
  /// unique prefix.
  ///
  /// See [CompileTimeErrorCode.SHARED_DEFERRED_PREFIX].
  void _checkForDeferredPrefixCollisions(CompilationUnit unit) {
    NodeList<Directive> directives = unit.directives;
    int count = directives.length;
    if (count > 0) {
      Map<PrefixElement, List<ImportDirective>> prefixToDirectivesMap =
          HashMap<PrefixElement, List<ImportDirective>>();
      for (int i = 0; i < count; i++) {
        Directive directive = directives[i];
        if (directive is ImportDirective) {
          var prefix = directive.prefix;
          if (prefix != null) {
            var element = prefix.staticElement;
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

    DartType iterableType = node.iterable.typeOrThrow;

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
      errorReporter.atNode(
        node.iterable,
        CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE,
        arguments: [iterableType, loopNamedType],
      );
      return false;
    }

    // TODO(scheglov): use NullableDereferenceVerifier
    if (typeSystem.isNullable(iterableType)) {
      return false;
    }

    // The type of the loop variable.
    DartType variableType;
    if (variableElement is VariableElement) {
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

    if (!typeSystem.isAssignableTo(iterableType, requiredSequenceType,
        strictCasts: strictCasts)) {
      errorReporter.atNode(
        node.iterable,
        CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE,
        arguments: [iterableType, loopNamedType],
      );
      return false;
    }

    DartType? sequenceElementType;
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

    if (!typeSystem.isAssignableTo(sequenceElementType, variableType,
        strictCasts: strictCasts)) {
      // Use an explicit string instead of [loopType] to remove the "<E>".
      String loopNamedType = awaitKeyword != null ? 'Stream' : 'Iterable';

      // A for-in loop is specified to desugar to a different set of statements
      // which include an assignment of the sequence element's `iterator`'s
      // `current` value, at which point "implicit tear-off conversion" may be
      // performed. We do not perform this desugaring; instead we allow a
      // special assignability here.
      var implicitCallMethod = getImplicitCallMethod(
          sequenceElementType, variableType, node.iterable);
      if (implicitCallMethod == null) {
        errorReporter.atNode(
          node.iterable,
          CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE,
          arguments: [iterableType, loopNamedType, variableType],
        );
      } else {
        var tearoffType = implicitCallMethod.type;
        // An implicit tear-off conversion does occur on the values of the
        // iterator, but this does not guarantee their assignability.

        if (_featureSet?.isEnabled(Feature.constructor_tearoffs) ?? true) {
          var typeArguments = typeSystem.inferFunctionTypeInstantiation(
            variableType as FunctionType,
            tearoffType,
            errorReporter: errorReporter,
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

        if (!typeSystem.isAssignableTo(tearoffType, variableType,
            strictCasts: strictCasts)) {
          errorReporter.atNode(
            node.iterable,
            CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE,
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
    if (valuesFieldType is InterfaceType) {
      var isWellBounded = typeSystem.isWellBounded(
        valuesFieldType.typeArguments.single,
        allowSuperBounded: true,
      );
      if (isWellBounded is NotWellBoundedTypeResult) {
        errorReporter.atToken(
          node.name,
          CompileTimeErrorCode.ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED,
        );
      }
    }
  }

  /// Check that if the visiting library is not system, then any given library
  /// should not be SDK internal library. The [exportElement] is the
  /// [LibraryExportElement] retrieved from the node, if the element in the node was
  /// `null`, then this method is not called.
  ///
  /// See [CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY].
  void _checkForExportInternalLibrary(
      ExportDirective directive, LibraryExportElement exportElement) {
    if (_isInSystemLibrary) {
      return;
    }

    var exportedLibrary = exportElement.exportedLibrary;
    if (exportedLibrary == null) {
      return;
    }

    // should be private
    var sdk = _currentLibrary.context.sourceFactory.dartSdk!;
    var uri = exportedLibrary.source.uri.toString();

    // We allow exporting `dart:_macros` from `package:macros`.
    if (uri == 'dart:_macros' &&
        _currentLibrary.source.uri.scheme == 'package' &&
        _currentLibrary.source.uri.pathSegments.first == 'macros') {
      return;
    }
    var sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return;
    }
    if (!sdkLibrary.isInternal) {
      return;
    }

    // It is safe to assume that `directive.uri.stringValue` is non-`null`,
    // because the only time it is `null` is if the URI contains a string
    // interpolation, in which case the export would never have resolved in the
    // first place.
    errorReporter.atNode(
      directive,
      CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY,
      arguments: [directive.uri.stringValue!],
    );
  }

  /// Verify that the given extends [clause] does not extend a deferred class.
  ///
  /// See [CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS].
  void _checkForExtendsDeferredClass(NamedType? superclass) {
    if (superclass == null) {
      return;
    }
    _checkForExtendsOrImplementsDeferredClass(
        superclass, CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS);
  }

  /// Verify that the given extends [clause] does not extend classes such as
  /// 'num' or 'String'.
  ///
  /// See [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS].
  bool _checkForExtendsDisallowedClass(NamedType? superclass) {
    if (superclass == null) {
      return false;
    }
    return _checkForExtendsOrImplementsDisallowedClass(
        superclass, CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS);
  }

  /// Verify that the given [namedType] does not extend, implement or mixin
  /// classes that are deferred.
  ///
  /// See [_checkForExtendsDeferredClass],
  /// [_checkForExtendsDeferredClassInTypeAlias],
  /// [_checkForImplementsDeferredClass],
  /// [_checkForAllMixinErrorCodes],
  /// [CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS],
  /// [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS], and
  /// [CompileTimeErrorCode.MIXIN_DEFERRED_CLASS].
  bool _checkForExtendsOrImplementsDeferredClass(
      NamedType namedType, ErrorCode errorCode) {
    if (namedType.isSynthetic) {
      return false;
    }
    if (namedType.isDeferred) {
      errorReporter.atNode(
        namedType,
        errorCode,
      );
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
      NamedType namedType, ErrorCode errorCode) {
    if (namedType.isSynthetic) {
      return false;
    }
    // The SDK implementation may implement disallowed types. For example,
    // JSNumber in dart2js and _Smi in Dart VM both implement int.
    if (_currentLibrary.source.uri.isScheme('dart')) {
      return false;
    }
    var type = namedType.type;
    return type is InterfaceType &&
        _typeProvider.isNonSubtypableClass(type.element);
  }

  void _checkForExtensionDeclaresMemberOfObject(MethodDeclaration node) {
    if (_enclosingExtension != null) {
      if (node.hasObjectMemberName) {
        errorReporter.atToken(
          node.name,
          CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT,
        );
      }
    }

    if (_enclosingClass is ExtensionTypeElement) {
      if (node.hasObjectMemberName) {
        errorReporter.atToken(
          node.name,
          CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT,
        );
      }
    }
  }

  void _checkForExtensionTypeConstructorWithSuperInvocation(
    SuperConstructorInvocation node,
  ) {
    if (_enclosingClass is ExtensionTypeElement) {
      errorReporter.atToken(
        node.superKeyword,
        CompileTimeErrorCode.EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_INVOCATION,
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
      errorReporter.atToken(
        field.name,
        CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD,
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
        CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS,
      );
    }
  }

  void _checkForExtensionTypeImplementsItself(
    ExtensionTypeDeclarationImpl node,
    ExtensionTypeElementImpl element,
  ) {
    if (element.hasImplementsSelfReference) {
      errorReporter.atToken(
        node.name,
        CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_ITSELF,
      );
    }
  }

  void _checkForExtensionTypeMemberConflicts({
    required ExtensionTypeDeclaration node,
    required ExtensionTypeElement element,
  }) {
    void report(String memberName, List<ExecutableElement> candidates) {
      var contextMessages = candidates.map<DiagnosticMessage>((executable) {
        var nonSynthetic = executable.nonSynthetic;
        var container = executable.enclosingElement3 as InterfaceElement;
        return DiagnosticMessageImpl(
          filePath: executable.source.fullName,
          offset: nonSynthetic.nameOffset,
          length: nonSynthetic.nameLength,
          message: "Inherited from '${container.name}'",
          url: null,
        );
      }).toList();
      errorReporter.atToken(
        node.name,
        CompileTimeErrorCode.EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT,
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
    ExtensionTypeElementImpl element,
  ) {
    if (element.hasRepresentationSelfReference) {
      errorReporter.atToken(
        node.name,
        CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF,
      );
    }
  }

  void _checkForExtensionTypeRepresentationTypeBottom(
    ExtensionTypeDeclarationImpl node,
    ExtensionTypeElementImpl element,
  ) {
    var representationType = element.representation.type;
    if (representationType.isBottom) {
      errorReporter.atNode(
        node.representation.fieldType,
        CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM,
      );
    }
  }

  void _checkForExtensionTypeWithAbstractMember(
    ExtensionTypeDeclarationImpl node,
  ) {
    for (var member in node.members) {
      if (member is MethodDeclarationImpl && !member.isStatic) {
        if (member.isAbstract) {
          errorReporter.atNode(
            member,
            CompileTimeErrorCode.EXTENSION_TYPE_WITH_ABSTRACT_MEMBER,
            arguments: [member.name.lexeme, node.name.lexeme],
          );
        }
      }
    }
  }

  /// Verify that the given field formal [parameter] is in a constructor
  /// declaration.
  ///
  /// See [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR].
  void _checkForFieldInitializingFormalRedirectingConstructor(
      FieldFormalParameter parameter) {
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
        errorReporter.atNode(
          parameter,
          CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR,
        );
        return;
      }
      // constructor cannot have a redirection
      for (ConstructorInitializer initializer in constructor.initializers) {
        if (initializer is RedirectingConstructorInvocation) {
          errorReporter.atNode(
            parameter,
            CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
          );
          return;
        }
      }
    } else {
      errorReporter.atNode(
        parameter,
        CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
      );
    }
  }

  /// Verify that the given variable declaration [list] has only initialized
  /// variables if the list is final or const.
  ///
  /// See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
  /// [CompileTimeErrorCode.FINAL_NOT_INITIALIZED].
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
          errorReporter.atToken(
            variable.name,
            CompileTimeErrorCode.CONST_NOT_INITIALIZED,
            arguments: [variable.name.lexeme],
          );
        } else {
          var variableElement = variable.declaredElement;
          if (variableElement is FieldElement &&
              (variableElement.isAbstract || variableElement.isExternal)) {
            // Abstract and external fields can't be initialized, so no error.
          } else if (variableElement is TopLevelVariableElement &&
              variableElement.isExternal) {
            // External top level variables can't be initialized, so no error.
          } else if (!variable.isLate) {
            errorReporter.atToken(
              variable.name,
              CompileTimeErrorCode.FINAL_NOT_INITIALIZED,
              arguments: [variable.name.lexeme],
            );
          }
        }
      }
    }
  }

  /// If there are no constructors in the given [members], verify that all
  /// final fields are initialized.  Cases in which there is at least one
  /// constructor are handled in [_checkForAllFinalInitializedErrorCodes].
  ///
  /// See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
  /// [CompileTimeErrorCode.FINAL_NOT_INITIALIZED].
  void _checkForFinalNotInitializedInClass(
    InstanceElementImpl container,
    List<ClassMember> members,
  ) {
    if (container is InterfaceElementImpl) {
      var augmented = container.augmented;
      for (var constructor in augmented.constructors) {
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
  /// See [CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY],
  /// [CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY],
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
          errorReporter.atNode(
            superclass,
            CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY,
            arguments: [element.name],
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
                  type.element.library.featureSet
                      .isEnabled(Feature.class_modifiers)) {
                continue;
              }

              errorReporter.atNode(
                namedType,
                CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY,
                arguments: [element.name],
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
            errorReporter.atNode(
              namedType,
              CompileTimeErrorCode
                  .FINAL_CLASS_USED_AS_MIXIN_CONSTRAINT_OUTSIDE_OF_LIBRARY,
              arguments: [element.name],
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
    if (type is FunctionType && type.typeFormals.isNotEmpty) {
      errorReporter.atNode(
        node,
        CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND,
      );
    }
  }

  void _checkForIllegalLanguageOverride(CompilationUnit node) {
    var sourceLanguageConstraint = options.sourceLanguageConstraint;
    if (sourceLanguageConstraint == null) {
      return;
    }

    var languageVersion = _currentLibrary.languageVersion.effective;
    if (sourceLanguageConstraint.allows(languageVersion)) {
      return;
    }

    var languageVersionToken = node.languageVersionToken;
    if (languageVersionToken != null) {
      errorReporter.atToken(
        languageVersionToken,
        CompileTimeErrorCode.ILLEGAL_LANGUAGE_VERSION_OVERRIDE,
        arguments: ['$sourceLanguageConstraint'],
      );
    }
  }

  /// Verify that the given implements [clause] does not implement classes such
  /// as 'num' or 'String'.
  ///
  /// See [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS],
  /// [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS].
  bool _checkForImplementsClauseErrorCodes(ImplementsClause? clause) {
    if (clause == null) {
      return false;
    }
    bool foundError = false;
    for (NamedType type in clause.interfaces) {
      if (_checkForExtendsOrImplementsDisallowedClass(
          type, CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS)) {
        foundError = true;
      } else if (_checkForExtendsOrImplementsDeferredClass(
          type, CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS)) {
        foundError = true;
      }
    }
    return foundError;
  }

  /// Check that if the visiting library is not system, then any given library
  /// should not be SDK internal library. The [importElement] is the
  /// [LibraryImportElement] retrieved from the node, if the element in the node
  /// was `null`, then this method is not called.
  void _checkForImportInternalLibrary(
      ImportDirective directive, LibraryImportElement importElement) {
    if (_isInSystemLibrary || _isWasm(importElement)) {
      return;
    }

    var importedLibrary = importElement.importedLibrary;
    if (importedLibrary == null) {
      return;
    }

    // should be private
    var sdk = _currentLibrary.context.sourceFactory.dartSdk!;
    var uri = importedLibrary.source.uri.toString();
    var sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null || !sdkLibrary.isInternal) {
      return;
    }
    // The only way an import URI's `stringValue` can be `null` is if the string
    // contained interpolations, in which case the import would have failed to
    // resolve, and we would never reach here.  So it is safe to assume that
    // `directive.uri.stringValue` is non-`null`.
    errorReporter.atNode(
      directive.uri,
      CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY,
      arguments: [directive.uri.stringValue!],
    );
  }

  /// Check that the given [typeReference] is not a type reference and that then
  /// the [name] is reference to an instance member.
  ///
  /// See [CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER].
  void _checkForInstanceAccessToStaticMember(InterfaceElement? typeReference,
      Expression? target, SimpleIdentifier name) {
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
      Element enclosingElement = element.enclosingElement3;
      if (enclosingElement is ExtensionElement) {
        if (target is ExtensionOverride) {
          // OK, target is an extension override
          return;
        } else if (target is SimpleIdentifier &&
            target.staticElement is ExtensionElement) {
          return;
        } else if (target is PrefixedIdentifier &&
            target.staticElement is ExtensionElement) {
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
  /// [CompileTimeErrorCode.INTERFACE_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY].
  void _checkForInterfaceClassOrMixinSuperclassOutsideOfLibrary(
      NamedType? superclass, WithClause? withClause) {
    if (superclass != null) {
      var superclassType = superclass.type;
      if (superclassType is InterfaceType) {
        var superclassElement = superclassType.element;
        if (superclassElement is ClassElementImpl &&
            superclassElement.isInterface &&
            !superclassElement.isSealed &&
            superclassElement.library != _currentLibrary &&
            !_mayIgnoreClassModifiers(superclassElement.library)) {
          errorReporter.atNode(
            superclass,
            CompileTimeErrorCode.INTERFACE_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY,
            arguments: [superclassElement.name],
          );
        }
      }
    }
  }

  /// Verify that an 'int' can be assigned to the parameter corresponding to the
  /// given [argument]. This is used for prefix and postfix expressions where
  /// the argument value is implicit.
  ///
  /// See [CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
  void _checkForIntNotAssignable(Expression argument) {
    var staticParameterElement = argument.staticParameterElement;
    var staticParameterType = staticParameterElement?.type;
    if (staticParameterType != null) {
      checkForArgumentTypeNotAssignable(argument, staticParameterType, _intType,
          CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
    }
  }

  /// Verify that the given [annotation] isn't defined in a deferred library.
  ///
  /// See [CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY].
  void _checkForInvalidAnnotationFromDeferredLibrary(Annotation annotation) {
    Identifier nameIdentifier = annotation.name;
    if (nameIdentifier is PrefixedIdentifier && nameIdentifier.isDeferred) {
      errorReporter.atNode(
        annotation.name,
        CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY,
      );
    }
  }

  /// Check the given [initializer] to ensure that the field being initialized
  /// is a valid field. The [fieldName] is the field name from the
  /// [ConstructorFieldInitializer]. The [staticElement] is the static element
  /// from the name in the [ConstructorFieldInitializer].
  void _checkForInvalidField(ConstructorFieldInitializer initializer,
      SimpleIdentifier fieldName, Element? staticElement) {
    if (staticElement is FieldElement) {
      if (staticElement.isSynthetic) {
        errorReporter.atNode(
          initializer,
          CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD,
          arguments: [fieldName.name],
        );
      } else if (staticElement.isStatic) {
        errorReporter.atNode(
          initializer,
          CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD,
          arguments: [fieldName.name],
        );
      }
    } else {
      errorReporter.atNode(
        initializer,
        CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD,
        arguments: [fieldName.name],
      );
      return;
    }
  }

  void _checkForInvalidGenerativeConstructorReference(ConstructorName node) {
    var constructorElement = node.staticElement;
    if (constructorElement != null &&
        constructorElement.isGenerative &&
        constructorElement.enclosingElement3 is EnumElement) {
      if (_currentLibrary.featureSet.isEnabled(Feature.enhanced_enums)) {
        errorReporter.atNode(
          node,
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
        );
      } else {
        errorReporter.atNode(
          node.type,
          CompileTimeErrorCode.INSTANTIATE_ENUM,
        );
      }
    }
  }

  /// Verify that if the given [identifier] is part of a constructor
  /// initializer, then it does not implicitly reference 'this' expression.
  ///
  /// See [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER],
  /// [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY], and
  /// [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC].
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
    Element enclosingElement = element.enclosingElement3;
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
      errorReporter.atNode(
        identifier,
        CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC,
      );
    } else if (_enclosingExecutable.inFactoryConstructor) {
      errorReporter.atNode(
        identifier,
        CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY,
      );
    } else {
      errorReporter.atNode(
        identifier,
        CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER,
        arguments: [identifier.name],
      );
    }
  }

  /// Check to see whether the given function [body] has a modifier associated
  /// with it, and report it as an error if it does.
  void _checkForInvalidModifierOnBody(
      FunctionBody body, CompileTimeErrorCode errorCode) {
    var keyword = body.keyword;
    if (keyword != null) {
      errorReporter.atToken(
        keyword,
        errorCode,
        arguments: [keyword.lexeme],
      );
    }
  }

  /// Verify that the usage of the given 'this' is valid.
  ///
  /// See [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS].
  void _checkForInvalidReferenceToThis(ThisExpression expression) {
    if (!_hasAccessToThis) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS,
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

    var hasGenerativeConstConstructor =
        _enclosingClass!.constructors.any((c) => c.isConst && !c.isFactory);
    if (!hasGenerativeConstConstructor) return;

    errorReporter.atToken(
      lateKeyword,
      CompileTimeErrorCode.LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR,
    );
  }

  /// Verify that the elements of the given list [literal] are subtypes of the
  /// list's static type.
  ///
  /// See [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE].
  void _checkForListElementTypeNotAssignable(ListLiteral literal) {
    // Determine the list's element type. We base this on the static type and
    // not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType listType = literal.typeOrThrow;
    assert(listType is InterfaceTypeImpl);

    List<DartType> typeArguments =
        (listType as InterfaceTypeImpl).typeArguments;
    assert(typeArguments.length == 1);

    DartType listElementType = typeArguments[0];

    // Check every list element.
    var verifier = LiteralElementVerifier(
      _typeProvider,
      typeSystem,
      errorReporter,
      this,
      forList: true,
      elementType: listElementType,
      featureSet: _featureSet!,
    );
    for (CollectionElement element in literal.elements) {
      verifier.verify(element);
    }
  }

  void _checkForMainFunction1(Token nameToken, Element declaredElement) {
    // We should only check exported declarations, i.e. top-level.
    if (declaredElement.enclosingElement3 is! CompilationUnitElement) {
      return;
    }

    if (declaredElement.displayName != 'main') {
      return;
    }

    if (declaredElement is! FunctionElement) {
      errorReporter.atToken(
        nameToken,
        CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION,
      );
    }
  }

  void _checkForMainFunction2(FunctionDeclaration functionDeclaration) {
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
    var requiredPositional =
        parameters.where((e) => e.isRequiredPositional).toList();

    if (requiredPositional.length > 2) {
      errorReporter.atToken(
        functionDeclaration.name,
        CompileTimeErrorCode.MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS,
      );
    }

    if (parameters.any((e) => e.isRequiredNamed)) {
      errorReporter.atToken(
        functionDeclaration.name,
        CompileTimeErrorCode.MAIN_HAS_REQUIRED_NAMED_PARAMETERS,
      );
    }

    if (positional.isNotEmpty) {
      var first = positional.first;
      var type = first.declaredElement!.type;
      var listOfString = _typeProvider.listType(_typeProvider.stringType);
      if (!typeSystem.isSubtypeOf(listOfString, type)) {
        errorReporter.atNode(
          first.notDefault.typeOrSelf,
          CompileTimeErrorCode.MAIN_FIRST_POSITIONAL_PARAMETER_TYPE,
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

    List<DartType> typeArguments = (mapType as InterfaceTypeImpl).typeArguments;
    // It is possible for the number of type arguments to be inconsistent when
    // the literal is ambiguous and a non-map type was selected.
    // TODO(brianwilkerson): Unify this and _checkForSetElementTypeNotAssignable3
    //  to better handle recovery situations.
    if (typeArguments.length == 2) {
      DartType keyType = typeArguments[0];
      DartType valueType = typeArguments[1];

      var verifier = LiteralElementVerifier(
        _typeProvider,
        typeSystem,
        errorReporter,
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
          errorReporter.atOffset(
            offset: offset,
            length: end - offset,
            errorCode: StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH,
            arguments: [constantName],
          );
        }

        if (typeSystem.isNullable(expressionType) && !hasCaseNull) {
          int offset = statement.offset;
          int end = statement.rightParenthesis.end;
          errorReporter.atOffset(
            offset: offset,
            length: end - offset,
            errorCode: StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH,
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
  /// See [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR].
  bool _checkForMixinClassDeclaresConstructor(
      NamedType mixinName, InterfaceElement mixinElement) {
    for (ConstructorElement constructor in mixinElement.constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        errorReporter.atNode(
          mixinName,
          CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR,
          arguments: [mixinElement.name],
        );
        return true;
      }
    }
    return false;
  }

  /// Verify that mixin classes must have 'Object' as their superclass and that
  /// they do not have a constructor.
  ///
  /// See [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR],
  /// [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT].
  void _checkForMixinClassErrorCodes(
      NamedCompilationUnitMember node,
      List<ClassMember> members,
      NamedType? superclass,
      WithClause? withClause) {
    var element = node.declaredElement;
    if (element is ClassElementImpl && element.isMixinClass) {
      // Check that the class does not have a constructor.
      for (ClassMember member in members) {
        if (member is ConstructorDeclarationImpl) {
          if (!member.isSynthetic && member.factoryKeyword == null) {
            // Report errors on non-trivial generative constructors on mixin
            // classes.
            if (!member.isTrivial) {
              errorReporter.atNode(
                member.returnType,
                CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR,
                arguments: [element.name],
              );
            }
          }
        }
      }
      // Check that the class has 'Object' as their superclass.
      if (superclass != null && !superclass.typeOrThrow.isDartCoreObject) {
        errorReporter.atNode(
          superclass,
          CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT,
          arguments: [element.name],
        );
      } else if (withClause != null &&
          !(element.isMixinApplication && withClause.mixinTypes.length < 2)) {
        errorReporter.atNode(
          withClause,
          CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT,
          arguments: [element.name],
        );
      }
    }
  }

  /// Verify that the given mixin has the 'Object' superclass.
  ///
  /// The [mixinName] is the node to report problem on. The [mixinElement] is
  /// the mixing to evaluate.
  ///
  /// See [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT].
  bool _checkForMixinInheritsNotFromObject(
      NamedType mixinName, InterfaceElement mixinElement) {
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

    errorReporter.atNode(
      mixinName,
      CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT,
      arguments: [mixinElement.name],
    );
    return true;
  }

  /// Check that superclass constrains for the mixin type of [mixinName] at
  /// the [mixinIndex] position in the mixins list are satisfied by the
  /// [_enclosingClass], or a previous mixin.
  bool _checkForMixinSuperclassConstraints(
      int mixinIndex, NamedType mixinName) {
    InterfaceType mixinType = mixinName.type as InterfaceType;
    for (var constraint in mixinType.superclassConstraints) {
      var superType = _enclosingClass!.supertype as InterfaceTypeImpl;
      superType = superType.withNullability(NullabilitySuffix.none);

      bool isSatisfied = typeSystem.isSubtypeOf(superType, constraint);
      if (!isSatisfied) {
        for (int i = 0; i < mixinIndex && !isSatisfied; i++) {
          isSatisfied =
              typeSystem.isSubtypeOf(_enclosingClass!.mixins[i], constraint);
        }
      }
      if (!isSatisfied) {
        // This error can only occur if [mixinName] resolved to an actual mixin,
        // so we can safely rely on `mixinName.type` being non-`null`.
        errorReporter.atToken(
          mixinName.name2,
          CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          arguments: [
            mixinName.type!,
            superType,
            constraint,
          ],
        );
        return true;
      }
    }
    return false;
  }

  /// Check that the superclass of the given [mixinElement] at the given
  /// [mixinIndex] in the list of mixins of [_enclosingClass] has concrete
  /// implementations of all the super-invoked members of the [mixinElement].
  bool _checkForMixinSuperInvokedMembers(int mixinIndex, NamedType mixinName,
      InterfaceElement mixinElement, InterfaceType mixinType) {
    var mixinElementImpl = mixinElement as MixinElementImpl;
    if (mixinElementImpl.superInvokedNames.isEmpty) {
      return false;
    }

    Uri mixinLibraryUri = mixinElement.librarySource.uri;
    for (var name in mixinElementImpl.superInvokedNames) {
      var nameObject = Name(mixinLibraryUri, name);

      var superMember = _inheritanceManager.getMember2(
          _enclosingClass!, nameObject,
          forMixinIndex: mixinIndex, concrete: true, forSuper: true);

      if (superMember == null) {
        var isSetter = name.endsWith('=');

        var errorCode = isSetter
            ? CompileTimeErrorCode
                .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_SETTER
            : CompileTimeErrorCode
                .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER;

        if (isSetter) {
          name = name.substring(0, name.length - 1);
        }

        errorReporter.atNode(
          mixinName,
          errorCode,
          arguments: [name],
        );
        return true;
      }

      var mixinMember =
          _inheritanceManager.getMember(mixinType, nameObject, forSuper: true);

      if (mixinMember != null) {
        var isCorrect = CorrectOverrideHelper(
          typeSystem: typeSystem,
          thisMember: superMember,
        ).isCorrectOverrideOf(
          superMember: mixinMember,
        );
        if (!isCorrect) {
          errorReporter.atNode(
            mixinName,
            CompileTimeErrorCode
                .MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE,
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
      WithClause? withClause, NamedType? superclassName) {
    if (withClause == null) {
      return;
    }
    var declaredSupertype = superclassName?.type ?? _typeProvider.objectType;
    if (declaredSupertype is! InterfaceType) {
      return;
    }
    Map<LibraryElement, Map<String, String>> mixedInNames =
        <LibraryElement, Map<String, String>>{};

    /// Report an error and return `true` if the given [name] is a private name
    /// (which is defined in the given [library]) and it conflicts with another
    /// definition of that name inherited from the superclass.
    bool isConflictingName(
        String name, LibraryElement library, NamedType namedType) {
      if (Identifier.isPrivateName(name)) {
        Map<String, String> names = mixedInNames.putIfAbsent(library, () => {});
        var conflictingName = names[name];
        if (conflictingName != null) {
          if (name.endsWith('=')) {
            name = name.substring(0, name.length - 1);
          }
          errorReporter.atNode(
            namedType,
            CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION,
            arguments: [name, namedType.name2.lexeme, conflictingName],
          );
          return true;
        }
        names[name] = namedType.name2.lexeme;
        var inheritedMember = _inheritanceManager.getMember2(
          declaredSupertype.element,
          Name(library.source.uri, name),
          concrete: true,
        );
        if (inheritedMember != null) {
          if (name.endsWith('=')) {
            name = name.substring(0, name.length - 1);
          }
          // Inherited members are always contained inside named elements, so we
          // can safely assume `inheritedMember.enclosingElement3.name` is
          // non-`null`.
          errorReporter.atNode(
            namedType,
            CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION,
            arguments: [
              name,
              namedType.name2.lexeme,
              inheritedMember.enclosingElement3.name!
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
        LibraryElement library = type.element.library;
        if (library != _currentLibrary) {
          for (PropertyAccessorElement accessor in type.accessors) {
            if (accessor.isStatic) {
              continue;
            }
            if (isConflictingName(accessor.name, library, mixinType)) {
              return;
            }
          }
          for (MethodElement method in type.methods) {
            if (method.isStatic) {
              continue;
            }
            if (isConflictingName(method.name, library, mixinType)) {
              return;
            }
          }
        }
      }
    }
  }

  /// Checks to ensure that the given native function [body] is in SDK code.
  ///
  /// See [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE].
  void _checkForNativeFunctionBodyInNonSdkCode(NativeFunctionBody body) {
    if (!_isInSystemLibrary) {
      errorReporter.atNode(
        body,
        ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE,
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
  /// See [CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR].
  void _checkForNewWithUndefinedConstructor(
      InstanceCreationExpression expression,
      ConstructorName constructorName,
      NamedType namedType) {
    // OK if resolved
    if (constructorName.staticElement != null) {
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
      errorReporter.atNode(
        name,
        CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR,
        arguments: [namedType.qualifiedName, name.name],
      );
    } else {
      errorReporter.atNode(
        constructorName,
        CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
        arguments: [namedType.qualifiedName],
      );
    }
  }

  /// Check that if the given class [element] implicitly calls default
  /// constructor of its superclass, there should be such default constructor -
  /// implicit or explicit.
  ///
  /// See [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT].
  void _checkForNoDefaultSuperConstructorImplicit(
    ClassElementImpl element,
    AugmentedClassElement augmented,
  ) {
    // do nothing if there is explicit constructor
    var constructors = augmented.constructors;
    if (!constructors[0].isSynthetic) {
      return;
    }
    // prepare super
    var superType = element.supertype;
    if (superType == null) {
      return;
    }
    var superElement = superType.element;
    // try to find default generative super constructor
    var superUnnamedConstructor = superElement.unnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        errorReporter.atElement(
          element,
          CompileTimeErrorCode.NON_GENERATIVE_IMPLICIT_CONSTRUCTOR,
          arguments: [
            superElement.name,
            element.name,
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
      errorReporter.atElement(
        element,
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT,
        arguments: [superType, element.displayName],
      );
    }
  }

  bool _checkForNoGenerativeConstructorsInSuperclass(NamedType? superclass) {
    var superType = _enclosingClass!.supertype;
    if (superType == null) {
      return false;
    }
    if (_enclosingClass!.constructors
        .every((constructor) => constructor.isFactory)) {
      // A class with no generative constructors *can* be extended if the
      // subclass has only factory constructors.
      return false;
    }
    var superElement = superType.element;
    if (superElement.constructors.isEmpty) {
      // Exclude empty constructor set, which indicates other errors occurred.
      return false;
    }
    if (superElement.constructors
        .every((constructor) => constructor.isFactory)) {
      // For `E extends Exception`, etc., this will never work, because it has
      // no generative constructors. State this clearly to users.
      errorReporter.atNode(
        superclass!,
        CompileTimeErrorCode.NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS,
        arguments: [_enclosingClass!.name, superElement.name],
      );
      return true;
    }
    return false;
  }

  void _checkForNonConstGenerativeEnumConstructor(ConstructorDeclaration node) {
    if (_enclosingClass is EnumElement &&
        node.constKeyword == null &&
        node.factoryKeyword == null) {
      errorReporter.atConstructorDeclaration(
        node,
        CompileTimeErrorCode.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR,
      );
    }
  }

  /// Verify the given map [literal] either:
  /// * has `const modifier`
  /// * has explicit type arguments
  /// * is not start of the statement
  ///
  /// See [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT].
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
    errorReporter.atNode(
      literal,
      CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT,
    );
  }

  void _checkForNonCovariantTypeParameterPositionInRepresentationType(
    ExtensionTypeDeclaration node,
    ExtensionTypeElement element,
  ) {
    var typeParameters = node.typeParameters?.typeParameters;
    if (typeParameters == null) {
      return;
    }

    var representationType = element.representation.type;

    for (var typeParameterNode in typeParameters) {
      var typeParameterElement = typeParameterNode.declaredElement!;
      var nonCovariant = representationType.accept(
        NonCovariantTypeParameterPositionVisitor(
          [typeParameterElement],
          initialVariance: Variance.covariant,
        ),
      );
      if (nonCovariant) {
        errorReporter.atNode(
          typeParameterNode,
          CompileTimeErrorCode
              .NON_COVARIANT_TYPE_PARAMETER_POSITION_IN_REPRESENTATION_TYPE,
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

    errorReporter.atToken(
      variableList.variables.first.name,
      CompileTimeErrorCode.NON_FINAL_FIELD_IN_ENUM,
    );
  }

  /// Verify that the given method [declaration] of operator `[]=`, has `void`
  /// return type.
  ///
  /// See [CompileTimeErrorCode.NON_VOID_RETURN_FOR_OPERATOR].
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
        errorReporter.atNode(
          annotation,
          CompileTimeErrorCode.NON_VOID_RETURN_FOR_OPERATOR,
        );
      }
    }
  }

  /// Verify the [namedType], used as the return type of a setter, is valid
  /// (either `null` or the type 'void').
  ///
  /// See [CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER].
  void _checkForNonVoidReturnTypeForSetter(TypeAnnotation? namedType) {
    if (namedType != null) {
      DartType type = namedType.typeOrThrow;
      if (type is! VoidType) {
        errorReporter.atNode(
          namedType,
          CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER,
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
      var fieldElement = field.declaredElement as FieldElement;
      if (fieldElement.isAbstract || fieldElement.isExternal) continue;
      if (field.initializer != null) continue;

      var type = fieldElement.type;
      if (!typeSystem.isPotentiallyNonNullable(type)) continue;

      errorReporter.atNode(
        field,
        CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD,
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
        errorReporter.atToken(
          variable.name,
          CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE,
          arguments: [variable.name.lexeme],
        );
      }
    }
  }

  /// Verify that all classes of the given [onClause] are valid.
  ///
  /// See [CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS],
  /// [CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS].
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
            CompileTimeErrorCode
                .MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS)) {
          problemReported = true;
        } else {
          if (_checkForExtendsOrImplementsDeferredClass(
              namedType,
              CompileTimeErrorCode
                  .MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS)) {
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
  /// See [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR].
  void _checkForOptionalParameterInOperator(MethodDeclaration declaration) {
    var parameterList = declaration.parameters;
    if (parameterList == null) {
      return;
    }

    NodeList<FormalParameter> formalParameters = parameterList.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      if (formalParameter.isOptional) {
        errorReporter.atNode(
          formalParameter,
          CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR,
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

      errorReporter.atNode(
        node,
        treatedAsDouble
            ? CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE
            : CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE,
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

    errorReporter.atToken(
      name,
      CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER,
    );
  }

  /// Check whether the given constructor [declaration] is the redirecting
  /// generative constructor and references itself directly or indirectly. The
  /// [constructorElement] is the constructor element.
  ///
  /// See [CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT].
  void _checkForRecursiveConstructorRedirect(ConstructorDeclaration declaration,
      ConstructorElement constructorElement) {
    // we check generative constructor here
    if (declaration.factoryKeyword != null) {
      return;
    }
    // try to find redirecting constructor invocation and analyze it for
    // recursion
    for (ConstructorInitializer initializer in declaration.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (_hasRedirectingFactoryConstructorCycle(constructorElement)) {
          errorReporter.atNode(
            initializer,
            CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT,
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
  /// See [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT].
  bool _checkForRecursiveFactoryRedirect(
      ConstructorDeclaration declaration, ConstructorElement element) {
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
    errorReporter.atNode(
      redirectedConstructorNode,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
    );
    return true;
  }

  /// Check that the given constructor [declaration] has a valid redirected
  /// constructor.
  void _checkForRedirectingConstructorErrorCodes(
      ConstructorDeclaration declaration) {
    // Check for default values in the parameters.
    var redirectedConstructor = declaration.redirectedConstructor;
    if (redirectedConstructor == null) {
      return;
    }
    for (FormalParameter parameter in declaration.parameters.parameters) {
      if (parameter is DefaultFormalParameter &&
          parameter.defaultValue != null) {
        errorReporter.atToken(
          parameter.name!,
          CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR,
        );
      }
    }
    var redirectedElement = redirectedConstructor.staticElement;
    _checkForRedirectToNonConstConstructor(
      declaration.declaredElement!,
      redirectedElement,
      redirectedConstructor,
    );
    var redirectedClass = redirectedElement?.enclosingElement3;
    if (redirectedClass is ClassElement &&
        redirectedClass.isAbstract &&
        redirectedElement != null &&
        !redirectedElement.isFactory) {
      String enclosingNamedType = _enclosingClass!.displayName;
      String constructorStrName = enclosingNamedType;
      if (declaration.name != null) {
        constructorStrName += ".${declaration.name!.lexeme}";
      }
      errorReporter.atNode(
        redirectedConstructor,
        CompileTimeErrorCode.REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR,
        arguments: [constructorStrName, redirectedClass.name],
      );
    }
    _checkForInvalidGenerativeConstructorReference(redirectedConstructor);
  }

  /// Check whether the redirecting constructor, [element], is const, and
  /// [redirectedElement], its redirectee, is not const.
  ///
  /// See [CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR].
  void _checkForRedirectToNonConstConstructor(
    ConstructorElement element,
    ConstructorElement? redirectedElement,
    SyntacticEntity errorEntity,
  ) {
    // This constructor is const, but it redirects to a non-const constructor.
    if (redirectedElement != null &&
        element.isConst &&
        !redirectedElement.isConst) {
      errorReporter.atEntity(
        errorEntity,
        CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR,
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
      errorReporter.reportError(
        DiagnosticFactory().referencedBeforeDeclaration(
          errorReporter.source,
          nameToken: nameToken,
          element: element,
        ),
      );
    }
  }

  void _checkForRepeatedType(
    Set<InstanceElement> accumulatedElements,
    List<NamedType>? namedTypes,
    ErrorCode errorCode,
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
          errorReporter.atNode(
            namedType,
            errorCode,
            arguments: [element.name],
          );
        }
      }
    }
  }

  /// Check that the given rethrow [expression] is inside of a catch clause.
  ///
  /// See [CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH].
  void _checkForRethrowOutsideCatch(RethrowExpression expression) {
    if (_enclosingExecutable.catchClauseLevel == 0) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH,
      );
    }
  }

  /// Check that if the given constructor [declaration] is generative, then
  /// it does not have an expression function body.
  ///
  /// See [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR].
  void _checkForReturnInGenerativeConstructor(
      ConstructorDeclaration declaration) {
    // ignore factory
    if (declaration.factoryKeyword != null) {
      return;
    }
    // block body (with possible return statement) is checked elsewhere
    FunctionBody body = declaration.body;
    if (body is! ExpressionFunctionBody) {
      return;
    }

    errorReporter.atNode(
      body,
      CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR,
    );
  }

  /// Check that if a direct supertype of a node is sealed, then it must be in
  /// the same library.
  ///
  /// See [CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY].
  void _checkForSealedSupertypeOutsideOfLibrary(
      NamedType? superclass,
      WithClause? withClause,
      ImplementsClause? implementsClause,
      MixinOnClause? onClause) {
    void reportErrorsForSealedClassesAndMixins(List<NamedType> namedTypes) {
      for (NamedType namedType in namedTypes) {
        var type = namedType.type;
        if (type is InterfaceType) {
          var element = type.element;
          if (element is ClassElement &&
              element.isSealed &&
              element.library != _currentLibrary) {
            errorReporter.atNode(
              namedType,
              CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY,
              arguments: [element.name],
            );
          }
        }
      }
    }

    if (superclass != null) {
      reportErrorsForSealedClassesAndMixins([superclass]);
    }
    if (withClause != null) {
      reportErrorsForSealedClassesAndMixins(withClause.mixinTypes);
    }
    if (implementsClause != null) {
      reportErrorsForSealedClassesAndMixins(implementsClause.interfaces);
    }
    if (onClause != null) {
      reportErrorsForSealedClassesAndMixins(onClause.superclassConstraints);
    }
  }

  /// Verify that the elements in the given set [literal] are subtypes of the
  /// set's static type.
  ///
  /// See [CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE].
  void _checkForSetElementTypeNotAssignable3(SetOrMapLiteral literal) {
    // Determine the set's element type. We base this on the static type and
    // not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType setType = literal.typeOrThrow;
    assert(setType is InterfaceTypeImpl);

    List<DartType> typeArguments = (setType as InterfaceTypeImpl).typeArguments;
    // It is possible for the number of type arguments to be inconsistent when
    // the literal is ambiguous and a non-set type was selected.
    // TODO(brianwilkerson): Unify this and _checkForMapTypeNotAssignable3 to
    //  better handle recovery situations.
    if (typeArguments.length == 1) {
      DartType setElementType = typeArguments[0];

      // Check every set element.
      var verifier = LiteralElementVerifier(
        _typeProvider,
        typeSystem,
        errorReporter,
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
  /// See [CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER].
  void _checkForStaticAccessToInstanceMember(
      InterfaceElement? typeReference, SimpleIdentifier name) {
    // OK, in comment
    if (_isInComment) {
      return;
    }
    // OK, target is not a type
    if (typeReference == null) {
      return;
    }
    // prepare member Element
    var element = name.staticElement;
    if (element is ExecutableElement) {
      // OK, static
      if (element.isStatic || element is ConstructorElement) {
        return;
      }
      errorReporter.atNode(
        name,
        CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
        arguments: [name.name],
      );
    }
  }

  void _checkForThrowOfInvalidType(ThrowExpression node) {
    var expression = node.expression;
    var type = node.expression.typeOrThrow;

    if (!typeSystem.isAssignableTo(type, typeSystem.objectNone,
        strictCasts: strictCasts)) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.THROW_OF_INVALID_TYPE,
        arguments: [type],
      );
    }
  }

  /// Verify that the given [element] does not reference itself directly.
  /// If it does, report the error on the [node].
  ///
  /// See [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF].
  void _checkForTypeAliasCannotReferenceItself(
    Token nameToken,
    TypeAliasElementImpl element,
  ) {
    if (element.hasSelfReference) {
      errorReporter.atToken(
        nameToken,
        CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      );
    }
  }

  /// Verify that the [type] is not a deferred type.
  ///
  /// See [CompileTimeErrorCode.TYPE_ANNOTATION_DEFERRED_CLASS].
  void _checkForTypeAnnotationDeferredClass(TypeAnnotation? type) {
    if (type is NamedType && type.isDeferred) {
      errorReporter.atNode(
        type,
        CompileTimeErrorCode.TYPE_ANNOTATION_DEFERRED_CLASS,
        arguments: [type.qualifiedName],
      );
    }
  }

  /// Check that none of the type [parameters] references itself in its bound.
  ///
  /// See [CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND].
  void _checkForTypeParameterBoundRecursion(List<TypeParameter> parameters) {
    Map<TypeParameterElement, TypeParameter>? elementToNode;
    for (var parameter in parameters) {
      if (parameter.bound != null) {
        if (elementToNode == null) {
          elementToNode = {};
          for (var parameter in parameters) {
            elementToNode[parameter.declaredElement!] = parameter;
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
            var element = parameter.declaredElement!;
            // This error can only occur if there is a bound, so we can safely
            // assume `element.bound` is non-`null`.
            errorReporter.atToken(
              parameter.name,
              CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND,
              arguments: [element.displayName, element.bound!],
            );
            break;
          }
        }
      }
    }
  }

  void _checkForTypeParameterReferencedByStatic({
    required Token name,
    required Element? element,
  }) {
    if (_enclosingExecutable.inStaticMethod || _isInStaticVariableDeclaration) {
      if (element is TypeParameterElement &&
          element.enclosingElement3 is InstanceElement) {
        // The class's type parameters are not in scope for static methods.
        // However all other type parameters are legal (e.g. the static method's
        // type parameters, or a local function's type parameters).
        errorReporter.atToken(
          name,
          CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC,
        );
      }
    }
  }

  /// Check that if the given generative [constructor] has neither an explicit
  /// super constructor invocation nor a redirecting constructor invocation,
  /// that the superclass has a default generative constructor.
  ///
  /// See [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT],
  /// [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR], and
  /// [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT].
  void _checkForUndefinedConstructorInInitializerImplicit(
      ConstructorDeclaration constructor) {
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

    if (superElement.constructors
        .every((constructor) => constructor.isFactory)) {
      // Already reported [NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS].
      return;
    }

    var superUnnamedConstructor = superElement.unnamedConstructor;
    if (superUnnamedConstructor == null) {
      errorReporter.atNode(
        constructor.returnType,
        CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
        arguments: [superElement.name],
      );
      return;
    }

    if (superUnnamedConstructor.isFactory) {
      errorReporter.atNode(
        constructor.returnType,
        CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR,
        arguments: [superUnnamedConstructor],
      );
      return;
    }

    var requiredPositionalParameterCount = superUnnamedConstructor.parameters
        .where((parameter) => parameter.isRequiredPositional)
        .length;
    var requiredNamedParameters = superUnnamedConstructor.parameters
        .where((parameter) => parameter.isRequiredNamed)
        .map((parameter) => parameter.name)
        .toSet();

    void reportError(ErrorCode errorCode, List<Object> arguments) {
      Identifier returnType = constructor.returnType;
      var name = constructor.name;
      int offset = returnType.offset;
      int length = (name != null ? name.end : returnType.end) - offset;
      errorReporter.atOffset(
        offset: offset,
        length: length,
        errorCode: errorCode,
        arguments: arguments,
      );
    }

    if (!_currentLibrary.featureSet.isEnabled(Feature.super_parameters)) {
      if (requiredPositionalParameterCount != 0 ||
          requiredNamedParameters.isNotEmpty) {
        reportError(
          CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT,
          [superType],
        );
      }
      return;
    }

    var superParametersResult = verifySuperFormalParameters(
      constructor: constructor,
      errorReporter: errorReporter,
    );
    requiredNamedParameters.removeAll(
      superParametersResult.namedArgumentNames,
    );

    if (requiredPositionalParameterCount >
            superParametersResult.positionalArgumentCount ||
        requiredNamedParameters.isNotEmpty) {
      reportError(
        CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS,
        [superType],
      );
    }
  }

  void _checkForUnnecessaryNullAware(Expression target, Token operator) {
    if (target is SuperExpression) {
      return;
    }

    ErrorCode errorCode;
    Token endToken = operator;
    List<Object> arguments = const [];
    if (operator.type == TokenType.QUESTION) {
      errorCode = StaticWarningCode.INVALID_NULL_AWARE_OPERATOR;
      endToken = operator.next!;
      arguments = ['?[', '['];
    } else if (operator.type == TokenType.QUESTION_PERIOD) {
      errorCode = StaticWarningCode.INVALID_NULL_AWARE_OPERATOR;
      arguments = [operator.lexeme, '.'];
    } else if (operator.type == TokenType.QUESTION_PERIOD_PERIOD) {
      errorCode = StaticWarningCode.INVALID_NULL_AWARE_OPERATOR;
      arguments = [operator.lexeme, '..'];
    } else if (operator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION) {
      errorCode = StaticWarningCode.INVALID_NULL_AWARE_OPERATOR;
      arguments = [operator.lexeme, '...'];
    } else if (operator.type == TokenType.BANG) {
      errorCode = StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION;
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
        var targetElement = target.staticElement;
        if (targetElement is InterfaceElement ||
            targetElement is ExtensionElement ||
            targetElement is TypeAliasElement) {
          errorReporter.atOffset(
            offset: operator.offset,
            length: endToken.end - operator.offset,
            errorCode: errorCode,
            arguments: arguments,
          );
        }
      }
      return;
    }

    if (typeSystem.isStrictlyNonNullable(targetType)) {
      if (errorCode == StaticWarningCode.INVALID_NULL_AWARE_OPERATOR) {
        var previousOperator = previousShortCircuitingOperator(target);
        if (previousOperator != null) {
          errorReporter.reportError(DiagnosticFactory()
              .invalidNullAwareAfterShortCircuit(
                  errorReporter.source,
                  operator.offset,
                  endToken.end - operator.offset,
                  arguments,
                  previousOperator));
          return;
        }
      }
      errorReporter.atOffset(
        offset: operator.offset,
        length: endToken.end - operator.offset,
        errorCode: errorCode,
        arguments: arguments,
      );
    }
  }

  /// Check that if the given [name] is a reference to a static member it is
  /// defined in the enclosing class rather than in a superclass.
  ///
  /// See
  /// [CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER].
  void _checkForUnqualifiedReferenceToNonLocalStaticMember(
      SimpleIdentifier name) {
    var element = name.writeOrReadElement;
    if (element == null || element is TypeParameterElement) {
      return;
    }

    var enclosingElement = element.enclosingElement3;
    if (enclosingElement == null) {
      return;
    }

    if (identical(enclosingElement.augmentedDeclaration, _enclosingClass)) {
      return;
    }
    if (enclosingElement is! InterfaceElement) {
      return;
    }
    if (element is ExecutableElement && !element.isStatic) {
      return;
    }
    if (element is MethodElement) {
      // Invalid methods are reported in
      // [MethodInvocationResolver._resolveReceiverNull].
      return;
    }
    if (_enclosingExtension != null) {
      errorReporter.atNode(
        name,
        CompileTimeErrorCode
            .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
        arguments: [enclosingElement.displayName],
      );
    } else {
      errorReporter.atNode(
        name,
        CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
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
    ParameterElement element = parameter.declaredElement!;
    if (element is FieldFormalParameterElement) {
      var fieldElement = element.field;
      if (fieldElement == null || fieldElement.isSynthetic) {
        errorReporter.atNode(
          parameter,
          CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
          arguments: [parameter.name.lexeme],
        );
      } else {
        var parameterElement = parameter.declaredElement!;
        if (parameterElement is FieldFormalParameterElementImpl) {
          DartType declaredType = parameterElement.type;
          DartType fieldType = fieldElement.type;
          if (fieldElement.isSynthetic) {
            errorReporter.atNode(
              parameter,
              CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
              arguments: [parameter.name.lexeme],
            );
          } else if (fieldElement.isStatic) {
            errorReporter.atNode(
              parameter,
              CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD,
              arguments: [parameter.name.lexeme],
            );
          } else if (!typeSystem.isSubtypeOf(declaredType, fieldType)) {
            errorReporter.atNode(
              parameter,
              CompileTimeErrorCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE,
              arguments: [declaredType, fieldType],
            );
          }
        } else {
          if (fieldElement.isSynthetic) {
            errorReporter.atNode(
              parameter,
              CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
              arguments: [parameter.name.lexeme],
            );
          } else if (fieldElement.isStatic) {
            errorReporter.atNode(
              parameter,
              CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD,
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
  /// See [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR].
  bool _checkForWrongNumberOfParametersForOperator(
      MethodDeclaration declaration) {
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
      errorReporter.atToken(
        nameToken,
        CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR,
        arguments: [name, expected, numParameters],
      );
      return true;
    } else if ("-" == name && numParameters > 1) {
      errorReporter.atToken(
        nameToken,
        CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS,
        arguments: [numParameters],
      );
      return true;
    }
    return false;
  }

  /// Verify that the given setter [parameterList] has only one required
  /// parameter. The [setterName] is the name of the setter to report problems
  /// on.
  ///
  /// This method assumes that the method declaration was tested to be a setter
  /// before being called.
  ///
  /// See [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER].
  void _checkForWrongNumberOfParametersForSetter(
      Token setterName, FormalParameterList? parameterList) {
    if (parameterList == null) {
      return;
    }

    NodeList<FormalParameter> parameters = parameterList.parameters;
    if (parameters.length != 1 || !parameters[0].isRequiredPositional) {
      errorReporter.atToken(
        setterName,
        CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
      );
    }
  }

  void _checkForWrongTypeParameterVarianceInField(FieldDeclaration node) {
    if (_enclosingClass != null) {
      for (var typeParameter in _enclosingClass!.typeParameters) {
        // TODO(kallentu): : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        if (!(typeParameter as TypeParameterElementImpl).isLegacyCovariant) {
          var fields = node.fields;
          var fieldElement = fields.variables.first.declaredElement!;
          var fieldName = fields.variables.first.name;
          Variance fieldVariance =
              typeParameter.computeVarianceInType(fieldElement.type);

          _checkForWrongVariancePosition(
              fieldVariance, typeParameter, fieldName);
          if (!fields.isFinal && node.covariantKeyword == null) {
            _checkForWrongVariancePosition(
                Variance.contravariant.combine(fieldVariance),
                typeParameter,
                fieldName);
          }
        }
      }
    }
  }

  void _checkForWrongTypeParameterVarianceInMethod(MethodDeclaration method) {
    // Only need to report errors for parameters with explicitly defined type
    // parameters in classes or mixins.
    if (_enclosingClass == null) {
      return;
    }

    for (var typeParameter in _enclosingClass!.typeParameters) {
      // TODO(kallentu): : Clean up TypeParameterElementImpl casting once
      // variance is added to the interface.
      if ((typeParameter as TypeParameterElementImpl).isLegacyCovariant) {
        continue;
      }

      var methodTypeParameters = method.typeParameters?.typeParameters;
      if (methodTypeParameters != null) {
        for (var methodTypeParameter in methodTypeParameters) {
          if (methodTypeParameter.bound == null) {
            continue;
          }
          var methodTypeParameterVariance = Variance.invariant.combine(
            typeParameter
                .computeVarianceInType(methodTypeParameter.bound!.typeOrThrow),
          );
          _checkForWrongVariancePosition(
              methodTypeParameterVariance, typeParameter, methodTypeParameter);
        }
      }

      var methodParameters = method.parameters?.parameters;
      if (methodParameters != null) {
        for (var methodParameter in methodParameters) {
          var methodParameterElement = methodParameter.declaredElement!;
          if (methodParameterElement.isCovariant) {
            continue;
          }
          var methodParameterVariance = Variance.contravariant.combine(
            typeParameter.computeVarianceInType(methodParameterElement.type),
          );
          _checkForWrongVariancePosition(
              methodParameterVariance, typeParameter, methodParameter);
        }
      }

      var returnType = method.returnType;
      if (returnType != null) {
        var methodReturnTypeVariance =
            typeParameter.computeVarianceInType(returnType.typeOrThrow);
        _checkForWrongVariancePosition(
            methodReturnTypeVariance, typeParameter, returnType);
      }
    }
  }

  void _checkForWrongTypeParameterVarianceInSuperinterfaces() {
    void checkOne(DartType? superInterface) {
      if (superInterface != null) {
        for (var typeParameter in _enclosingClass!.typeParameters) {
          // TODO(kallentu): : Clean up TypeParameterElementImpl casting once
          // variance is added to the interface.
          var typeParameterElementImpl =
              typeParameter as TypeParameterElementImpl;
          var superVariance =
              typeParameterElementImpl.computeVarianceInType(superInterface);
          // Let `D` be a class or mixin declaration, let `S` be a direct
          // superinterface of `D`, and let `X` be a type parameter declared by
          // `D`.
          // If `X` is an `out` type parameter, it can only occur in `S` in an
          // covariant or unrelated position.
          // If `X` is an `in` type parameter, it can only occur in `S` in an
          // contravariant or unrelated position.
          // If `X` is an `inout` type parameter, it can occur in `S` in any
          // position.
          if (!superVariance
              .greaterThanOrEqual(typeParameterElementImpl.variance)) {
            if (!typeParameterElementImpl.isLegacyCovariant) {
              errorReporter.atElement(
                typeParameter,
                CompileTimeErrorCode
                    .WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
                arguments: [
                  typeParameter.name,
                  typeParameterElementImpl.variance.keyword,
                  superVariance.keyword,
                  superInterface,
                ],
              );
            } else {
              errorReporter.atElement(
                typeParameter,
                CompileTimeErrorCode
                    .WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
                arguments: [typeParameter.name, superInterface],
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
    if (enclosingClass is MixinElement) {
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
  void _checkForWrongVariancePosition(Variance variance,
      TypeParameterElement typeParameter, SyntacticEntity errorTarget) {
    TypeParameterElementImpl typeParameterImpl =
        typeParameter as TypeParameterElementImpl;
    if (!variance.greaterThanOrEqual(typeParameterImpl.variance)) {
      errorReporter.atEntity(
        errorTarget,
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_POSITION,
        arguments: [
          typeParameterImpl.variance.keyword,
          typeParameterImpl.name,
          variance.keyword
        ],
      );
    }
  }

  /// Verify that the current class does not have the same class in the
  /// 'extends' and 'implements' clauses.
  ///
  /// See [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS].
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
        errorReporter.atNode(
          interfaceNode,
          CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS,
          arguments: [superElement],
        );
      }
    }
  }

  void _checkMixinAugmentationModifiers({
    required Token? augmentKeyword,
    required MixinDeclarationImpl augmentationNode,
    required MixinElementImpl augmentationElement,
  }) {
    if (augmentKeyword == null) {
      return;
    }

    var target = augmentationElement.augmentationTarget;
    if (target == null) {
      return;
    }

    var declaration = target.augmented.declaration;

    void singleModifier({
      required String modifierName,
      required bool declarationFlag,
      required Token? augmentationModifier,
    }) {
      if (declarationFlag) {
        if (augmentationModifier == null) {
          errorReporter.atToken(
            augmentKeyword,
            CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING,
            arguments: [modifierName],
          );
        }
      } else {
        if (augmentationModifier != null) {
          errorReporter.atToken(
            augmentationModifier,
            CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA,
            arguments: [modifierName],
          );
        }
      }
    }

    singleModifier(
      modifierName: 'base',
      declarationFlag: declaration.isBase,
      augmentationModifier: augmentationNode.baseKeyword,
    );
  }

  /// Checks the class for problems with the superclass, mixins, or implemented
  /// interfaces.
  void _checkMixinInheritance(
      MixinElementImpl declarationElement,
      MixinDeclaration node,
      MixinOnClause? onClause,
      ImplementsClause? implementsClause) {
    // Only check for all of the inheritance logic around clauses if there
    // isn't an error code such as "Cannot implement double" already.
    if (!_checkForOnClauseErrorCodes(onClause) &&
        !_checkForImplementsClauseErrorCodes(implementsClause)) {
//      _checkForImplicitDynamicType(superclass);
      _checkForRepeatedType(
        libraryContext.setOfOn(declarationElement),
        onClause?.superclassConstraints,
        CompileTimeErrorCode.ON_REPEATED,
      );
      _checkForRepeatedType(
        libraryContext.setOfImplements(declarationElement),
        implementsClause?.interfaces,
        CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      );
      _checkForConflictingGenerics(node);
      _checkForBaseClassOrMixinImplementedOutsideOfLibrary(implementsClause);
      _checkForFinalSupertypeOutsideOfLibrary(
          null, null, implementsClause, onClause);
      _checkForSealedSupertypeOutsideOfLibrary(
          null, null, implementsClause, onClause);
    }
  }

  /// Verify that the current class does not have the same class in the
  /// 'extends' and 'with' clauses.
  ///
  /// See [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS].
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
        errorReporter.atNode(
          mixinNode,
          CompileTimeErrorCode.MIXINS_SUPER_CLASS,
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
        errorReporter.atToken(
          keyword,
          CompileTimeErrorCode.INVALID_USE_OF_COVARIANT,
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
            errorReporter.atEntity(
              errorTarget,
              CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER,
            );
          }
        } else if (defaultValuesAreExpected) {
          var parameterElement = parameter.declaredElement!;
          if (!parameterElement.hasDefaultValue) {
            var type = parameterElement.type;
            if (typeSystem.isPotentiallyNonNullable(type)) {
              var parameterName = _parameterName(parameter);
              var errorTarget = parameterName ?? parameter;
              if (parameterElement.hasRequired) {
                errorReporter.atEntity(
                  errorTarget,
                  CompileTimeErrorCode
                      .MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION,
                );
              } else {
                if (!_isWildcardSuperFormalPositionalParameter(parameter)) {
                  errorReporter.atEntity(
                    errorTarget,
                    parameterElement.isPositional
                        ? CompileTimeErrorCode
                            .MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL
                        : CompileTimeErrorCode
                            .MISSING_DEFAULT_VALUE_FOR_PARAMETER,
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
        _ => _hasAccessToThis
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
        return library.definingCompilationUnit.source.uri.toString();
      }
    }
    List<String> indirectSources = <String>[];
    for (var import in imports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null) {
        if (import.namespace.get(name) == element) {
          indirectSources.add(
              importedLibrary.definingCompilationUnit.source.uri.toString());
        }
      }
    }
    int indirectCount = indirectSources.length;
    StringBuffer buffer = StringBuffer();
    buffer.write(library.definingCompilationUnit.source.uri.toString());
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
      current = current.redirectedConstructor?.declaration;
    }
    return false;
  }

  /// Returns `true` if the given [library] is the `dart:ffi` library.
  bool _isDartFfiLibrary(LibraryElement library) => library.name == 'dart.ffi';

  /// Return `true` if the given [identifier] is in a location where it is
  /// allowed to resolve to a static member of a supertype.
  bool _isUnqualifiedReferenceToNonLocalStaticMemberAllowed(
      SimpleIdentifier identifier) {
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
  bool _isWasm(LibraryImportElement importElement) {
    var importedUri = importElement.importedLibrary?.source.uri.toString();
    if (importedUri != 'dart:_wasm') {
      return false;
    }
    var importingUri = _currentLibrary.source.uri.toString();
    if (importingUri == 'package:js/js.dart') {
      return true;
    } else if (importingUri.startsWith('package:ui/')) {
      return true;
    }
    return false;
  }

  bool _isWildcardSuperFormalPositionalParameter(
          DefaultFormalParameter parameter) =>
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

  void _reportMacroDiagnostics(MacroTargetElement element) {
    _MacroDiagnosticsReporter(
      libraryContext: libraryContext,
      errorReporter: errorReporter,
      element: element,
    ).report();
  }

  void _withEnclosingExecutable(
    ExecutableElement element,
    void Function() operation,
  ) {
    var current = _enclosingExecutable;
    try {
      _enclosingExecutable = EnclosingExecutableContext(element);
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
      GuardedPatternImpl guardedPattern, void Function() f) {
    _hiddenElements =
        HiddenElements.forGuardedPattern(_hiddenElements, guardedPattern);
    try {
      f();
    } finally {
      _hiddenElements = _hiddenElements!.outerElements;
    }
  }

  /// Return [FieldElement]s that are declared in the [ClassDeclaration] with
  /// the given [constructor], but are not initialized.
  static List<FieldElement> computeNotInitializedFields(
      ConstructorDeclaration constructor) {
    Set<FieldElement> fields = <FieldElement>{};
    var classDeclaration = constructor.parent as ClassDeclaration;
    for (ClassMember fieldDeclaration in classDeclaration.members) {
      if (fieldDeclaration is FieldDeclaration) {
        for (VariableDeclaration field in fieldDeclaration.fields.variables) {
          if (field.initializer == null) {
            fields.add(field.declaredElement as FieldElement);
          }
        }
      }
    }

    List<FormalParameter> parameters = constructor.parameters.parameters;
    for (FormalParameter parameter in parameters) {
      parameter = parameter.notDefault;
      if (parameter is FieldFormalParameter) {
        var element = parameter.declaredElement as FieldFormalParameterElement;
        fields.remove(element.field);
      }
    }

    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        fields.remove(initializer.fieldName.staticElement);
      }
    }

    return fields.toList();
  }

  /// Return [FieldElement]s that are declared in the [ClassDeclaration] with
  /// the given [constructor], but are not initialized.
  static List<FieldElement2> computeNotInitializedFields2(
      ConstructorDeclaration constructor) {
    var fields = <FieldElement2>{};
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
        fields.remove(element.field2);
      }
    }

    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        fields.remove(initializer.fieldName.element);
      }
    }

    return fields.toList();
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
  final Set<Element> _elements = HashSet<Element>();

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
  final Map<FileState, FileAnalysis> files;

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
    required this.files,
  });

  _MacroSyntacticTypeAnnotationLocation? declarationByElement(Element element) {
    var unitElement = element.thisOrAncestorOfType<CompilationUnitElement>();
    if (unitElement == null) {
      return null;
    }

    var uri = unitElement.source.uri;
    var fileAnalysis = files.entries.firstWhereOrNull((entry) {
      return entry.key.uri == uri;
    })?.value;
    if (fileAnalysis == null) {
      return null;
    }

    var locator = DeclarationByElementLocator(element);
    fileAnalysis.unit.accept(locator);

    var node = locator.result;
    if (node == null) {
      return null;
    }

    return _MacroSyntacticTypeAnnotationLocation(
      fileAnalysis: fileAnalysis,
      entity: node,
    );
  }

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

class _MacroDiagnosticsReporter {
  final LibraryVerificationContext libraryContext;
  final ErrorReporter errorReporter;
  final MacroTargetElement element;

  _MacroDiagnosticsReporter({
    required this.libraryContext,
    required this.errorReporter,
    required this.element,
  });

  void report() {
    _reportApplicationFromSameLibraryCycle();

    for (var diagnostic in element.macroDiagnostics) {
      switch (diagnostic) {
        case ArgumentMacroDiagnostic():
          _reportArgument(diagnostic);
        case DeclarationsIntrospectionCycleDiagnostic():
          _reportIntrospectionCycle(diagnostic);
        case ExceptionMacroDiagnostic():
          _reportException(diagnostic);
        case InvalidMacroTargetDiagnostic():
          _reportInvalidTarget(diagnostic);
        case MacroDiagnostic():
          _reportCustom(diagnostic);
        case NotAllowedDeclarationDiagnostic():
          _reportNotAllowedDeclaration(diagnostic);
      }
    }
  }

  DiagnosticMessage _convertMessage(MacroDiagnosticMessage object) {
    var target = object.target;
    switch (target) {
      case ApplicationMacroDiagnosticTarget():
        var node = element.annotationAst(target.annotationIndex);
        return DiagnosticMessageImpl(
          filePath: element.source!.fullName,
          length: node.length,
          message: object.message,
          offset: node.offset,
          url: null,
        );
      case ElementMacroDiagnosticTarget():
        var element = target.element;
        return DiagnosticMessageImpl(
          filePath: element.source!.fullName,
          length: element.nameLength,
          message: object.message,
          offset: element.nameOffset,
          url: null,
        );
      case TypeAnnotationMacroDiagnosticTarget():
        // TODO(scheglov): Handle this case.
        throw UnimplementedError();
      case ElementAnnotationMacroDiagnosticTarget():
        // TODO(scheglov): Handle this case.
        throw UnimplementedError();
    }
  }

  void _reportApplicationFromSameLibraryCycle() {
    for (var annotation in element.metadata) {
      var element = annotation.element;
      if (element is! ConstructorElementImpl) continue;

      var macroElement = element.enclosingElement3;
      if (macroElement is! ClassElementImpl) continue;
      if (!macroElement.isMacro) continue;

      var macroUri = macroElement.library.source.uri;
      if (!libraryContext.libraryCycleContains(macroUri)) continue;

      errorReporter.atNode(
        _annotationNameIdentifier(annotation),
        CompileTimeErrorCode.MACRO_DEFINITION_APPLICATION_SAME_LIBRARY_CYCLE,
        arguments: [
          macroElement.name,
        ],
      );
    }
  }

  void _reportArgument(ArgumentMacroDiagnostic diagnostic) {
    var annotation = element.annotationAst(diagnostic.annotationIndex);
    var arguments = annotation.arguments!.arguments;
    errorReporter.atNode(
      arguments[diagnostic.argumentIndex],
      CompileTimeErrorCode.MACRO_APPLICATION_ARGUMENT_ERROR,
      arguments: [diagnostic.message],
    );
  }

  void _reportCustom(MacroDiagnostic diagnostic) {
    var errorCode = switch (diagnostic.severity) {
      macro.Severity.info => HintCode.MACRO_INFO,
      macro.Severity.warning => WarningCode.MACRO_WARNING,
      macro.Severity.error => CompileTimeErrorCode.MACRO_ERROR,
    };

    var contextMessages =
        diagnostic.contextMessages.map(_convertMessage).toList();

    var target = diagnostic.message.target;
    switch (target) {
      case ApplicationMacroDiagnosticTarget():
        var node = element.annotationAst(target.annotationIndex);
        errorReporter.reportError(
          AnalysisError.forValues(
            source: element.source!,
            offset: node.offset,
            length: node.length,
            errorCode: errorCode,
            message: diagnostic.message.message,
            correctionMessage: diagnostic.correctionMessage,
            contextMessages: contextMessages,
          ),
        );
      case ElementMacroDiagnosticTarget():
        errorReporter.reportError(
          AnalysisError.forValues(
            source: target.element.source!,
            offset: target.element.nameOffset,
            length: target.element.nameLength,
            errorCode: errorCode,
            message: diagnostic.message.message,
            correctionMessage: diagnostic.correctionMessage,
            contextMessages: contextMessages,
          ),
        );
      case ElementAnnotationMacroDiagnosticTarget():
        var location = libraryContext.declarationByElement(
          target.element,
        );
        if (location == null) {
          return;
        }
        var node = target.element.annotationAst(target.annotationIndex);
        location.fileAnalysis.errorReporter.reportError(
          AnalysisError.forValues(
            source: target.element.source!,
            offset: node.offset,
            length: node.length,
            errorCode: errorCode,
            message: diagnostic.message.message,
            correctionMessage: diagnostic.correctionMessage,
            contextMessages: contextMessages,
          ),
        );
      case TypeAnnotationMacroDiagnosticTarget():
        var nodeLocation = _MacroTypeAnnotationLocationConverter(
          libraryVerificationContext: libraryContext,
        ).convert(target.location);
        var fileAnalysis = nodeLocation?.fileAnalysis;
        var errorEntity = nodeLocation?.entity;
        if (fileAnalysis != null && errorEntity != null) {
          fileAnalysis.errorReporter.reportError(
            AnalysisError.forValues(
              source: fileAnalysis.element.source,
              offset: errorEntity.offset,
              length: errorEntity.length,
              errorCode: errorCode,
              message: diagnostic.message.message,
              correctionMessage: diagnostic.correctionMessage,
              contextMessages: contextMessages,
            ),
          );
        }
    }
  }

  void _reportException(ExceptionMacroDiagnostic diagnostic) {
    errorReporter.atNode(
      element.annotationAst(diagnostic.annotationIndex),
      CompileTimeErrorCode.MACRO_INTERNAL_EXCEPTION,
      arguments: [
        diagnostic.message,
        diagnostic.stackTrace,
      ],
    );
  }

  void _reportIntrospectionCycle(
    DeclarationsIntrospectionCycleDiagnostic diagnostic,
  ) {
    var messages = diagnostic.components.map<DiagnosticMessage>(
      (component) {
        var target = _macroAnnotationNameIdentifier(
          element: component.element,
          annotationIndex: component.annotationIndex,
        );
        var introspectedName = component.introspectedElement.name;
        return DiagnosticMessageImpl(
          filePath: component.element.source!.fullName,
          length: target.length,
          message: "The macro application introspects '$introspectedName'.",
          offset: target.offset,
          url: null,
        );
      },
    ).toList();

    errorReporter.atNode(
      _macroAnnotationNameIdentifier(
        element: element,
        annotationIndex: diagnostic.annotationIndex,
      ),
      CompileTimeErrorCode.MACRO_DECLARATIONS_PHASE_INTROSPECTION_CYCLE,
      arguments: [diagnostic.introspectedElement.name!],
      contextMessages: messages,
    );
  }

  void _reportInvalidTarget(InvalidMacroTargetDiagnostic diagnostic) {
    errorReporter.atNode(
      element.annotationAst(diagnostic.annotationIndex),
      CompileTimeErrorCode.INVALID_MACRO_APPLICATION_TARGET,
      arguments: [
        diagnostic.supportedKinds.commaSeparatedWithOr,
      ],
    );
  }

  void _reportNotAllowedDeclaration(
    NotAllowedDeclarationDiagnostic diagnostic,
  ) {
    errorReporter.atNode(
      element.annotationAst(diagnostic.annotationIndex),
      CompileTimeErrorCode.MACRO_NOT_ALLOWED_DECLARATION,
      arguments: [
        diagnostic.phase.name,
        diagnostic.nodeRanges
            .map((r) => '(${r.offset}, ${r.length})')
            .join(' '),
        diagnostic.code.trimRight(),
      ],
    );
  }

  static SimpleIdentifier _annotationNameIdentifier(
    ElementAnnotationImpl annotation,
  ) {
    var fullName = annotation.annotationAst.name;
    if (fullName is PrefixedIdentifierImpl) {
      return fullName.identifier;
    } else {
      return fullName as SimpleIdentifierImpl;
    }
  }

  static SimpleIdentifier _macroAnnotationNameIdentifier({
    required ElementImpl element,
    required int annotationIndex,
  }) {
    var annotationNode = element.annotationAst(annotationIndex);
    var fullName = annotationNode.name;
    if (fullName is PrefixedIdentifierImpl) {
      return fullName.identifier;
    } else {
      return fullName as SimpleIdentifierImpl;
    }
  }
}

class _MacroSyntacticTypeAnnotationLocation {
  final FileAnalysis fileAnalysis;

  /// Usually a [AstNode], sometimes [Token] if the type is omitted.
  final SyntacticEntity entity;

  _MacroSyntacticTypeAnnotationLocation({
    required this.fileAnalysis,
    required this.entity,
  });

  _MacroSyntacticTypeAnnotationLocation next(SyntacticEntity entity) {
    return _MacroSyntacticTypeAnnotationLocation(
      fileAnalysis: fileAnalysis,
      entity: entity,
    );
  }
}

class _MacroTypeAnnotationLocationConverter {
  final LibraryVerificationContext libraryVerificationContext;

  _MacroTypeAnnotationLocationConverter({
    required this.libraryVerificationContext,
  });

  /// Returns the syntactic location for the offset independent [location];
  _MacroSyntacticTypeAnnotationLocation? convert(
    TypeAnnotationLocation location,
  ) {
    switch (location) {
      case AliasedTypeLocation():
        return _aliasedType(location);
      case ElementTypeLocation():
        var element = location.element;
        return libraryVerificationContext.declarationByElement(element);
      case ExtendsClauseTypeLocation():
        return _extendsClause(location);
      case FormalParameterTypeLocation():
        return _formalParameter(location);
      case ListIndexTypeLocation():
        return _listIndex(location);
      case RecordNamedFieldTypeLocation():
        return _recordNamedField(location);
      case RecordPositionalFieldTypeLocation():
        return _recordPositionalField(location);
      case ReturnTypeLocation():
        return _returnType(location);
      case VariableTypeLocation():
        return _variableType(location);
      default:
        throw UnimplementedError('${location.runtimeType}');
    }
  }

  _MacroSyntacticTypeAnnotationLocation? _aliasedType(
    AliasedTypeLocation location,
  ) {
    var nodeLocation = convert(location.parent);
    if (nodeLocation == null) {
      return null;
    }
    var node = nodeLocation.entity;
    switch (node) {
      case GenericTypeAlias():
        return nodeLocation.next(node.type);
      default:
        throw UnimplementedError('${node.runtimeType}');
    }
  }

  _MacroSyntacticTypeAnnotationLocation? _extendsClause(
    ExtendsClauseTypeLocation location,
  ) {
    var nodeLocation = convert(location.parent);
    if (nodeLocation == null) {
      return null;
    }
    var node = nodeLocation.entity;
    switch (node) {
      case ClassDeclaration():
        var next = node.extendsClause!.superclass;
        return nodeLocation.next(next);
      default:
        throw UnimplementedError('${node.runtimeType}');
    }
  }

  _MacroSyntacticTypeAnnotationLocation? _formalParameter(
    FormalParameterTypeLocation location,
  ) {
    var nodeLocation = convert(location.parent);
    if (nodeLocation == null) {
      return null;
    }
    var node = nodeLocation.entity;
    switch (node) {
      case ConstructorDeclaration():
        var parameterList = node.parameters;
        var next = parameterList.parameters[location.index];
        return nodeLocation.next(next);
      case FunctionDeclaration():
        var parameterList = node.functionExpression.parameters;
        var next = parameterList!.parameters[location.index];
        return nodeLocation.next(next);
      case GenericFunctionType():
        var parameterList = node.parameters;
        var parameter = parameterList.parameters[location.index];
        parameter = parameter.notDefault;
        return nodeLocation.next(parameter.typeOrSelf);
      case MethodDeclaration():
        var parameterList = node.parameters;
        var next = parameterList!.parameters[location.index];
        return nodeLocation.next(next);
      default:
        throw UnimplementedError('${node.runtimeType}');
    }
  }

  _MacroSyntacticTypeAnnotationLocation? _listIndex(
    ListIndexTypeLocation location,
  ) {
    var nodeLocation = convert(location.parent);
    if (nodeLocation == null) {
      return null;
    }
    var node = nodeLocation.entity;
    switch (node) {
      case NamedType():
        var argument = node.typeArguments?.arguments[location.index];
        if (argument == null) {
          return null;
        }
        return nodeLocation.next(argument);
      default:
        throw UnimplementedError('${node.runtimeType}');
    }
  }

  _MacroSyntacticTypeAnnotationLocation? _recordNamedField(
    RecordNamedFieldTypeLocation location,
  ) {
    var nodeLocation = convert(location.parent);
    if (nodeLocation == null) {
      return null;
    }
    var node = nodeLocation.entity;
    switch (node) {
      case RecordTypeAnnotation():
        var field = node.namedFields?.fields[location.index].type;
        if (field == null) {
          return null;
        }
        return nodeLocation.next(field);
      default:
        throw UnimplementedError('${node.runtimeType}');
    }
  }

  _MacroSyntacticTypeAnnotationLocation? _recordPositionalField(
    RecordPositionalFieldTypeLocation location,
  ) {
    var nodeLocation = convert(location.parent);
    if (nodeLocation == null) {
      return null;
    }
    var node = nodeLocation.entity;
    switch (node) {
      case RecordTypeAnnotation():
        var field = node.positionalFields[location.index];
        return nodeLocation.next(field);
      default:
        throw UnimplementedError('${node.runtimeType}');
    }
  }

  _MacroSyntacticTypeAnnotationLocation? _returnType(
    ReturnTypeLocation location,
  ) {
    var nodeLocation = convert(location.parent);
    if (nodeLocation == null) {
      return null;
    }
    var node = nodeLocation.entity;
    switch (node) {
      case FunctionDeclaration():
        var next = node.returnType ?? node.name;
        return nodeLocation.next(next);
      case GenericFunctionType():
        var next = node.returnType ?? node;
        return nodeLocation.next(next);
      case MethodDeclaration():
        var next = node.returnType ?? node.name;
        return nodeLocation.next(next);
      default:
        throw UnimplementedError('${node.runtimeType}');
    }
  }

  _MacroSyntacticTypeAnnotationLocation? _variableType(
    VariableTypeLocation location,
  ) {
    var nodeLocation = convert(location.parent);
    if (nodeLocation == null) {
      return null;
    }
    var node = nodeLocation.entity;
    if (node is DefaultFormalParameter) {
      node = node.parameter;
    }
    var parent = node.ifTypeOrNull<AstNode>()?.parent;
    switch (node) {
      case FieldFormalParameter():
        var next = node.type ?? node.name;
        return nodeLocation.next(next);
      case SimpleFormalParameter():
        var next = node.type ?? node.name;
        if (next == null) {
          return null;
        }
        return nodeLocation.next(next);
      case SuperFormalParameter():
        var next = node.type ?? node.name;
        return nodeLocation.next(next);
      case VariableDeclaration():
        if (parent is VariableDeclarationList) {
          var next = parent.type ?? node.name;
          return nodeLocation.next(next);
        }
    }
    throw UnimplementedError(
      '${node.runtimeType} ${parent.runtimeType}',
    );
  }
}

/// Recursively visits a type annotation, looking uninstantiated bounds.
class _UninstantiatedBoundChecker extends RecursiveAstVisitor<void> {
  final ErrorReporter _errorReporter;

  _UninstantiatedBoundChecker(this._errorReporter);

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
      _errorReporter.atNode(
        node,
        CompileTimeErrorCode.NOT_INSTANTIATED_BOUND,
      );
    }
  }
}
