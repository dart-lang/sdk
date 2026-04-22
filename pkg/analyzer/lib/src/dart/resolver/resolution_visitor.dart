// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/variable_bindings.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/dart/resolver/ast_rewrite.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/named_type_resolver.dart';
import 'package:analyzer/src/dart/resolver/record_type_annotation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/scope_context.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

class ResolutionVisitor extends RecursiveAstVisitor<void> {
  final LibraryElementImpl _libraryElement;
  final TypeProviderImpl _typeProvider;
  final LibraryFragmentImpl _libraryFragment;
  final DiagnosticReporter _diagnosticReporter;
  final AstRewriter _astRewriter;
  final NamedTypeResolver _namedTypeResolver;
  final RecordTypeAnnotationResolver _recordTypeResolver;

  /// Data structure for tracking declared pattern variables.
  late final _VariableBinder _patternVariables = _VariableBinder(
    errors: _VariableBinderErrors(this),
    typeProvider: _typeProvider,
  );

  /// The set of required operations on types.
  final TypeSystemOperations typeSystemOperations;

  final TypeConstraintGenerationDataForTesting? dataForTesting;

  final ScopeContext _scopeContext;

  /// The container with information about local variables.
  final LocalVariableInfo _localVariableInfo = LocalVariableInfo();

  LabelScope? _labelScope;

  UnlabeledBreakContinueContext _unlabeledBreakContinueContext =
      UnlabeledBreakContinueContext.root;

  LocalFunctionElement? _enclosingClosure;

  int _libraryDirectiveIndex = 0;

  factory ResolutionVisitor({
    required LibraryFragmentImpl libraryFragment,
    required DiagnosticListener diagnosticListener,
    required Scope nameScope,
    required List<LibraryElement> docImportLibraries,
    required bool strictInference,
    required bool strictCasts,
    required TypeConstraintGenerationDataForTesting? dataForTesting,
  }) {
    var libraryElement = libraryFragment.library;
    var typeProvider = libraryElement.typeProvider;
    var unitSource = libraryFragment.source;
    var diagnosticReporter = DiagnosticReporter(diagnosticListener, unitSource);

    var typeSystemOperations = TypeSystemOperations(
      libraryFragment.library.typeSystem,
      strictCasts: strictCasts,
    );

    var scopeContext = ScopeContext(
      libraryFragment: libraryFragment,
      nameScope: nameScope,
      docImportLibraries: docImportLibraries,
    );

    var namedTypeResolver = NamedTypeResolver(
      libraryElement,
      libraryFragment,
      scopeContext,
      diagnosticReporter,
      strictInference: strictInference,
      strictCasts: strictCasts,
      typeSystemOperations: typeSystemOperations,
    );

    var recordTypeResolver = RecordTypeAnnotationResolver(
      typeProvider: typeProvider,
      diagnosticReporter: diagnosticReporter,
      libraryElement: libraryElement,
    );

    return ResolutionVisitor._(
      libraryElement,
      typeProvider,
      libraryFragment,
      diagnosticReporter,
      AstRewriter(diagnosticReporter),
      namedTypeResolver,
      recordTypeResolver,
      scopeContext,
      typeSystemOperations,
      dataForTesting,
    );
  }

  ResolutionVisitor._(
    this._libraryElement,
    this._typeProvider,
    this._libraryFragment,
    this._diagnosticReporter,
    this._astRewriter,
    this._namedTypeResolver,
    this._recordTypeResolver,
    this._scopeContext,
    this.typeSystemOperations,
    this.dataForTesting,
  );

  Scope get nameScope => _scopeContext.nameScope;

  /// Set information about enclosing declarations.
  void prepareEnclosingDeclarations({
    InterfaceElementImpl? enclosingClassElement,
  }) {
    _namedTypeResolver.enclosingClass = enclosingClassElement;
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    node.visitChildrenWithHooks(this, visitConstructorName: (_) {});
  }

  @override
  void visitAnonymousMethodInvocation(
    covariant AnonymousMethodInvocationImpl node,
  ) {
    node.target?.accept(this);

    _scopeContext.withLocalScope((scope) {
      if (node.parameters case var parameters?) {
        scope.addFormalParameterList(parameters);
        parameters.accept(this);
      }
      node.body.accept(this);
    });
  }

  @override
  void visitAssignedVariablePattern(
    covariant AssignedVariablePatternImpl node,
  ) {
    var name = node.name.lexeme;
    var element = nameScope.lookup(name).getter;
    node.element = element;

    if (element is PromotableElementImpl) {
      _localVariableInfo.potentiallyMutatedInScope.add(element);
    }

    if (element == null) {
      // Recovery: the code might try to refer to an instance field.
      if (_scopeContext.enclosingInstanceElement
          case InterfaceElementImpl enclosingInterfaceElement?) {
        var element = enclosingInterfaceElement.inheritanceManager.getMember(
          enclosingInterfaceElement,
          Name.forLibrary(_libraryElement, name).forSetter,
        );
        if (element != null) {
          node.element = element;
          _diagnosticReporter.report(
            diag.patternAssignmentNotLocalVariable.at(node.name),
          );
          return;
        }
      }

      _diagnosticReporter.report(
        diag.undefinedIdentifier.withArguments(name: name).at(node.name),
      );
    } else if (!(element is LocalVariableElement ||
        element is FormalParameterElement)) {
      _diagnosticReporter.report(
        diag.patternAssignmentNotLocalVariable.at(node.name),
      );
    }
  }

