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

class ResolutionVisitor extends RecursiveAstVisitor<void> {
  final LibraryElementImpl _libraryElement;
  final TypeProviderImpl _typeProvider;
  final LibraryFragmentImpl _libraryFragment;
  final DiagnosticReporter _diagnosticReporter;
  final AstRewriter _astRewriter;
  final NamedTypeResolver _namedTypeResolver;
  final RecordTypeAnnotationResolver _recordTypeResolver;

  /// The enclosing instance element, or `null` if not in an instance element.
  InstanceElement? _enclosingInstanceElement;

  /// Data structure for tracking declared pattern variables.
  late final _VariableBinder _patternVariables = _VariableBinder(
    errors: _VariableBinderErrors(this),
    typeProvider: _typeProvider,
  );

  /// The set of required operations on types.
  final TypeSystemOperations typeSystemOperations;

  final TypeConstraintGenerationDataForTesting? dataForTesting;

  final ScopeContext _scopeContext;
  LabelScope? _labelScope;
  int _libraryDirectiveIndex = 0;

  factory ResolutionVisitor({
    required LibraryFragmentImpl libraryFragment,
    required DiagnosticListener diagnosticListener,
    required Scope nameScope,
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

    var namedTypeResolver = NamedTypeResolver(
      libraryElement,
      libraryFragment,
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
      nameScope,
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
    Scope nameScope,
    this.typeSystemOperations,
    this.dataForTesting,
  ) : _scopeContext = ScopeContext(
        libraryFragment: _libraryFragment,
        nameScope: nameScope,
      );

  // TODO(scheglov): Remove this temporary routing getter.
  Scope get _nameScope => _scopeContext.nameScope;

  /// Set information about enclosing declarations.
  void prepareEnclosingDeclarations({
    InterfaceElementImpl? enclosingClassElement,
  }) {
    _namedTypeResolver.enclosingClass = enclosingClassElement;
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    super.visitAnnotation(node);
  }

  @override
  void visitAssignedVariablePattern(
    covariant AssignedVariablePatternImpl node,
  ) {
    var name = node.name.lexeme;
    var element = _nameScope.lookup(name).getter;
    node.element = element;

    if (element == null) {
      // Recovery: the code might try to refer to an instance field.
      if (_enclosingInstanceElement
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
  void visitBlock(Block node) {
    withLocalScope(() {
      var statements = node.statements;
      _buildLocalElements(statements);
      statements.accept(this);
    });
  }

  @override
  void visitCatchClause(covariant CatchClauseImpl node) {
    var exceptionTypeNode = node.exceptionType;
    exceptionTypeNode?.accept(this);

    withLocalScope(() {
      var exceptionNode = node.exceptionParameter;
      if (exceptionNode != null) {
        var fragment = exceptionNode.declaredFragment!;
        _define(fragment.element);

        if (exceptionTypeNode == null) {
          fragment.element.type = _typeProvider.objectType;
        } else {
          fragment.element.type = exceptionTypeNode.typeOrThrow;
        }
      }

      var stackTraceNode = node.stackTraceParameter;
      if (stackTraceNode != null) {
        var fragment = stackTraceNode.declaredFragment!;
        _define(fragment.element);

        fragment.element.type = _typeProvider.stackTraceType;
      }

      node.body.accept(this);
    });
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    node.metadata.accept(this);

    _withTypeParameterScope(node.namePart.typeParameters, () {
      node.namePart.accept(this);

      var extendsClause = node.extendsClause;
      var withClause = node.withClause;

      if (extendsClause != null) {
        _resolveType(
          declaration: node,
          clause: extendsClause,
          namedType: extendsClause.superclass,
        );
      }

      _resolveWithClause(declaration: node, clause: withClause);
      _resolveImplementsClause(
        declaration: node,
        clause: node.implementsClause,
      );

      _withEnclosingInstanceElement(element, () {
        withInstanceScope(element, () {
          node.body.accept(this);
        });
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var fragment = node.declaredFragment!;
    _namedTypeResolver.enclosingClass = fragment.element;

    node.metadata.accept(this);

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);

      _resolveType(declaration: node, clause: null, namedType: node.superclass);

      _resolveWithClause(declaration: node, clause: node.withClause);
      _resolveImplementsClause(
        declaration: node,
        clause: node.implementsClause,
      );
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var fragment = node.declaredFragment!;

    node.metadata.accept(this);

    node.typeName?.accept(this);

    node.parameters.accept(this);

    withScope(ConstructorInitializerScope(_nameScope, fragment.element), () {
      node.initializers.accept(this);
    });

    node.redirectedConstructor?.accept(this);

    _withFormalParameterScope(fragment.element.formalParameters, () {
      node.body.accept(this);
    });
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

    _patternVariables.add(node.name.lexeme, element);
    _define(element);

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
  void visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    var normalParameter = node.parameter;
    normalParameter.accept(this);

    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      defaultValue.accept(this);
    }
  }

  @override
  void visitEnumConstantDeclaration(
    covariant EnumConstantDeclarationImpl node,
  ) {
    node.metadata.accept(this);

    var arguments = node.arguments;
    if (arguments != null) {
      arguments.accept(this);
    }
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    node.metadata.accept(this);

    _withTypeParameterScope(node.namePart.typeParameters, () {
      node.namePart.accept(this);

      _resolveWithClause(declaration: node, clause: node.withClause);
      _resolveImplementsClause(
        declaration: node,
        clause: node.implementsClause,
      );

      _withEnclosingInstanceElement(element, () {
        withInstanceScope(element, () {
          node.body.accept(this);
        });
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    super.visitExportDirective(node);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    node.metadata.accept(this);

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);
      node.onClause?.accept(this);

      _withEnclosingInstanceElement(element, () {
        withScope(ExtensionScope(_nameScope, element), () {
          node.body.accept(this);
        });
      });
    });
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _namedTypeResolver.enclosingClass = element;
    node.metadata.accept(this);

    _withTypeParameterScope(node.primaryConstructor.typeParameters, () {
      node.primaryConstructor.accept(this);

      _resolveImplementsClause(
        declaration: node,
        clause: node.implementsClause,
      );

      _withEnclosingInstanceElement(element, () {
        withInstanceScope(element, () {
          node.body.accept(this);
        });
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    node.metadata.accept(this);

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      node.type?.accept(this);
    });
  }

  @override
  void visitForEachPartsWithDeclaration(
    covariant ForEachPartsWithDeclarationImpl node,
  ) {
    node.iterable.accept(this);
    node.loopVariable.accept(this);
    var fragment = node.loopVariable.declaredFragment!;
    _define(fragment.element);
  }

  @override
  void visitForEachPartsWithPattern(
    covariant ForEachPartsWithPatternImpl node,
  ) {
    _patternVariables.casePatternStart();
    super.visitForEachPartsWithPattern(node);
    var variablesMap = _patternVariables.casePatternFinish();
    node.variables = variablesMap.values
        .whereType<BindPatternVariableElementImpl>()
        .map((e) => e.firstFragment)
        .toList();
  }

  @override
  void visitForElement(covariant ForElementImpl node) {
    withLocalScope(() {
      super.visitForElement(node);
    });
  }

  @override
  void visitForStatement(covariant ForStatementImpl node) {
    withLocalScope(() {
      super.visitForStatement(node);
    });
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    _withTypeParameterScope(node.functionExpression.typeParameters, () {
      super.visitFunctionDeclaration(node);
    });

    if (node.parent is FunctionDeclarationStatement) {
      fragment.element.returnType =
          node.returnType?.type ?? _typeProvider.dynamicType;
    }
  }

  @override
  void visitFunctionDeclarationStatement(
    covariant FunctionDeclarationStatementImpl node,
  ) {
    if (!_hasLocalElementsBuilt(node)) {
      _defineLocalFunction(node);
    }
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node) {
    var fragment = node.declaredFragment;

    if (fragment is LocalFunctionFragmentImpl) {
      fragment.element.returnType = _typeProvider.dynamicType;
    }

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      if (fragment != null) {
        _withFormalParameterScope(fragment.element.formalParameters, () {
          node.body.accept(this);
        });
      } else {
        node.body.accept(this);
      }
    });
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    node.metadata.accept(this);

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);

      node.returnType?.accept(this);
      node.parameters.accept(this);
    });
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var fragment = node.declaredFragment;
    node.metadata.accept(this);

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);
      node.parameters.accept(this);
      node.returnType?.accept(this);

      if (fragment != null) {
        var returnType = node.returnType?.type ?? _typeProvider.dynamicType;
        var type = FunctionTypeImpl(
          typeParameters: fragment.typeParameters
              .map((f) => f.element)
              .toList(),
          parameters: fragment.formalParameters.map((f) => f.element).toList(),
          returnType: returnType,
          nullabilitySuffix: _getNullability(node.question != null),
        );
        fragment.element.type = type;
      }
    });
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    node as GenericFunctionTypeImpl;
    var fragment = node.declaredFragment!;
    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);
      node.parameters.accept(this);
      node.returnType?.accept(this);
    });

