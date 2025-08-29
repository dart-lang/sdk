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
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/ast_rewrite.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/named_type_resolver.dart';
import 'package:analyzer/src/dart/resolver/record_type_annotation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/element_walker.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

class ElementHolder {
  final FragmentImpl _element;
  final List<TypeParameterFragmentImpl> _typeParameters = [];
  final List<FormalParameterFragmentImpl> _formalParameters = [];

  ElementHolder(this._element);

  List<FormalParameterFragmentImpl> get formalParameters {
    return _formalParameters.toFixedList();
  }

  List<TypeParameterFragmentImpl> get typeParameters {
    return _typeParameters.toFixedList();
  }

  void addParameter(FormalParameterFragmentImpl element) {
    _formalParameters.add(element);
  }

  void addTypeParameter(TypeParameterFragmentImpl element) {
    _typeParameters.add(element);
  }

  void enclose(FragmentImpl element) {
    element.enclosingFragment = _element;
  }
}

/// Recursively visit AST and perform following resolution tasks:
///
/// 1. Set existing top-level elements from [_elementWalker] to corresponding
///    nodes in AST.
/// 2. Create and set new elements for local declarations.
/// 3. Resolve all [NamedType]s - set elements and types.
/// 4. Resolve all [GenericFunctionType]s - set their types.
/// 5. Rewrite AST where resolution provides a more accurate understanding.
class ResolutionVisitor extends RecursiveAstVisitor<void> {
  final LibraryElementImpl _libraryElement;
  final TypeProviderImpl _typeProvider;
  final LibraryFragmentImpl _unitElement;
  final DiagnosticReporter _diagnosticReporter;
  final AstRewriter _astRewriter;
  final NamedTypeResolver _namedTypeResolver;
  final RecordTypeAnnotationResolver _recordTypeResolver;

  /// This index is incremented every time we visit a [LibraryDirective].
  /// There is just one [LibraryElement], so we can support only one node.
  int _libraryDirectiveIndex = 0;

  /// The provider of pre-built children elements from the element being
  /// visited. For example when we visit a method, its element is resynthesized
  /// from the summary, and we get resynthesized elements for type parameters
  /// and formal parameters to apply to corresponding AST nodes.
  ElementWalker? _elementWalker;

  /// The scope used to resolve identifiers.
  Scope _nameScope;

  /// The scope used to resolve labels for `break` and `continue` statements,
  /// or `null` if no labels have been defined in the current context.
  LabelScope? _labelScope;

  /// The container to add newly created elements that should be put into the
  /// enclosing element.
  ElementHolder _elementHolder;

  /// Data structure for tracking declared pattern variables.
  late final _VariableBinder _patternVariables = _VariableBinder(
    errors: _VariableBinderErrors(this),
    typeProvider: _typeProvider,
  );

  /// The set of required operations on types.
  final TypeSystemOperations typeSystemOperations;

  final TypeConstraintGenerationDataForTesting? dataForTesting;

  factory ResolutionVisitor({
    required LibraryFragmentImpl unitElement,
    required DiagnosticListener diagnosticListener,
    required Scope nameScope,
    required bool strictInference,
    required bool strictCasts,
    ElementWalker? elementWalker,
    required TypeConstraintGenerationDataForTesting? dataForTesting,
  }) {
    var libraryElement = unitElement.library;
    var typeProvider = libraryElement.typeProvider;
    var unitSource = unitElement.source;
    var diagnosticReporter = DiagnosticReporter(diagnosticListener, unitSource);

    var typeSystemOperations = TypeSystemOperations(
      unitElement.library.typeSystem,
      strictCasts: strictCasts,
    );

    var namedTypeResolver = NamedTypeResolver(
      libraryElement,
      unitElement,
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
      unitElement,
      diagnosticReporter,
      AstRewriter(diagnosticReporter),
      namedTypeResolver,
      recordTypeResolver,
      nameScope,
      elementWalker,
      ElementHolder(unitElement),
      typeSystemOperations,
      dataForTesting,
    );
  }

  ResolutionVisitor._(
    this._libraryElement,
    this._typeProvider,
    this._unitElement,
    this._diagnosticReporter,
    this._astRewriter,
    this._namedTypeResolver,
    this._recordTypeResolver,
    this._nameScope,
    this._elementWalker,
    this._elementHolder,
    this.typeSystemOperations,
    this.dataForTesting,
  );

  TypeImpl get _dynamicType => _typeProvider.dynamicType;

  /// Set information about enclosing declarations.
  void prepareEnclosingDeclarations({
    InterfaceElementImpl? enclosingClassElement,
  }) {
    _namedTypeResolver.enclosingClass = enclosingClassElement;
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    if (_elementWalker == null) {
      ElementAnnotationImpl(_unitElement, node);
    }
    _withElementWalker(null, () {
      super.visitAnnotation(node);
    });
  }