  @override
  void visitBlock(covariant BlockImpl node) {
    _scopeContext.withLocalScope((scope) {
      node.nameScope = scope;
      _defineLocalElements(scope, node.statements);
      node.statements.accept(this);
    });
  }

  @override
  void visitBlockFunctionBody(covariant BlockFunctionBodyImpl node) {
    node.localVariableInfo = _localVariableInfo;
    _withUnlabeledBreakContinueContext(UnlabeledBreakContinueContext.root, () {
      super.visitBlockFunctionBody(node);
    });
  }

  @override
  void visitBreakStatement(covariant BreakStatementImpl node) {
    node.target = _lookupBreakOrContinueTarget(
      node,
      node.label,
      isContinue: false,
    );
  }

  @override
  void visitCatchClause(covariant CatchClauseImpl node) {
    var exceptionTypeNode = node.exceptionType;
    exceptionTypeNode?.accept(this);

    _scopeContext.withLocalScope((scope) {
      if (node.exceptionParameter case var exceptionNode?) {
        var fragment = exceptionNode.declaredFragment!;
        var element = fragment.element;
        scope.add(element);

        if (node.exceptionType case var typeNode?) {
          element.type = typeNode.typeOrThrow;
        } else {
          element.type = _typeProvider.objectType;
        }
      }

      var stackTraceNode = node.stackTraceParameter;
      if (stackTraceNode != null) {
        var fragment = stackTraceNode.declaredFragment!;
        var element = fragment.element;
        scope.add(element);

        element.type = _typeProvider.stackTraceType;
      }

      node.body.accept(this);
    });
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    _scopeContext.visitClassDeclaration(node, visitor: this);
    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var fragment = node.declaredFragment!;
    _namedTypeResolver.enclosingClass = fragment.element;

    _scopeContext.visitClassTypeAlias(
      node,
      visitor: this,
      visitSuperclass: (superclass) {
        _resolveType(declaration: node, clause: null, namedType: superclass);
      },
    );

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitComment(covariant CommentImpl node) {
    _scopeContext.visitDocumentationComment(node, this);
  }

  @override
  void visitCompilationUnit(covariant CompilationUnitImpl node) {
    node.nameScope = nameScope;
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    _scopeContext.visitConstructorDeclaration(node, visitor: this);
  }

  @override
  void visitConstructorFieldInitializer(
    covariant ConstructorFieldInitializerImpl node,
  ) {
    node.visitChildrenWithHooks(this, visitFieldName: (_) {});
  }

  @override
  void visitConstructorName(covariant ConstructorNameImpl node) {
    node.visitChildrenWithHooks(this, visitName: (_) {});
  }

  @override
  void visitContinueStatement(covariant ContinueStatementImpl node) {
    node.target = _lookupBreakOrContinueTarget(
      node,
      node.label,
      isContinue: true,
    );
  }

  @override
  void visitDeclaredIdentifier(covariant DeclaredIdentifierImpl node) {
    super.visitDeclaredIdentifier(node);

    if (node.type != null) {
      node.declaredFragment!.element.type = node.type!.typeOrThrow;
    } else {
      node.declaredFragment!.element.type = _typeProvider.dynamicType;
    }
  }

  @override
  void visitDeclaredVariablePattern(
    covariant DeclaredVariablePatternImpl node,
  ) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    node.type?.accept(this);

    if (node.type != null) {
      element.type = node.type!.typeOrThrow;
    } else {
      fragment.hasImplicitType = true;
    }

    var patternContext = node.patternContext;
    if (patternContext is ForEachPartsWithPatternImpl) {
      fragment.isFinal = patternContext.keyword.keyword == Keyword.FINAL;
    } else if (patternContext is PatternVariableDeclarationImpl) {
      fragment.isFinal = patternContext.keyword.keyword == Keyword.FINAL;
    } else {
      fragment.isFinal = node.keyword?.keyword == Keyword.FINAL;
    }
  }

  @override
  void visitDoStatement(covariant DoStatementImpl node) {
    _withUnlabeledBreakContinueContextNested(node, () {
      _visitStatementInScope(node.body);
      node.condition.accept(this);
    });
  }

  @override
  void visitDotShorthandConstructorInvocation(
    covariant DotShorthandConstructorInvocationImpl node,
  ) {
    node.visitChildrenWithHooks(this, visitConstructorName: (_) {});
  }

  @override
  void visitDotShorthandInvocation(covariant DotShorthandInvocationImpl node) {
    node.visitChildrenWithHooks(this, visitMemberName: (_) {});
  }

  @override
  void visitDotShorthandPropertyAccess(
    covariant DotShorthandPropertyAccessImpl node,
  ) {
    node.visitChildrenWithHooks(this, visitPropertyName: (_) {});
  }

  @override
  void visitEmptyClassBody(EmptyClassBody node) {}

  @override
  void visitEmptyEnumBody(EmptyEnumBody node) {}