    fragment.returnType = node.returnType?.type ?? _typeProvider.dynamicType;
    var parameters = node.parameters.parameters;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (parameter is SimpleFormalParameterImpl) {
        var element = fragment.formalParameters[i];
        element.element.type =
            parameter.type?.type ?? _typeProvider.dynamicType;
      }
    }

    var type = FunctionTypeImpl(
      typeParameters: fragment.typeParameters.map((f) => f.element).toList(),
      parameters: fragment.formalParameters.map((f) => f.element).toList(),
      returnType: fragment.returnType,
      nullabilitySuffix: _getNullability(node.question != null),
    );
    fragment.type = type;
    node.type = type;
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    node.metadata.accept(this);

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);
      node.type.accept(this);
    });
  }

  @override
  void visitIfElement(covariant IfElementImpl node) {
    _visitIf(node);
  }

  @override
  void visitIfStatement(covariant IfStatementImpl node) {
    _visitIf(node);
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
    super.visitImportDirective(node);
  }

  @override
  void visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    var newNode = _astRewriter.instanceCreationExpression(
      _nameScope,
      node,
      libraryElement: _libraryElement,
      enclosingInstanceElement: _enclosingInstanceElement,
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
    var outerScope = _labelScope;
    try {
      var unlabeled = node.unlabeled;
      for (Label label in node.labels) {
        SimpleIdentifier labelNameNode = label.label;
        _labelScope = LabelScope(
          _labelScope,
          labelNameNode.name,
          unlabeled,
          labelNameNode.element as LabelElement,
        );
      }
      unlabeled.accept(this);
    } finally {
      _labelScope = outerScope;
    }
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
  void visitLogicalAndPattern(covariant LogicalAndPatternImpl node) {
    node.leftOperand.accept(this);
    node.rightOperand.accept(this);
  }

  @override
  void visitLogicalOrPattern(covariant LogicalOrPatternImpl node) {
    _patternVariables.logicalOrPatternStart();
    node.leftOperand.accept(this);
    _patternVariables.logicalOrPatternFinishLeft();
    node.rightOperand.accept(this);
    _patternVariables.logicalOrPatternFinish(node);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var fragment = node.declaredFragment!;

    node.metadata.accept(this);

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      node.returnType?.accept(this);

      _withFormalParameterScope(fragment.element.formalParameters, () {
        node.body.accept(this);
      });
    });
  }

  @override
  void visitMethodInvocation(covariant MethodInvocationImpl node) {
    var newNode = _astRewriter.methodInvocation(_nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    _scopeContext.walkMixinDeclarationScopes(
      node,
      visitor: this,
      visitBody: (body) {
        _withEnclosingInstanceElement(element, () {
          body.accept(this);
        });
      },
    );
  }

  @override
  void visitMixinOnClause(covariant MixinOnClauseImpl node) {
    _resolveMixinOnClause(
      declaration: node.parent as Declaration,
      clause: node,
    );
  }

  @override
  void visitNamedType(covariant NamedTypeImpl node) {
    node.typeArguments?.accept(this);

    _namedTypeResolver.nameScope = _nameScope;
    _namedTypeResolver.resolve(node, dataForTesting: dataForTesting);

    if (_namedTypeResolver.rewriteResult != null) {
      _namedTypeResolver.rewriteResult!.accept(this);
    }
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
  void visitPatternAssignment(PatternAssignment node) {
    // We need to call `casePatternStart` and `casePatternFinish` in case there
    // are any declared variable patterns inside the pattern assignment (this
    // could happen due to error recovery).  But we don't need to keep the
    // variables map that `casePatternFinish` returns.
    _patternVariables.casePatternStart();
    super.visitPatternAssignment(node);
    _patternVariables.casePatternFinish();
  }

  @override
  void visitPatternVariableDeclaration(
    covariant PatternVariableDeclarationImpl node,
  ) {
    _patternVariables.casePatternStart();
    super.visitPatternVariableDeclaration(node);
    var variablesMap = _patternVariables.casePatternFinish();
    node.elements = variablesMap.values
        .whereType<BindPatternVariableElementImpl>()
        .toList();
  }

  @override
  void visitPrefixedIdentifier(covariant PrefixedIdentifierImpl node) {
    var newNode = _astRewriter.prefixedIdentifier(_nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrimaryConstructorBody(covariant PrimaryConstructorBodyImpl node) {
    if (node.declaration case var declaration?) {
      var fragment = declaration.declaredFragment!;
      var element = fragment.element;
      node.visitChildrenWithHooks(
        this,
        visitInitializers: (initializers) {
          withScope(ConstructorInitializerScope(_nameScope, element), () {
            initializers.accept(this);
          });
        },
        visitBody: (body) {
          withScope(PrimaryParameterScope(_nameScope, element), () {
            body.accept(this);
          });
        },
      );
    } else {
      super.visitPrimaryConstructorBody(node);
    }
  }

  @override
  void visitPrimaryConstructorDeclaration(
    covariant PrimaryConstructorDeclarationImpl node,
  ) {
    node.typeParameters?.accept(this);
    node.formalParameters.accept(this);
  }

  @override
  void visitPropertyAccess(covariant PropertyAccessImpl node) {
    var newNode = _astRewriter.propertyAccess(_nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitRecordTypeAnnotation(covariant RecordTypeAnnotationImpl node) {
    node.visitChildren(this);
    _recordTypeResolver.resolve(node);
  }

  @override
  void visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    var fragment = node.declaredFragment;
    node.type?.accept(this);
    if (fragment != null) {
      if (node.type != null) {
        fragment.element.type = node.type!.type ?? _typeProvider.dynamicType;
      } else if (fragment.element.type is InvalidTypeImpl) {
        // TODO(scheglov): review and improve resolution to not rely on dynamic.
        fragment.element.type = _typeProvider.dynamicType;
      }
    }
    node.metadata.accept(this);
  }

  @override
  void visitSimpleIdentifier(covariant SimpleIdentifierImpl node) {
    var newNode = _astRewriter.simpleIdentifier(_nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    node.metadata.accept(this);

    _withTypeParameterScope(node.typeParameters, () {
      node.typeParameters?.accept(this);
      node.type?.accept(this);
      node.parameters?.accept(this);
    });
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
      group.variables = _patternVariables.switchStatementSharedCaseScopeFinish(
        group,
      );
      withLocalScope(() {
        var statements = group.statements;
        _buildLocalElements(statements);
        statements.accept(this);
      });
    }
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
    var initializerNode = node.initializer;
    if (initializerNode != null) {
      initializerNode.accept(this);
    }
  }

  @override
  void visitVariableDeclarationList(
    covariant VariableDeclarationListImpl node,
  ) {
    var parent = node.parent;
    if (parent is ForPartsWithDeclarations ||
        parent is VariableDeclarationStatement &&
            !_hasLocalElementsBuilt(parent)) {
      _defineLocalVariables(node);
    }

    node.visitChildren(this);

    var variables = node.variables;
    for (var i = 0; i < variables.length; i++) {
      var variable = variables[i];
      var fragment = variable.declaredFragment!;

      var offset = (i == 0 ? node.parent! : variable).offset;
      var length = variable.end - offset;
      fragment.setCodeRange(offset, length);

      if (node.type != null) {
        fragment.element.type = node.type!.typeOrThrow;
      } else if (fragment is LocalVariableFragmentImpl) {
        // TODO(scheglov): review and improve resolution to not rely on dynamic.
        fragment.element.type = _typeProvider.dynamicType;
      }
    }
  }

  // TODO(scheglov): Remove this temporary routing method.
  void withInstanceScope(InstanceElementImpl element, void Function() f) {
    _scopeContext.withInstanceScope(element, f);
  }

  // TODO(scheglov): Remove this temporary routing method.
  void withLocalScope(void Function() f) {
    _scopeContext.withLocalScope(f);
  }

  // TODO(scheglov): Remove this temporary routing method.
  void withScope(Scope scope, void Function() f) {
    _scopeContext.withScope(scope, f);
  }

  // TODO(scheglov): Remove this temporary routing method.
  void withTypeParameterScope(
    List<TypeParameterElementImpl> elements,
    void Function() f,
  ) {
    _scopeContext.withTypeParameterScope(elements, f);
  }

  /// Ensure that each type parameter from the [typeParameterList] has its
  /// fragment set.
  ///
  /// Returns the corresponding elements in declaration order.
  List<TypeParameterElement> _bindTypeParameterElements(
    TypeParameterListImpl? typeParameterList,
  ) {
    if (typeParameterList == null) return const [];

    var elements = <TypeParameterElement>[];

    for (var typeParameter in typeParameterList.typeParameters) {
      var fragment = typeParameter.declaredFragment;
      if (fragment != null) {
        elements.add(fragment.element);
      }
    }

    return elements;
  }

  void _buildLocalElements(List<Statement> statements) {
    for (var statement in statements) {
      if (statement is FunctionDeclarationStatementImpl) {
        _defineLocalFunction(statement);
      } else if (statement is VariableDeclarationStatement) {
        _defineLocalVariables(statement.variables);
      }
    }
  }

  void _define(Element element) {
    if (_nameScope case LocalScope nameScope) {
      nameScope.add(element);
    }
  }

  void _defineLocalFunction(FunctionDeclarationStatementImpl statement) {
    var fragment = statement.functionDeclaration.declaredFragment;
    if (fragment != null && !_isWildCardVariable(fragment.name)) {
      _define(fragment.element);
    }
  }

  void _defineLocalVariables(VariableDeclarationList variables) {
    for (var variable in variables.variables) {
      var fragment = variable.declaredFragment;
      if (fragment != null) {
        _define(fragment.element);
      }
    }
  }

  NullabilitySuffix _getNullability(bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else {
      return NullabilitySuffix.none;
    }
  }

  bool _isWildCardVariable(String? name) =>
      name == '_' &&
      _libraryElement.featureSet.isEnabled(Feature.wildcard_variables);

  void _resolveGuardedPattern(
    GuardedPatternImpl guardedPattern, {
    Object? sharedCaseScopeKey,
    void Function()? then,
  }) {
    _patternVariables.casePatternStart();
    guardedPattern.pattern.accept(this);
    var variables = _patternVariables.casePatternFinish(
      sharedCaseScopeKey: sharedCaseScopeKey,
    );
    // Matched variables are available in `whenClause`.
    withLocalScope(() {
      for (var variable in variables.values) {
        _define(variable);
      }
      guardedPattern.variables = variables;
      guardedPattern.whenClause?.accept(this);
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

  void _visitIf(IfElementOrStatementImpl node) {
    var caseClause = node.caseClause;
    if (caseClause != null) {
      node.expression.accept(this);
      _resolveGuardedPattern(
        caseClause.guardedPattern,
        then: () {
          node.ifTrue.accept(this);
        },
      );
      node.ifFalse?.accept(this);
    } else {
      node.visitChildren(this);
    }
  }

  void _withEnclosingInstanceElement(
    InstanceElement element,
    void Function() f,
  ) {
    var previous = _enclosingInstanceElement;
    _enclosingInstanceElement = element;
    try {
      f();
    } finally {
      _enclosingInstanceElement = previous;
    }
  }

  void _withFormalParameterScope(
    List<FormalParameterElement> parameters,
    void Function() f,
  ) {
    withScope(FormalParameterScope(_nameScope, parameters), f);
  }

  void _withTypeParameterScope(
    TypeParameterListImpl? typeParameterList,
    void Function() f,
  ) {
    var elements = _bindTypeParameterElements(typeParameterList);
    withScope(
      TypeParameterScope(
        _nameScope,
        elements,
        featureSet: _libraryElement.featureSet,
      ),
      f,
    );
  }

  /// We always build local elements for [VariableDeclarationStatement]s and
  /// [FunctionDeclarationStatement]s in blocks, because invalid code might try
  /// to use forward references.
  static bool _hasLocalElementsBuilt(Statement node) {
    var parent = node.parent;
    return parent is Block || parent is SwitchMember;
  }

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
