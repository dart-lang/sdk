// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/element_walker.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ElementBindingVisitor extends RecursiveAstVisitor<void> {
  final LibraryFragmentImpl _libraryFragment;

  /// This index is incremented every time we visit a [LibraryDirective].
  /// There is just one [LibraryElement], so we can support only one node.
  int _libraryDirectiveIndex = 0;

  /// The provider of pre-built children elements from the element being
  /// visited. For example when we visit a method, its element is resynthesized
  /// from the summary, and we get resynthesized elements for type parameters
  /// and formal parameters to apply to corresponding AST nodes.
  ElementWalker? _elementWalker;

  /// The container to add newly created elements that should be put into the
  /// enclosing element.
  ElementHolder _elementHolder;

  ElementBindingVisitor(this._libraryFragment, this._elementWalker)
    : _elementHolder = ElementHolder(_libraryFragment);

  void bindSubtree(FragmentImpl enclosingFragment, AstNode node) {
    _withElementHolder(ElementHolder(enclosingFragment), () {
      node.accept(this);
    });
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    if (node.elementAnnotation == null && _elementWalker == null) {
      ElementAnnotationImpl(_libraryFragment, node);
    }
    _withElementWalker(null, () {
      super.visitAnnotation(node);
    });
  }

  @override
  void visitCatchClause(covariant CatchClauseImpl node) {
    _withElementWalker(null, () {
      var exceptionNode = node.exceptionParameter;
      if (exceptionNode != null) {
        var fragment = LocalVariableFragmentImpl(
          name: exceptionNode.name.nameIfNotEmpty,
          firstTokenOffset: exceptionNode.offset,
        );
        fragment.nameOffset = exceptionNode.name.offsetIfNotEmpty;
        _elementHolder.enclose(fragment);

        exceptionNode.declaredFragment = fragment;

        fragment.isFinal = true;
        if (node.exceptionType == null) {
          fragment.hasImplicitType = true;
        } else {
          // We don't resolve the type here, this will be done in the
          // resolver phase.
        }

        fragment.setCodeRange(
          exceptionNode.name.offset,
          exceptionNode.name.length,
        );
      }

      var stackTraceNode = node.stackTraceParameter;
      if (stackTraceNode != null) {
        var fragment = LocalVariableFragmentImpl(
          name: stackTraceNode.name.nameIfNotEmpty,
          firstTokenOffset: stackTraceNode.offset,
        );
        fragment.nameOffset = stackTraceNode.name.offsetIfNotEmpty;
        _elementHolder.enclose(fragment);

        stackTraceNode.declaredFragment = fragment;

        fragment.isFinal = true;
        fragment.hasImplicitType = true;

        fragment.setCodeRange(
          stackTraceNode.name.offset,
          stackTraceNode.name.length,
        );
      }

      super.visitCatchClause(node);
    });
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var fragment = _elementWalker!.getClass();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forClass(fragment), () {
      super.visitClassDeclaration(node);
    });
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    ClassFragmentImpl fragment = _elementWalker!.getClass();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forClass(fragment), () {
      super.visitClassTypeAlias(node);
    });
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var fragment = _elementWalker!.getConstructor();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementHolder(ElementHolder(fragment), () {
      _withElementWalker(null, () {
        node.typeName?.accept(this);

        _withElementWalker(ElementWalker.forExecutable(fragment), () {
          node.parameters.accept(this);
        });

        node.initializers.accept(this);
        node.redirectedConstructor?.accept(this);
        node.body.accept(this);
      });
    });
  }

  @override
  void visitDeclaredIdentifier(covariant DeclaredIdentifierImpl node) {
    var nameToken = node.name;
    var fragment = LocalVariableFragmentImpl(
      name: nameToken.nameIfNotEmpty,
      firstTokenOffset: node.offset,
    );
    fragment.nameOffset = nameToken.offsetIfNotEmpty;
    node.declaredFragment = fragment;
    _elementHolder.enclose(fragment);

    _setOrCreateMetadataElements(fragment, node.metadata);

    fragment.isConst = node.isConst;
    fragment.isFinal = node.isFinal;

    if (node.type == null) {
      fragment.hasImplicitType = true;
    }

    fragment.setCodeRange(node.offset, node.length);

    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(
    covariant DeclaredVariablePatternImpl node,
  ) {
    if (_elementWalker != null) {
      // We don't verify / emulate local variables in walkers.
    } else {
      var nameToken = node.name;
      var fragment = BindPatternVariableFragmentImpl(
        node: node,
        name: nameToken.lexeme,
        firstTokenOffset: node.offset,
      );
      fragment.nameOffset = nameToken.offset;
      node.declaredFragment = fragment;
      _elementHolder.enclose(fragment);

      fragment.isFinal = node.keyword?.keyword == Keyword.FINAL;
      fragment.setCodeRange(node.name.offset, node.name.length);
    }

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    var normalParameter = node.parameter;

    normalParameter.accept(this);

    var fragment =
        normalParameter.declaredFragment as FormalParameterFragmentImpl;
    node.declaredFragment = fragment;

    var defaultValue = node.defaultValue;
    if (_elementWalker == null) {
      fragment.constantInitializer = defaultValue;
      fragment.setCodeRange(node.offset, node.length);
    }

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
    var fragment = _elementWalker!.getVariable() as FieldFragmentImpl;
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    var arguments = node.arguments;
    if (arguments != null) {
      _withElementWalker(null, () {
        _withElementHolder(ElementHolder(fragment), () {
          arguments.accept(this);
        });
      });
    }
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var fragment = _elementWalker!.getEnum();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forEnum(fragment), () {
      super.visitEnumDeclaration(node);
    });
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
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forExtension(fragment), () {
      super.visitExtensionDeclaration(node);
    });
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var fragment = _elementWalker!.getExtensionType();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forExtensionType(fragment), () {
      super.visitExtensionTypeDeclaration(node);
    });
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    var nameToken = node.name;

    FormalParameterFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment =
          _elementWalker!.getParameter() as FieldFormalParameterFragmentImpl;
    } else {
      // Only for recovery, this should not happen in valid code.
      fragment = FieldFormalParameterFragmentImpl(
        firstTokenOffset: node.offset,
        name: nameToken.nameIfNotEmpty,
        nameOffset: nameToken.offsetIfNotEmpty,
        parameterKind: node.kind,
        privateName: null,
      );
      _elementHolder.addParameter(fragment);
      fragment.isConst = node.isConst;
      fragment.isExplicitlyCovariant = node.covariantKeyword != null;
      fragment.isFinal = node.isFinal;
      fragment.setCodeRange(node.offset, node.length);
    }
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementHolder(ElementHolder(fragment), () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forParameter(fragment) : null,
        () {
          super.visitFieldFormalParameter(node);
        },
      );
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

      fragment.setCodeRange(node.offset, node.length);

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
      node.returnType?.accept(this);
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forExecutable(fragment) : null,
        () {
          node.functionExpression.typeParameters?.accept(this);
          node.functionExpression.parameters?.accept(this);
        },
      );

      _withElementWalker(null, () {
        node.functionExpression.body.accept(this);
      });

      if (_elementWalker == null) {
        fragment.typeParameters = holder.typeParameters;
        fragment.formalParameters = holder.formalParameters;
      }
    });
  }

  @override
  void visitFunctionDeclarationStatement(
    covariant FunctionDeclarationStatementImpl node,
  ) {
    var functionNode = node.functionDeclaration;
    var nameToken = functionNode.name;

    var fragment = LocalFunctionFragmentImpl(
      name: nameToken.nameIfNotEmpty,
      firstTokenOffset: node.offset,
    );
    fragment.nameOffset = nameToken.offsetIfNotEmpty;
    functionNode.declaredFragment = fragment;
    functionNode.functionExpression.declaredFragment = fragment;

    _elementHolder.enclose(fragment);

    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node) {
    if (node.parent is FunctionDeclaration) {
      // Handled in visitFunctionDeclaration
      super.visitFunctionExpression(node);
      return;
    }

    var fragment = LocalFunctionFragmentImpl(
      name: null,
      firstTokenOffset: node.offset,
    );

    _elementHolder.enclose(fragment);
    node.declaredFragment = fragment;

    fragment.hasImplicitReturnType = true;

    FunctionBody body = node.body;
    fragment.isAsynchronous = body.isAsynchronous;
    fragment.isGenerator = body.isGenerator;

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      super.visitFunctionExpression(node);
      fragment.typeParameters = holder.typeParameters;
      fragment.formalParameters = holder.formalParameters;
    });

    fragment.setCodeRange(node.offset, node.length);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var fragment = _elementWalker!.getTypedef();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _withElementWalker(ElementWalker.forTypedef(fragment), () {
        node.typeParameters?.accept(this);

        _withElementWalker(null, () {
          node.returnType?.accept(this);
          node.parameters.accept(this);
          fragment.encloseElements(holder.formalParameters);
        });
      });
    });
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var nameToken = node.name;

    FormalParameterFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment = _elementWalker!.getParameter();
    } else {
      fragment = FormalParameterFragmentImpl(
        firstTokenOffset: node.offset,
        name: nameToken.nameIfNotEmpty,
        nameOffset: nameToken.offsetIfNotEmpty,
        parameterKind: node.kind,
      );
      _elementHolder.addParameter(fragment);
      fragment.isConst = node.isConst;
      fragment.isExplicitlyCovariant = node.covariantKeyword != null;
      fragment.isFinal = node.isFinal;
      fragment.setCodeRange(node.offset, node.length);
    }
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forParameter(fragment) : null,
        () {
          super.visitFunctionTypedFormalParameter(node);

          if (_elementWalker == null) {
            fragment.typeParameters = holder.typeParameters;
            fragment.formalParameters = holder.formalParameters;
          }
        },
      );
    });
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var fragment = GenericFunctionTypeFragmentImpl(
      firstTokenOffset: node.offset,
    );
    _libraryFragment.encloseElement(fragment);
    (node as GenericFunctionTypeImpl).declaredFragment = fragment;

    fragment.isNullable = node.question != null;

    fragment.setCodeRange(node.offset, node.length);

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _withElementWalker(null, () {
        super.visitGenericFunctionType(node);
        fragment.typeParameters = holder.typeParameters;
        fragment.formalParameters = holder.formalParameters;
      });
    });
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var fragment = _elementWalker!.getTypedef();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forGenericTypeAlias(fragment), () {
      super.visitGenericTypeAlias(node);
    });
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
  void visitLabeledStatement(LabeledStatement node) {
    _buildLabelElements(node.labels, false);
    super.visitLabeledStatement(node);
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
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    ExecutableFragmentImpl fragment;
    if (node.isGetter) {
      fragment = _elementWalker!.getGetter();
    } else if (node.isSetter) {
      fragment = _elementWalker!.getSetter();
    } else {
      fragment = _elementWalker!.getFunction();
    }
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    node.returnType?.accept(this);
    _withElementWalker(ElementWalker.forExecutable(fragment), () {
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
    });

    _withElementHolder(ElementHolder(fragment), () {
      _withElementWalker(null, () {
        node.body.accept(this);
      });
    });
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var fragment = _elementWalker!.getMixin();
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementWalker(ElementWalker.forMixin(fragment), () {
      super.visitMixinDeclaration(node);
    });
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
  void visitPrimaryConstructorBody(covariant PrimaryConstructorBodyImpl node) {
    if (node.declaration case var declaration?) {
      var fragment = declaration.declaredFragment!;
      _withElementHolder(ElementHolder(fragment), () {
        _withElementWalker(null, () {
          super.visitPrimaryConstructorBody(node);
        });
      });
    } else {
      _withElementWalker(null, () {
        super.visitPrimaryConstructorBody(node);
      });
    }
  }

  @override
  void visitPrimaryConstructorDeclaration(
    covariant PrimaryConstructorDeclarationImpl node,
  ) {
    var fragment = _elementWalker!.getConstructor();
    node.declaredFragment = fragment;

    _withElementHolder(ElementHolder(fragment), () {
      _withElementWalker(ElementWalker.forExecutable(fragment), () {
        node.formalParameters.accept(this);
      });
    });

    node.typeParameters?.accept(this);
  }

  @override
  void visitRecordTypeAnnotation(covariant RecordTypeAnnotationImpl node) {
    _withElementWalker(null, () {
      super.visitRecordTypeAnnotation(node);
    });
  }

  @override
  void visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    var nameToken = node.name;

    FormalParameterFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment = _elementWalker!.getParameter();
    } else {
      fragment = FormalParameterFragmentImpl(
        firstTokenOffset: node.offset,
        name: nameToken?.nameIfNotEmpty,
        nameOffset: nameToken?.offsetIfNotEmpty,
        parameterKind: node.kind,
      );
      _elementHolder.addParameter(fragment);

      fragment.setCodeRange(node.offset, node.length);
      fragment.isConst = node.isConst;
      fragment.isExplicitlyCovariant = node.covariantKeyword != null;
      fragment.isFinal = node.isFinal;
      if (node.type == null) {
        fragment.hasImplicitType = true;
      }
    }
    node.declaredFragment = fragment;

    super.visitSimpleFormalParameter(node);

    _setOrCreateMetadataElements(fragment, node.metadata);
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    var nameToken = node.name;

    SuperFormalParameterFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment =
          _elementWalker!.getParameter() as SuperFormalParameterFragmentImpl;
    } else {
      // Only for recovery, this should not happen in valid code.
      fragment = SuperFormalParameterFragmentImpl(
        firstTokenOffset: node.offset,
        name: nameToken.nameIfNotEmpty,
        nameOffset: nameToken.offsetIfNotEmpty,
        parameterKind: node.kind,
      );
      _elementHolder.addParameter(fragment);
      fragment.isConst = node.isConst;
      fragment.isExplicitlyCovariant = node.covariantKeyword != null;
      fragment.isFinal = node.isFinal;
      fragment.setCodeRange(node.offset, node.length);
    }
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    _withElementHolder(ElementHolder(fragment), () {
      _withElementWalker(
        _elementWalker != null ? ElementWalker.forParameter(fragment) : null,
        () {
          super.visitSuperFormalParameter(node);
        },
      );
    });
  }

  @override
  void visitSwitchStatement(covariant SwitchStatementImpl node) {
    for (var group in node.memberGroups) {
      for (var member in group.members) {
        _buildLabelElements(member.labels, true);
      }
    }
    super.visitSwitchStatement(node);
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var name = node.name;

    TypeParameterFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment = _elementWalker!.getTypeParameter();
    } else {
      fragment = TypeParameterFragmentImpl(
        name: name.lexeme,
        firstTokenOffset: node.offset,
      );
      fragment.nameOffset = name.offset;
      _elementHolder.addTypeParameter(fragment);

      fragment.setCodeRange(node.offset, node.length);
    }
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    VariableFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment = _elementWalker!.getVariable();
      node.declaredFragment = fragment;
    } else {
      var localFragment = LocalVariableFragmentImpl(
        name: node.name.nameIfNotEmpty,
        firstTokenOffset: node.offset,
      );
      fragment = localFragment;
      localFragment.nameOffset = node.name.offsetIfNotEmpty;
      node.declaredFragment = fragment;
      _elementHolder.enclose(fragment);

      var varList = node.parent as VariableDeclarationListImpl;
      localFragment.hasInitializer = node.initializer != null;
      if (varList.type == null) {
        localFragment.hasImplicitType = true;
      }
    }

    _withElementWalker(null, () {
      _withElementHolder(ElementHolder(fragment), () {
        super.visitVariableDeclaration(node);
      });
    });
  }

  @override
  void visitVariableDeclarationList(
    covariant VariableDeclarationListImpl node,
  ) {
    super.visitVariableDeclarationList(node);

    for (var i = 0; i < node.variables.length; i++) {
      var variable = node.variables[i];
      var fragment = variable.declaredFragment!;

      NodeList<AnnotationImpl> annotations;
      var parent = node.parent;
      if (parent is FieldDeclarationImpl) {
        annotations = parent.metadata;
      } else if (parent is TopLevelVariableDeclarationImpl) {
        annotations = parent.metadata;
      } else {
        annotations = node.metadata;
      }

      _setOrCreateMetadataElements(fragment, annotations);

      var offset = (i == 0 ? node.parent! : variable).offset;
      var length = variable.end - offset;
      fragment.setCodeRange(offset, length);

      if (fragment is LocalVariableFragmentImpl) {
        fragment.isConst = node.isConst;
        fragment.isFinal = node.isFinal;
        fragment.isLate = node.isLate;
      }
    }
  }

  /// Builds the label elements associated with [labels] and stores them in the
  /// element holder.
  void _buildLabelElements(List<Label> labels, bool onSwitchMember) {
    for (var label in labels) {
      label as LabelImpl;
      var labelName = label.label;
      var fragment = LabelFragmentImpl(
        name: labelName.name,
        firstTokenOffset: label.offset,
        onSwitchMember: onSwitchMember,
      );
      labelName.element = fragment.element;
      _elementHolder.enclose(fragment);
    }
  }

  /// Associate [annotations] with `element`.
  /// If `element` is generic, we can reuse it.
  /// If `element` is not generic, we create new `ElementAnnotation`s.
  void _setOrCreateMetadataElements(
    FragmentImpl fragment,
    List<AnnotationImpl> annotations,
  ) {
    if (annotations.isEmpty) {
      return;
    }

    var metadata = fragment.metadata;
    if (metadata.annotations.isNotEmpty &&
        metadata.annotations.length == annotations.length) {
      _setElementAnnotations(annotations, metadata.annotations);
    }

    _withElementWalker(null, () {
      for (var node in annotations) {
        node.accept(this);
      }
    });

    if (_elementWalker == null) {
      fragment.metadata = MetadataImpl(
        annotations.map((a) => a.elementAnnotation!).toList(),
      );
    }
  }

  void _withElementHolder(ElementHolder holder, void Function() f) {
    var previous = _elementHolder;
    _elementHolder = holder;
    try {
      f();
    } finally {
      _elementHolder = previous;
    }
  }

  void _withElementWalker(ElementWalker? walker, void Function() f) {
    var current = _elementWalker;
    try {
      _elementWalker = walker;
      f();
    } finally {
      _elementWalker = current;
    }
  }

  /// Associate each of the annotation [nodes] with the corresponding
  /// [ElementAnnotation] in [annotations].
  static void _setElementAnnotations(
    List<AnnotationImpl> nodes,
    List<ElementAnnotationImpl> annotations,
  ) {
    int nodeCount = nodes.length;
    if (nodeCount != annotations.length) {
      return;
    }
    for (int i = 0; i < nodeCount; i++) {
      nodes[i].elementAnnotation = annotations[i];
    }
  }
}

class ElementHolder {
  final FragmentImpl _fragment;
  final List<TypeParameterFragmentImpl> _typeParameters = [];
  final List<FormalParameterFragmentImpl> _formalParameters = [];

  ElementHolder(this._fragment);

  List<FormalParameterFragmentImpl> get formalParameters {
    return _formalParameters.toFixedList();
  }

  List<TypeParameterFragmentImpl> get typeParameters {
    return _typeParameters.toFixedList();
  }

  void addParameter(FormalParameterFragmentImpl fragment) {
    _formalParameters.add(fragment);
  }

  void addTypeParameter(TypeParameterFragmentImpl fragment) {
    _typeParameters.add(fragment);
  }

  void enclose(FragmentImpl fragment) {
    fragment.enclosingFragment = _fragment;
  }
}

extension on Token {
  String? get nameIfNotEmpty => lexeme.isNotEmpty ? lexeme : null;

  int? get offsetIfNotEmpty => lexeme.isNotEmpty ? offset : null;
}
