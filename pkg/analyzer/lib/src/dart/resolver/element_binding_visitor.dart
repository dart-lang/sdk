// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/generated/element_walker.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ElementBindingVisitor extends RecursiveAstVisitor<void> {
  final LibraryFragmentImpl _libraryFragment;
  final DiagnosticReporter? _errorReporter;

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

  ElementBindingVisitor.forAnalysis({
    required LibraryFragmentImpl fragment,
    required DiagnosticReporter reporter,
    required ElementWalker walker,
  }) : this._(fragment, reporter, walker);

  ElementBindingVisitor.forPartialResolution({
    required LibraryFragmentImpl fragment,
  }) : this._(fragment, null, null);

  ElementBindingVisitor._(
    this._libraryFragment,
    this._errorReporter,
    this._elementWalker,
  ) : _elementHolder = ElementHolder(_libraryFragment);

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
  void visitAnonymousMethodInvocation(
    covariant AnonymousMethodInvocationImpl node,
  ) {
    var fragment = LocalFunctionFragmentImpl(
      name: null,
      firstTokenOffset: node.offset,
    );

    _elementHolder.enclose(fragment);
    node.declaredFragment = fragment;
    fragment.hasImplicitReturnType = true;
    fragment.isAsynchronous = false;
    fragment.isGenerator = false;

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      super.visitAnonymousMethodInvocation(node);
      fragment.typeParameters = [];
      fragment.formalParameters = holder.formalParameters;
      for (var formalParameter in fragment.formalParameters) {
        formalParameter.initElement();
      }
    });

    fragment.setCodeRange(node.offset, node.length);
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

    _checkAndRewriteTypeParameters(
      firstTypeParameters: fragment.element.firstFragment.typeParameters,
      nameOrKeywordToken: node.namePart.typeName,
      typeParameterList: node.namePart.typeParameters,
    );

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

    _checkAndRewriteTypeParameters(
      firstTypeParameters: fragment.element.firstFragment.typeParameters,
      nameOrKeywordToken: node.namePart.typeName,
      typeParameterList: node.namePart.typeParameters,
    );

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

    _checkAndRewriteTypeParameters(
      firstTypeParameters: fragment.element.firstFragment.typeParameters,
      nameOrKeywordToken: node.name ?? node.extensionKeyword,
      typeParameterList: node.typeParameters,
    );

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

    _checkAndRewriteTypeParameters(
      firstTypeParameters: fragment.element.firstFragment.typeParameters,
      nameOrKeywordToken: node.primaryConstructor.typeName,
      typeParameterList: node.primaryConstructor.typeParameters,
    );

    _withElementWalker(ElementWalker.forExtensionType(fragment), () {
      super.visitExtensionTypeDeclaration(node);
    });
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    var nameToken = node.name;
    _visitFormalParameter(node, () {
      return FieldFormalParameterFragmentImpl(
        firstTokenOffset: node.offset,
        name: nameToken.nameIfNotEmpty,
        nameOffset: nameToken.offsetIfNotEmpty,
        parameterKind: node.kind,
        privateName: null,
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

      if (_elementWalker != null) {
        _checkAndRewriteTypeParameters(
          firstTypeParameters: fragment.element.firstFragment.typeParameters,
          nameOrKeywordToken: node.name,
          typeParameterList: node.functionExpression.typeParameters,
        );

        _withElementWalker(ElementWalker.forExecutable(fragment), () {
          node.functionExpression.typeParameters?.accept(this);
          node.functionExpression.parameters?.accept(this);
        });

        _withElementWalker(null, () {
          node.functionExpression.body.accept(this);
        });
      } else {
        node.functionExpression.typeParameters?.accept(this);
        fragment.typeParameters = holder.typeParameters;
        for (var typeParameter in fragment.typeParameters) {
          TypeParameterElementImpl(firstFragment: typeParameter);
        }

        node.functionExpression.parameters?.accept(this);
        fragment.formalParameters = holder.formalParameters;
        for (var formalParameter in fragment.formalParameters) {
          formalParameter.initElement();
        }

        node.functionExpression.body.accept(this);
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
      node.typeParameters?.accept(this);
      fragment.typeParameters = holder.typeParameters;
      for (var typeParameter in fragment.typeParameters) {
        TypeParameterElementImpl(firstFragment: typeParameter);
      }

      node.parameters?.accept(this);
      fragment.formalParameters = holder.formalParameters;
      for (var formalParameter in fragment.formalParameters) {
        formalParameter.initElement();
      }

      node.body.accept(this);
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
          for (var formalParameter in holder.formalParameters) {
            formalParameter.initElement();
          }
        });
      });
    });
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var fragment = GenericFunctionTypeFragmentImpl(
      firstTokenOffset: node.offset,
    );
    _libraryFragment.encloseElement(fragment);
    node.declaredFragment = fragment;

    fragment.isNullable = node.question != null;

    fragment.setCodeRange(node.offset, node.length);

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _withElementWalker(null, () {
        super.visitGenericFunctionType(node);
        fragment.typeParameters = holder.typeParameters;
        fragment.formalParameters = holder.formalParameters;
        GenericFunctionTypeElementImpl(fragment);
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
  void visitLabeledStatement(covariant LabeledStatementImpl node) {
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

    _checkAndRewriteTypeParameters(
      firstTypeParameters: fragment.element.firstFragment.typeParameters,
      nameOrKeywordToken: node.name,
      typeParameterList: node.typeParameters,
    );

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

    _checkAndRewriteTypeParameters(
      firstTypeParameters: fragment.element.firstFragment.typeParameters,
      nameOrKeywordToken: node.name,
      typeParameterList: node.typeParameters,
    );

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
  void visitPartOfDirective(covariant PartOfDirectiveImpl node) {
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
  void visitRegularFormalParameter(covariant RegularFormalParameterImpl node) {
    var nameToken = node.name;
    _visitFormalParameter(node, () {
      var fragment = FormalParameterFragmentImpl(
        firstTokenOffset: node.offset,
        name: nameToken?.nameIfNotEmpty,
        nameOffset: nameToken?.offsetIfNotEmpty,
        parameterKind: node.kind,
      );
      if (node.type == null && node.functionTypedSuffix == null) {
        fragment.hasImplicitType = true;
      }
      return fragment;
    });
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    var nameToken = node.name;
    _visitFormalParameter(node, () {
      return SuperFormalParameterFragmentImpl(
        firstTokenOffset: node.offset,
        name: nameToken.nameIfNotEmpty,
        nameOffset: nameToken.offsetIfNotEmpty,
        parameterKind: node.kind,
      );
    });
  }

  @override
  void visitSwitchStatement(covariant SwitchStatementImpl node) {
    for (var member in node.members) {
      _buildLabelElements(member.labels, true);
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
    var variableList = node.parent as VariableDeclarationListImpl;
    var declarationParent = variableList.parent!;

    VariableFragmentImpl fragment;
    if (_elementWalker != null) {
      fragment = _elementWalker!.getVariable();
    } else {
      var localFragment = LocalVariableFragmentImpl(
        name: node.name.nameIfNotEmpty,
        firstTokenOffset: node.offset,
      );
      fragment = localFragment;
      _elementHolder.enclose(fragment);

      localFragment.hasImplicitType = variableList.type == null;
      localFragment.hasInitializer = node.initializer != null;
      localFragment.isConst = variableList.isConst;
      localFragment.isFinal = variableList.isFinal;
      localFragment.isLate = variableList.isLate;
      localFragment.nameOffset = node.name.offsetIfNotEmpty;
    }
    node.declaredFragment = fragment;

    var annotations = switch (declarationParent) {
      FieldDeclarationImpl() => declarationParent.metadata,
      TopLevelVariableDeclarationImpl() => declarationParent.metadata,
      _ => variableList.metadata,
    };
    _setOrCreateMetadataElements(fragment, annotations);

    var offset = node == variableList.variables.first
        ? declarationParent.offset
        : node.offset;
    fragment.setCodeRange(offset, node.end - offset);

    _withElementWalker(null, () {
      _withElementHolder(ElementHolder(fragment), () {
        super.visitVariableDeclaration(node);
      });
    });
  }

  /// Builds the label elements associated with [labels] and stores them in the
  /// element holder.
  void _buildLabelElements(List<LabelImpl> labels, bool onSwitchMember) {
    for (var label in labels) {
      var fragment = LabelFragmentImpl(
        name: label.name.lexeme,
        firstTokenOffset: label.offset,
        onSwitchMember: onSwitchMember,
      );
      label.declaredFragment = fragment;
      _elementHolder.enclose(fragment);
    }
  }

  /// Checks that the number of type parameters in [typeParameterList] matches
  /// the number of [firstTypeParameters] for this declaration.
  ///
  /// The number of fragments in [firstTypeParameters] is equal to the
  /// number of type parameters in the introductory declaration.
  ///
  /// If they don't match, reports [diag.augmentationTypeParameterCount].
  ///
  /// If the augmentation has more type parameters, the extra ones are excised
  /// from the AST and token stream, and added to the compilation unit's
  /// `invalidNodes`.
  void _checkAndRewriteTypeParameters({
    required List<TypeParameterFragmentImpl> firstTypeParameters,
    required Token nameOrKeywordToken,
    required TypeParameterListImpl? typeParameterList,
  }) {
    var introductoryCount = firstTypeParameters
        .takeWhile((p) => !p.isOriginOtherFragmentOfEnclosing)
        .length;

    // If no type parameter nodes, but introductory has type parameters.
    if (typeParameterList == null) {
      if (introductoryCount != 0) {
        _errorReporter?.atToken(
          nameOrKeywordToken,
          diag.augmentationTypeParameterCount,
        );
      }
      return;
    }

    // If the number of type parameters does not match, it is an error.
    if (typeParameterList.typeParameters.length > introductoryCount) {
      _errorReporter?.atToken(
        typeParameterList.typeParameters[introductoryCount].name,
        diag.augmentationTypeParameterCount,
      );
    } else if (typeParameterList.typeParameters.length < introductoryCount) {
      _errorReporter?.atToken(
        typeParameterList.rightBracket,
        diag.augmentationTypeParameterCount,
      );
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

  void _visitFormalParameter<T extends FormalParameterFragmentImpl>(
    FormalParameterImpl node,
    T Function() createFragment,
  ) {
    T fragment;
    if (_elementWalker != null) {
      fragment = _elementWalker!.getParameter() as T;
    } else {
      fragment = createFragment();
      _elementHolder.addParameter(fragment);

      fragment.setCodeRange(node.offset, node.length);
      fragment.isConst = node.isConst;
      fragment.isExplicitlyCovariant = node.covariantKeyword != null;
      fragment.isFinal = node.isFinal;
    }
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    var functionTypedSuffix = node.functionTypedSuffix;
    if (functionTypedSuffix != null) {
      var holder = ElementHolder(fragment);
      _withElementHolder(holder, () {
        _withElementWalker(
          _elementWalker != null ? ElementWalker.forParameter(fragment) : null,
          () {
            node.documentationComment?.accept(this);
            node.type?.accept(this);
            functionTypedSuffix.typeParameters?.accept(this);
            functionTypedSuffix.formalParameters.accept(this);
          },
        );
      });
      if (_elementWalker == null) {
        fragment.typeParameters = holder.typeParameters;
        fragment.formalParameters = holder.formalParameters;
      }
    } else {
      node.documentationComment?.accept(this);
      node.type?.accept(this);
    }

    if (node.defaultClause case var defaultClause?) {
      if (_elementWalker == null) {
        fragment.constantInitializer = defaultClause.value;
      }

      _withElementWalker(null, () {
        _withElementHolder(ElementHolder(fragment), () {
          defaultClause.value.accept(this);
        });
      });
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
