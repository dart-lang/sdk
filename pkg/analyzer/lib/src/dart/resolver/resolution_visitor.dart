// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/ast_rewrite.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/type_name_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/declaration_resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

class ElementHolder {
  final ElementImpl _element;
  final List<TypeParameterElementImpl> _typeParameters = [];
  final List<ParameterElementImpl> _parameters = [];

  ElementHolder(this._element) : assert(_element != null);

  List<ParameterElementImpl> get parameters => _parameters;

  List<TypeParameterElementImpl> get typeParameters => _typeParameters;

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
/// 3. Resolve all [TypeName]s - set elements and types.
/// 4. Resolve all [GenericFunctionType]s - set their types.
class ResolutionVisitor extends RecursiveAstVisitor<void> {
  final TypeProvider _typeProvider;
  final CompilationUnitElementImpl _unitElement;
  final bool _isNonNullableByDefault;
  final ErrorReporter _errorReporter;
  final AstRewriter _astRewriter;
  final TypeNameResolver _typeNameResolver;

  /// This index is incremented every time we visit a [LibraryDirective].
  /// There is just one [LibraryElement], so we can support only one node.
  int _libraryDirectiveIndex = 0;

  /// The provider of pre-built children elements from the element being
  /// visited. For example when we visit a method, its element is resynthesized
  /// from the summary, and we get resynthesized elements for type parameters
  /// and formal parameters to apply to corresponding AST nodes.
  ElementWalker _elementWalker;

  /// The scope used to resolve identifiers.
  Scope _nameScope;

  /// The scope used to resolve labels for `break` and `continue` statements,
  /// or `null` if no labels have been defined in the current context.
  LabelScope _labelScope;

  /// The container to add newly created elements that should be put into the
  /// enclosing element.
  ElementHolder _elementHolder;

  factory ResolutionVisitor({
    @required CompilationUnitElementImpl unitElement,
    @required AnalysisErrorListener errorListener,
    @required FeatureSet featureSet,
    @required Scope nameScope,
    ElementWalker elementWalker,
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

    var typeNameResolver = TypeNameResolver(
      libraryElement.typeSystem,
      typeProvider,
      isNonNullableByDefault,
      errorReporter,
    );

    return ResolutionVisitor._(
      typeProvider,
      unitElement,
      isNonNullableByDefault,
      errorReporter,
      AstRewriter(errorReporter),
      typeNameResolver,
      nameScope,
      elementWalker,
      ElementHolder(unitElement),
    );
  }

  ResolutionVisitor._(
    this._typeProvider,
    this._unitElement,
    this._isNonNullableByDefault,
    this._errorReporter,
    this._astRewriter,
    this._typeNameResolver,
    this._nameScope,
    this._elementWalker,
    this._elementHolder,
  );

  DartType get _dynamicType => _typeProvider.dynamicType;

  @override
  void visitAnnotation(Annotation node) {
    _withElementWalker(null, () {
      super.visitAnnotation(node);
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
  void visitCatchClause(CatchClause node) {
    var exceptionTypeNode = node.exceptionType;
    exceptionTypeNode?.accept(this);

    _withNameScope(() {
      var exceptionNode = node.exceptionParameter;
      if (exceptionNode != null) {
        var element = LocalVariableElementImpl(
          exceptionNode.name,
          exceptionNode.offset,
        );
        _elementHolder.enclose(element);
        _define(element);

        exceptionNode.staticElement = element;

        element.isFinal = true;
        if (exceptionTypeNode == null) {
          element.hasImplicitType = true;
          var type =
              _isNonNullableByDefault ? _typeProvider.objectType : _dynamicType;
          element.type = type;
          exceptionNode.staticType = type;
        } else {
          element.type = exceptionTypeNode.type;
          exceptionNode.staticType = exceptionTypeNode.type;
        }

        _setCodeRange(element, exceptionNode);
      }

      var stackTraceNode = node.stackTraceParameter;
      if (stackTraceNode != null) {
        var element = LocalVariableElementImpl(
          stackTraceNode.name,
          stackTraceNode.offset,
        );
        _elementHolder.enclose(element);
        _define(element);

        stackTraceNode.staticElement = element;

        element.isFinal = true;
        element.type = _typeProvider.stackTraceType;
        stackTraceNode.staticType = _typeProvider.stackTraceType;

        _setCodeRange(element, stackTraceNode);
      }

      node.body.accept(this);
    });
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    ClassElementImpl element = _elementWalker.getClass();
    node.name.staticElement = element;
    _typeNameResolver.enclosingClass = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

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

    _typeNameResolver.enclosingClass = null;
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    ClassElementImpl element = _elementWalker.getClass();
    node.name.staticElement = element;
    _typeNameResolver.enclosingClass = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

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

    _typeNameResolver.enclosingClass = null;
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElementImpl element = _elementWalker.getConstructor();
    (node as ConstructorDeclarationImpl).declaredElement = element;
    node.name?.staticElement = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

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
          node.body?.accept(this);
        });
      });
    });
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    var nameNode = node.identifier;
    var element = LocalVariableElementImpl(nameNode.name, nameNode.offset);
    _elementHolder.enclose(element);
    nameNode.staticElement = element;