  @override
  void visitEmptyFunctionBody(covariant EmptyFunctionBodyImpl node) {
    node.localVariableInfo = _localVariableInfo;
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    _scopeContext.visitEnumDeclaration(node, visitor: this);
    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(covariant ExpressionFunctionBodyImpl node) {
    node.localVariableInfo = _localVariableInfo;
    node.nameScope = nameScope;
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExtendsClause(covariant ExtendsClauseImpl node) {
    _resolveType(
      declaration: node.parent as Declaration?,
      clause: node,
      namedType: node.superclass,
    );
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    _scopeContext.visitExtensionDeclaration(node, visitor: this);
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    _scopeContext.visitExtensionTypeDeclaration(node, visitor: this);
    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    _scopeContext.visitFieldDeclaration(node, visitor: this);
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    _scopeContext.visitFormalParameter(node, visitor: this);
  }

  @override
  void visitForEachPartsWithDeclaration(
    covariant ForEachPartsWithDeclarationImpl node,
  ) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitForEachPartsWithPattern(
    covariant ForEachPartsWithPatternImpl node,
  ) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitForElement(covariant ForElementImpl node) {
    _scopeContext.withLocalScope((scope) {
      node.nameScope = scope;
      _visitForLoopParts(scope, node.forLoopParts);
      _scopeContext.withLocalScope((_) {
        node.body.accept(this);
      });
    });
  }

  @override
  void visitForPartsWithPattern(covariant ForPartsWithPatternImpl node) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitForStatement(covariant ForStatementImpl node) {
    _withUnlabeledBreakContinueContextNested(node, () {
      _scopeContext.withLocalScope((scope) {
        node.nameScope = scope;
        _visitForLoopParts(scope, node.forLoopParts);
        _visitStatementInScope(node.body);
      });
    });
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var element = node.declaredFragment!.element;
    var closure = element.tryCast<LocalFunctionElementImpl>();

    _withEnclosingClosure(closure, () {
      _scopeContext.visitFunctionDeclaration(node, visitor: this);
    });

    if (element is LocalFunctionElementImpl) {
      element.returnType = node.returnType?.type ?? _typeProvider.dynamicType;
    }
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node) {
    var element = node.declaredFragment!.element;
    var closure = element.tryCast<LocalFunctionElementImpl>();

    _withEnclosingClosure(closure, () {
      _scopeContext.visitFunctionExpression(node, visitor: this);
    });
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    _scopeContext.visitFunctionTypeAlias(node, visitor: this);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    _scopeContext.visitGenericFunctionType(node, visitor: this);

    var element = node.declaredFragment!.element;
    element.returnType = node.returnType?.type ?? _typeProvider.dynamicType;

    var type = FunctionTypeImpl(
      typeParameters: element.typeParameters,
      parameters: element.formalParameters,
      returnType: element.returnType,
      nullabilitySuffix: _getNullability(node.question != null),
    );
    element.type = type;
    node.type = type;
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    _scopeContext.visitGenericTypeAlias(
      node,
      visitor: this,
      enterTypeParameterScope: () {
        node.nameScope = nameScope;
      },
    );
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    var scope = nameScope.tryCast<LibraryFragmentScope>();
    scope?.importsTrackingActive(false);
    try {
      super.visitHideCombinator(node);
    } finally {
      scope?.importsTrackingActive(true);
    }
  }

  @override
  void visitIfElement(covariant IfElementImpl node) {
    if (node.caseClause case var caseClause?) {
      node.expression.accept(this);
      _resolveGuardedPattern(
        caseClause.guardedPattern,
        then: () {
          caseClause.nameScope = nameScope;
          node.ifTrue.accept(this);
        },
      );
      node.ifFalse?.accept(this);
    } else {
      node.visitChildren(this);
    }
  }

  @override
  void visitIfStatement(covariant IfStatementImpl node) {
    if (node.caseClause case var caseClause?) {
      node.expression.accept(this);
      _resolveGuardedPattern(
        caseClause.guardedPattern,
        then: () {
          caseClause.nameScope = nameScope;
          _visitStatementInScope(node.ifTrue);
        },
      );
      _visitStatementInScope(node.ifFalse);
    } else {
      node.expression.accept(this);
      _visitStatementInScope(node.ifTrue);
      _visitStatementInScope(node.ifFalse);
    }
  }

  @override
  void visitImplementsClause(covariant ImplementsClauseImpl node) {
    _resolveImplementsClause(
      declaration: node.parent as Declaration,
      clause: node,
    );
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var element = node.libraryImport;
    if (element != null) {
      _setElementAnnotations(node.metadata, element.metadata.annotations);
    }
    node.visitChildrenWithHooks(this, visitPrefix: (_) {});
  }

  @override
  void visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    var newNode = _astRewriter.instanceCreationExpression(
      nameScope,
      node,
      libraryElement: _libraryElement,
      enclosingInstanceElement: _scopeContext.enclosingInstanceElement,
    );
    if (newNode != node) {
      if (node.constructorName.type.typeArguments != null &&
          newNode is MethodInvocation &&
          newNode.target is FunctionReference &&
          !_libraryElement.featureSet.isEnabled(Feature.constructor_tearoffs)) {
        // A function reference with explicit type arguments (an expression of
        // the form `a<...>.m(...)` or `p.a<...>.m(...)` where `a` does not
        // refer to a class name, nor a type alias), is illegal without the
        // constructor tearoff feature.
        //
        // This is a case where the parser does not report an error, because the
        // parser thinks this could be an InstanceCreationExpression.
        _diagnosticReporter.report(diag.sdkVersionConstructorTearoffs.at(node));
      }
      return newNode.accept(this);
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    var unlabeled = node.unlabeled;
    var labelScope = _nestLabelScopes(_labelScope, node.labels, unlabeled);

    _withLabelScope(labelScope, () {
      unlabeled.accept(this);
    });
  }

  @override
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {
    ++_libraryDirectiveIndex;
    var element = node.element;
    if (element is LibraryElementImpl && _libraryDirectiveIndex == 1) {
      _setElementAnnotations(node.metadata, element.metadata.annotations);
    }
    super.visitLibraryDirective(node);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    _scopeContext.visitMethodDeclaration(node, visitor: this);
  }

  @override
  void visitMethodInvocation(covariant MethodInvocationImpl node) {
    var newNode = _astRewriter.methodInvocation(nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    node.visitChildrenWithHooks(
      this,
      visitMethodName: (methodName) {
        if (node.realTarget == null) {
          methodName.accept(this);
        }
      },
    );
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    _scopeContext.visitMixinDeclaration(node, visitor: this);
  }

  @override
  void visitMixinOnClause(covariant MixinOnClauseImpl node) {
    _resolveMixinOnClause(
      declaration: node.parent as Declaration,
      clause: node,
    );
  }

  @override
  void visitNamedArgument(covariant NamedArgumentImpl node) {
    node.visitChildren(this);
  }

  @override
  void visitNamedType(covariant NamedTypeImpl node) {
    node.typeArguments?.accept(this);

    _namedTypeResolver.resolve(node, dataForTesting: dataForTesting);

    if (_namedTypeResolver.rewriteResult != null) {
      _namedTypeResolver.rewriteResult!.accept(this);
    }
  }

  @override
  void visitNativeFunctionBody(covariant NativeFunctionBodyImpl node) {
    node.localVariableInfo = _localVariableInfo;
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitPartDirective(covariant PartDirectiveImpl node) {
    var partInclude = node.partInclude;
    if (partInclude != null) {
      _setElementAnnotations(node.metadata, partInclude.metadata.annotations);
    }
    super.visitPartDirective(node);
  }

  @override
  void visitPatternAssignment(covariant PatternAssignmentImpl node) {
    _scopeContext.withLocalScope((scope) {
      var variables = _computeDeclaredPatternVariables(node.pattern);
      scope.addAll(variables);
      node.pattern.accept(this);
      node.expression.accept(this);
    });
  }

  @override
  void visitPatternVariableDeclarationStatement(
    covariant PatternVariableDeclarationStatementImpl node,
  ) {
    node.declaration.accept(this);
  }

  @override
  void visitPrefixedIdentifier(covariant PrefixedIdentifierImpl node) {
    var newNode = _astRewriter.prefixedIdentifier(nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    node.visitChildrenWithHooks(this, visitIdentifier: (_) {});
  }

  @override
  void visitPrimaryConstructorBody(covariant PrimaryConstructorBodyImpl node) {
    _scopeContext.visitPrimaryConstructorBody(node, visitor: this);
  }

  @override
  void visitPropertyAccess(covariant PropertyAccessImpl node) {
    var newNode = _astRewriter.propertyAccess(nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    node.visitChildrenWithHooks(this, visitPropertyName: (_) {});
  }

  @override
  void visitRecordTypeAnnotation(covariant RecordTypeAnnotationImpl node) {
    node.visitChildren(this);
    _recordTypeResolver.resolve(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    covariant RedirectingConstructorInvocationImpl node,
  ) {
    node.visitChildrenWithHooks(this, visitConstructorName: (_) {});
  }

  @override
  void visitRegularFormalParameter(covariant RegularFormalParameterImpl node) {
    if (node.functionTypedSuffix case var functionTypedSuffix?) {
      _scopeContext.visitFormalParameter(node, visitor: this);

      var element = node.declaredFragment!.element;
      element.type = FunctionTypeImpl(
        typeParameters: element.typeParameters,
        parameters: element.formalParameters,
        returnType: node.type?.type ?? _typeProvider.dynamicType,
        nullabilitySuffix: _getNullability(
          functionTypedSuffix.question != null,
        ),
      );
      return;
    }

    node.visitChildren(this);

    var element = node.declaredFragment!.element;
    if (node.type case var type?) {
      element.type = type.type ?? _typeProvider.dynamicType;
    } else if (element.type is InvalidTypeImpl) {
      // TODO(scheglov): review and improve resolution to not rely on dynamic.
      element.type = _typeProvider.dynamicType;
    }
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    var scope = nameScope.tryCast<LibraryFragmentScope>();
    scope?.importsTrackingActive(false);
    try {
      super.visitShowCombinator(node);
    } finally {
      scope?.importsTrackingActive(true);
    }
  }

  @override
  void visitSimpleIdentifier(covariant SimpleIdentifierImpl node) {
    var newNode = _astRewriter.simpleIdentifier(nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    var scopeLookupResult = nameScope.lookup(node.name);
    node.scopeLookupResult = scopeLookupResult;

    var element = scopeLookupResult.getter;
    if (element is PromotableElementImpl) {
      node.element = element;

      if (element is JoinPatternVariableElementImpl) {
        element.references.add(node);
      }

      if (node.inSetterContext()) {
        _localVariableInfo.potentiallyMutatedInScope.add(element);

        if (element is PatternVariableElementImpl &&
            element.isVisitingWhenClause) {
          _diagnosticReporter.report(
            diag.patternVariableAssignmentInsideGuard.at(node),
          );
        }
      }
    }
  }

  @override
  void visitSuperConstructorInvocation(
    covariant SuperConstructorInvocationImpl node,
  ) {
    node.visitChildrenWithHooks(this, visitConstructorName: (_) {});
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    _scopeContext.visitFormalParameter(node, visitor: this);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitSwitchExpression(covariant SwitchExpressionImpl node) {
    node.expression.accept(this);

    for (var case_ in node.cases) {
      _resolveGuardedPattern(
        case_.guardedPattern,
        then: () {
          case_.nameScope = nameScope;
          case_.expression.accept(this);
        },
      );
    }
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitSwitchStatement(covariant SwitchStatementImpl node) {
    var labelScope = _labelScope;
    for (var member in node.members) {
      labelScope = _nestLabelScopes(labelScope, member.labels, member);
    }

    _withUnlabeledBreakContinueContextNested(node, () {
      _withLabelScope(labelScope, () {
        node.expression.accept(this);

        for (var group in node.memberGroups) {
          _patternVariables.switchStatementSharedCaseScopeStart(group);
          for (var member in group.members) {
            if (member is SwitchCaseImpl) {
              member.expression.accept(this);
            } else if (member is SwitchDefaultImpl) {
              _patternVariables.switchStatementSharedCaseScopeEmpty(group);
            } else if (member is SwitchPatternCaseImpl) {
              _resolveGuardedPattern(
                member.guardedPattern,
                sharedCaseScopeKey: group,
              );
            } else {
              throw UnimplementedError('(${member.runtimeType}) $member');
            }
          }
          if (group.hasLabels) {
            _patternVariables.switchStatementSharedCaseScopeEmpty(group);
          }
          group.variables = _patternVariables
              .switchStatementSharedCaseScopeFinish(group);

          _scopeContext.withLocalScope((scope) {
            group.members.lastOrNull?.nameScope = scope;
            _defineLocalElements(scope, group.statements);
            scope.addAll(group.variables.values);
            group.statements.accept(this);
          });
        }
      });
    });
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var fragment = node.declaredFragment!;

    node.metadata.accept(this);

    var boundNode = node.bound;
    if (boundNode != null) {
      boundNode.accept(this);
      fragment.element.bound = boundNode.type;
    }
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    var element = node.declaredFragment!.element;

    if (element is LocalVariableElementImpl) {
      var varList = node.parent as VariableDeclarationListImpl;
      if (varList.type case var typeNode?) {
        element.type = typeNode.typeOrThrow;
      } else {
        // TODO(scheglov): review and improve resolution to not rely on dynamic.
        element.type = _typeProvider.dynamicType;
      }
    }

    node.initializer?.accept(this);
  }

  @override
  void visitVariableDeclarationList(
    covariant VariableDeclarationListImpl node,
  ) {
    _scopeContext.visitVariableDeclarationList(node, visitor: this);
  }

  @override
  void visitWhileStatement(covariant WhileStatementImpl node) {
    _withUnlabeledBreakContinueContextNested(node, () {
      node.condition.accept(this);
      _visitStatementInScope(node.body);
    });
  }

  @override
  void visitWithClause(covariant WithClauseImpl node) {
    _resolveWithClause(declaration: node.parent as Declaration?, clause: node);
  }

  List<BindPatternVariableElementImpl> _computeDeclaredPatternVariables(
    DartPatternImpl pattern,
  ) {
    var variables = _computePatternVariables(pattern);
    return variables.values
        .whereType<BindPatternVariableElementImpl>()
        .toList();
  }

  Map<String, PatternVariableElementImpl> _computePatternVariables(
    DartPatternImpl pattern, {
    Object? sharedCaseScopeKey,
  }) {
    _patternVariables.casePatternStart();
    pattern.accept(_PatternVariableBinderVisitor(_patternVariables));
    return _patternVariables.casePatternFinish(
      sharedCaseScopeKey: sharedCaseScopeKey,
    );
  }

  void _defineLocalElements(LocalScope scope, List<Statement> statements) {
    for (var statement in statements) {
      statement = statement.unlabeled;
      switch (statement) {
        case FunctionDeclarationStatementImpl():
          var declaration = statement.functionDeclaration;
          var element = declaration.declaredFragment!.element;
          scope.add(element);
        case PatternVariableDeclarationStatementImpl():
          var declaration = statement.declaration;
          _definePatternVariableDeclarationElements(scope, declaration);
        case VariableDeclarationStatementImpl():
          scope.addAll(statement.variables.declaredElements);
      }
    }
  }

  void _definePatternVariableDeclarationElements(
    LocalScope scope,
    PatternVariableDeclarationImpl declaration,
  ) {
    var pattern = declaration.pattern;
    var variables = _computeDeclaredPatternVariables(pattern);
    declaration.elements = variables;
    scope.addAll(variables);
  }

  NullabilitySuffix _getNullability(bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else {
      return NullabilitySuffix.none;
    }
  }

  AstNode? _lookupBreakOrContinueTarget(
    AstNode parentNode,
    LabelReferenceImpl? labelNode, {
    required bool isContinue,
  }) {
    if (labelNode == null) {
      return isContinue
          ? _unlabeledBreakContinueContext.continueTarget
          : _unlabeledBreakContinueContext.breakTarget;
    } else {
      var labelName = labelNode.name.lexeme;
      var definingScope = _labelScope?.lookup(labelName);
      if (definingScope == null) {
        _diagnosticReporter.report(
          diag.labelUndefined.withArguments(name: labelName).at(labelNode),
        );
        return null;
      }
      labelNode.element = definingScope.element;
      if (_enclosingClosure case var enclosingClosure?) {
        var labelFragment = definingScope.element.firstFragment;
        var labelContainer = labelFragment.enclosingFragment;
        if (!identical(labelContainer, enclosingClosure.firstFragment)) {
          _diagnosticReporter.report(
            diag.labelInOuterScope.withArguments(name: labelName).at(labelNode),
          );
        }
      }
      var node = definingScope.node;
      if (isContinue &&
          node is! DoStatement &&
          node is! ForStatement &&
          node is! SwitchMember &&
          node is! WhileStatement) {
        _diagnosticReporter.report(diag.continueLabelInvalid.at(parentNode));
      }
      return node;
    }
  }

  LabelScope? _nestLabelScopes(
    LabelScope? outer,
    List<Label> labels,
    AstNode node,
  ) {
    var current = outer;
    for (var label in labels) {
      var labelElement = label.declaredFragment!.element;
      current = LabelScope(current, labelElement, node);
    }
    return current;
  }

  void _resolveGuardedPattern(
    GuardedPatternImpl guardedPattern, {
    Object? sharedCaseScopeKey,
    void Function()? then,
  }) {
    var variables = _computePatternVariables(
      guardedPattern.pattern,
      sharedCaseScopeKey: sharedCaseScopeKey,
    );
    // Matched variables are available in `whenClause`.
    _scopeContext.withLocalScope((scope) {
      scope.addAll(variables.values);
      guardedPattern.variables = variables;
      guardedPattern.pattern.accept(this);

      for (var variable in variables.values) {
        variable.isVisitingWhenClause = true;
      }
      try {
        guardedPattern.whenClause?.accept(this);
      } finally {
        for (var variable in variables.values) {
          variable.isVisitingWhenClause = false;
        }
      }

      if (then != null) {
        then();
      }
    });
  }

  void _resolveImplementsClause({
    required Declaration? declaration,
    required ImplementsClauseImpl? clause,
  }) {
    if (clause == null) return;

    _resolveTypes(
      declaration: declaration,
      clause: clause,
      namedTypes: clause.interfaces,
    );
  }

  void _resolveMixinOnClause({
    required Declaration? declaration,
    required MixinOnClauseImpl clause,
  }) {
    _resolveTypes(
      declaration: declaration,
      clause: clause,
      namedTypes: clause.superclassConstraints,
    );
  }

  /// Resolves the given [namedType], reports errors if the resulting type
  /// is not valid in the context of the [declaration] and [clause].
  void _resolveType({
    required Declaration? declaration,
    required AstNode? clause,
    required NamedTypeImpl namedType,
  }) {
    _namedTypeResolver.classHierarchy_namedType = namedType;
    visitNamedType(namedType);
    _namedTypeResolver.classHierarchy_namedType = null;

    if (_namedTypeResolver.hasErrorReported) {
      return;
    }

    var type = namedType.typeOrThrow;

    var enclosingElement = _namedTypeResolver.enclosingClass;
    if (enclosingElement is ExtensionTypeElementImpl) {
      _verifyExtensionElementImplements(enclosingElement, namedType, type);
      return;
    }

    var element = type.element;
    switch (element) {
      case ClassElement():
        return;
      case MixinElement():
        if (clause is ImplementsClause ||
            clause is MixinOnClause ||
            clause is WithClause) {
          return;
        }
    }

    if (_libraryFragment.shouldIgnoreUndefinedNamedType(namedType)) {
      return;
    }

    LocatableDiagnostic? diagnosticCode;
    switch (clause) {
      case null:
        if (declaration is ClassTypeAlias) {
          diagnosticCode = diag.mixinWithNonClassSuperclass;
        }
      case ExtendsClause():
        if (declaration is ClassDeclaration) {
          diagnosticCode = declaration.withClause == null
              ? diag.extendsNonClass
              : diag.mixinWithNonClassSuperclass;
        }
      case ImplementsClause():
        diagnosticCode = diag.implementsNonClass;
      case MixinOnClause():
        diagnosticCode = diag.mixinSuperClassConstraintNonInterface;
      case WithClause():
        diagnosticCode = diag.mixinOfNonClass;
    }

    // Should not happen.
    if (diagnosticCode == null) {
      assert(false);
      return;
    }

    var firstToken = namedType.importPrefix?.name ?? namedType.name;
    var offset = firstToken.offset;
    var length = namedType.name.end - offset;
    _diagnosticReporter.report(
      diagnosticCode.atOffset(offset: offset, length: length),
    );
  }

  /// Resolve the types in the given list of type names.
  ///
  /// @param typeNames the type names to be resolved
  /// @param nonTypeError the error to produce if the type name is defined to be
  ///        something other than a type
  /// @param enumTypeError the error to produce if the type name is defined to
  ///        be an enum
  /// @param dynamicTypeError the error to produce if the type name is "dynamic"
  /// @return an array containing all of the types that were resolved.
  void _resolveTypes({
    required Declaration? declaration,
    required AstNode clause,
    required NodeList<NamedTypeImpl> namedTypes,
  }) {
    for (var namedType in namedTypes) {
      _resolveType(
        declaration: declaration,
        clause: clause,
        namedType: namedType,
      );
    }
  }

  void _resolveWithClause({
    required Declaration? declaration,
    required WithClauseImpl? clause,
  }) {
    if (clause == null) return;

    for (var namedType in clause.mixinTypes) {
      _namedTypeResolver.withClause_namedType = namedType;
      _resolveType(
        declaration: declaration,
        clause: clause,
        namedType: namedType,
      );
      _namedTypeResolver.withClause_namedType = null;
    }
  }

  void _verifyExtensionElementImplements(
    ExtensionTypeElementImpl declaredElement,
    NamedTypeImpl node,
    TypeImpl type,
  ) {
    var typeSystem = _libraryElement.typeSystem;

    if (!typeSystem.isValidExtensionTypeSuperinterface(type)) {
      _diagnosticReporter.report(
        diag.extensionTypeImplementsDisallowedType
            .withArguments(type: type)
            .at(node),
      );
      return;
    }

    var declaredRepresentation = declaredElement.representation.type;
    if (typeSystem.isSubtypeOf(declaredRepresentation, type)) {
      return;
    }

    // When `type` is an extension type.
    if (type is InterfaceTypeImpl) {
      var implementedRepresentation = type.representationType;
      if (implementedRepresentation != null) {
        if (!typeSystem.isSubtypeOf(
          declaredRepresentation,
          implementedRepresentation,
        )) {
          _diagnosticReporter.report(
            diag.extensionTypeImplementsRepresentationNotSupertype
                .withArguments(
                  implementedRepresentationType: implementedRepresentation,
                  implementedExtensionTypeName: type.element.name ?? '',
                  representationType: declaredRepresentation,
                  extensionTypeName: declaredElement.name ?? '',
                )
                .at(node),
          );
        }
        return;
      }
    }

    _diagnosticReporter.report(
      diag.extensionTypeImplementsNotSupertype
          .withArguments(type: type, representationType: declaredRepresentation)
          .at(node),
    );
  }

  void _visitForLoopParts(LocalScope scope, ForLoopPartsImpl node) {
    switch (node) {
      case ForEachPartsWithDeclarationImpl():
        node.iterable.accept(this);
        var element = node.loopVariable.declaredFragment!.element;
        scope.add(element);
        node.loopVariable.accept(this);
      case ForEachPartsWithIdentifierImpl():
        node.iterable.accept(this);
        node.identifier.accept(this);
      case ForEachPartsWithPatternImpl():
        node.iterable.accept(this);
        var variables = _computeDeclaredPatternVariables(node.pattern);
        node.variables = variables;
        scope.addAll(variables);
        node.pattern.accept(this);
        node.metadata.accept(this);
      case ForPartsWithDeclarationsImpl():
        scope.addAll(node.variables.declaredElements);
        node.variables.accept(this);
        node.condition?.accept(this);
        node.updaters.accept(this);
      case ForPartsWithExpressionImpl():
        node.initialization?.accept(this);
        node.condition?.accept(this);
        node.updaters.accept(this);
      case ForPartsWithPatternImpl():
        _definePatternVariableDeclarationElements(scope, node.variables);
        node.variables.accept(this);
        node.condition?.accept(this);
        node.updaters.accept(this);
    }
  }

  /// Visits [statement], ensuring that if it is a block it is visited as such,
  /// and if it is not, it is wrapped in an implicit block scope.
  ///
  /// This implements the requirement from the specification that sub-statements
  /// of control flow statements (like `if`, `while`, `do`, `for`) introduce
  /// a new scope, even if they are not explicitly blocks.
  void _visitStatementInScope(StatementImpl? statement) {
    if (statement != null) {
      if (statement is BlockImpl) {
        visitBlock(statement);
      } else {
        _scopeContext.withLocalScope((scope) {
          _defineLocalElements(scope, [statement]);
          statement.accept(this);
        });
      }
    }
  }

  void _withEnclosingClosure(
    LocalFunctionElement? scope,
    void Function() callback,
  ) {
    var previous = _enclosingClosure;
    try {
      _enclosingClosure = scope;
      callback();
    } finally {
      _enclosingClosure = previous;
    }
  }

  void _withLabelScope(LabelScope? scope, void Function() callback) {
    var previous = _labelScope;
    try {
      _labelScope = scope;
      callback();
    } finally {
      _labelScope = previous;
    }
  }

  void _withUnlabeledBreakContinueContext(
    UnlabeledBreakContinueContext context,
    void Function() callback,
  ) {
    var previous = _unlabeledBreakContinueContext;
    try {
      _unlabeledBreakContinueContext = context;
      callback();
    } finally {
      _unlabeledBreakContinueContext = previous;
    }
  }

  void _withUnlabeledBreakContinueContextNested(
    Statement statement,
    void Function() callback,
  ) {
    _withUnlabeledBreakContinueContext(
      _unlabeledBreakContinueContext.nest(statement),
      callback,
    );
  }

  /// We always build local elements for [VariableDeclarationStatement]s and
  /// [FunctionDeclarationStatement]s in blocks, because invalid code might try
  /// to use forward references.

  /// Associate each of the annotation [nodes] with the corresponding
  /// [ElementAnnotation] in [annotations].
  static void _setElementAnnotations(
    List<AnnotationImpl> nodes,
    List<ElementAnnotationImpl> annotations,
  ) {
    int nodeCount = nodes.length;
    if (nodeCount != annotations.length) {
      throw StateError(
        'Found $nodeCount annotation nodes and '
        '${annotations.length} element annotations',
      );
    }
    for (int i = 0; i < nodeCount; i++) {
      nodes[i].elementAnnotation = annotations[i];
    }
  }
}

class _PatternVariableBinderVisitor extends ThrowingAstVisitor<void> {
  final VariableBinder<DartPatternImpl, PatternVariableElementImpl> _binder;

  _PatternVariableBinderVisitor(this._binder);

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {}

  @override
  void visitCastPattern(CastPattern node) {
    node.pattern.accept(this);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {}

  @override
  void visitDeclaredVariablePattern(
    covariant DeclaredVariablePatternImpl node,
  ) {
    var element = node.declaredFragment!.element;
    _binder.add(node.name.lexeme, element);
  }

  @override
  void visitListPattern(ListPattern node) {
    node.elements.accept(this);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    node.leftOperand.accept(this);
    node.rightOperand.accept(this);
  }

  @override
  void visitLogicalOrPattern(covariant LogicalOrPatternImpl node) {
    _binder.logicalOrPatternStart();
    node.leftOperand.accept(this);
    _binder.logicalOrPatternFinishLeft();
    node.rightOperand.accept(this);
    _binder.logicalOrPatternFinish(node);
  }

  @override
  void visitMapPattern(MapPattern node) {
    node.elements.accept(this);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    node.value.accept(this);
  }

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    node.pattern.accept(this);
  }

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    node.pattern.accept(this);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    node.fields.accept(this);
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    node.pattern.accept(this);
  }

  @override
  void visitPatternField(PatternField node) {
    node.pattern.accept(this);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    node.fields.accept(this);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {}

  @override
  void visitRestPatternElement(RestPatternElement node) {
    node.pattern?.accept(this);
  }

  @override
  void visitWildcardPattern(WildcardPattern node) {}
}

class _VariableBinder
    extends VariableBinder<DartPatternImpl, PatternVariableElementImpl> {
  final TypeProvider typeProvider;

  _VariableBinder({required super.errors, required this.typeProvider});

  @override
  JoinPatternVariableElementImpl joinPatternVariables({
    required Object key,
    required List<PatternVariableElementImpl> components,
    required shared.JoinedPatternVariableInconsistency inconsistency,
  }) {
    var first = components.first;
    List<PatternVariableElementImpl> expandedVariables;
    if (key is LogicalOrPatternImpl) {
      expandedVariables = components
          .expand((variable) {
            if (variable is JoinPatternVariableElementImpl) {
              return variable.variables;
            } else {
              return [variable];
            }
          })
          .toList(growable: false);
    } else if (key is SwitchStatementCaseGroup) {
      expandedVariables = components;
    } else {
      throw UnimplementedError('(${key.runtimeType}) $key');
    }

    var resultFragment = JoinPatternVariableFragmentImpl(
      name: first.name,
      firstTokenOffset: null,
      variables: expandedVariables.map((e) => e.firstFragment).toList(),
      inconsistency: inconsistency.maxWithAll(
        components.whereType<JoinPatternVariableElementImpl>().map(
          (e) => e.inconsistency,
        ),
      ),
    );
    resultFragment.enclosingFragment = first.firstFragment.enclosingFragment;

    return resultFragment.element;
  }
}

class _VariableBinderErrors
    implements
        VariableBinderErrors<DartPatternImpl, PatternVariableElementImpl> {
  final ResolutionVisitor visitor;

  _VariableBinderErrors(this.visitor);

  @override
  void assertInErrorRecovery() {
    // TODO(scheglov): implement assertInErrorRecovery
    throw UnimplementedError();
  }

  @override
  void duplicateVariablePattern({
    required String name,
    required covariant BindPatternVariableElementImpl original,
    required covariant BindPatternVariableElementImpl duplicate,
  }) {
    visitor._diagnosticReporter.report(
      DiagnosticFactory().duplicateDefinitionForNodes(
        visitor._diagnosticReporter.source,
        diag.duplicateVariablePattern.withArguments(name: name),
        duplicate.node.name,
        original.node.name,
      ),
    );
    duplicate.isDuplicate = true;
  }

  @override
  void logicalOrPatternBranchMissingVariable({
    required covariant LogicalOrPatternImpl node,
    required bool hasInLeft,
    required String name,
    required PromotableElementImpl variable,
  }) {
    visitor._diagnosticReporter.report(
      diag.missingVariablePattern
          .withArguments(name: name)
          .at(hasInLeft ? node.rightOperand : node.leftOperand),
    );
  }
}

extension _VariableDeclarationList on VariableDeclarationList {
  List<LocalVariableElementImpl> get declaredElements {
    return variables
        .map((v) => v.declaredFragment!.element)
        .cast<LocalVariableElementImpl>()
        .toList();
  }
}