  @override
  void visitAssignedVariablePattern(
    covariant AssignedVariablePatternImpl node,
  ) {
    var name = node.name.lexeme;
    var element = _nameScope.lookup(name).getter;
    node.element = element;

    if (element == null) {
      _diagnosticReporter.atToken(
        node.name,
        CompileTimeErrorCode.undefinedIdentifier,
        arguments: [name],
      );
    } else if (!(element is LocalVariableElement ||
        element is FormalParameterElement)) {
      _diagnosticReporter.atToken(
        node.name,
        CompileTimeErrorCode.patternAssignmentNotLocalVariable,
      );
    }
  }

  @override
  void visitBlock(Block node) {
    var outerScope = _nameScope;
    try {
      _nameScope = LocalScope(_nameScope);

      var statements = node.statements;
      _buildLocalElements(statements);
      statements.accept(this);
    } finally {
      _nameScope = outerScope;
    }
  }

  @override
  void visitCatchClause(covariant CatchClauseImpl node) {
    var exceptionTypeNode = node.exceptionType;
    exceptionTypeNode?.accept(this);

    _withNameScope(() {
      var exceptionNode = node.exceptionParameter;
      if (exceptionNode != null) {
        var fragment = LocalVariableFragmentImpl(
          name: _getFragmentName(exceptionNode.name),
          firstTokenOffset: exceptionNode.offset,
        );
        fragment.nameOffset = exceptionNode.name.offsetIfNotEmpty;
        _elementHolder.enclose(fragment);
        _define(fragment.element);

        exceptionNode.declaredFragment = fragment;

        fragment.isFinal = true;
        if (exceptionTypeNode == null) {
          fragment.hasImplicitType = true;
          fragment.element.type = _typeProvider.objectType;
        } else {
          fragment.element.type = exceptionTypeNode.typeOrThrow;
        }

        fragment.setCodeRange(
          exceptionNode.name.offset,
          exceptionNode.name.length,
        );
      }

      var stackTraceNode = node.stackTraceParameter;
      if (stackTraceNode != null) {
        var fragment = LocalVariableFragmentImpl(
          name: _getFragmentName(stackTraceNode.name),
          firstTokenOffset: stackTraceNode.offset,
        );
        fragment.nameOffset = stackTraceNode.name.offsetIfNotEmpty;
        _elementHolder.enclose(fragment);
        _define(fragment.element);

        stackTraceNode.declaredFragment = fragment;

        fragment.isFinal = true;
        fragment.hasImplicitType = true;
        fragment.element.type = _typeProvider.stackTraceType;

        fragment.setCodeRange(
          stackTraceNode.name.offset,
          stackTraceNode.name.length,
        );
      }

      node.body.accept(this);
    });
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var fragment = _elementWalker!.getClass();
    var element = fragment.element;
    node.declaredFragment = fragment;
    _namedTypeResolver.enclosingClass = element;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forClass(fragment), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

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

        _defineElements(element.getters);
        _defineElements(element.setters);
        _defineElements(element.methods);
        node.members.accept(this);
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    ClassFragmentImpl element = _elementWalker!.getClass();
    node.declaredFragment = element;
    _namedTypeResolver.enclosingClass = element.asElement2;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forClass(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

        _resolveType(
          declaration: node,
          clause: null,
          namedType: node.superclass,
        );

        _resolveWithClause(declaration: node, clause: node.withClause);
        _resolveImplementsClause(
          declaration: node,
          clause: node.implementsClause,
        );
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var fragment = _elementWalker!.getConstructor();
    var element = fragment.element;
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementHolder(ElementHolder(fragment), () {
      _withElementWalker(null, () {
        _withNameScope(() {
          node.returnType.accept(this);

          _withElementWalker(ElementWalker.forExecutable(fragment), () {
            node.parameters.accept(this);
          });
          _defineFormalParameters(element.formalParameters);

          node.redirectedConstructor?.accept(this);
          node.initializers.accept(this);
          node.body.accept(this);
        });
      });
    });
  }

  @override
  void visitDeclaredIdentifier(covariant DeclaredIdentifierImpl node) {
    var nameToken = node.name;
    var fragment = LocalVariableFragmentImpl(
      name: _getFragmentName(nameToken),
      firstTokenOffset: node.offset,
    );
    fragment.nameOffset = nameToken.offsetIfNotEmpty;
    node.declaredFragment = fragment;
    _elementHolder.enclose(fragment);

    _setOrCreateMetadataElements(fragment, node.metadata);

    fragment.isConst = node.isConst;
    fragment.isFinal = node.isFinal;

    if (node.type case var typeNode?) {
      typeNode.accept(this);
      fragment.element.type = typeNode.typeOrThrow;
    } else {
      fragment.hasImplicitType = true;
      fragment.element.type = _dynamicType;
    }

    _setCodeRange(fragment, node);
  }

  @override
  void visitDeclaredVariablePattern(
    covariant DeclaredVariablePatternImpl node,
  ) {
    node.type?.accept(this);

    var name = node.name.lexeme;
    var fragment = BindPatternVariableFragmentImpl(
      node: node,
      name: _getFragmentName(node.name),
      firstTokenOffset: node.offset,
    );
    fragment.nameOffset = node.name.offsetIfNotEmpty;
    _patternVariables.add(name, fragment.element);
    _elementHolder.enclose(fragment);
    _define(fragment.element);
    fragment.hasImplicitType = node.type == null;
    if (node.type case var typeNode?) {
      fragment.element.type = typeNode.typeOrThrow;
    }
    node.declaredFragment = fragment;

    var patternContext = node.patternContext;
    if (patternContext is ForEachPartsWithPatternImpl) {
      fragment.isFinal = patternContext.finalKeyword != null;
    } else if (patternContext is PatternVariableDeclarationImpl) {
      fragment.isFinal = patternContext.finalKeyword != null;
    } else {
      fragment.isFinal = node.finalKeyword != null;
    }
  }

  @override
  void visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    var normalParameter = node.parameter;
    var nameToken = normalParameter.name;

    FormalParameterFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment = _elementWalker!.getParameter();
    } else {
      var name2 = nameToken?.lexeme.nullIfEmpty;
      var nameOffset2 = nameToken?.offset;
      if (node.parameter is FieldFormalParameter) {
        // Only for recovery, this should not happen in valid code.
        fragment = FieldFormalParameterFragmentImpl(
          firstTokenOffset: node.offset,
          parameterKind: node.kind,
          name: name2,
          nameOffset: nameOffset2,
        )..constantInitializer = node.defaultValue;
      } else if (node.parameter is SuperFormalParameter) {
        // Only for recovery, this should not happen in valid code.
        fragment = SuperFormalParameterFragmentImpl(
          firstTokenOffset: node.offset,
          parameterKind: node.kind,
          name: name2,
          nameOffset: nameOffset2,
        )..constantInitializer = node.defaultValue;
      } else {
        fragment = FormalParameterFragmentImpl(
          firstTokenOffset: node.offset,
          parameterKind: node.kind,
          name: name2,
          nameOffset: nameOffset2,
        )..constantInitializer = node.defaultValue;
      }
      _elementHolder.addParameter(fragment);

      _setCodeRange(fragment, node);
      fragment.isConst = node.isConst;
      fragment.isExplicitlyCovariant = node.parameter.covariantKeyword != null;
      fragment.isFinal = node.isFinal;

      if (normalParameter is SimpleFormalParameterImpl &&
          normalParameter.type == null) {
        fragment.hasImplicitType = true;
      }
    }

