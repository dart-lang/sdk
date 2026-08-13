// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ElementBindingVisitor extends RecursiveAstVisitor2<void> {
  final LibraryFragmentImpl _libraryFragment;

  /// This index is incremented every time we visit a [LibraryDirective].
  /// There is just one [LibraryElement], so we can support only one node.
  int _libraryDirectiveIndex = 0;

  /// The container to add newly created elements that should be put into the
  /// enclosing element.
  ElementHolder _elementHolder;

  ElementBindingVisitor(this._libraryFragment)
    : _elementHolder = ElementHolder(_libraryFragment);

  void bindSubtree(FragmentImpl enclosingFragment, AstNode node) {
    _withElementHolder(ElementHolder(enclosingFragment), () {
      node.accept2(this);
    });
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    if (node.elementAnnotation == null) {
      ElementAnnotationImpl(_libraryFragment, node);
    }
    super.visitAnnotation(node);
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
  }

  @override
  void visitCompilationUnit(covariant CompilationUnitImpl node) {
    node.directives.accept2(this);

    int classIndex = 0;
    int enumIndex = 0;
    int extensionIndex = 0;
    int extensionTypeIndex = 0;
    int functionIndex = 0;
    int getterIndex = 0;
    int setterIndex = 0;
    int mixinIndex = 0;
    int typedefIndex = 0;
    int variableIndex = 0;

    var getters = _libraryFragment.getters
        .where((f) => f.isOriginDeclaration)
        .toList();
    var setters = _libraryFragment.setters
        .where((f) => f.isOriginDeclaration)
        .toList();
    var variables = _libraryFragment.topLevelVariables
        .where((f) => f.isOriginDeclaration)
        .toList();

    for (var declaration in node.declarations) {
      switch (declaration) {
        case ClassDeclarationImpl():
          _bindClassDeclaration(
            declaration,
            _libraryFragment.classes[classIndex++],
          );
        case ClassTypeAliasImpl():
          _bindClassTypeAlias(
            declaration,
            _libraryFragment.classes[classIndex++],
          );
        case EnumDeclarationImpl():
          _bindEnumDeclaration(
            declaration,
            _libraryFragment.enums[enumIndex++],
          );
        case ExtensionDeclarationImpl():
          _bindExtensionDeclaration(
            declaration,
            _libraryFragment.extensions[extensionIndex++],
          );
        case ExtensionTypeDeclarationImpl():
          _bindExtensionTypeDeclaration(
            declaration,
            _libraryFragment.extensionTypes[extensionTypeIndex++],
          );
        case FunctionDeclarationImpl():
          ExecutableFragmentImpl fragment;
          if (declaration.isGetter) {
            fragment = getters[getterIndex++];
          } else if (declaration.isSetter) {
            fragment = setters[setterIndex++];
          } else {
            fragment = _libraryFragment.functions[functionIndex++];
          }
          _bindFunctionDeclaration(declaration, fragment);
        case MixinDeclarationImpl():
          _bindMixinDeclaration(
            declaration,
            _libraryFragment.mixins[mixinIndex++],
          );
        case FunctionTypeAliasImpl():
          _bindFunctionTypeAlias(
            declaration,
            _libraryFragment.typeAliases[typedefIndex++],
          );
        case GenericTypeAliasImpl():
          _bindGenericTypeAlias(
            declaration,
            _libraryFragment.typeAliases[typedefIndex++],
          );
        case TopLevelVariableDeclarationImpl():
          declaration.documentationComment?.accept2(this);
          declaration.variables.type?.accept2(this);
          for (var variable in declaration.variables.variables) {
            _bindTopLevelVariable(
              variable,
              variables[variableIndex++],
              declaration,
            );
          }
      }
    }
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

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var element = node.libraryExport;
    if (element != null) {
      _setElementAnnotations(node.metadata, element.metadata.annotations);
    }
    super.visitExportDirective(node);
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
    var fragment = node.declaredFragment as LocalFunctionFragmentImpl;

    fragment.setCodeRange(node.offset, node.length);

    var body = expression.body;
    if (node.externalKeyword != null || body is NativeFunctionBody) {
      fragment.isExternal = true;
    }

    fragment.isComplete = node.isComplete;
    fragment.isAsynchronous = body.isAsynchronous;
    fragment.isGenerator = body.isGenerator;
    if (node.returnType == null) {
      fragment.hasImplicitReturnType = true;
    }

    _setOrCreateMetadataElements(fragment, node.metadata);

    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      node.returnType?.accept2(this);

      expression.typeParameters?.accept2(this);
      fragment.typeParameters = holder.typeParameters;
      for (var typeParameter in fragment.typeParameters) {
        TypeParameterElementImpl(firstFragment: typeParameter);
      }

      expression.parameters?.accept2(this);
      fragment.formalParameters = holder.formalParameters;
      for (var formalParameter in fragment.formalParameters) {
        formalParameter.initElement();
      }

      expression.body.accept2(this);
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
    if (node.parent2 is FunctionDeclaration) {
      // Handled in visitFunctionDeclaration / _bindFunctionDeclaration
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
      node.typeParameters?.accept2(this);
      fragment.typeParameters = holder.typeParameters;
      for (var typeParameter in fragment.typeParameters) {
        TypeParameterElementImpl(firstFragment: typeParameter);
      }

      node.parameters?.accept2(this);
      fragment.formalParameters = holder.formalParameters;
      for (var formalParameter in fragment.formalParameters) {
        formalParameter.initElement();
      }

      node.body.accept2(this);
    });

    fragment.setCodeRange(node.offset, node.length);
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
      super.visitGenericFunctionType(node);
      fragment.typeParameters = holder.typeParameters;
      fragment.formalParameters = holder.formalParameters;
      GenericFunctionTypeElementImpl(fragment);
    });
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
    super.visitLibraryDirective(node);
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
  void visitPrimaryConstructorBody(covariant PrimaryConstructorBodyImpl node) {
    if (node.declaration case var declaration?) {
      var fragment = declaration.declaredFragment!;
      _withElementHolder(ElementHolder(fragment), () {
        super.visitPrimaryConstructorBody(node);
      });
    } else {
      super.visitPrimaryConstructorBody(node);
    }
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

    var fragment = TypeParameterFragmentImpl(
      name: name.lexeme,
      firstTokenOffset: node.offset,
    );
    fragment.nameOffset = name.offset;
    _elementHolder.addTypeParameter(fragment);

    fragment.setCodeRange(node.offset, node.length);
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    var variableList = node.parent2 as VariableDeclarationListImpl;
    var declarationParent = variableList.parent2!;

    var fragment = LocalVariableFragmentImpl(
      name: node.name.nameIfNotEmpty,
      firstTokenOffset: node.offset,
    );
    _elementHolder.enclose(fragment);

    fragment.hasImplicitType = variableList.type == null;
    fragment.hasInitializer = node.initializer2 != null;
    fragment.isConst = variableList.isConst;
    fragment.isFinal = variableList.isFinal;
    fragment.isLate = variableList.isLate;
    fragment.nameOffset = node.name.offsetIfNotEmpty;
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, variableList.metadata);

    var offset = node == variableList.variables.first
        ? declarationParent.offset
        : node.offset;
    fragment.setCodeRange(offset, node.end - offset);

    _withElementHolder(ElementHolder(fragment), () {
      super.visitVariableDeclaration(node);
    });
  }

  void _bindClassDeclaration(
    ClassDeclarationImpl node,
    ClassFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    var memberFragments = _ContainerMemberFragments(
      constructors: fragment.constructors
          .where((f) => f.isOriginDeclaration)
          .toList(),
      fields: fragment.fields.where((f) => f.isOriginDeclaration).toList(),
      getters: fragment.getters.where((f) => f.isOriginDeclaration).toList(),
      setters: fragment.setters.where((f) => f.isOriginDeclaration).toList(),
      methods: fragment.methods,
    );

    node.documentationComment?.accept2(this);
    var namePart = node.namePart;
    _bindTypeParameters(namePart.typeParameters, fragment.typeParameters);
    if (namePart is PrimaryConstructorDeclarationImpl) {
      var constructorFragment = memberFragments.nextConstructor();
      namePart.declaredFragment = constructorFragment;
      _bindFormalParameters(
        namePart.formalParameters,
        constructorFragment.formalParameters,
      );
    }

    node.extendsClause?.accept2(this);
    node.withClause?.accept2(this);
    node.implementsClause?.accept2(this);
    node.nativeClause?.accept2(this);

    _bindMembers(node.body.members, memberFragments);
  }

  void _bindClassTypeAlias(
    ClassTypeAliasImpl node,
    ClassFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    node.documentationComment?.accept2(this);
    _bindTypeParameters(node.typeParameters, fragment.typeParameters);
    node.superclass.accept2(this);
    node.withClause.accept2(this);
    node.implementsClause?.accept2(this);
  }

  void _bindConstructorDeclaration(
    ConstructorDeclarationImpl node,
    ConstructorFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    node.documentationComment?.accept2(this);
    _bindFormalParameters(node.parameters, fragment.formalParameters);

    _withElementHolder(ElementHolder(fragment), () {
      for (var initializer in node.initializers) {
        initializer.accept2(this);
      }
      node.factoryRedirectionTarget?.accept2(this);
      node.body.accept2(this);
    });
  }

  void _bindEnumConstant(
    EnumConstantDeclarationImpl node,
    FieldFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    node.documentationComment?.accept2(this);
    if (node.arguments case var arguments?) {
      _withElementHolder(ElementHolder(fragment), () {
        arguments.accept2(this);
      });
    }
  }

  void _bindEnumDeclaration(
    EnumDeclarationImpl node,
    EnumFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    var memberFragments = _ContainerMemberFragments(
      constructors: fragment.constructors
          .where((f) => f.isOriginDeclaration)
          .toList(),
      fields: fragment.fields.where((f) => f.isOriginDeclaration).toList(),
      getters: fragment.getters.where((f) => f.isOriginDeclaration).toList(),
      setters: fragment.setters.where((f) => f.isOriginDeclaration).toList(),
      methods: fragment.methods,
    );

    node.documentationComment?.accept2(this);
    var namePart = node.namePart;
    _bindTypeParameters(namePart.typeParameters, fragment.typeParameters);
    if (namePart is PrimaryConstructorDeclarationImpl) {
      var constructorFragment = memberFragments.nextConstructor();
      namePart.declaredFragment = constructorFragment;
      _bindFormalParameters(
        namePart.formalParameters,
        constructorFragment.formalParameters,
      );
    }

    node.withClause?.accept2(this);
    node.implementsClause?.accept2(this);

    for (var constant in node.body.constants) {
      _bindEnumConstant(constant, memberFragments.nextField());
    }

    _bindMembers(node.body.members, memberFragments);
  }

  void _bindExtensionDeclaration(
    ExtensionDeclarationImpl node,
    ExtensionFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    var memberFragments = _ContainerMemberFragments(
      fields: fragment.fields.where((f) => f.isOriginDeclaration).toList(),
      getters: fragment.getters.where((f) => f.isOriginDeclaration).toList(),
      setters: fragment.setters.where((f) => f.isOriginDeclaration).toList(),
      methods: fragment.methods,
    );

    node.documentationComment?.accept2(this);
    _bindTypeParameters(node.typeParameters, fragment.typeParameters);
    node.onClause?.accept2(this);

    _bindMembers(node.body.members, memberFragments);
  }

  void _bindExtensionTypeDeclaration(
    ExtensionTypeDeclarationImpl node,
    ExtensionTypeFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    var memberFragments = _ContainerMemberFragments(
      constructors: fragment.constructors,
      fields: fragment.fields.where((f) => f.isOriginDeclaration).toList(),
      getters: fragment.getters.where((f) => f.isOriginDeclaration).toList(),
      setters: fragment.setters.where((f) => f.isOriginDeclaration).toList(),
      methods: fragment.methods,
    );

    node.documentationComment?.accept2(this);
    var namePart = node.namePart;
    _bindTypeParameters(namePart.typeParameters, fragment.typeParameters);
    if (namePart is PrimaryConstructorDeclarationImpl) {
      var constructorFragment = memberFragments.nextConstructor();
      namePart.declaredFragment = constructorFragment;
      _bindFormalParameters(
        namePart.formalParameters,
        constructorFragment.formalParameters,
      );
    }

    node.implementsClause?.accept2(this);

    _bindMembers(node.body.members, memberFragments);
  }

  void _bindField(
    VariableDeclarationImpl node,
    FieldFragmentImpl fragment,
    FieldDeclarationImpl declaration,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, declaration.metadata);

    var offset = node == declaration.fields.variables.first
        ? declaration.offset
        : node.offset;
    fragment.setCodeRange(offset, node.end - offset);

    node.documentationComment?.accept2(this);
    if (node.initializer2 case var initializer?) {
      _withElementHolder(ElementHolder(fragment), () {
        initializer.accept2(this);
      });
    }
  }

  void _bindFormalParameter(
    FormalParameterImpl node,
    FormalParameterFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    var functionTypedSuffix = node.functionTypedSuffix;
    if (functionTypedSuffix != null) {
      var holder = ElementHolder(fragment);
      _withElementHolder(holder, () {
        node.documentationComment?.accept2(this);
        node.type?.accept2(this);
        functionTypedSuffix.typeParameters?.accept2(this);
        functionTypedSuffix.formalParameters.accept2(this);
      });
      for (var typeParameter in holder.typeParameters) {
        TypeParameterElementImpl(firstFragment: typeParameter);
      }
      for (var formalParameter in holder.formalParameters) {
        formalParameter.initElement();
      }
    } else {
      node.documentationComment?.accept2(this);
      node.type?.accept2(this);
    }

    if (node.defaultClause case var defaultClause?) {
      fragment.constantInitializer2 = defaultClause.value2;
      _withElementHolder(ElementHolder(fragment), () {
        defaultClause.value2.accept2(this);
      });
    }
  }

  void _bindFormalParameters(
    FormalParameterListImpl? parameters,
    List<FormalParameterFragmentImpl> fragments,
  ) {
    if (parameters != null) {
      var parameterNodes = parameters.allFormalParameters;
      var declaredFragments = fragments
          .where((f) => f.isOriginDeclaration)
          .toList();
      for (int i = 0; i < parameterNodes.length; i++) {
        _bindFormalParameter(parameterNodes[i], declaredFragments[i]);
      }
    }
  }

  void _bindFunctionDeclaration(
    FunctionDeclarationImpl node,
    ExecutableFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    var expression = node.functionExpression;
    expression.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    node.documentationComment?.accept2(this);
    node.returnType?.accept2(this);
    _bindTypeParameters(expression.typeParameters, fragment.typeParameters);
    _bindFormalParameters(expression.parameters, fragment.formalParameters);

    _withElementHolder(ElementHolder(fragment), () {
      expression.body.accept2(this);
    });
  }

  void _bindFunctionTypeAlias(
    FunctionTypeAliasImpl node,
    TypeAliasFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    node.documentationComment?.accept2(this);
    var holder = ElementHolder(fragment);
    _withElementHolder(holder, () {
      _bindTypeParameters(node.typeParameters, fragment.typeParameters);
      node.returnType?.accept2(this);
      node.parameters.accept2(this);
      fragment.encloseElements(holder.formalParameters);
      for (var formalParameter in holder.formalParameters) {
        formalParameter.initElement();
      }
    });
  }

  void _bindGenericTypeAlias(
    GenericTypeAliasImpl node,
    TypeAliasFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    node.documentationComment?.accept2(this);
    _bindTypeParameters(node.typeParameters, fragment.typeParameters);
    node.type.accept2(this);
  }

  void _bindMembers(
    List<ClassMemberImpl> members,
    _ContainerMemberFragments fragments,
  ) {
    for (var member in members) {
      switch (member) {
        case ConstructorDeclarationImpl():
          _bindConstructorDeclaration(member, fragments.nextConstructor());
        case MethodDeclarationImpl():
          if (member.isGetter) {
            _bindMethodDeclaration(member, fragments.nextGetter());
          } else if (member.isSetter) {
            _bindMethodDeclaration(member, fragments.nextSetter());
          } else {
            _bindMethodDeclaration(member, fragments.nextMethod());
          }
        case FieldDeclarationImpl():
          member.documentationComment?.accept2(this);
          member.fields.type?.accept2(this);
          for (var variable in member.fields.variables) {
            _bindField(variable, fragments.nextField(), member);
          }
        case PrimaryConstructorBodyImpl():
          member.accept2(this);
      }
    }
  }

  void _bindMethodDeclaration(
    MethodDeclarationImpl node,
    ExecutableFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    node.documentationComment?.accept2(this);
    node.returnType?.accept2(this);
    _bindTypeParameters(node.typeParameters, fragment.typeParameters);
    _bindFormalParameters(node.parameters, fragment.formalParameters);

    _withElementHolder(ElementHolder(fragment), () {
      node.body.accept2(this);
    });
  }

  void _bindMixinDeclaration(
    MixinDeclarationImpl node,
    MixinFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);

    var memberFragments = _ContainerMemberFragments(
      constructors: fragment.constructors
          .where((f) => f.isOriginDeclaration)
          .toList(),
      fields: fragment.fields.where((f) => f.isOriginDeclaration).toList(),
      getters: fragment.getters.where((f) => f.isOriginDeclaration).toList(),
      setters: fragment.setters.where((f) => f.isOriginDeclaration).toList(),
      methods: fragment.methods,
    );

    node.documentationComment?.accept2(this);
    _bindTypeParameters(node.typeParameters, fragment.typeParameters);

    node.onClause?.accept2(this);
    node.implementsClause?.accept2(this);

    _bindMembers(node.body.members, memberFragments);
  }

  void _bindTopLevelVariable(
    VariableDeclarationImpl node,
    TopLevelVariableFragmentImpl fragment,
    TopLevelVariableDeclarationImpl declaration,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, declaration.metadata);

    var offset = node == declaration.variables.variables.first
        ? declaration.offset
        : node.offset;
    fragment.setCodeRange(offset, node.end - offset);

    node.documentationComment?.accept2(this);
    if (node.initializer2 case var initializer?) {
      _withElementHolder(ElementHolder(fragment), () {
        initializer.accept2(this);
      });
    }
  }

  void _bindTypeParameter(
    TypeParameterImpl node,
    TypeParameterFragmentImpl fragment,
  ) {
    node.declaredFragment = fragment;
    _setOrCreateMetadataElements(fragment, node.metadata);
    node.documentationComment?.accept2(this);
    node.bound?.accept2(this);
  }

  void _bindTypeParameters(
    TypeParameterListImpl? typeParameters,
    List<TypeParameterFragmentImpl> fragments,
  ) {
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters.typeParameters.length; i++) {
        _bindTypeParameter(typeParameters.typeParameters[i], fragments[i]);
      }
    }
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

    for (var node in annotations) {
      node.accept2(this);
    }

    if (fragment.metadata.annotations.isEmpty) {
      fragment.metadata = MetadataImpl(
        annotations.map((a) => a.elementAnnotation!).toList(),
      );
    }
  }

  void _visitFormalParameter<T extends FormalParameterFragmentImpl>(
    FormalParameterImpl node,
    T Function() createFragment,
  ) {
    var fragment = createFragment();
    _elementHolder.addParameter(fragment);

    fragment.setCodeRange(node.offset, node.length);
    fragment.isConst = node.isConst;
    fragment.isExplicitlyCovariant = node.covariantKeyword != null;
    fragment.isFinal = node.isFinal;
    node.declaredFragment = fragment;

    _setOrCreateMetadataElements(fragment, node.metadata);

    var functionTypedSuffix = node.functionTypedSuffix;
    if (functionTypedSuffix != null) {
      var holder = ElementHolder(fragment);
      _withElementHolder(holder, () {
        node.documentationComment?.accept2(this);
        node.type?.accept2(this);
        functionTypedSuffix.typeParameters?.accept2(this);
        functionTypedSuffix.formalParameters.accept2(this);
      });
      for (var typeParameter in holder.typeParameters) {
        TypeParameterElementImpl(firstFragment: typeParameter);
      }
      for (var formalParameter in holder.formalParameters) {
        formalParameter.initElement();
      }
    } else {
      node.documentationComment?.accept2(this);
      node.type?.accept2(this);
    }

    if (node.defaultClause case var defaultClause?) {
      fragment.constantInitializer2 = defaultClause.value2;
      _withElementHolder(ElementHolder(fragment), () {
        defaultClause.value2.accept2(this);
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
    fragment.enclosingFragment = _fragment;
    _formalParameters.add(fragment);
  }

  void addTypeParameter(TypeParameterFragmentImpl fragment) {
    fragment.enclosingFragment = _fragment;
    _typeParameters.add(fragment);
  }

  void enclose(FragmentImpl fragment) {
    fragment.enclosingFragment = _fragment;
  }
}

final class _ContainerMemberFragments {
  final List<ConstructorFragmentImpl> constructors;
  int _constructorIndex = 0;

  final List<FieldFragmentImpl> fields;
  int _fieldIndex = 0;

  final List<GetterFragmentImpl> getters;
  int _getterIndex = 0;

  final List<SetterFragmentImpl> setters;
  int _setterIndex = 0;

  final List<MethodFragmentImpl> methods;
  int _methodIndex = 0;

  _ContainerMemberFragments({
    this.constructors = const [],
    this.fields = const [],
    this.getters = const [],
    this.setters = const [],
    this.methods = const [],
  });

  ConstructorFragmentImpl nextConstructor() {
    return constructors[_constructorIndex++];
  }

  FieldFragmentImpl nextField() {
    return fields[_fieldIndex++];
  }

  GetterFragmentImpl nextGetter() {
    return getters[_getterIndex++];
  }

  MethodFragmentImpl nextMethod() {
    return methods[_methodIndex++];
  }

  SetterFragmentImpl nextSetter() {
    return setters[_setterIndex++];
  }
}

extension on Token {
  String? get nameIfNotEmpty => lexeme.isNotEmpty ? lexeme : null;

  int? get offsetIfNotEmpty => lexeme.isNotEmpty ? offset : null;
}
