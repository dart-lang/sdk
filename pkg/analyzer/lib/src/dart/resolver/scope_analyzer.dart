// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/variable_bindings.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
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
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/named_type_resolver.dart';
import 'package:analyzer/src/dart/resolver/record_type_annotation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/scope_context.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/error/lookup_failure_reporter.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

/// Builds scopes, and resolves everything found by scope lookup: local and
/// top-level names, import prefixes, type annotations, labels, and pattern
/// variables.
///
/// It also replaces the `Parsed*` nodes built by the parser. The parser cannot
/// see declarations, so where the node kind depends on what a name refers to,
/// it builds a `Parsed*` node instead. For example:
/// - `x` is a type literal if `x` is a type, and a read of `x` otherwise;
/// - `a.b` reads a static member if `a` is a class, a declaration of an
///   imported library if `a` is an import prefix, and a property of the value
///   `a` otherwise; `C.named` is a constructor tear-off;
/// - `X<T>` is a type literal if `X` is a type, and a function instantiation
///   otherwise; `C<T>.named` is a constructor tear-off;
/// - `f()` is a constructor invocation if `f` is a class, an extension
///   override if `f` is an extension, and a function invocation otherwise;
/// - `a.b = v` writes a declaration of an imported library if `a` is an
///   import prefix, and a member of `a` otherwise.
///
/// Each `visitParsed*` method lowers its node, puts the result into the tree,
/// and visits the result, which lowers the `Parsed*` nodes inside it. Nodes
/// are lowered only by these methods and the helpers they call. A selector
/// chain such as `a.b.c` is lowered as a whole, from its outermost node,
/// because what `a` is decides what `.b` and `.c` become. A call or type
/// arguments end the chain: in `a.b().c`, the call `a.b()` is the receiver of
/// `.c`, and is lowered when visited.
///
/// A call `a.b()` keeps its parsed form, unless it is a constructor invocation
/// `C.named()`: whether `b` is a method or a getter whose value is called is
/// decided by member lookup during type analysis. The same holds for `..b()`
/// and `.b()`. For these calls, this class only resolves the names in the
/// receiver and visits the arguments.
class ScopeAnalyzer extends RecursiveAstVisitor2<void> {
  final LibraryElementImpl _libraryElement;
  final TypeProviderImpl _typeProvider;
  final LibraryFragmentImpl _libraryFragment;
  final DiagnosticReporter _diagnosticReporter;
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

  factory({
    required LibraryFragmentImpl libraryFragment,
    required DiagnosticListener diagnosticListener,
    required Scope nameScope,
    required DocImportScope? docImportScope,
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
      docImportScope: docImportScope,
    );

    var namedTypeResolver = NamedTypeResolver(
      libraryElement,
      libraryFragment,
      scopeContext,
      diagnosticReporter,
      strictCasts: strictCasts,
      typeSystemOperations: typeSystemOperations,
    );

    var recordTypeResolver = RecordTypeAnnotationResolver(
      typeProvider: typeProvider,
      diagnosticReporter: diagnosticReporter,
      libraryElement: libraryElement,
    );

    return ScopeAnalyzer._(
      libraryElement,
      typeProvider,
      libraryFragment,
      diagnosticReporter,
      namedTypeResolver,
      recordTypeResolver,
      scopeContext,
      typeSystemOperations,
      dataForTesting,
    );
  }

  new _(
    this._libraryElement,
    this._typeProvider,
    this._libraryFragment,
    this._diagnosticReporter,
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
  void visitAnonymousMethodInvocation(
    covariant AnonymousMethodInvocationImpl node,
  ) {
    node.target2?.accept2(this);

    _scopeContext.withLocalScope((scope) {
      if (node.parameters case var parameters?) {
        scope.addFormalParameterList(parameters);
        parameters.accept2(this);
      }
      node.body.accept2(this);
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

      LookupFailureReporter(
        _diagnosticReporter,
        _libraryFragment,
      ).reportWriteFailure(
        domain: UnqualifiedLookupDomain(),
        name: node.name,
        foundInstead: null,
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
      _defineLocalElements(scope, node.statements2);
      node.statements2.accept2(this);
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
    exceptionTypeNode?.accept2(this);

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

      node.body.accept2(this);
    });
  }

  @override
  void visitClassDeclaration2(covariant ClassDeclaration2Impl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    _scopeContext.visitClassDeclaration2(node, visitor: this);
    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitClassTypeAlias2(covariant ClassTypeAlias2Impl node) {
    var fragment = node.declaredFragment!;
    _namedTypeResolver.enclosingClass = fragment.element;

    _scopeContext.visitClassTypeAlias2(
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
  void visitCommentReference(covariant CommentReferenceImpl node) {
    var first = node.components.first;
    first.scopeLookupResult = nameScope.lookup(first.name.lexeme);
  }

  @override
  void visitCompilationUnit(covariant CompilationUnitImpl node) {
    node.nameScope = nameScope;
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration2(
    covariant ConstructorDeclaration2Impl node,
  ) {
    _scopeContext.visitConstructorDeclaration2(node, visitor: this);
  }

  @override
  void visitConstructorFieldInitializer(
    covariant ConstructorFieldInitializerImpl node,
  ) {
    node.visitChildren2(this);
  }

  @override
  void visitConstructorReference2(covariant ConstructorReference2Impl node) {
    node.typeReference.accept2(this);
  }

  @override
  void visitConstructorTearOff(covariant ConstructorTearOffImpl node) {
    node.typeReference.accept2(this);
  }

  @override
  void visitConstructorTypeReference(
    covariant ConstructorTypeReferenceImpl node,
  ) {
    node.typeArguments?.accept2(this);
    _namedTypeResolver.resolveConstructorTypeReference(
      node,
      dataForTesting: dataForTesting,
    );
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

    node.type?.accept2(this);

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
      _visitStatementInScope(node.body2);
      node.condition2.accept2(this);
    });
  }

  @override
  void visitEmptyFunctionBody(covariant EmptyFunctionBodyImpl node) {
    node.localVariableInfo = _localVariableInfo;
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEnumDeclaration2(covariant EnumDeclaration2Impl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    _scopeContext.visitEnumDeclaration2(node, visitor: this);
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
      declaration: node.parent2 as AnnotatedNode?,
      clause: node,
      namedType: node.superclass,
    );
  }

  @override
  void visitExtensionDeclaration2(covariant ExtensionDeclaration2Impl node) {
    _scopeContext.visitExtensionDeclaration2(node, visitor: this);
  }

  @override
  void visitExtensionTypeDeclaration2(
    covariant ExtensionTypeDeclaration2Impl node,
  ) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    _scopeContext.visitExtensionTypeDeclaration2(node, visitor: this);
    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    _scopeContext.visitFormalParameter(node, visitor: this);
    _setExplicitFormalParameterType(node);
  }

  @override
  void visitFieldsDeclaration(covariant FieldsDeclarationImpl node) {
    _scopeContext.visitFieldsDeclaration(node, visitor: this);
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
        node.body2.accept2(this);
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
        _visitStatementInScope(node.body2);
      });
    });
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
  void visitFunctionTypeAlias2(covariant FunctionTypeAlias2Impl node) {
    _scopeContext.visitFunctionTypeAlias2(node, visitor: this);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    _scopeContext.visitGenericFunctionType(node, visitor: this);

    var element = node.declaredFragment!.element;
    element.returnType = node.returnType?.type ?? _typeProvider.dynamicType;

    var type = FunctionTypeImpl(
      typeParameters: element.typeParameters,
      formalParameters: element.formalParameters,
      returnType: element.returnType,
      nullabilitySuffix: _getNullability(node.question != null),
    );
    element.type = type;
    node.type = type;
  }