    normalParameter.declaredFragment = fragment;
    node.declaredFragment = fragment;

    normalParameter.accept(this);

    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      _withElementWalker(null, () {
        _withElementHolder(ElementHolder(fragment), () {
          defaultValue.accept(this);
        });
      });
    }
  }

  @override
  void visitEnumConstantDeclaration(
    covariant EnumConstantDeclarationImpl node,
  ) {
    var element = _elementWalker!.getVariable() as FieldFragmentImpl;
    node.declaredFragment = element;

    _setOrCreateMetadataElements(element, node.metadata);

    var arguments = node.arguments;
    if (arguments != null) {
      _withElementWalker(null, () {
        _withElementHolder(ElementHolder(element), () {
          arguments.accept(this);
        });
      });
    }
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var fragment = _elementWalker!.getEnum();
    var element = fragment.element;
    node.declaredFragment = fragment;
    _namedTypeResolver.enclosingClass = element;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forEnum(fragment), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

        _resolveWithClause(declaration: node, clause: node.withClause);
        _resolveImplementsClause(
          declaration: node,
          clause: node.implementsClause,
        );

        _defineElements(element.getters);
        _defineElements(element.setters);
        _defineElements(element.methods);
        node.constants.accept(this);
        node.members.accept(this);
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var element = node.libraryExport;
    if (element != null) {
      _setElementAnnotations(node.metadata, element.metadata.annotations);
    }

    _withElementWalker(null, () {
      super.visitExportDirective(node);
    });
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var fragment = _elementWalker!.getExtension();
    var element = fragment.element;
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forExtension(fragment), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.onClause?.accept(this);

        _defineElements(element.getters);
        _defineElements(element.setters);
        _defineElements(element.methods);
        node.members.accept(this);
      });
    });
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var fragment = _elementWalker!.getExtensionType();
    var element = fragment.element;
    node.declaredFragment = fragment;
    _namedTypeResolver.enclosingClass = element;

    _setOrCreateMetadataElements(fragment, node.metadata);

    if (identical(element.firstFragment, fragment)) {
      _setOrCreateMetadataElements(
        element.representation.firstFragment,
        node.representation.fieldMetadata,
      );
    }

    _withElementWalker(ElementWalker.forExtensionType(fragment), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

        node.representation.accept(this);
        _resolveImplementsClause(
          declaration: node,
          clause: node.implementsClause,
        );

        _defineElements(element.getters);
        _defineElements(element.setters);
        _defineElements(element.methods);
        node.members.accept(this);
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    FieldFormalParameterFragmentImpl fragment;
    if (node.parent is DefaultFormalParameter) {
      fragment = node.declaredFragment!;
    } else {
      var nameToken = node.name;
      if (_elementWalker != null) {
        fragment =
            _elementWalker!.getParameter() as FieldFormalParameterFragmentImpl;
      } else {
        // Only for recovery, this should not happen in valid code.
        fragment = FieldFormalParameterFragmentImpl(
          firstTokenOffset: node.offset,
          name: nameToken.lexeme.nullIfEmpty,
          nameOffset: nameToken.offset.nullIfNegative,
          parameterKind: node.kind,
        );
        _elementHolder.enclose(fragment);
        fragment.isConst = node.isConst;
        fragment.isExplicitlyCovariant = node.covariantKeyword != null;
        fragment.isFinal = node.isFinal;
        _setCodeRange(fragment, node);
      }
      node.declaredFragment = fragment;
    }

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementHolder(ElementHolder(fragment), () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forParameter(fragment) : null,
        () {
          _withNameScope(() {
            _buildTypeParameterElements(node.typeParameters);
            node.typeParameters?.accept(this);
            node.type?.accept(this);
            if (_elementWalker != null) {
              node.parameters?.accept(this);
            } else {
              // Only for recovery, this should not happen in valid code.
              fragment.element.type = node.type?.type ?? _dynamicType;
              _withElementWalker(null, () {
                node.parameters?.accept(this);
              });
            }
          });
        },
      );
    });
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
        .map((e) => e.asElement)
        .toList();
  }

  @override
  void visitForElement(covariant ForElementImpl node) {
    _withNameScope(() {
      super.visitForElement(node);
    });
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _withNameScope(() {
      super.visitForPartsWithDeclarations(node);
    });
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var expression = node.functionExpression;

    ExecutableFragmentImpl fragment;
    if (_elementWalker != null) {
      if (node.isGetter) {
        fragment = _elementWalker!.getGetter();
      } else if (node.isSetter) {
        fragment = _elementWalker!.getSetter();
      } else {
        fragment = _elementWalker!.getFunction();
      }
      node.declaredFragment = fragment;
      expression.declaredFragment = fragment;
    } else {
      var functionFragment = node.declaredFragment as LocalFunctionFragmentImpl;

      fragment = functionFragment;
      expression.declaredFragment = functionFragment;

      _setCodeRange(fragment, node);
      setElementDocumentationComment(fragment, node);

      var body = node.functionExpression.body;
      if (node.externalKeyword != null || body is NativeFunctionBody) {
        fragment.isExternal = true;
      }

      fragment.isAsynchronous = body.isAsynchronous;
      fragment.isGenerator = body.isGenerator;
      if (node.returnType == null) {
        fragment.hasImplicitReturnType = true;
      }
    }

    _setOrCreateMetadataElements(fragment, node.metadata);

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forExecutable(fragment) : null,
        () {
          _withNameScope(() {
            _buildTypeParameterElements(expression.typeParameters);
            expression.typeParameters?.accept(this);
            if (_elementWalker == null) {
              fragment.typeParameters = holder.typeParameters;
            }

            expression.parameters?.accept(this);
            if (_elementWalker == null) {
              fragment.formalParameters = holder.formalParameters;
            }

            node.returnType?.accept(this);
            if (_elementWalker == null) {
              fragment.element.returnType =
                  node.returnType?.type ?? _dynamicType;
            }

            _defineFormalParameters(fragment.element.formalParameters);
            _withElementWalker(null, () {
              expression.body.accept(this);
            });
          });
        },
      );
    });
  }

  @override
  void visitFunctionDeclarationStatement(
    covariant FunctionDeclarationStatementImpl node,
  ) {
    if (!_hasLocalElementsBuilt(node)) {
      _buildLocalFunctionElement(node);
    }

    node.functionDeclaration.accept(this);
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node) {
    var fragment = LocalFunctionFragmentImpl(
      name: null,
      firstTokenOffset: node.offset,
    );

    _elementHolder.enclose(fragment);
    node.declaredFragment = fragment;

    fragment.hasImplicitReturnType = true;
    fragment.element.returnType = DynamicTypeImpl.instance;

    FunctionBody body = node.body;
    fragment.isAsynchronous = body.isAsynchronous;
    fragment.isGenerator = body.isGenerator;

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        fragment.typeParameters = holder.typeParameters;

        node.parameters!.accept(this);
        fragment.formalParameters = holder.formalParameters;

        _defineFormalParameters(fragment.element.formalParameters);
        node.body.accept(this);
      });
    });

    _setCodeRange(fragment, node);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var fragment = _elementWalker!.getTypedef();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forTypedef(fragment), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.returnType?.accept(this);
        node.parameters.accept(this);
      });
    });
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    FormalParameterFragmentImpl fragment;
    if (node.parent is DefaultFormalParameter) {
      fragment = node.declaredFragment!;
    } else {
      var nameToken = node.name;
      if (_elementWalker != null) {
        fragment = _elementWalker!.getParameter();
      } else {
        fragment = FormalParameterFragmentImpl(
          firstTokenOffset: node.offset,
          name: nameToken.lexeme.nullIfEmpty,
          nameOffset: nameToken.offset.nullIfNegative,
          parameterKind: node.kind,
        );
        _elementHolder.addParameter(fragment);
        fragment.isConst = node.isConst;
        fragment.isExplicitlyCovariant = node.covariantKeyword != null;
        fragment.isFinal = node.isFinal;
        _setCodeRange(fragment, node);
      }
      node.declaredFragment = fragment;
    }

    _setOrCreateMetadataElements(fragment, node.metadata);

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forParameter(fragment) : null,
        () {
          _withNameScope(() {
            _buildTypeParameterElements(node.typeParameters);
            node.typeParameters?.accept(this);
            if (_elementWalker == null) {
              fragment.typeParameters = holder.typeParameters;
            }

            node.parameters.accept(this);
            if (_elementWalker == null) {
              fragment.formalParameters = holder.formalParameters;
            }

            node.returnType?.accept(this);
            if (_elementWalker == null) {
              var type = FunctionTypeImpl(
                typeParameters: fragment.typeParameters
                    .map((f) => f.element)
                    .toList(),
                parameters: fragment.formalParameters
                    .map((f) => f.asElement2)
                    .toList(),
                returnType: node.returnType?.type ?? _dynamicType,
                nullabilitySuffix: _getNullability(node.question != null),
              );
              fragment.element.type = type;
            }
          });
        },
      );
    });
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var fragment = GenericFunctionTypeFragmentImpl(
      firstTokenOffset: node.offset,
    );
    _unitElement.encloseElement(fragment);
    (node as GenericFunctionTypeImpl).declaredFragment = fragment;

    fragment.isNullable = node.question != null;

    _setCodeRange(fragment, node);

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _withElementWalker(null, () {
        _withNameScope(() {
          _buildTypeParameterElements(node.typeParameters);
          node.typeParameters?.accept(this);
          fragment.typeParameters = holder.typeParameters;

          node.parameters.accept(this);
          fragment.formalParameters = holder.formalParameters;

          node.returnType?.accept(this);
          fragment.returnType = node.returnType?.type ?? _dynamicType;
        });
      });
    });

    var type = FunctionTypeImpl(
      typeParameters: fragment.typeParameters.map((f) => f.asElement2).toList(),
      parameters: fragment.formalParameters.map((f) => f.asElement2).toList(),
      returnType: fragment.returnType,
      nullabilitySuffix: _getNullability(node.question != null),
    );
    fragment.type = type;
    node.type = type;
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var fragment = _elementWalker!.getTypedef();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forGenericTypeAlias(fragment), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.type.accept(this);
      });
    });
  }

  @override
  void visitIfElement(covariant IfElementImpl node) {
    _withNameScope(() {
      _visitIf(node);
    });
  }

  @override
  void visitIfStatement(covariant IfStatementImpl node) {
    _visitIf(node);
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var element = node.libraryImport;
    if (element != null) {
      _setElementAnnotations(node.metadata, element.metadata.annotations);
    }

    _withElementWalker(null, () {
      super.visitImportDirective(node);
    });
  }

  @override
  void visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    var newNode = _astRewriter.instanceCreationExpression(_nameScope, node);
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
        _diagnosticReporter.atNode(
          node,
          WarningCode.sdkVersionConstructorTearoffs,
        );
      }
      return newNode.accept(this);
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _buildLabelElements(node.labels, false);

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

    _withElementWalker(null, () {
      super.visitLibraryDirective(node);
    });
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
    ExecutableFragmentImpl fragment;
    if (node.isGetter) {
      fragment = _elementWalker!.getGetter();
    } else if (node.isSetter) {
      fragment = _elementWalker!.getSetter();
    } else {
      fragment = _elementWalker!.getFunction();
      assert(() {
        if (node.name.lexeme != fragment.name) {
          throw StateError(
            'Method name mismatch:'
            '\nNode: |$node|\nFragment: |$fragment|',
          );
        }
        return true;
      }());
    }
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forExecutable(fragment), () {
      node.metadata.accept(this);
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.parameters?.accept(this);
        node.returnType?.accept(this);

        _withElementWalker(null, () {
          _withElementHolder(ElementHolder(fragment), () {
            _defineFormalParameters(fragment.element.formalParameters);
            node.body.accept(this);
          });
        });
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
    var fragment = _elementWalker!.getMixin();
    var element = fragment.element;
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forMixin(fragment), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

        _resolveOnClause(declaration: node, clause: node.onClause);
        _resolveImplementsClause(
          declaration: node,
          clause: node.implementsClause,
        );

        _defineElements(element.getters);
        _defineElements(element.setters);
        _defineElements(element.methods);
        node.members.accept(this);
      });
    });
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

    _withElementWalker(null, () {
      super.visitPartDirective(node);
    });
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _withElementWalker(null, () {
      super.visitPartOfDirective(node);
    });
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
  void visitPropertyAccess(covariant PropertyAccessImpl node) {
    var newNode = _astRewriter.propertyAccess(_nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitRecordTypeAnnotation(covariant RecordTypeAnnotationImpl node) {
    _withElementWalker(null, () {
      node.visitChildren(this);
    });

    _recordTypeResolver.resolve(node);
  }

  @override
  void visitRepresentationDeclaration(
    covariant RepresentationDeclarationImpl node,
  ) {
    node.fieldFragment = _elementWalker!.getVariable() as FieldFragmentImpl;
    node.constructorFragment = _elementWalker!.getConstructor();

    super.visitRepresentationDeclaration(node);
  }

  @override
  void visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    FormalParameterFragmentImpl fragment;
    if (node.parent is DefaultFormalParameter) {
      fragment = node.declaredFragment!;
    } else {
      var nameToken = node.name;
      if (_elementWalker != null) {
        fragment = _elementWalker!.getParameter();
      } else {
        if (nameToken != null) {
          fragment = FormalParameterFragmentImpl(
            firstTokenOffset: node.offset,
            name: nameToken.lexeme.nullIfEmpty,
            nameOffset: nameToken.offset.nullIfNegative,
            parameterKind: node.kind,
          );
        } else {
          fragment = FormalParameterFragmentImpl(
            firstTokenOffset: node.offset,
            name: null,
            nameOffset: null,
            parameterKind: node.kind,
          );
        }
        _elementHolder.addParameter(fragment);

        _setCodeRange(fragment, node);
        fragment.isConst = node.isConst;
        fragment.isExplicitlyCovariant = node.covariantKeyword != null;
        fragment.isFinal = node.isFinal;
        if (node.type == null) {
          fragment.hasImplicitType = true;
        }
        node.declaredFragment = fragment;
      }
      node.declaredFragment = fragment;
    }

    node.type?.accept(this);
    if (_elementWalker == null) {
      fragment.element.type = node.type?.type ?? _dynamicType;
    }

    _setOrCreateMetadataElements(fragment, node.metadata);
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
    SuperFormalParameterFragmentImpl element;
    if (node.parent is DefaultFormalParameter) {
      element = node.declaredFragment as SuperFormalParameterFragmentImpl;
    } else {
      var nameToken = node.name;
      if (_elementWalker != null) {
        element =
            _elementWalker!.getParameter() as SuperFormalParameterFragmentImpl;
      } else {
        // Only for recovery, this should not happen in valid code.
        element = SuperFormalParameterFragmentImpl(
          firstTokenOffset: node.offset,
          name: nameToken.lexeme.nullIfEmpty,
          nameOffset: nameToken.offset.nullIfNegative,
          parameterKind: node.kind,
        );
        _elementHolder.enclose(element);
        element.isConst = node.isConst;
        element.isExplicitlyCovariant = node.covariantKeyword != null;
        element.isFinal = node.isFinal;
        _setCodeRange(element, node);
      }
      node.declaredFragment = element;
    }

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementHolder(ElementHolder(element), () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forParameter(element) : null,
        () {
          _withNameScope(() {
            _buildTypeParameterElements(node.typeParameters);
            node.typeParameters?.accept(this);
            node.type?.accept(this);
            if (_elementWalker != null) {
              node.parameters?.accept(this);
            } else {
              // Only for recovery, this should not happen in valid code.
              element.element.type = node.type?.type ?? _dynamicType;
              _withElementWalker(null, () {
                node.parameters?.accept(this);
              });
            }
          });
        },
      );
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
      _withNameScope(() {
        _resolveGuardedPattern(
          case_.guardedPattern,
          then: () {
            case_.expression.accept(this);
          },
        );
      });
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
        _buildLabelElements(member.labels, true);
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
      _withNameScope(() {
        var statements = group.statements;
        _buildLocalElements(statements);
        statements.accept(this);
      });
    }
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var fragment = node.declaredFragment!;

    _setOrCreateMetadataElements(fragment, node.metadata);

    var boundNode = node.bound;
    if (boundNode != null) {
      boundNode.accept(this);
      if (_elementWalker == null) {
        fragment.element.bound = boundNode.type;
      }
    }
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    var initializerNode = node.initializer;

    VariableFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment = _elementWalker!.getVariable();
      node.declaredFragment = fragment;
    } else {
      var localFragment = node.declaredFragment as LocalVariableFragmentImpl;
      fragment = localFragment;

      var varList = node.parent as VariableDeclarationListImpl;
      localFragment.hasInitializer = initializerNode != null;
      if (varList.type case var typeNode?) {
        var type = typeNode.typeOrThrow;
        localFragment.element.type = type;
      } else {
        localFragment.hasImplicitType = true;
        localFragment.element.type = _dynamicType;
      }
    }

    if (initializerNode != null) {
      _withElementWalker(null, () {
        _withElementHolder(ElementHolder(fragment), () {
          initializerNode.accept(this);
        });
      });
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
      _buildLocalVariableElements(node);
    }

    node.visitChildren(this);

    NodeList<AnnotationImpl> annotations;
    if (parent is FieldDeclarationImpl) {
      annotations = parent.metadata;
    } else if (parent is TopLevelVariableDeclarationImpl) {
      annotations = parent.metadata;
    } else {
      // Local variable declaration
      annotations = node.metadata;
    }

    var variables = node.variables;
    for (var i = 0; i < variables.length; i++) {
      var variable = variables[i];
      var element = variable.declaredFragment!;
      _setOrCreateMetadataElements(element, annotations, visitNodes: false);

      var offset = (i == 0 ? node.parent! : variable).offset;
      var length = variable.end - offset;
      element.setCodeRange(offset, length);
    }
  }

  /// Builds the label elements associated with [labels] and stores them in the
  /// element holder.
  void _buildLabelElements(List<Label> labels, bool onSwitchMember) {
    for (var label in labels) {
      label as LabelImpl;
      var labelName = label.label;
      var element = LabelFragmentImpl(
        name: labelName.name,
        firstTokenOffset: label.offset,
        onSwitchMember: onSwitchMember,
      );
      labelName.element = element.asElement2;
      _elementHolder.enclose(element);
    }
  }

  void _buildLocalElements(List<Statement> statements) {
    for (var statement in statements) {
      if (statement is FunctionDeclarationStatementImpl) {
        _buildLocalFunctionElement(statement);
      } else if (statement is VariableDeclarationStatement) {
        _buildLocalVariableElements(statement.variables);
      }
    }
  }

  void _buildLocalFunctionElement(
    covariant FunctionDeclarationStatementImpl statement,
  ) {
    var node = statement.functionDeclaration;
    var nameToken = node.name;

    var fragment = LocalFunctionFragmentImpl(
      name: nameToken.nameIfNotEmpty,
      firstTokenOffset: node.offset,
    );
    fragment.nameOffset = nameToken.offsetIfNotEmpty;
    node.declaredFragment = fragment;
    node.functionExpression.declaredFragment = fragment;

    // The fragment's old enclosing element needs to be set before we can get
    // the new element for it.
    _elementHolder.enclose(fragment);

    if (!_isWildCardVariable(nameToken.lexeme)) {
      _define(fragment.element);
    }
  }

  void _buildLocalVariableElements(VariableDeclarationList variableList) {
    var isConst = variableList.isConst;
    var isFinal = variableList.isFinal;
    var isLate = variableList.isLate;
    for (var variable in variableList.variables) {
      variable as VariableDeclarationImpl;
      var nameToken = variable.name;

      var fragment = LocalVariableFragmentImpl(
        name: _getFragmentName(nameToken),
        firstTokenOffset: variable.offset,
      );
      fragment.nameOffset = nameToken.offsetIfNotEmpty;
      variable.declaredFragment = fragment;
      _elementHolder.enclose(fragment);
      _define(fragment.element);

      fragment.isConst = isConst;
      fragment.isFinal = isFinal;
      fragment.isLate = isLate;
    }
  }

  /// Ensure that each type parameters from the [typeParameterList] has its
  /// element set, either from the [_elementWalker] or new, and define these
  /// elements in the [_nameScope].
  void _buildTypeParameterElements(TypeParameterList? typeParameterList) {
    if (typeParameterList == null) return;

    for (var typeParameter in typeParameterList.typeParameters) {
      typeParameter as TypeParameterImpl;
      var name = typeParameter.name;

      TypeParameterFragmentImpl fragment;
      if (_elementWalker != null) {
        fragment = _elementWalker!.getTypeParameter();
      } else {
        fragment = TypeParameterFragmentImpl(
          name: name.lexeme,
          firstTokenOffset: typeParameter.offset,
        );
        fragment.nameOffset = name.offset;
        _elementHolder.addTypeParameter(fragment);

        _setCodeRange(fragment, typeParameter);
      }
      typeParameter.declaredFragment = fragment;

      if (!_isWildCardVariable(fragment.name)) {
        _define(fragment.element);
      }

      _setOrCreateMetadataElements(fragment, typeParameter.metadata);
    }
  }

  void _define(Element element) {
    if (_nameScope case LocalScope nameScope) {
      nameScope.add(element);
    }
  }

  /// Define given [elements] in the [_nameScope].
  void _defineElements(List<Element> elements) {
    int length = elements.length;
    for (int i = 0; i < length; i++) {
      var element = elements[i];
      _define(element);
    }
  }

  /// Define given [parameters] in the [_nameScope].
  void _defineFormalParameters(List<FormalParameterElement> parameters) {
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      var formalParameter = parameters[i];
      if (!formalParameter.isInitializingFormal) {
        _define(formalParameter);
      }
    }
  }

  String? _getFragmentName(Token? nameToken) {
    if (nameToken == null || nameToken.isSynthetic) {
      return null;
    }
    return nameToken.lexeme;
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
    _withNameScope(() {
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

  void _resolveOnClause({
    required Declaration? declaration,
    required MixinOnClauseImpl? clause,
  }) {
    if (clause == null) return;

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
      _verifyExtensionElementImplements(
        enclosingElement.asElement,
        namedType,
        type,
      );
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

    if (_unitElement.shouldIgnoreUndefinedNamedType(namedType)) {
      return;
    }

    DiagnosticCode? diagnosticCode;
    switch (clause) {
      case null:
        if (declaration is ClassTypeAlias) {
          diagnosticCode = CompileTimeErrorCode.mixinWithNonClassSuperclass;
        }
      case ExtendsClause():
        if (declaration is ClassDeclaration) {
          diagnosticCode = declaration.withClause == null
              ? CompileTimeErrorCode.extendsNonClass
              : CompileTimeErrorCode.mixinWithNonClassSuperclass;
        }
      case ImplementsClause():
        diagnosticCode = CompileTimeErrorCode.implementsNonClass;
      case MixinOnClause():
        diagnosticCode =
            CompileTimeErrorCode.mixinSuperClassConstraintNonInterface;
      case WithClause():
        diagnosticCode = CompileTimeErrorCode.mixinOfNonClass;
    }

    // Should not happen.
    if (diagnosticCode == null) {
      assert(false);
      return;
    }

    var firstToken = namedType.importPrefix?.name ?? namedType.name;
    var offset = firstToken.offset;
    var length = namedType.name.end - offset;
    _diagnosticReporter.atOffset(
      offset: offset,
      length: length,
      diagnosticCode: diagnosticCode,
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

  void _setCodeRange(FragmentImpl element, AstNode node) {
    element.setCodeRange(node.offset, node.length);
  }

  void _setOrCreateMetadataElements(
    FragmentImpl element,
    NodeList<AnnotationImpl> annotations, {
    bool visitNodes = true,
  }) {
    if (visitNodes) {
      annotations.accept(this);
    }
    if (_elementWalker != null) {
      _setElementAnnotations(annotations, element.metadata.annotations);
    } else if (annotations.isNotEmpty) {
      element.metadata = MetadataImpl(
        annotations.map((annotation) {
          return annotation.elementAnnotation!;
        }).toList(),
      );
    }
  }

  void _verifyExtensionElementImplements(
    ExtensionTypeFragmentImpl declaredFragment,
    NamedTypeImpl node,
    TypeImpl type,
  ) {
    var typeSystem = _libraryElement.typeSystem;

    if (!typeSystem.isValidExtensionTypeSuperinterface(type)) {
      _diagnosticReporter.atNode(
        node,
        CompileTimeErrorCode.extensionTypeImplementsDisallowedType,
        arguments: [type],
      );
      return;
    }

    var declaredElement = declaredFragment.element;
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
          _diagnosticReporter.atNode(
            node,
            CompileTimeErrorCode
                .extensionTypeImplementsRepresentationNotSupertype,
            arguments: [
              implementedRepresentation,
              type.element.name ?? '',
              declaredRepresentation,
              declaredFragment.name ?? '',
            ],
          );
        }
        return;
      }
    }

    _diagnosticReporter.atNode(
      node,
      CompileTimeErrorCode.extensionTypeImplementsNotSupertype,
      arguments: [type, declaredRepresentation],
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

  /// Make the given [holder] be the current one while running [f].
  void _withElementHolder(ElementHolder holder, void Function() f) {
    var previousHolder = _elementHolder;
    _elementHolder = holder;
    try {
      f();
    } finally {
      _elementHolder = previousHolder;
    }
  }

  /// Make the given [walker] be the current one while running [f].
  void _withElementWalker(ElementWalker? walker, void Function() f) {
    var current = _elementWalker;
    try {
      _elementWalker = walker;
      f();
    } finally {
      _elementWalker = current;
    }
  }

  /// Run [f] with the new name scope.
  void _withNameScope(void Function() f) {
    var current = _nameScope;
    try {
      _nameScope = LocalScope(current);
      f();
    } finally {
      _nameScope = current;
    }
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
      variables: expandedVariables.map((e) => e.asElement).toList(),
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
    visitor._diagnosticReporter.reportError(
      DiagnosticFactory().duplicateDefinitionForNodes(
        visitor._diagnosticReporter.source,
        CompileTimeErrorCode.duplicateVariablePattern,
        duplicate.node.name,
        original.node.name,
        [name],
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
    visitor._diagnosticReporter.atNode(
      hasInLeft ? node.rightOperand : node.leftOperand,
      CompileTimeErrorCode.missingVariablePattern,
      arguments: [name],
    );
  }
}

extension on Token {
  String? get nameIfNotEmpty {
    return lexeme.isNotEmpty ? lexeme : null;
  }

  int? get offsetIfNotEmpty {
    return lexeme.isNotEmpty ? offset : null;
  }
}
