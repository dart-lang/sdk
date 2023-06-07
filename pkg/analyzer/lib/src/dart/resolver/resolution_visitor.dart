// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/variable_bindings.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/ast_rewrite.dart';
import 'package:analyzer/src/dart/resolver/named_type_resolver.dart';
import 'package:analyzer/src/dart/resolver/record_type_annotation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/element_walker.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ElementHolder {
  final ElementImpl _element;
  final List<TypeParameterElementImpl> _typeParameters = [];
  final List<ParameterElementImpl> _parameters = [];

  ElementHolder(this._element);

  List<ParameterElementImpl> get parameters {
    return _parameters.toFixedList();
  }

  List<TypeParameterElementImpl> get typeParameters {
    return _typeParameters.toFixedList();
  }

  void addParameter(ParameterElementImpl element) {
    _parameters.add(element);
  }

  void addTypeParameter(TypeParameterElementImpl element) {
    _typeParameters.add(element);
  }

  void enclose(ElementImpl element) {
    element.enclosingElement = _element;
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
  LibraryElementImpl _libraryElement;
  final TypeProvider _typeProvider;
  final CompilationUnitElementImpl _unitElement;
  final bool _isNonNullableByDefault;
  final ErrorReporter _errorReporter;
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

  factory ResolutionVisitor({
    required CompilationUnitElementImpl unitElement,
    required AnalysisErrorListener errorListener,
    required FeatureSet featureSet,
    required Scope nameScope,
    ElementWalker? elementWalker,
  }) {
    var libraryElement = unitElement.library;
    var typeProvider = libraryElement.typeProvider;
    var unitSource = unitElement.source;
    var isNonNullableByDefault = featureSet.isEnabled(Feature.non_nullable);
    var errorReporter = ErrorReporter(
      errorListener,
      unitSource,
      isNonNullableByDefault: isNonNullableByDefault,
    );

    var namedTypeResolver = NamedTypeResolver(
      libraryElement,
      isNonNullableByDefault,
      errorReporter,
    );

    final recordTypeResolver = RecordTypeAnnotationResolver(
      typeProvider: typeProvider,
      errorReporter: errorReporter,
    );

    return ResolutionVisitor._(
      libraryElement,
      typeProvider,
      unitElement,
      isNonNullableByDefault,
      errorReporter,
      AstRewriter(errorReporter, typeProvider),
      namedTypeResolver,
      recordTypeResolver,
      nameScope,
      elementWalker,
      ElementHolder(unitElement),
    );
  }

  ResolutionVisitor._(
    this._libraryElement,
    this._typeProvider,
    this._unitElement,
    this._isNonNullableByDefault,
    this._errorReporter,
    this._astRewriter,
    this._namedTypeResolver,
    this._recordTypeResolver,
    this._nameScope,
    this._elementWalker,
    this._elementHolder,
  );

  DartType get _dynamicType => _typeProvider.dynamicType;

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    if (_elementWalker == null) {
      _createElementAnnotation(node);
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
      _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
        node.name,
        [name],
      );
    } else if (!(element is LocalVariableElement ||
        element is ParameterElement)) {
      _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE,
        node.name,
      );
    }
  }

  @override
  void visitAugmentationImportDirective(AugmentationImportDirective node) {
    final element = node.element;
    if (element is AugmentationImportElementImpl) {
      _setOrCreateMetadataElements(element, node.metadata);
    }

    _withElementWalker(null, () {
      super.visitAugmentationImportDirective(node);
    });
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
        var element = LocalVariableElementImpl(
          exceptionNode.name.lexeme,
          exceptionNode.name.offset,
        );
        _elementHolder.enclose(element);
        _define(element);

        exceptionNode.declaredElement = element;

        element.isFinal = true;
        if (exceptionTypeNode == null) {
          element.hasImplicitType = true;
          var type =
              _isNonNullableByDefault ? _typeProvider.objectType : _dynamicType;
          element.type = type;
        } else {
          element.type = exceptionTypeNode.typeOrThrow;
        }

        element.setCodeRange(
          exceptionNode.name.offset,
          exceptionNode.name.length,
        );
      }

      var stackTraceNode = node.stackTraceParameter;
      if (stackTraceNode != null) {
        var element = LocalVariableElementImpl(
          stackTraceNode.name.lexeme,
          stackTraceNode.name.offset,
        );
        _elementHolder.enclose(element);
        _define(element);

        stackTraceNode.declaredElement = element;

        element.isFinal = true;
        element.type = _typeProvider.stackTraceType;

        element.setCodeRange(
          stackTraceNode.name.offset,
          stackTraceNode.name.length,
        );
      }

      node.body.accept(this);
    });
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    ClassElementImpl element = _elementWalker!.getClass();
    node.declaredElement = element;
    _namedTypeResolver.enclosingClass = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forClass(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

        var extendsClause = node.extendsClause;
        var withClause = node.withClause;

        if (extendsClause != null) {
          ErrorCode errorCode = withClause == null
              ? CompileTimeErrorCode.EXTENDS_NON_CLASS
              : CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS;
          _resolveType(extendsClause.superclass, errorCode, asClass: true);
        }

        _resolveWithClause(withClause);
        _resolveImplementsClause(node.implementsClause);

        _defineElements(element.accessors);
        _defineElements(element.methods);
        node.members.accept(this);
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    ClassElementImpl element = _elementWalker!.getClass();
    node.declaredElement = element;
    _namedTypeResolver.enclosingClass = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forClass(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

        _resolveType(
          node.superclass,
          CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS,
          asClass: true,
        );

        _resolveWithClause(node.withClause);
        _resolveImplementsClause(node.implementsClause);
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElementImpl element = _elementWalker!.getConstructor();
    (node as ConstructorDeclarationImpl).declaredElement = element;
    node.declaredElement = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementHolder(ElementHolder(element), () {
      _withElementWalker(null, () {
        _withNameScope(() {
          node.returnType.accept(this);

          _withElementWalker(
            ElementWalker.forExecutable(element),
            () {
              node.parameters.accept(this);
            },
          );
          _defineParameters(element.parameters);

          _resolveRedirectedConstructor(node);
          node.initializers.accept(this);
          node.body.accept(this);
        });
      });
    });
  }

  @override
  void visitDeclaredIdentifier(covariant DeclaredIdentifierImpl node) {
    var nameToken = node.name;
    var element = LocalVariableElementImpl(nameToken.lexeme, nameToken.offset);
    _elementHolder.enclose(element);
    node.declaredElement = element;

    _setOrCreateMetadataElements(element, node.metadata);

    element.isConst = node.isConst;
    element.isFinal = node.isFinal;

    if (node.type == null) {
      element.hasImplicitType = true;
      element.type = _dynamicType;
    } else {
      node.type!.accept(this);
      element.type = node.type!.typeOrThrow;
    }

    _setCodeRange(element, node);
  }

  @override
  void visitDeclaredVariablePattern(
      covariant DeclaredVariablePatternImpl node) {
    node.type?.accept(this);

    final name = node.name.lexeme;
    var element = BindPatternVariableElementImpl(
      node,
      name,
      node.name.offset,
    );
    _patternVariables.add(name, element);
    _elementHolder.enclose(element);
    _define(element);
    element.hasImplicitType = node.type == null;
    element.type = node.type?.type ?? InvalidTypeImpl.instance;
    node.declaredElement = element;

    var patternContext = node.patternContext;
    if (patternContext is ForEachPartsWithPatternImpl) {
      element.isFinal = patternContext.finalKeyword != null;
    } else if (patternContext is PatternVariableDeclarationImpl) {
      element.isFinal = patternContext.finalKeyword != null;
    } else {
      element.isFinal = node.finalKeyword != null;
    }
  }

  @override
  void visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    var normalParameter = node.parameter;
    var nameToken = normalParameter.name;

    ParameterElementImpl element;
    if (_elementWalker != null) {
      element = _elementWalker!.getParameter();
    } else {
      var name = nameToken?.lexeme ?? '';
      var nameOffset = nameToken?.offset ?? -1;
      if (node.parameter is FieldFormalParameter) {
        // Only for recovery, this should not happen in valid code.
        element = DefaultFieldFormalParameterElementImpl(
          name: name,
          nameOffset: nameOffset,
          parameterKind: node.kind,
        )..constantInitializer = node.defaultValue;
      } else if (node.parameter is SuperFormalParameter) {
        // Only for recovery, this should not happen in valid code.
        element = DefaultSuperFormalParameterElementImpl(
          name: name,
          nameOffset: nameOffset,
          parameterKind: node.kind,
        )..constantInitializer = node.defaultValue;
      } else {
        element = DefaultParameterElementImpl(
          name: name,
          nameOffset: nameOffset,
          parameterKind: node.kind,
        )..constantInitializer = node.defaultValue;
      }
      _elementHolder.addParameter(element);

      _setCodeRange(element, node);
      element.isConst = node.isConst;
      element.isExplicitlyCovariant = node.parameter.covariantKeyword != null;
      element.isFinal = node.isFinal;

      if (normalParameter is SimpleFormalParameterImpl &&
          normalParameter.type == null) {
        element.hasImplicitType = true;
      }
    }

    normalParameter.declaredElement = element;
    node.declaredElement = element;

    normalParameter.accept(this);

    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      _withElementWalker(null, () {
        _withElementHolder(ElementHolder(element), () {
          defaultValue.accept(this);
        });
      });
    }
  }

  @override
  void visitEnumConstantDeclaration(
      covariant EnumConstantDeclarationImpl node) {
    var element = _elementWalker!.getVariable() as ConstFieldElementImpl;
    node.declaredElement = element;

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
    EnumElementImpl element = _elementWalker!.getEnum();
    node.declaredElement = element;
    _namedTypeResolver.enclosingClass = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forEnum(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

        _resolveWithClause(node.withClause);
        _resolveImplementsClause(node.implementsClause);

        _defineElements(element.accessors);
        _defineElements(element.methods);
        node.constants.accept(this);
        node.members.accept(this);
      });
    });

    _namedTypeResolver.enclosingClass = null;
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var element = node.element;
    if (element is LibraryExportElementImpl) {
      _setOrCreateMetadataElements(element, node.metadata);
    }

    _withElementWalker(null, () {
      super.visitExportDirective(node);
    });
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var element = _elementWalker!.getExtension();
    (node as ExtensionDeclarationImpl).declaredElement = element;
    node.declaredElement = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forExtension(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.extendedType.accept(this);

        _defineElements(element.accessors);
        _defineElements(element.methods);
        node.members.accept(this);
      });
    });
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    FieldFormalParameterElementImpl element;
    if (node.parent is DefaultFormalParameter) {
      element = node.declaredElement as FieldFormalParameterElementImpl;
    } else {
      var nameToken = node.name;
      if (_elementWalker != null) {
        element =
            _elementWalker!.getParameter() as FieldFormalParameterElementImpl;
      } else {
        // Only for recovery, this should not happen in valid code.
        element = FieldFormalParameterElementImpl(
          name: nameToken.lexeme,
          nameOffset: nameToken.offset,
          parameterKind: node.kind,
        );
        _elementHolder.enclose(element);
        element.isConst = node.isConst;
        element.isExplicitlyCovariant = node.covariantKeyword != null;
        element.isFinal = node.isFinal;
        _setCodeRange(element, node);
      }
      node.declaredElement = element;
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
              element.type = node.type?.type ?? _dynamicType;
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
    ExecutableElementImpl element;
    if (_elementWalker != null) {
      element = node.isGetter || node.isSetter
          ? _elementWalker!.getAccessor()
          : _elementWalker!.getFunction();
      node.declaredElement = element;
    } else {
      element = node.declaredElement as ExecutableElementImpl;

      _setCodeRange(element, node);
      setElementDocumentationComment(element, node);

      var body = node.functionExpression.body;
      if (node.externalKeyword != null || body is NativeFunctionBody) {
        element.isExternal = true;
      }

      element.isAsynchronous = body.isAsynchronous;
      element.isGenerator = body.isGenerator;
      if (node.returnType == null) {
        element.hasImplicitReturnType = true;
      }
    }

    var expression = node.functionExpression;
    expression.declaredElement = element;

    _setOrCreateMetadataElements(element, node.metadata);

    var holder = ElementHolder(element);
    _withElementHolder(holder, () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forExecutable(element) : null,
        () {
          _withNameScope(() {
            _buildTypeParameterElements(expression.typeParameters);
            expression.typeParameters?.accept(this);
            if (_elementWalker == null) {
              element.typeParameters = holder.typeParameters;
            }

            expression.parameters?.accept(this);
            if (_elementWalker == null) {
              element.parameters = holder.parameters;
            }

            node.returnType?.accept(this);
            if (_elementWalker == null) {
              element.returnType = node.returnType?.type ?? _dynamicType;
            }

            _defineParameters(element.parameters);
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
      covariant FunctionDeclarationStatementImpl node) {
    if (!_hasLocalElementsBuilt(node)) {
      _buildLocalFunctionElement(node);
    }

    node.functionDeclaration.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var element = FunctionElementImpl.forOffset(node.offset);
    _elementHolder.enclose(element);
    (node as FunctionExpressionImpl).declaredElement = element;

    element.hasImplicitReturnType = true;
    element.returnType = DynamicTypeImpl.instance;

    FunctionBody body = node.body;
    element.isAsynchronous = body.isAsynchronous;
    element.isGenerator = body.isGenerator;

    var holder = ElementHolder(element);
    _withElementHolder(holder, () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        element.typeParameters = holder.typeParameters;

        node.parameters!.accept(this);
        element.parameters = holder.parameters;

        _defineParameters(element.parameters);
        node.body.accept(this);
      });
    });

    _setCodeRange(element, node);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var element = _elementWalker!.getTypedef();
    node.declaredElement = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forTypedef(element), () {
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
    ParameterElementImpl element;
    if (node.parent is DefaultFormalParameter) {
      element = node.declaredElement as ParameterElementImpl;
    } else {
      var nameToken = node.name;
      if (_elementWalker != null) {
        element = _elementWalker!.getParameter();
      } else {
        element = ParameterElementImpl(
          name: nameToken.lexeme,
          nameOffset: nameToken.offset,
          parameterKind: node.kind,
        );
        _elementHolder.addParameter(element);
        element.isConst = node.isConst;
        element.isExplicitlyCovariant = node.covariantKeyword != null;
        element.isFinal = node.isFinal;
        _setCodeRange(element, node);
      }
      node.declaredElement = element;
    }

    _setOrCreateMetadataElements(element, node.metadata);

    var holder = ElementHolder(element);
    _withElementHolder(holder, () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forParameter(element) : null,
        () {
          _withNameScope(() {
            _buildTypeParameterElements(node.typeParameters);
            node.typeParameters?.accept(this);
            if (_elementWalker == null) {
              element.typeParameters = holder.typeParameters;
            }

            node.parameters.accept(this);
            if (_elementWalker == null) {
              element.parameters = holder.parameters;
            }

            node.returnType?.accept(this);
            if (_elementWalker == null) {
              element.type = FunctionTypeImpl(
                typeFormals: element.typeParameters,
                parameters: element.parameters,
                returnType: node.returnType?.type ?? _dynamicType,
                nullabilitySuffix: _getNullability(node.question != null),
              );
            }
          });
        },
      );
    });
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var element = GenericFunctionTypeElementImpl.forOffset(node.offset);
    _unitElement.encloseElement(element);
    (node as GenericFunctionTypeImpl).declaredElement = element;

    element.isNullable = node.question != null;

    _setCodeRange(element, node);

    var holder = ElementHolder(element);
    _withElementHolder(holder, () {
      _withElementWalker(null, () {
        _withNameScope(() {
          _buildTypeParameterElements(node.typeParameters);
          node.typeParameters?.accept(this);
          element.typeParameters = holder.typeParameters;

          node.parameters.accept(this);
          element.parameters = holder.parameters;

          node.returnType?.accept(this);
          element.returnType = node.returnType?.type ?? _dynamicType;
        });
      });
    });

    var type = FunctionTypeImpl(
      typeFormals: element.typeParameters,
      parameters: element.parameters,
      returnType: element.returnType,
      nullabilitySuffix: _getNullability(node.question != null),
    );
    element.type = type;
    node.type = type;
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var element = _elementWalker!.getTypedef();
    node.declaredElement = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forGenericTypeAlias(element), () {
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
  void visitImportDirective(ImportDirective node) {
    var element = node.element;
    if (element is LibraryImportElementImpl) {
      _setOrCreateMetadataElements(element, node.metadata);
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
        _errorReporter.reportErrorForNode(
            WarningCode.SDK_VERSION_CONSTRUCTOR_TEAROFFS, node, []);
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
          labelNameNode.staticElement as LabelElement,
        );
      }
      unlabeled.accept(this);
    } finally {
      _labelScope = outerScope;
    }
  }

  @override
  void visitLibraryAugmentationDirective(LibraryAugmentationDirective node) {
    final element = node.element;
    if (element is LibraryOrAugmentationElementImpl) {
      _setOrCreateMetadataElements(element, node.metadata);
    }

    _withElementWalker(null, () {
      super.visitLibraryAugmentationDirective(node);
    });
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    ++_libraryDirectiveIndex;
    var element = node.element;
    if (element is LibraryElementImpl && _libraryDirectiveIndex == 1) {
      _setOrCreateMetadataElements(element, node.metadata);
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
    ExecutableElementImpl element = node.isGetter || node.isSetter
        ? _elementWalker!.getAccessor()
        : _elementWalker!.getFunction();
    node.declaredElement = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forExecutable(element), () {
      node.metadata.accept(this);
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.parameters?.accept(this);
        node.returnType?.accept(this);

        _withElementWalker(null, () {
          _withElementHolder(ElementHolder(element), () {
            _defineParameters(element.parameters);
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
    var element = _elementWalker!.getMixin();
    node.declaredElement = element;

    _setOrCreateMetadataElements(element, node.metadata);

    _withElementWalker(ElementWalker.forMixin(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);

        _resolveOnClause(node.onClause);
        _resolveImplementsClause(node.implementsClause);

        _defineElements(element.accessors);
        _defineElements(element.methods);
        node.members.accept(this);
      });
    });
  }

  @override
  void visitNamedType(covariant NamedTypeImpl node) {
    node.typeArguments?.accept(this);

    _namedTypeResolver.nameScope = _nameScope;
    _namedTypeResolver.resolve(node);

    if (_namedTypeResolver.rewriteResult != null) {
      _namedTypeResolver.rewriteResult!.accept(this);
    }
  }

  @override
  void visitPartDirective(PartDirective node) {
    var element = node.element;
    if (element is PartElementImpl) {
      _setOrCreateMetadataElements(element, node.metadata);
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
  void visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    ParameterElementImpl element;
    if (node.parent is DefaultFormalParameter) {
      element = node.declaredElement as ParameterElementImpl;
    } else {
      var nameToken = node.name;
      if (_elementWalker != null) {
        element = _elementWalker!.getParameter();
      } else {
        if (nameToken != null) {
          element = ParameterElementImpl(
            name: nameToken.lexeme,
            nameOffset: nameToken.offset,
            parameterKind: node.kind,
          );
        } else {
          element = ParameterElementImpl(
            name: '',
            nameOffset: -1,
            parameterKind: node.kind,
          );
        }
        _elementHolder.addParameter(element);

        _setCodeRange(element, node);
        element.isConst = node.isConst;
        element.isExplicitlyCovariant = node.covariantKeyword != null;
        element.isFinal = node.isFinal;
        if (node.type == null) {
          element.hasImplicitType = true;
        }
        node.declaredElement = element;
      }
      node.declaredElement = element;
    }

    node.type?.accept(this);
    if (_elementWalker == null) {
      element.type = node.type?.type ?? _dynamicType;
    }

    _setOrCreateMetadataElements(element, node.metadata);
  }

  @override
  void visitSimpleIdentifier(covariant SimpleIdentifierImpl node) {
    final newNode = _astRewriter.simpleIdentifier(_nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    SuperFormalParameterElementImpl element;
    if (node.parent is DefaultFormalParameter) {
      element = node.declaredElement as SuperFormalParameterElementImpl;
    } else {
      var nameToken = node.name;
      if (_elementWalker != null) {
        element =
            _elementWalker!.getParameter() as SuperFormalParameterElementImpl;
      } else {
        // Only for recovery, this should not happen in valid code.
        element = SuperFormalParameterElementImpl(
          name: nameToken.lexeme,
          nameOffset: nameToken.offset,
          parameterKind: node.kind,
        );
        _elementHolder.enclose(element);
        element.isConst = node.isConst;
        element.isExplicitlyCovariant = node.covariantKeyword != null;
        element.isFinal = node.isFinal;
        _setCodeRange(element, node);
      }
      node.declaredElement = element;
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
              element.type = node.type?.type ?? _dynamicType;
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
      group.variables =
          _patternVariables.switchStatementSharedCaseScopeFinish(group);
      _withNameScope(() {
        var statements = group.statements;
        _buildLocalElements(statements);
        statements.accept(this);
      });
    }
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    var element = node.declaredElement as TypeParameterElementImpl;

    _setOrCreateMetadataElements(element, node.metadata);

    var boundNode = node.bound;
    if (boundNode != null) {
      boundNode.accept(this);
      if (_elementWalker == null) {
        element.bound = boundNode.type;
      }
    }
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    var initializerNode = node.initializer;

    VariableElementImpl element;
    if (_elementWalker != null) {
      element = _elementWalker!.getVariable();
      node.declaredElement = element;
    } else {
      var localElement = node.declaredElement as LocalVariableElementImpl;
      element = localElement;

      var varList = node.parent as VariableDeclarationList;
      localElement.hasImplicitType = varList.type == null;
      localElement.hasInitializer = initializerNode != null;
      localElement.type = varList.type?.type ?? _dynamicType;
    }

    if (initializerNode != null) {
      _withElementWalker(null, () {
        _withElementHolder(ElementHolder(element), () {
          initializerNode.accept(this);
        });
      });
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    var parent = node.parent;
    if (parent is ForPartsWithDeclarations ||
        parent is VariableDeclarationStatement &&
            !_hasLocalElementsBuilt(parent)) {
      _buildLocalVariableElements(node);
    }

    node.visitChildren(this);

    NodeList<Annotation> annotations;
    if (parent is FieldDeclaration) {
      annotations = parent.metadata;
    } else if (parent is TopLevelVariableDeclaration) {
      annotations = parent.metadata;
    } else {
      // Local variable declaration
      annotations = node.metadata;
    }

    var variables = node.variables;
    for (var i = 0; i < variables.length; i++) {
      var variable = variables[i];
      var element = variable.declaredElement as ElementImpl;
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
      var element = LabelElementImpl(
        labelName.name,
        labelName.offset,
        onSwitchMember,
      );
      labelName.staticElement = element;
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
      covariant FunctionDeclarationStatementImpl statement) {
    var node = statement.functionDeclaration;
    var nameToken = node.name;
    var element = FunctionElementImpl(nameToken.lexeme, nameToken.offset);
    node.declaredElement = element;
    _define(element);
    _elementHolder.enclose(element);
  }

  void _buildLocalVariableElements(VariableDeclarationList variableList) {
    var isConst = variableList.isConst;
    var isFinal = variableList.isFinal;
    var isLate = variableList.isLate;
    for (var variable in variableList.variables) {
      variable as VariableDeclarationImpl;
      var nameToken = variable.name;

      LocalVariableElementImpl element;
      if (isConst && variable.initializer != null) {
        element = ConstLocalVariableElementImpl(
          nameToken.lexeme,
          nameToken.offset,
        );
      } else {
        element = LocalVariableElementImpl(
          nameToken.lexeme,
          nameToken.offset,
        );
      }
      variable.declaredElement = element;
      _elementHolder.enclose(element);
      _define(element);

      element.isConst = isConst;
      element.isFinal = isFinal;
      element.isLate = isLate;
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

      TypeParameterElementImpl element;
      if (_elementWalker != null) {
        element = _elementWalker!.getTypeParameter();
      } else {
        element = TypeParameterElementImpl(name.lexeme, name.offset);
        _elementHolder.addTypeParameter(element);

        _setCodeRange(element, typeParameter);
      }
      typeParameter.declaredElement = element;
      _define(element);
      _setOrCreateMetadataElements(element, typeParameter.metadata);
    }
  }

  /// Create a new [ElementAnnotation] for the [node].
  void _createElementAnnotation(AnnotationImpl node) {
    var element = ElementAnnotationImpl(_unitElement);
    element.annotationAst = node;
    node.elementAnnotation = element;
  }

  void _define(Element element) {
    (_nameScope as LocalScope).add(element);
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
  void _defineParameters(List<ParameterElement> parameters) {
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      ParameterElement parameter = parameters[i];
      if (!parameter.isInitializingFormal) {
        _define(parameter);
      }
    }
  }

  NullabilitySuffix _getNullability(bool hasQuestion) {
    if (_isNonNullableByDefault) {
      if (hasQuestion) {
        return NullabilitySuffix.question;
      } else {
        return NullabilitySuffix.none;
      }
    }
    return NullabilitySuffix.star;
  }

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
      guardedPattern.variables = variables.cast();
      guardedPattern.whenClause?.accept(this);
      if (then != null) {
        then();
      }
    });
  }

  void _resolveImplementsClause(ImplementsClause? clause) {
    if (clause == null) return;

    _resolveTypes(
      clause.interfaces,
      CompileTimeErrorCode.IMPLEMENTS_NON_CLASS,
    );
  }

  void _resolveOnClause(OnClause? clause) {
    if (clause == null) return;

    _resolveTypes(
      clause.superclassConstraints,
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE,
    );
  }

  void _resolveRedirectedConstructor(ConstructorDeclaration node) {
    var redirectedConstructor = node.redirectedConstructor;
    if (redirectedConstructor == null) return;

    var namedType = redirectedConstructor.type;
    _namedTypeResolver.redirectedConstructor_namedType = namedType;

    redirectedConstructor.accept(this);

    _namedTypeResolver.redirectedConstructor_namedType = null;
  }

  /// Return the [InterfaceType] of the given [namedType].
  ///
  /// If the resulting type is not a valid interface type, return `null`.
  ///
  /// The flag [asClass] specifies if the type will be used as a class, so mixin
  /// declarations are not valid (they declare interfaces and mixins, but not
  /// classes).
  void _resolveType(NamedTypeImpl namedType, ErrorCode errorCode,
      {bool asClass = false}) {
    _namedTypeResolver.classHierarchy_namedType = namedType;
    visitNamedType(namedType);
    _namedTypeResolver.classHierarchy_namedType = null;

    if (_namedTypeResolver.hasErrorReported) {
      return;
    }

    DartType type = namedType.typeOrThrow;
    if (type is InterfaceType) {
      final element = type.element;
      if (element is EnumElement || element is MixinElement && asClass) {
        _errorReporter.reportErrorForNode(errorCode, namedType);
        return;
      }
      return;
    }

    // If the type is not an InterfaceType, then visitNamedType() sets the type
    // to be a DynamicTypeImpl
    if (!_libraryElement.shouldIgnoreUndefinedNamedType(namedType)) {
      final firstToken = namedType.importPrefix?.name ?? namedType.name2;
      final offset = firstToken.offset;
      final length = namedType.name2.end - offset;
      _errorReporter.reportErrorForOffset(errorCode, offset, length);
    }
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
  void _resolveTypes(NodeList<NamedType> namedTypes, ErrorCode errorCode) {
    for (var namedType in namedTypes) {
      _resolveType(namedType as NamedTypeImpl, errorCode);
    }
  }

  void _resolveWithClause(WithClause? clause) {
    if (clause == null) return;

    for (var namedType in clause.mixinTypes) {
      _namedTypeResolver.withClause_namedType = namedType;
      _resolveType(
        namedType as NamedTypeImpl,
        CompileTimeErrorCode.MIXIN_OF_NON_CLASS,
      );
      _namedTypeResolver.withClause_namedType = null;
    }
  }

  void _setCodeRange(ElementImpl element, AstNode node) {
    element.setCodeRange(node.offset, node.length);
  }

  void _setOrCreateMetadataElements(
    ElementImpl element,
    NodeList<Annotation> annotations, {
    bool visitNodes = true,
  }) {
    if (visitNodes) {
      annotations.accept(this);
    }
    if (_elementWalker != null) {
      _setElementAnnotations(annotations, element.metadata);
    } else if (annotations.isNotEmpty) {
      element.metadata = annotations.map((annotation) {
        return annotation.elementAnnotation!;
      }).toList();
    }
  }

  void _visitIf(IfElementOrStatementImpl node) {
    var caseClause = node.caseClause;
    if (caseClause != null) {
      node.expression.accept(this);
      _resolveGuardedPattern(caseClause.guardedPattern, then: () {
        node.ifTrue.accept(this);
      });
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
      List<Annotation> nodes, List<ElementAnnotation> annotations) {
    int nodeCount = nodes.length;
    if (nodeCount != annotations.length) {
      throw StateError(
        'Found $nodeCount annotation nodes and '
        '${annotations.length} element annotations',
      );
    }
    for (int i = 0; i < nodeCount; i++) {
      (nodes[i] as AnnotationImpl).elementAnnotation = annotations[i];
    }
  }
}

class _VariableBinder
    extends VariableBinder<DartPatternImpl, PromotableElement> {
  final TypeProvider typeProvider;

  _VariableBinder({
    required super.errors,
    required this.typeProvider,
  });

  @override
  JoinPatternVariableElementImpl joinPatternVariables({
    required Object key,
    required List<PromotableElement> components,
    required shared.JoinedPatternVariableInconsistency inconsistency,
  }) {
    var first = components.first;
    List<PatternVariableElementImpl> expandedVariables;
    if (key is LogicalOrPatternImpl) {
      expandedVariables = components.expand((variable) {
        variable as PatternVariableElementImpl;
        if (variable is JoinPatternVariableElementImpl) {
          return variable.variables;
        } else {
          return [variable];
        }
      }).toList(growable: false);
    } else if (key is SwitchStatementCaseGroup) {
      expandedVariables = components
          .map((e) => e as PatternVariableElementImpl)
          .toList(growable: false);
    } else {
      throw UnimplementedError('(${key.runtimeType}) $key');
    }
    return JoinPatternVariableElementImpl(
      first.name,
      -1,
      expandedVariables,
      inconsistency.maxWithAll(
        components
            .whereType<JoinPatternVariableElementImpl>()
            .map((e) => e.inconsistency),
      ),
    )
      ..enclosingElement = first.enclosingElement
      ..type = InvalidTypeImpl.instance;
  }
}

class _VariableBinderErrors
    implements VariableBinderErrors<DartPatternImpl, PromotableElement> {
  final ResolutionVisitor visitor;

  _VariableBinderErrors(this.visitor);

  @override
  void assertInErrorRecovery() {
    // TODO: implement assertInErrorRecovery
    throw UnimplementedError();
  }

  @override
  void duplicateVariablePattern({
    required String name,
    required covariant BindPatternVariableElementImpl original,
    required covariant BindPatternVariableElementImpl duplicate,
  }) {
    visitor._errorReporter.reportError(
      DiagnosticFactory().duplicateDefinitionForNodes(
        visitor._errorReporter.source,
        CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN,
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
    required PromotableElement variable,
  }) {
    visitor._errorReporter.reportErrorForNode(
      CompileTimeErrorCode.MISSING_VARIABLE_PATTERN,
      hasInLeft ? node.rightOperand : node.leftOperand,
      [name],
    );
  }
}