  @override
  void visitGenericTypeAlias2(covariant GenericTypeAlias2Impl node) {
    _scopeContext.visitGenericTypeAlias2(
      node,
      visitor: this,
      enterTypeParameterScope: () {
        node.nameScope = nameScope;
      },
    );
  }

  @override
  void visitGetterDeclaration(covariant GetterDeclarationImpl node) {
    _scopeContext.visitMethodDeclaration(node, visitor: this);
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
      node.expression2.accept2(this);
      _resolveGuardedPattern(
        caseClause.guardedPattern,
        then: () {
          caseClause.nameScope = nameScope;
          node.ifTrue2.accept2(this);
        },
      );
      node.ifFalse2?.accept2(this);
    } else {
      node.visitChildren2(this);
    }
  }

  @override
  void visitIfStatement(covariant IfStatementImpl node) {
    if (node.caseClause case var caseClause?) {
      node.expression2.accept2(this);
      _resolveGuardedPattern(
        caseClause.guardedPattern,
        then: () {
          caseClause.nameScope = nameScope;
          _visitStatementInScope(node.ifTrue2);
        },
      );
      _visitStatementInScope(node.ifFalse2);
    } else {
      node.expression2.accept2(this);
      _visitStatementInScope(node.ifTrue2);
      _visitStatementInScope(node.ifFalse2);
    }
  }

  @override
  void visitImplementsClause(covariant ImplementsClauseImpl node) {
    _resolveImplementsClause(
      declaration: node.parent2 as AnnotatedNode,
      clause: node,
    );
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var element = node.libraryImport;
    if (element != null) {
      _setElementAnnotations(node.metadata, element.metadata.annotations);
    }
    node.visitChildren2(this);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    var unlabeled = node.unlabeled2;
    var labelScope = _nestLabelScopes(_labelScope, node.labels, unlabeled);

    _withLabelScope(labelScope, () {
      unlabeled.accept2(this);
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
  void visitLocalFunctionDeclaration(
    covariant LocalFunctionDeclarationImpl node,
  ) {
    var element = node.declaredFragment!.element;

    _withEnclosingClosure(element, () {
      _scopeContext.visitLocalFunctionDeclaration(node, visitor: this);
    });

    element.returnType = node.returnType?.type ?? _typeProvider.dynamicType;
  }

  @override
  void visitLocalVariable(covariant LocalVariableImpl node) {
    var element = node.declaredFragment!.element;
    if (node.parent2.type case var typeNode?) {
      element.type = typeNode.typeOrThrow;
    } else {
      // TODO(scheglov): review and improve resolution to not rely on dynamic.
      element.type = _typeProvider.dynamicType;
    }

    node.initializer?.accept2(this);
  }

  @override
  void visitLocalVariablesDeclaration(
    covariant LocalVariablesDeclarationImpl node,
  ) {
    node.metadata.accept2(this);
    node.type?.accept2(this);
    node.variables.accept2(this);
  }

  @override
  void visitMethodDeclaration2(covariant MethodDeclaration2Impl node) {
    _scopeContext.visitMethodDeclaration(node, visitor: this);
  }

  @override
  void visitMixinDeclaration2(covariant MixinDeclaration2Impl node) {
    _scopeContext.visitMixinDeclaration2(node, visitor: this);
  }

  @override
  void visitMixinOnClause(covariant MixinOnClauseImpl node) {
    _resolveMixinOnClause(
      declaration: node.parent2 as AnnotatedNode,
      clause: node,
    );
  }

  @override
  void visitNamedArgument(covariant NamedArgumentImpl node) {
    node.visitChildren2(this);
  }

  @override
  void visitNamedType(covariant NamedTypeImpl node) {
    node.typeArguments?.accept2(this);

    _namedTypeResolver.resolve(node, dataForTesting: dataForTesting);
  }

  @override
  void visitNativeFunctionBody(covariant NativeFunctionBodyImpl node) {
    node.localVariableInfo = _localVariableInfo;
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitOperatorDeclaration(covariant OperatorDeclarationImpl node) {
    _scopeContext.visitMethodDeclaration(node, visitor: this);
  }

  @override
  void visitParsedNameAccess(covariant ParsedNameAccessImpl node) {
    var expression = _lowerNameAccessAsValue(node);
    node.replaceWith(expression);
    expression.accept2(this);
  }

  @override
  void visitParsedNameAccessAssignmentTarget(
    covariant ParsedNameAccessAssignmentTargetImpl node,
  ) {
    var target = _lowerNameAccessAssignmentTarget(node);
    node.replaceWith(target);
    target.accept2(this);
  }

  @override
  void visitParsedTypeArguments(covariant ParsedTypeArgumentsImpl node) {
    var expression = _lowerTypeArguments(node);
    node.replaceWith(expression);
    expression.accept2(this);
  }

  @override
  void visitParsedUnqualifiedName(covariant ParsedUnqualifiedNameImpl node) {
    var expression = _buildNameExpression(
      importPrefix: null,
      name: node.name,
      lookup: _lookupParsedName(node),
    );
    node.replaceWith(expression);
    expression.accept2(this);
  }

  @override
  void visitParsedValueArguments(covariant ParsedValueArgumentsImpl node) {
    // `..m()` stays parsed: it awaits member lookup on the once-evaluated
    // cascade receiver.
    if (node.cascadeInvocationParts case (:var typeArguments, head: _)) {
      typeArguments?.accept2(this);
      node.argumentList.accept2(this);
      return;
    }

    // `.m()` stays parsed: it needs the context established by its enclosing
    // expression before lookup can distinguish a constructor, method, or
    // callable property.
    if (node.dotShorthandInvocationParts case (:var typeArguments, head: _)) {
      typeArguments?.accept2(this);
      node.argumentList.accept2(this);
      return;
    }

    // `C<T>.n()` is a constructor invocation, unless `C` names a function,
    // method, or variable, as `f` in `f<int>.call()`. An unknown `C` is taken
    // for a misspelled class, see [_buildCalledConstructorTypeReference].
    if (node.operand case ParsedNameAccessImpl(
      operand: ParsedTypeArgumentsImpl instantiation,
      :var operator,
      :var name,
    )) {
      if (_buildCalledConstructorTypeReference(instantiation, node)
          case var typeReference?) {
        var expression = ConstructorInvocationImpl(
          keyword: null,
          constructorReference: ConstructorReference2Impl(
            typeReference: typeReference,
            selector: ConstructorSelectorImpl.v2(period: operator, name2: name),
          ),
          argumentList: node.argumentList,
          typeArguments: null,
        );
        node.replaceWith(expression);
        expression.accept2(this);
        return;
      }
    }

    // `R.n()` calls `n` of the receiver `R`, unless `R` is an import prefix:
    // `p.f()` calls the imported `f`.
    if (node.namedInvocationParts case (:var selector, :var typeArguments)
        when !_isImportPrefixName(selector.operand)) {
      _visitReceiverInvocation(node, selector, typeArguments);
      return;
    }

    // Otherwise a call of a name: `f()`, `C<T>()`, or `p.f()`.
    _visitScopeInvocation(node);
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
      node.pattern.accept2(this);
      node.expression2.accept2(this);
    });
  }

  @override
  void visitPatternVariableDeclarationStatement(
    covariant PatternVariableDeclarationStatementImpl node,
  ) {
    node.declaration.accept2(this);
  }

  @override
  void visitPrimaryConstructorBody2(
    covariant PrimaryConstructorBody2Impl node,
  ) {
    _scopeContext.visitPrimaryConstructorBody2(node, visitor: this);
  }

  @override
  void visitReceiverPropertyAssignmentTarget(
    covariant ReceiverPropertyAssignmentTargetImpl node,
  ) {
    node.visitChildren2(this);
  }

  @override
  void visitRecordTypeAnnotation(covariant RecordTypeAnnotationImpl node) {
    node.visitChildren2(this);
    _recordTypeResolver.resolve(node);
  }

  @override
  void visitRegularFormalParameter(covariant RegularFormalParameterImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    if (node.functionTypedSuffix != null) {
      _scopeContext.visitFormalParameter(node, visitor: this);
    } else {
      node.visitChildren2(this);
    }

    var explicitFragmentType = _setExplicitFormalParameterType(node);

    if (fragment.previousFragment == null) {
      if (explicitFragmentType != null) {
        element.type = explicitFragmentType;
      } else if (node.type != null) {
        element.type = _typeProvider.dynamicType;
      } else if (element.type is InvalidTypeImpl) {
        // TODO(scheglov): review and improve resolution to not rely on dynamic.
        element.type = _typeProvider.dynamicType;
      }
    }
  }

  @override
  void visitSemicolonEnumDeclarationBody(SemicolonEnumDeclarationBody node) {}

  @override
  void visitSemicolonInstanceDeclarationBody(
    SemicolonInstanceDeclarationBody node,
  ) {}

  @override
  void visitSetterDeclaration(covariant SetterDeclarationImpl node) {
    _scopeContext.visitMethodDeclaration(node, visitor: this);
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
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    _scopeContext.visitFormalParameter(node, visitor: this);
    _setExplicitFormalParameterType(node);
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
    node.expression2.accept2(this);

    for (var case_ in node.cases) {
      _resolveGuardedPattern(
        case_.guardedPattern,
        then: () {
          case_.nameScope = nameScope;
          case_.expression2.accept2(this);
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
        node.expression2.accept2(this);

        for (var group in node.memberGroups) {
          _patternVariables.switchStatementSharedCaseScopeStart(group);
          for (var member in group.members) {
            if (member is SwitchCaseImpl) {
              member.expression2.accept2(this);
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
            group.statements.accept2(this);
          });
        }
      });
    });
  }

  @override
  void visitTopLevelFunctionDeclaration(
    covariant TopLevelFunctionDeclarationImpl node,
  ) {
    _scopeContext.visitTopLevelFunctionDeclaration(node, visitor: this);
  }

  @override
  void visitTopLevelGetterDeclaration(
    covariant TopLevelGetterDeclarationImpl node,
  ) {
    _scopeContext.visitTopLevelGetterDeclaration(node, visitor: this);
  }

  @override
  void visitTopLevelSetterDeclaration(
    covariant TopLevelSetterDeclarationImpl node,
  ) {
    _scopeContext.visitTopLevelSetterDeclaration(node, visitor: this);
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var fragment = node.declaredFragment!;

    node.metadata.accept2(this);

    var boundNode = node.bound;
    if (boundNode != null) {
      boundNode.accept2(this);
      if (fragment.previousFragment == null) {
        fragment.element.bound = boundNode.type;
      }
    }
  }

  @override
  void visitUnqualifiedFunctionInvocation(
    covariant UnqualifiedFunctionInvocationImpl node,
  ) {
    var lookup = node.scopeLookupResult ??= nameScope.lookup(node.name.lexeme);
    if (lookup.getter case JoinPatternVariableElementImpl element) {
      element.references.add(node.name);
    }
    node.visitChildren2(this);
  }

  @override
  void visitUnqualifiedNameAssignmentTarget(
    covariant UnqualifiedNameAssignmentTargetImpl node,
  ) {
    var scopeLookupResult = nameScope.lookup(node.name.lexeme);
    node.scopeLookupResult = scopeLookupResult;

    if (scopeLookupResult.getter case JoinPatternVariableElementImpl element) {
      element.references.add(node.name);
    }

    _recordUnqualifiedWrite(scopeLookupResult, node);
  }

  @override
  void visitUnqualifiedNameExpression(
    covariant UnqualifiedNameExpressionImpl node,
  ) {
    var scopeLookupResult = node.scopeLookupResult ??= nameScope.lookup(
      node.name.lexeme,
    );

    if (scopeLookupResult.getter case JoinPatternVariableElementImpl element) {
      element.references.add(node.name);
    }
  }

  @override
  void visitWhileStatement(covariant WhileStatementImpl node) {
    _withUnlabeledBreakContinueContextNested(node, () {
      node.condition2.accept2(this);
      _visitStatementInScope(node.body2);
    });
  }

  @override
  void visitWithClause(covariant WithClauseImpl node) {
    _resolveWithClause(
      declaration: node.parent2 as AnnotatedNode?,
      clause: node,
    );
  }

  /// Returns the reference to the type `C<T>` or `p.C<T>` in the call
  /// `C<T>.name()` or `p.C<T>.name()`, or `null` if it calls a member of a
  /// value.
  ///
  /// Unlike [_buildConstructorTypeReference], an unknown name is taken for a
  /// misspelled class, so that the call is reported as a constructor call.
  /// Language versions without constructor tear-offs have their own rules.
  ConstructorTypeReferenceImpl? _buildCalledConstructorTypeReference(
    ParsedTypeArgumentsImpl instantiation,
    ParsedValueArgumentsImpl invocation,
  ) {
    var constructorTearoffsEnabled = _libraryElement.featureSet.isEnabled(
      Feature.constructor_tearoffs,
    );
    var typeName = _lookupInstantiatedName(instantiation);

    // If `C<T>` is neither `C` nor `p.C`, as in `x.C<T>.m()` where `x` is not
    // an import prefix, it is not a constructor's type, and the call is a
    // member call on a value, lowered by [_visitReceiverInvocation].
    if (typeName == null) {
      // `x.C<T>` explicitly instantiates a generic member of `x`, which
      // requires the constructor tear-offs feature.
      if (instantiation.operand
          case ParsedNameAccessImpl(
            operand: ParsedUnqualifiedNameImpl(),
            :var operator,
          )
          when operator.type == TokenType.PERIOD) {
        if (!constructorTearoffsEnabled) {
          _diagnosticReporter.report(
            diag.sdkVersionConstructorTearoffs.at(invocation),
          );
        }
      }
      return null;
    }

    var element = typeName.element;

    // An instance member found through an implicit `this`, as in
    // `foo<int>.m()`, must not be taken for a misspelled class.
    if (element == null && typeName.importPrefix == null) {
      element = _lookupInstanceMember(typeName.name.lexeme);
    }

    // `f<T>.m()`, where `f` is a function, method, or variable, calls `m` of
    // the instantiated `f<T>`.
    if (element is ExecutableElement || element is VariableElement) {
      if (constructorTearoffsEnabled) return null;

      // Before constructor tear-offs, explicit instantiation is an error.
      // With a function, method, or getter, `f<T>.m()` is reported here, and
      // stays a member call. With a variable, or a getter through an import
      // prefix, it is taken for a constructor invocation, and reported as
      // one: "The name 'f' isn't a class".
      if (element is ExecutableElement &&
          (typeName.importPrefix == null ||
              element is TopLevelFunctionElement)) {
        _diagnosticReporter.report(
          diag.sdkVersionConstructorTearoffs.at(invocation),
        );
        return null;
      }
    }

    // Otherwise `C<T>` is a constructor's type: a type, an unknown name taken
    // for a misspelled class, or another name reported later as not a class.
    return ConstructorTypeReferenceImpl(
      importPrefix: typeName.importPrefix,
      name: typeName.name,
      typeArguments: instantiation.typeArguments,
    );
  }

  /// Returns the reference to the type `C<T>` or `p.C<T>` in `C<T>.name` or
  /// `p.C<T>.name`, if `C` names a class, enum, mixin, or extension type,
  /// possibly through a type alias, or a function-type alias. Written type
  /// arguments make this constructor syntax even if `C` has no constructor
  /// `name`, or cannot have constructors at all.
  ///
  /// Otherwise returns `null`, and `C<T>` is a value, such as the generic
  /// function instantiation `f<int>`.
  ///
  /// [instantiation] is always followed by `.name`; `C<T>` alone is lowered
  /// by [_lowerTypeArguments].
  ConstructorTypeReferenceImpl? _buildConstructorTypeReference(
    ParsedTypeArgumentsImpl instantiation,
  ) {
    if (_lookupInstantiatedName(instantiation) case var typeName?) {
      var element = typeName.element;
      // TODO(scheglov): `X<T>.name` is constructor syntax for any type `X`,
      // not only for a class or a function-type alias. So any name that is
      // not a value, such as a record or type parameter alias, should be a
      // type reference, instead of `X<T>` being a type literal whose `.name`
      // reads a member of `Type`.
      if (element.unaliasedInterface != null ||
          element is TypeAliasElement && element.aliasedType is FunctionType) {
        return ConstructorTypeReferenceImpl(
          importPrefix: typeName.importPrefix,
          name: typeName.name,
          typeArguments: instantiation.typeArguments,
        );
      }
    }
    return null;
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
    pattern.accept2(_PatternVariableBinderVisitor(_patternVariables));
    return _patternVariables.casePatternFinish(
      sharedCaseScopeKey: sharedCaseScopeKey,
    );
  }

  void _defineLocalElements(LocalScope scope, List<Statement> statements) {
    for (var statement in statements) {
      statement = statement.unlabeled2;
      switch (statement) {
        case LocalFunctionDeclarationImpl():
          var element = statement.declaredFragment!.element;
          scope.add(element);
        case PatternVariableDeclarationStatementImpl():
          var declaration = statement.declaration;
          _definePatternVariableDeclarationElements(scope, declaration);
        case LocalVariablesDeclarationStatementImpl():
          scope.addAll(statement.declaration.declaredElements);
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

  /// Whether [node] is a name that resolves to an import prefix.
  bool _isImportPrefixName(InstanceReceiverImpl node) {
    return node is ParsedUnqualifiedNameImpl &&
        _lookupParsedName(node).getter is PrefixElement;
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

  /// Looks up [name] among the instance members of the enclosing class, mixin,
  /// enum, or extension type, which are not in the lexical scope.
  Element? _lookupInstanceMember(String name) {
    if (_scopeContext.enclosingInstanceElement
        case InterfaceElementImpl enclosingElement) {
      return enclosingElement.inheritanceManager.getMember(
        enclosingElement,
        Name(_libraryElement.uri, name),
      );
    }
    return null;
  }

  /// Looks up in the lexical scope the name `X` or `p.X` that [node]
  /// instantiates in `X<T>` or `p.X<T>`. Returns `null` for any other shape,
  /// including `x.X<T>` where `x` is not an import prefix.
  ({ImportPrefixReferenceImpl? importPrefix, Token name, Element? element})?
  _lookupInstantiatedName(ParsedTypeArgumentsImpl node) {
    switch (node.operand) {
      case ParsedUnqualifiedNameImpl operand:
        return (
          importPrefix: null,
          name: operand.name,
          element: _lookupParsedName(operand).getter,
        );
      case ParsedNameAccessImpl operand:
        if (_lookupPrefixedName(operand) case (
          :var importPrefix,
          :var lookup,
        )) {
          return (
            importPrefix: importPrefix,
            name: operand.name,
            element: lookup.getter,
          );
        }
      default:
    }
    return null;
  }

  /// Returns the scope lookup of [node], stored on it to be done only once.
  ///
  /// The same name is often looked up by more than one step, for example
  /// `a` in `a.m()` to check for an import prefix, and then to lower `a`.
  ScopeLookupResult _lookupParsedName(ParsedUnqualifiedNameImpl node) {
    return node.scopeLookupResult ??= nameScope.lookup(node.name.lexeme);
  }

  /// Returns the import prefix `p` and the lookup of `a` in it, if [node] is
  /// the prefixed name `p.a`, otherwise `null`.
  ///
  /// `p?.a` is not a prefixed name: `p` is read as a value, and reported
  /// later.
  ({ImportPrefixReferenceImpl importPrefix, ScopeLookupResult lookup})?
  _lookupPrefixedName(ParsedNameAccessImpl node) {
    if (node.operand case ParsedUnqualifiedNameImpl prefixName) {
      // TODO(scheglov): Treat `p?.a` as the prefixed name `p.a` too, with an
      // error, as the CFE does, instead of reading `p` as a value. Then all
      // slots can use this method, see [_visitScopeInvocation].
      if (node.operator.type == TokenType.PERIOD) {
        if (_lookupParsedName(prefixName).getter case PrefixElement prefix) {
          return (
            importPrefix: ImportPrefixReferenceImpl(
              name: prefixName.name,
              period: node.operator,
            )..element = prefix,
            lookup: prefix.scope.lookup(node.name.lexeme),
          );
        }
      }
    }
    return null;
  }

  /// Lowers the target `H.n` of an assignment, such as `H.n = v`, `H.n += v`,
  /// or `H.n++`, to an import-prefixed name, or a write of `n` to `H`.
  ///
  /// The read `H.n` is lowered by [_lowerReceiver] and [_lowerSelector].
  AssignmentTargetImpl _lowerNameAccessAssignmentTarget(
    ParsedNameAccessAssignmentTargetImpl node,
  ) {
    var ParsedNameAccessAssignmentTargetImpl(:operand, :operator, :name) = node;

    // `C<T>.n` is a constructor tear-off, which cannot be assigned.
    if (operand is ParsedTypeArgumentsImpl) {
      if (_buildConstructorTypeReference(operand) case var typeReference?) {
        return InvalidExpressionAssignmentTargetImpl(
          expression: ConstructorTearOffImpl(
            typeReference: typeReference,
            selector: ConstructorSelectorImpl.v2(period: operator, name2: name),
          ),
        );
      }
    }

    // `p.n` is one prefixed name, as in reads, see [_lookupPrefixedName].
    // Unlike there, `n` is not looked up for `p.n`: type analysis looks it up
    // anyway, to find the setter, and a lookup has a cost.
    // TODO(scheglov): Treat `p?.n` as `p.n` too, see [_lookupPrefixedName].
    if (operand is ParsedUnqualifiedNameImpl &&
        operator.type == TokenType.PERIOD) {
      if (_lookupParsedName(operand).getter case PrefixElement prefix) {
        return ImportPrefixedAssignmentTargetImpl(
          importPrefix: ImportPrefixReferenceImpl(
            name: operand.name,
            period: operator,
          )..element = prefix,
          name: name,
        );
      }
    }

    // Otherwise a write: to a static member in `C.n`, or to a property of a
    // value in `a.n`.
    return ReceiverPropertyAssignmentTargetImpl(
      receiver: _lowerReceiver(operand, hasSelector: true),
      operator: operator,
      name: name,
    );
  }

  /// Lowers the selector chain that ends with [node], read as a value.
  ///
  /// For example, `a.b` reads a property of the value `a`, `C.b` reads a
  /// static member, `p.b` reads a declaration imported with the prefix `p`,
  /// and `C.named` or `C<int>.named` is a constructor tear-off.
  ExpressionImpl _lowerNameAccessAsValue(ParsedNameAccessImpl node) {
    // No selector or call follows [node]: if one did, [node] would be lowered
    // as part of that longer chain, such as `p.C.x` or `p.C.x()`. So [node]
    // is a value: `p.C` here is a type literal, not a static qualifier.
    return _lowerReceiver(node, hasSelector: false) as ExpressionImpl;
  }

  /// Lowers the chain [node] to a receiver: a name `a`, a prefixed name `p.a`,
  /// or a selector `H.n` over a lowered operand `H`.
  ///
  /// A chain is lowered from its root, instead of each node being visited on
  /// its own, because what each node becomes depends on the rest of the
  /// chain: `p.C.named` is a constructor tear-off, `p.C.x` reads from a
  /// static qualifier, and `a.b.x` reads from a value.
  ///
  /// [hasSelector] is whether a selector or a call follows [node]; every
  /// operand inside the chain has one. The caller puts the result in place of
  /// [node].
  NamedReceiverImpl _lowerReceiver(
    InstanceReceiverImpl node, {
    required bool hasSelector,
  }) {
    switch (node) {
      case ParsedUnqualifiedNameImpl():
        return _buildNameReceiver(
          importPrefix: null,
          name: node.name,
          lookup: _lookupParsedName(node),
          hasSelector: hasSelector,
        );
      case ParsedNameAccessImpl():
        if (_lookupPrefixedName(node) case (:var importPrefix, :var lookup)) {
          return _buildNameReceiver(
            importPrefix: importPrefix,
            name: node.name,
            lookup: lookup,
            hasSelector: hasSelector,
          );
        }
        return _lowerSelector(node);
      default:
        // Nested call syntax and ordinary expressions use their own visitors,
        // including constructor and extension-override selection.
        return node;
    }
  }

  /// Lowers the selector `H.n`, where `H` is not an import prefix, to a
  /// constructor tear-off, or a read of `n` from `H`.
  ExpressionImpl _lowerSelector(ParsedNameAccessImpl node) {
    var ParsedNameAccessImpl(:operand, :operator, :name) = node;

    // `C<T>.n` is a constructor tear-off.
    if (operand is ParsedTypeArgumentsImpl) {
      if (_buildConstructorTypeReference(operand) case var typeReference?) {
        return ConstructorTearOffImpl(
          typeReference: typeReference,
          selector: ConstructorSelectorImpl.v2(period: operator, name2: name),
        );
      }
    }

    // `C.n` is a constructor tear-off, if `C` has the constructor `n`.
    var receiver = _lowerReceiver(operand, hasSelector: true);
    if (receiver is StaticQualifierImpl) {
      var interface = receiver.element.unaliasedInterface;
      if (interface?.getNamedConstructor(name.lexeme) != null) {
        return ConstructorTearOffImpl(
          typeReference: ConstructorTypeReferenceImpl(
            importPrefix: receiver.importPrefix,
            name: receiver.name,
            typeArguments: null,
          ),
          selector: ConstructorSelectorImpl.v2(period: operator, name2: name),
        );
      }
    }

    // Otherwise a read: a static member in `C.x`, or a property of a value in
    // `a.x`, including members of `Type` on a type literal, as in `T.x`.
    return ReceiverPropertyExtractionImpl(
      receiver: receiver,
      operator: operator,
      name: name,
    );
  }

  /// Lowers `X<T>` that is not followed by `.name`, such as `C<int>`,
  /// `p.C<int>`, `f<int>`, or `a.m<int>`.
  ///
  /// If `X` names a type, the result is a type literal. Otherwise `X` is a
  /// value, and the result is its instantiation, such as the generic function
  /// instantiation `f<int>`.
  ///
  /// `X<T>.name` is lowered with its selector, see
  /// [_buildConstructorTypeReference].
  ExpressionImpl _lowerTypeArguments(ParsedTypeArgumentsImpl node) {
    if (_lookupInstantiatedName(node)
        case (:var importPrefix, :var name, :var element)
        when element.isTypeDefining) {
      return TypeLiteralImpl(
        type: NamedTypeImpl(
          importPrefix: importPrefix,
          name: name,
          typeArguments: node.typeArguments,
          question: null,
        ),
      );
    }

    // Otherwise `X<T>` instantiates the value `X`. Usually `X` is lowered
    // later: the caller visits the returned `FunctionInstantiation`, which
    // visits `X`.
    //
    // But `F.m<int>`, with `F` a function-type alias, must read `m` from the
    // type literal `F`, while `F.m` lowered alone keeps `F` as a static
    // qualifier. So a name access is lowered here, where the type arguments
    // are known, and its receiver is replaced, see [_functionTypeAliasValue].
    // TODO(scheglov): Lower `X` later in all cases, once a function-type alias
    // is a type literal, see the TODO in [_buildNameReceiver].
    var operand = node.operand;
    if (operand is ParsedNameAccessImpl) {
      var expression = _lowerNameAccessAsValue(operand);
      operand.replaceWith(expression);
      operand = expression;
      if (operand case ReceiverPropertyExtractionImpl(:var receiver)) {
        if (_functionTypeAliasValue(receiver) case var value?) {
          operand.receiver = value;
        }
      }
    }
    return FunctionInstantiationImpl(
      operand: operand,
      typeArguments: node.typeArguments,
    );
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

  void _recordUnqualifiedWrite(
    ScopeLookupResult scopeLookupResult,
    SyntacticEntity errorEntity,
  ) {
    var element = scopeLookupResult.getter;
    if (element is PromotableElementImpl) {
      _localVariableInfo.potentiallyMutatedInScope.add(element);

      if (element is PatternVariableElementImpl &&
          element.isVisitingWhenClause) {
        _diagnosticReporter.report(
          diag.patternVariableAssignmentInsideGuard.at(errorEntity),
        );
      }
    }
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
      guardedPattern.pattern.accept2(this);

      for (var variable in variables.values) {
        variable.isVisitingWhenClause = true;
      }
      try {
        guardedPattern.whenClause?.accept2(this);
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
    required AnnotatedNode? declaration,
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
    required AnnotatedNode? declaration,
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
    required AnnotatedNode? declaration,
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

    if (namedType.isSynthetic) {
      return;
    }

    switch (type.element) {
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
        if (declaration is ClassTypeAlias2) {
          diagnosticCode = diag.mixinWithNonClassSuperclass;
        }
      case ExtendsClause():
        if (declaration is ClassDeclaration2) {
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
    required AnnotatedNode? declaration,
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
    required AnnotatedNode? declaration,
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

  TypeImpl? _setExplicitFormalParameterType(FormalParameterImpl node) {
    if (node.functionTypedSuffix case var functionTypedSuffix?) {
      return node.explicitFragmentType = FunctionTypeImpl(
        typeParameters: [
          for (var typeParameter
              in functionTypedSuffix.typeParameters?.typeParameters ??
                  const <TypeParameterImpl>[])
            typeParameter.declaredFragment!.element,
        ],
        formalParameters: [
          for (var parameter
              in functionTypedSuffix.formalParameters.allFormalParameters)
            parameter.declaredFragment!.element,
        ],
        returnType: node.type?.type ?? _typeProvider.dynamicType,
        nullabilitySuffix: _getNullability(
          functionTypedSuffix.question != null,
        ),
      );
    }

    if (node.type case var type?) {
      return node.explicitFragmentType = type.type;
    }

    return node.explicitFragmentType = null;
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
        node.iterable2.accept2(this);
        var element = node.loopVariable.declaredFragment!.element;
        scope.add(element);
        node.loopVariable.accept2(this);
      case ForEachPartsWithIdentifierImpl():
        node.iterable2.accept2(this);
        node.target.accept2(this);
      case ForEachPartsWithPatternImpl():
        node.iterable2.accept2(this);
        var variables = _computeDeclaredPatternVariables(node.pattern);
        node.variables = variables;
        scope.addAll(variables);
        node.pattern.accept2(this);
        node.metadata.accept2(this);
      case ForPartsWithDeclarationsImpl():
        scope.addAll(node.variables2.declaredElements);
        node.variables2.accept2(this);
        node.condition2?.accept2(this);
        node.updaters2.accept2(this);
      case ForPartsWithExpressionImpl():
        node.initialization2?.accept2(this);
        node.condition2?.accept2(this);
        node.updaters2.accept2(this);
      case ForPartsWithPatternImpl():
        _definePatternVariableDeclarationElements(scope, node.variables);
        node.variables.accept2(this);
        node.condition2?.accept2(this);
        node.updaters2.accept2(this);
    }
  }

  /// Lowers the call `R.n()` or `R.n<T>()`, where `R` is not an import prefix,
  /// to a constructor invocation `C.n()`, or lowers only `R`.
  ///
  /// Other calls keep their parsed selector and arguments until type-based
  /// lookup distinguishes a method from a property whose value is invoked.
  /// Their lowered receiver replaces the selector operand, except a static
  /// qualifier, which the operand cannot hold, so it is stored in
  /// [ParsedValueArgumentsImpl.staticQualifier].
  void _visitReceiverInvocation(
    ParsedValueArgumentsImpl node,
    ParsedNameAccessImpl selector,
    TypeArgumentListImpl? typeArguments,
  ) {
    var receiver = _lowerReceiver(selector.operand, hasSelector: true);
    // `F.m()` calls a member of `Type` on the type literal `F`.
    receiver = _functionTypeAliasValue(receiver) ?? receiver;

    // `C.n()` and `C.new()` are constructor invocations, if `C` has the
    // constructor `n`, or `new` is written.
    if (receiver is StaticQualifierImpl) {
      var interface = receiver.element.unaliasedInterface;
      var constructor = interface?.getNamedConstructor(selector.name.lexeme);
      if (interface != null &&
          (constructor != null || selector.name.lexeme == 'new')) {
        // Type arguments after the constructor name are an error. For
        // recovery, `p.C.n<T>()` applies them to `C`, as `p.C<T>.n()` would,
        // while `C.n<T>()` keeps them on the invocation, where they are not
        // used.
        if (typeArguments != null) {
          _diagnosticReporter.report(
            diag.wrongNumberOfTypeArgumentsConstructor
                .withArguments(
                  className: receiver.toSource(),
                  constructorName: selector.name.lexeme,
                )
                .at(typeArguments),
          );
        }
        var expression = ConstructorInvocationImpl(
          keyword: null,
          constructorReference: ConstructorReference2Impl(
            typeReference: ConstructorTypeReferenceImpl(
              importPrefix: receiver.importPrefix,
              name: receiver.name,
              typeArguments: receiver.importPrefix != null
                  ? typeArguments
                  : null,
            ),
            selector: ConstructorSelectorImpl.v2(
              period: selector.operator,
              name2: selector.name,
            ),
          ),
          typeArguments: receiver.importPrefix == null ? typeArguments : null,
          argumentList: node.argumentList,
        );
        node.replaceWith(expression);
        expression.accept2(this);
        return;
      }
    }

    // Otherwise the call stays parsed, with its lowered receiver.
    switch (receiver) {
      case StaticQualifierImpl():
        node.staticQualifier = receiver;
      case ExpressionImpl():
        selector.operand = receiver;
        receiver.accept2(this);
      case SuperReferenceImpl():
      case ExtensionOverride2Impl():
        break;
    }
    typeArguments?.accept2(this);
    node.argumentList.accept2(this);
  }

  /// Lowers the call of a name found by scope lookup, unlike
  /// [_visitReceiverInvocation], where it is a member of the receiver: `f()`
  /// or `f<T>()`, optionally import-prefixed, as in `p.f()`, to a constructor
  /// invocation `C()`, an extension override `E(x)`, or a function invocation
  /// `f()`.
  void _visitScopeInvocation(ParsedValueArgumentsImpl node) {
    // `f<T>()` and `p.f<T>()` pass type arguments to the callee.
    ExpressionImpl callee = node.operand;
    TypeArgumentListImpl? typeArguments;
    if (callee case ParsedTypeArgumentsImpl(
      :var operand,
      typeArguments: var writtenTypeArguments,
    )) {
      callee = operand;
      typeArguments = writtenTypeArguments;
    }

    // Look up the called name: `f` in the lexical scope, or `f` in the import
    // prefix `p` for `p.f()`.
    Token name;
    ScopeLookupResult lookup;
    ImportPrefixReferenceImpl? importPrefix;
    switch (callee) {
      case ParsedUnqualifiedNameImpl():
        name = callee.name;
        lookup = _lookupParsedName(callee);
      case ParsedNameAccessImpl(operand: ParsedUnqualifiedNameImpl prefixName):
        // `p` is an import prefix: other receivers went to
        // [_visitReceiverInvocation].
        var prefix = _lookupParsedName(prefixName).getter as PrefixElement;
        // `p?.f()` is reported, but still calls the imported `f`, so that `f`
        // and the arguments are resolved. Unlike the read `p?.x`, which reads
        // `p` as a value, see [_lookupPrefixedName].
        // TODO(scheglov): Use [_lookupPrefixedName] here, once it treats `p?.f`
        // as `p.f` too, and report the error in one place for all slots.
        if (callee.operator.type != TokenType.PERIOD) {
          _diagnosticReporter.report(
            diag.prefixIdentifierNotFollowedByDot
                .withArguments(name: prefixName.name.lexeme)
                .at(prefixName.name),
          );
        }
        importPrefix = ImportPrefixReferenceImpl(
          name: prefixName.name,
          period: callee.operator,
        )..element = prefix;
        name = callee.name;
        lookup = prefix.scope.lookup(name.lexeme);
      default:
        // Cascade, shorthand, and receiver calls were handled by the caller,
        // and the parser creates value arguments for no other operands.
        throw StateError('Unexpected operand: ${callee.runtimeType}');
    }

    var argumentList = node.argumentList;
    var element = lookup.getter;
    ExpressionImpl expression;
    if (element.unaliasedInterface != null) {
      // `C()` and `C<T>()` invoke the unnamed constructor.
      expression = ConstructorInvocationImpl(
        keyword: null,
        constructorReference: ConstructorReference2Impl(
          typeReference: ConstructorTypeReferenceImpl(
            importPrefix: importPrefix,
            name: name,
            typeArguments: typeArguments,
          ),
          selector: null,
        ),
        argumentList: argumentList,
        typeArguments: null,
      );
    } else if (element is ExtensionElementImpl) {
      // `E(x)` is an explicit extension override, not an expression: it is
      // valid only as the receiver of a member access, as in `E(x).m()`.
      // [_replaceWithExtensionOverride] puts it into the receiver slot of the
      // parent, or wraps it as invalid, as in `var v = E(x);`.
      var receiver = ExtensionOverride2Impl(
        importPrefix: importPrefix,
        name: name,
        element: element,
        typeArguments: typeArguments,
        argumentList: argumentList,
      );
      _replaceWithExtensionOverride(node, receiver).accept2(this);
      return;
    } else if (importPrefix != null) {
      // Otherwise a function invocation; an undefined `f` is reported by type
      // analysis.
      expression = ImportPrefixedFunctionInvocationImpl(
        importPrefix: importPrefix,
        name: name,
        typeArguments: typeArguments,
        argumentList: argumentList,
      );
    } else {
      expression = UnqualifiedFunctionInvocationImpl(
        name: name,
        typeArguments: typeArguments,
        argumentList: argumentList,
      )..scopeLookupResult = lookup;
    }
    node.replaceWith(expression);
    expression.accept2(this);
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
          statement.accept2(this);
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

  /// Returns the value expression for [name], optionally prefixed with
  /// [importPrefix], whose scope lookup gave [lookup].
  ///
  /// A name of a type is a type literal, and any other name is a read of
  /// what it names. Undefined names are also reads, reported later by type
  /// analysis.
  static ExpressionImpl _buildNameExpression({
    required ImportPrefixReferenceImpl? importPrefix,
    required Token name,
    required ScopeLookupResult lookup,
  }) {
    if (lookup.getter.isTypeDefining) {
      return TypeLiteralImpl(
        type: NamedTypeImpl(
          importPrefix: importPrefix,
          name: name,
          typeArguments: null,
          question: null,
        ),
      );
    }
    if (importPrefix != null) {
      return ImportPrefixedNameExpressionImpl(
        importPrefix: importPrefix,
        name: name,
      );
    }
    return UnqualifiedNameExpressionImpl(name: name)
      ..scopeLookupResult = lookup;
  }

  /// Returns the receiver for [name], optionally prefixed with
  /// [importPrefix], whose scope lookup gave [lookup].
  ///
  /// If [hasSelector], a name of a class, enum, mixin, extension type, or
  /// extension, possibly through a type alias, is a static qualifier, as `C`
  /// in `C.x`. So is a function-type alias, see the body. Otherwise the name
  /// is a value, see [_buildNameExpression]: `C` alone is a type literal.
  static NamedReceiverImpl _buildNameReceiver({
    required ImportPrefixReferenceImpl? importPrefix,
    required Token name,
    required ScopeLookupResult lookup,
    required bool hasSelector,
  }) {
    if (hasSelector) {
      var element = lookup.getter;
      // Static members are accessed through a class, enum, mixin, extension
      // type, or extension, or a type alias of one of these. Any other name
      // of a type is a type literal, and a selector reads a member of `Type`.
      if (element.unaliasedInterface != null || element is ExtensionElement) {
        return StaticQualifierImpl(importPrefix: importPrefix, name: name)
          ..element = element
          ..scopeLookupResult = lookup;
      }
      // TODO(scheglov): A function-type alias should be a type literal, as
      // other type aliases that do not denote a class are, and as in the CFE.
      // It is a qualifier only to report invalid static access for `F.x`;
      // but `F.m()` and `F.m<T>` use members of `Type`, see
      // [_functionTypeAliasValue].
      if (element is TypeAliasElement && element.aliasedType is FunctionType) {
        return StaticQualifierImpl(importPrefix: importPrefix, name: name)
          ..element = element
          ..scopeLookupResult = lookup;
      }
    }
    // A value: either no selector follows, or the name is not a qualifier.
    return _buildNameExpression(
      importPrefix: importPrefix,
      name: name,
      lookup: lookup,
    );
  }

  /// Returns `F` as a value if [receiver] is a static qualifier `F` naming a
  /// function-type alias, otherwise `null`.
  ///
  /// `F.m()` and `F.m<T>` use the members of `Type`, while the read `F.m`
  /// keeps the qualifier, to report the invalid static access.
  static ExpressionImpl? _functionTypeAliasValue(NamedReceiverImpl receiver) {
    if (receiver case StaticQualifierImpl(
      element: TypeAliasElement(aliasedType: FunctionType()),
    )) {
      return _buildNameExpression(
        importPrefix: receiver.importPrefix,
        name: receiver.name,
        lookup: receiver.scopeLookupResult!,
      );
    }
    return null;
  }

  /// Puts the [extensionOverride] built for [node], the call `E(x)` of an
  /// extension, into the tree, and returns the node to visit.
  ///
  /// An extension override is not an expression, so it replaces [node] only
  /// where [node] is the receiver of a member access, as in `E(x).m()` or
  /// `E(x) + 1`. In an assignment target, as in `E(x) = v`, it replaces the
  /// invalid target. Anywhere else, as in `var v = E(x);`, it is wrapped in an
  /// invalid expression.
  static InstanceReceiverImpl _replaceWithExtensionOverride(
    ExpressionImpl node,
    ExtensionOverride2Impl extensionOverride,
  ) {
    var parent = node.parent2;
    if (parent is InvalidExpressionAssignmentTargetImpl) {
      parent.replaceWith(
        InvalidExtensionOverrideAssignmentTargetImpl(
          extensionOverride: extensionOverride,
        ),
      );
      return extensionOverride;
    }
    var isReceiver = switch (parent) {
      ParsedNameAccessImpl(:var operand) => identical(operand, node),
      ReceiverPropertyExtractionImpl(:var receiver) => identical(
        receiver,
        node,
      ),
      ReceiverPropertyAssignmentTargetImpl(:var receiver) => identical(
        receiver,
        node,
      ),
      ReceiverMethodInvocationImpl(:var receiver) => identical(receiver, node),
      ReceiverIndexExpressionImpl(:var receiver) => identical(receiver, node),
      ReceiverIndexAssignmentTargetImpl(:var receiver) => identical(
        receiver,
        node,
      ),
      CallInvocationImpl(:var receiver) => identical(receiver, node),
      BinaryOperatorInvocationImpl(:var leftOperand) => identical(
        leftOperand,
        node,
      ),
      UnaryOperatorInvocationImpl(:var operand) => identical(operand, node),
      _ => false,
    };
    InstanceReceiverImpl replacement = isReceiver
        ? extensionOverride
        : InvalidExtensionOverrideExpressionImpl(
            extensionOverride: extensionOverride,
          );
    node.replaceWith(replacement);
    return replacement;
  }

  /// We always build local elements for [LocalVariablesDeclaration]s and
  /// [LocalFunctionDeclaration]s in blocks, because invalid code might try
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

class _PatternVariableBinderVisitor extends ThrowingAstVisitor2<void> {
  final VariableBinder<DartPatternImpl, PatternVariableElementImpl> _binder;

  new(this._binder);

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {}

  @override
  void visitCastPattern(CastPattern node) {
    node.pattern.accept2(this);
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
    node.elements.accept2(this);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    node.leftOperand.accept2(this);
    node.rightOperand.accept2(this);
  }

  @override
  void visitLogicalOrPattern(covariant LogicalOrPatternImpl node) {
    _binder.logicalOrPatternStart();
    node.leftOperand.accept2(this);
    _binder.logicalOrPatternFinishLeft();
    node.rightOperand.accept2(this);
    _binder.logicalOrPatternFinish(node);
  }

  @override
  void visitMapPattern(MapPattern node) {
    node.elements.accept2(this);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    node.value.accept2(this);
  }

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    node.pattern.accept2(this);
  }

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    node.pattern.accept2(this);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    node.fields.accept2(this);
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    node.pattern.accept2(this);
  }

  @override
  void visitPatternField(PatternField node) {
    node.pattern.accept2(this);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    node.fields.accept2(this);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {}

  @override
  void visitRestPatternElement(RestPatternElement node) {
    node.pattern?.accept2(this);
  }

  @override
  void visitWildcardPattern(WildcardPattern node) {}
}

class _VariableBinder
    extends VariableBinder<DartPatternImpl, PatternVariableElementImpl> {
  final TypeProvider typeProvider;

  new({required super.errors, required this.typeProvider});

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
  final ScopeAnalyzer scopeAnalyzer;

  new(this.scopeAnalyzer);

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
    scopeAnalyzer._diagnosticReporter.report(
      DiagnosticFactory().duplicateDefinitionForNodes(
        scopeAnalyzer._diagnosticReporter.source,
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
    scopeAnalyzer._diagnosticReporter.report(
      diag.missingVariablePattern
          .withArguments(name: name)
          .at(hasInLeft ? node.rightOperand : node.leftOperand),
    );
  }
}

extension on Element? {
  /// Whether a name resolved to this element denotes a type, so that the
  /// name alone is a type literal.
  bool get isTypeDefining {
    return switch (this) {
      DynamicElementImpl() ||
      InterfaceElementImpl() ||
      NeverElementImpl() ||
      TypeAliasElementImpl() ||
      TypeParameterElementImpl() => true,
      _ => false,
    };
  }

  /// This element if it is an interface (a class, enum, mixin, or extension
  /// type), or the interface aliased by this type alias; otherwise `null`.
  InterfaceElement? get unaliasedInterface {
    return switch (this) {
      InterfaceElement element => element,
      TypeAliasElement(aliasedType: InterfaceType(:var element)) => element,
      _ => null,
    };
  }
}

extension _LocalVariablesDeclaration on LocalVariablesDeclarationImpl {
  List<LocalVariableElementImpl> get declaredElements {
    return [for (var variable in variables) variable.declaredFragment!.element];
  }
}