    node.metadata.accept(this);
    element.metadata = _createElementAnnotations(node.metadata);

    element.isConst = node.isConst;
    element.isFinal = node.isFinal;

    if (node.type == null) {
      element.hasImplicitType = true;
      element.type = _dynamicType;
    } else {
      node.type.accept(this);
      element.type = node.type.type;
    }

    _setCodeRange(element, node);
  }

  @override
  void visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    NormalFormalParameter normalParameter = node.parameter;
    SimpleIdentifier nameNode = normalParameter.identifier;

    ParameterElementImpl element;
    if (_elementWalker != null) {
      element = _elementWalker.getParameter();
    } else {
      var name = nameNode?.name ?? '';
      var nameOffset = nameNode?.offset ?? -1;
      if (node.parameter is FieldFormalParameter) {
        // Only for recovery, this should not happen in valid code.
        element = DefaultFieldFormalParameterElementImpl(name, nameOffset);
      } else {
        element = DefaultParameterElementImpl(name, nameOffset);
      }
      _elementHolder.addParameter(element);

      _setCodeRange(element, node);
      element.isConst = node.isConst;
      element.isExplicitlyCovariant = node.parameter.covariantKeyword != null;
      element.isFinal = node.isFinal;
      element.parameterKind = node.kind;

      if (normalParameter is SimpleFormalParameter &&
          normalParameter.type == null) {
        element.hasImplicitType = true;
      }
    }

    if (normalParameter is SimpleFormalParameterImpl) {
      normalParameter.declaredElement = element;
    }
    nameNode?.staticElement = element;

    normalParameter.accept(this);

    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      _withElementWalker(null, () {
        _withElementHolder(ElementHolder(element), () {
          defaultValue.accept(this);
        });
      });
      element.defaultValueCode = defaultValue.toSource();
    }
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    var element = _elementWalker.getVariable();
    node.name.staticElement = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    EnumElementImpl element = _elementWalker.getEnum();
    node.name.staticElement = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

    _withElementWalker(ElementWalker.forClass(element), () {
      _withNameScope(() {
        _defineElements(element.accessors);
        node.constants.accept(this);
      });
    });
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _withElementWalker(null, () {
      super.visitExportDirective(node);
      if (node.element != null) {
        _setElementAnnotations(node.metadata, node.element.metadata);
      }
    });
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var element = _elementWalker.getExtension();
    (node as ExtensionDeclarationImpl).declaredElement = element;
    node.name?.staticElement = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

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
  void visitFieldDeclaration(FieldDeclaration node) {
    super.visitFieldDeclaration(node);
    FieldElement firstFieldElement = node.fields.variables[0].declaredElement;
    _setElementAnnotations(node.metadata, firstFieldElement.metadata);
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    FieldFormalParameterElementImpl element;
    if (node.parent is DefaultFormalParameter) {
      element = node.declaredElement;
    } else {
      var nameNode = node.identifier;
      if (_elementWalker != null) {
        element = _elementWalker.getParameter();
      } else {
        // Only for recovery, this should not happen in valid code.
        element = FieldFormalParameterElementImpl(
          nameNode.name,
          nameNode.offset,
        );
        _elementHolder.enclose(element);
        element.isConst = node.isConst;
        element.isExplicitlyCovariant = node.covariantKeyword != null;
        element.isFinal = node.isFinal;
        element.parameterKind = node.kind;
        _setCodeRange(element, node);
      }
      nameNode.staticElement = element;
    }

    element.metadata = _createElementAnnotations(node.metadata);
    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

    _withElementHolder(ElementHolder(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.type?.accept(this);
        if (_elementWalker != null) {
          _withElementWalker(ElementWalker.forParameter(element), () {
            node.parameters?.accept(this);
          });
        } else {
          // Only for recovery, this should not happen in valid code.
          element.type = node.type?.type ?? _dynamicType;
          _withElementWalker(null, () {
            node.parameters?.accept(this);
          });
        }
      });
    });
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _withNameScope(() {
      super.visitForPartsWithDeclarations(node);
    });
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElementImpl element;
    if (_elementWalker != null) {
      element = node.isGetter || node.isSetter
          ? _elementWalker.getAccessor()
          : _elementWalker.getFunction();
      node.name.staticElement = element;
    } else {
      element = node.declaredElement;

      _setCodeRange(element, node);
      setElementDocumentationComment(element, node);
      element.metadata = _createElementAnnotations(node.metadata);

      FunctionBody body = node.functionExpression.body;
      if (node.externalKeyword != null || body is NativeFunctionBody) {
        element.isExternal = true;
      }

      element.isAsynchronous = body.isAsynchronous;
      element.isGenerator = body.isGenerator;
      if (node.returnType == null) {
        element.hasImplicitReturnType = true;
      }
    }

    FunctionExpressionImpl expression = node.functionExpression;
    expression.declaredElement = element;

    node.metadata?.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

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
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
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

    FunctionBody body = node.body;
    element.isAsynchronous = body.isAsynchronous;
    element.isGenerator = body.isGenerator;

    var holder = ElementHolder(element);
    _withElementHolder(holder, () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        element.typeParameters = holder.typeParameters;

        node.parameters.accept(this);
        element.parameters = holder.parameters;

        _defineParameters(element.parameters);
        node.body.accept(this);
      });
    });

    _setCodeRange(element, node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    var element = _elementWalker.getTypedef();
    node.name.staticElement = element;

    node.metadata?.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

    _withElementWalker(ElementWalker.forTypedef(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.returnType?.accept(this);
        node.parameters?.accept(this);
      });
    });
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    ParameterElementImpl element;
    if (node.parent is DefaultFormalParameter) {
      element = node.declaredElement;
    } else {
      SimpleIdentifier nameNode = node.identifier;
      if (_elementWalker != null) {
        element = _elementWalker.getParameter();
      } else {
        element = ParameterElementImpl(nameNode.name, nameNode.offset);
        _elementHolder.addParameter(element);
        element.isConst = node.isConst;
        element.isExplicitlyCovariant = node.covariantKeyword != null;
        element.isFinal = node.isFinal;
        element.parameterKind = node.kind;
        _setCodeRange(element, node);
      }
      nameNode.staticElement = element;
    }

    node.metadata?.accept(this);
    element.metadata = _createElementAnnotations(node.metadata);

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
    (node as GenericFunctionTypeImpl).type = type;
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    var element = _elementWalker.getTypedef();
    node.name.staticElement = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

    _withElementWalker(ElementWalker.forGenericTypeAlias(element), () {
      _withNameScope(() {
        _buildTypeParameterElements(node.typeParameters);
        node.typeParameters?.accept(this);
        node.type?.accept(this);
      });
    });
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _withElementWalker(null, () {
      super.visitImportDirective(node);
      if (node.element != null) {
        _setElementAnnotations(node.metadata, node.element.metadata);
      }
    });
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    bool onSwitchStatement = node.statement is SwitchStatement;
    _buildLabelElements(node.labels, onSwitchStatement, false);

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
  void visitLibraryDirective(LibraryDirective node) {
    super.visitLibraryDirective(node);
    ++_libraryDirectiveIndex;
    if (node.element != null && _libraryDirectiveIndex == 1) {
      _setElementAnnotations(node.metadata, node.element.metadata);
    } else {
      for (var annotation in node.metadata) {
        annotation.elementAnnotation = ElementAnnotationImpl(_unitElement);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElementImpl element = node.isGetter || node.isSetter
        ? _elementWalker.getAccessor()
        : _elementWalker.getFunction();
    node.name.staticElement = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

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
            node.body?.accept(this);
          });
        });
      });
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var newNode = _astRewriter.methodInvocation(_nameScope, node);
    if (newNode != node) {
      return newNode.accept(this);
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var element = _elementWalker.getMixin();
    node.name.staticElement = element;

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

    _withElementWalker(ElementWalker.forClass(element), () {
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
  void visitPartDirective(PartDirective node) {
    _withElementWalker(null, () {
      super.visitPartDirective(node);
      if (node.element != null) {
        _setElementAnnotations(node.metadata, node.element.metadata);
      }
    });
  }

  @override
  void visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    ParameterElementImpl element;
    if (node.parent is DefaultFormalParameter) {
      element = node.declaredElement;
    } else {
      SimpleIdentifier nameNode = node.identifier;
      if (_elementWalker != null) {
        element = _elementWalker.getParameter();
      } else {
        if (nameNode != null) {
          element = ParameterElementImpl(nameNode.name, nameNode.offset);
        } else {
          element = ParameterElementImpl('', -1);
        }
        _elementHolder.addParameter(element);

        _setCodeRange(element, node);
        element.isConst = node.isConst;
        element.isExplicitlyCovariant = node.covariantKeyword != null;
        element.isFinal = node.isFinal;
        element.parameterKind = node.kind;
        if (node.type == null) {
          element.hasImplicitType = true;
        }
        node.declaredElement = element;
      }
      nameNode?.staticElement = element;
      node.declaredElement = element;
    }

    node.type?.accept(this);
    if (_elementWalker == null) {
      element.metadata = _createElementAnnotations(node.metadata);
      element.type = node.type?.type ?? _dynamicType;
    }

    node.metadata.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _buildLabelElements(node.labels, false, true);

    node.expression.accept(this);

    _withNameScope(() {
      var statements = node.statements;
      _buildLocalElements(statements);
      statements.accept(this);
    });
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _buildLabelElements(node.labels, false, true);

    _withNameScope(() {
      var statements = node.statements;
      _buildLocalElements(statements);
      statements.accept(this);
    });
  }

  @override
  void visitTypeName(TypeName node) {
    node.typeArguments?.accept(this);

    _typeNameResolver.nameScope = _nameScope;
    _typeNameResolver.resolveTypeName(node);

    if (_typeNameResolver.rewriteResult != null) {
      _typeNameResolver.rewriteResult.accept(this);
    }
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    TypeParameterElementImpl element = node.declaredElement;

    node.metadata?.accept(this);
    _setElementAnnotations(node.metadata, element.metadata);

    var boundNode = node.bound;
    if (boundNode != null) {
      boundNode.accept(this);
      if (_elementWalker == null) {
        element.bound = boundNode.type;
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    Expression initializerNode = node.initializer;

    VariableElementImpl element;
    if (_elementWalker != null) {
      element = _elementWalker.getVariable();
      node.name.staticElement = element;
    } else {
      LocalVariableElementImpl localElement = node.declaredElement;
      element = localElement;

      VariableDeclarationList varList = node.parent;
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

    List<ElementAnnotation> elementAnnotations;
    if (parent is FieldDeclaration) {
      elementAnnotations = _createElementAnnotations(parent.metadata);
    } else if (parent is TopLevelVariableDeclaration) {
      elementAnnotations = _createElementAnnotations(parent.metadata);
    } else {
      // Local variable declaration
      elementAnnotations = _createElementAnnotations(node.metadata);
    }

    var variables = node.variables;
    for (var i = 0; i < variables.length; i++) {
      var variable = variables[i];
      var element = variable.declaredElement as ElementImpl;
      element.metadata = elementAnnotations;

      var offset = (i == 0 ? node.parent : variable).offset;
      var length = variable.end - offset;
      element.setCodeRange(offset, length);
    }
  }

  /// Builds the label elements associated with [labels] and stores them in the
  /// element holder.
  void _buildLabelElements(
      List<Label> labels, bool onSwitchStatement, bool onSwitchMember) {
    for (Label label in labels) {
      var labelName = label.label;
      var element = LabelElementImpl(
        labelName.name,
        labelName.offset,
        onSwitchStatement,
        onSwitchMember,
      );
      labelName.staticElement = element;
      _elementHolder.enclose(element);
    }
  }

  void _buildLocalElements(List<Statement> statements) {
    for (var statement in statements) {
      if (statement is FunctionDeclarationStatement) {
        _buildLocalFunctionElement(statement);
      } else if (statement is VariableDeclarationStatement) {
        _buildLocalVariableElements(statement.variables);
      }
    }
  }

  void _buildLocalFunctionElement(FunctionDeclarationStatement statement) {
    var node = statement.functionDeclaration;
    var nameNode = node.name;
    var element = FunctionElementImpl(nameNode.name, nameNode.offset);
    nameNode.staticElement = element;
    _define(element);
    _elementHolder.enclose(element);
  }

  void _buildLocalVariableElements(VariableDeclarationList variableList) {
    var isConst = variableList.isConst;
    var isFinal = variableList.isFinal;
    var isLate = variableList.isLate;
    for (var variable in variableList.variables) {
      var variableName = variable.name;

      LocalVariableElementImpl element;
      if (isConst && variable.initializer != null) {
        element = ConstLocalVariableElementImpl(
          variableName.name,
          variableName.offset,
        );
      } else {
        element = LocalVariableElementImpl(
          variableName.name,
          variableName.offset,
        );
      }
      variableName.staticElement = element;
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
  void _buildTypeParameterElements(TypeParameterList typeParameterList) {
    if (typeParameterList == null) return;

    for (var typeParameter in typeParameterList.typeParameters) {
      var name = typeParameter.name;

      TypeParameterElementImpl element;
      if (_elementWalker != null) {
        element = _elementWalker.getTypeParameter();
      } else {
        element = TypeParameterElementImpl(name.name, name.offset);
        _elementHolder.addTypeParameter(element);

        element.metadata = _createElementAnnotations(typeParameter.metadata);
        _setCodeRange(element, typeParameter);
      }
      name.staticElement = element;
      _define(element);
    }
  }

  /// For each [Annotation] found in [annotations], create a new
  /// [ElementAnnotation] object and set the [Annotation] to point to it.
  List<ElementAnnotation> _createElementAnnotations(
      List<Annotation> annotations) {
    if (annotations.isEmpty) {
      return const <ElementAnnotation>[];
    }
    return annotations.map((Annotation a) {
      var elementAnnotation = ElementAnnotationImpl(_unitElement);
      a.elementAnnotation = elementAnnotation;
      return elementAnnotation;
    }).toList();
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

  void _resolveImplementsClause(ImplementsClause clause) {
    if (clause == null) return;

    _resolveTypes(
      clause.interfaces,
      CompileTimeErrorCode.IMPLEMENTS_NON_CLASS,
    );
  }

  void _resolveOnClause(OnClause clause) {
    if (clause == null) return;

    _resolveTypes(
      clause.superclassConstraints,
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE,
    );
  }

  void _resolveRedirectedConstructor(ConstructorDeclaration node) {
    var redirectedConstructor = node.redirectedConstructor;
    if (redirectedConstructor == null) return;

    var typeName = redirectedConstructor.type;
    _typeNameResolver.redirectedConstructor_typeName = typeName;

    redirectedConstructor.accept(this);

    _typeNameResolver.redirectedConstructor_typeName = null;
  }

  /// Return the [InterfaceType] of the given [typeName].
  ///
  /// If the resulting type is not a valid interface type, return `null`.
  ///
  /// The flag [asClass] specifies if the type will be used as a class, so mixin
  /// declarations are not valid (they declare interfaces and mixins, but not
  /// classes).
  void _resolveType(TypeName typeName, ErrorCode errorCode,
      {bool asClass = false}) {
    _typeNameResolver.classHierarchy_typeName = typeName;
    visitTypeName(typeName);
    _typeNameResolver.classHierarchy_typeName = null;

    DartType type = typeName.type;
    if (type is InterfaceType) {
      ClassElement element = type.element;
      if (element.isEnum || element.isMixin && asClass) {
        _errorReporter.reportErrorForNode(errorCode, typeName);
        return;
      }
      return;
    }

    // If the type is not an InterfaceType, then visitTypeName() sets the type
    // to be a DynamicTypeImpl
    Identifier name = typeName.name;
    if (!_nameScope.shouldIgnoreUndefined(name)) {
      _errorReporter.reportErrorForNode(errorCode, name, [name.name]);
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
  void _resolveTypes(NodeList<TypeName> typeNames, ErrorCode errorCode) {
    for (TypeName typeName in typeNames) {
      _resolveType(typeName, errorCode);
    }
  }

  void _resolveWithClause(WithClause clause) {
    if (clause == null) return;

    for (var typeName in clause.mixinTypes) {
      _typeNameResolver.withClause_typeName = typeName;
      _resolveType(
        typeName,
        CompileTimeErrorCode.MIXIN_OF_NON_CLASS,
      );
      _typeNameResolver.withClause_typeName = null;
    }
  }

  void _setCodeRange(ElementImpl element, AstNode node) {
    element.setCodeRange(node.offset, node.length);
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
  void _withElementWalker(ElementWalker walker, void Function() f) {
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
      nodes[i].elementAnnotation = annotations[i];
    }
  }
}
