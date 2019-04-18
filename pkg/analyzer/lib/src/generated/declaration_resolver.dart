// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// A visitor that resolves declarations in an AST structure to already built
/// elements.
///
/// The resulting AST must have everything resolved that would have been
/// resolved by a [CompilationUnitBuilder] (that is, must be a valid
/// [RESOLVED_UNIT1]). This class must not assume that the
/// [CompilationUnitElement] passed to it is any more complete than a
/// [COMPILATION_UNIT_ELEMENT].
class DeclarationResolver extends RecursiveAstVisitor<void> {
  /// The compilation unit containing the AST nodes being visited.
  CompilationUnitElementImpl _enclosingUnit;

  /// The type provider used to access the known types.
  TypeProvider _typeProvider;

  /// The [ElementWalker] we are using to keep track of progress through the
  /// element model.
  ElementWalker _walker;

  DeclarationResolver();

  /// Resolve the declarations within the given compilation [unit] to the
  /// elements rooted at the given [element]. Throw an
  /// [ElementMismatchException] if the element model and compilation unit do
  /// not match each other.
  void resolve(CompilationUnit unit, CompilationUnitElement element) {
    _enclosingUnit = element;
    _typeProvider = _enclosingUnit.context?.typeProvider;
    _walker = new ElementWalker.forCompilationUnit(element);
    unit.element = element;
    try {
      unit.accept(this);
      _walker.validate();
    } on Error catch (e, st) {
      throw new _ElementMismatchException(
          element, _walker.element, new CaughtException(e, st));
    }
  }

  @override
  void visitAnnotation(Annotation node) {
    // Annotations can only contain elements in certain erroneous situations,
    // in which case the elements are disconnected from the rest of the element
    // model, thus we can't reconnect to them.  To avoid crashes, just create
    // fresh elements.
    ElementHolder elementHolder = new ElementHolder();
    new ElementBuilder(elementHolder, _enclosingUnit).visitAnnotation(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    if (_isBodyToCreateElementsFor(node)) {
      _walker.consumeLocalElements();
      node.accept(_walker.elementBuilder);
    } else {
      super.visitBlockFunctionBody(node);
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    _walker.elementBuilder.buildCatchVariableElements(node);
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    ClassElement element = _match(node.name, _walker.getClass());
    _walk(new ElementWalker.forClass(element), () {
      super.visitClassDeclaration(node);
    });
    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement element = _match(node.name, _walker.getClass());
    _walk(new ElementWalker.forClass(element), () {
      super.visitClassTypeAlias(node);
    });
    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElement element = _match(node.name, _walker.getConstructor(),
        offset: node.name?.offset ?? node.returnType.offset);
    _walk(new ElementWalker.forExecutable(element, _enclosingUnit), () {
      (node as ConstructorDeclarationImpl).declaredElement = element;
      super.visitConstructorDeclaration(node);
    });
    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    // Declared identifiers can only occur inside executable elements.
    _walker.elementBuilder.visitDeclaredIdentifier(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    NormalFormalParameter normalParameter = node.parameter;
    ParameterElement element =
        _match(normalParameter.identifier, _walker.getParameter());
    if (normalParameter is SimpleFormalParameterImpl) {
      normalParameter.declaredElement = element;
      _setGenericFunctionType(normalParameter.type, element.type);
    }
    if (normalParameter is FieldFormalParameterImpl) {
      _setGenericFunctionType(normalParameter.type, element.type);
    }

    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      _walk(
          new ElementWalker.forExecutable(element.initializer, _enclosingUnit),
          () {
        defaultValue.accept(this);
      });
    }

    _walk(new ElementWalker.forParameter(element), () {
      normalParameter.accept(this);
    });

    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    ClassElement element = _match(node.name, _walker.getEnum());
    node.name.staticType = _typeProvider.typeType;
    resolveMetadata(node, node.metadata, element);
    _walk(new ElementWalker.forClass(element), () {
      for (EnumConstantDeclaration constant in node.constants) {
        VariableElement field = _match(constant.name, _walker.getVariable());
        resolveMetadata(node, constant.metadata, field);
        constant.name.staticElement = field;
        constant.name.staticType = field.type;
      }
      _walker.getFunction(); // toString()
      super.visitEnumDeclaration(node);
    });
  }

  @override
  void visitExportDirective(ExportDirective node) {
    super.visitExportDirective(node);
    List<ElementAnnotation> annotations =
        _enclosingUnit.getAnnotations(node.offset);
    if (annotations.isEmpty && node.metadata.isNotEmpty) {
      int index = (node.parent as CompilationUnit)
          .directives
          .where((directive) => directive is ExportDirective)
          .toList()
          .indexOf(node);
      annotations = _walker.element.library.exports[index].metadata;
    }
    resolveAnnotations(node, node.metadata, annotations);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (_isBodyToCreateElementsFor(node)) {
      _walker.consumeLocalElements();
      node.accept(_walker.elementBuilder);
    } else {
      super.visitExpressionFunctionBody(node);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    super.visitFieldDeclaration(node);
    FieldElement firstFieldElement = node.fields.variables[0].declaredElement;
    resolveMetadata(node, node.metadata, firstFieldElement);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      ParameterElement element =
          _match(node.identifier, _walker.getParameter());
      _walk(new ElementWalker.forParameter(element), () {
        super.visitFieldFormalParameter(node);
      });
      resolveMetadata(node, node.metadata, element);
      _setGenericFunctionType(node.type, element.type);
    } else {
      super.visitFieldFormalParameter(node);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    SimpleIdentifier functionName = node.name;
    Token property = node.propertyKeyword;
    ExecutableElement element;
    if (property == null) {
      element = _match(functionName, _walker.getFunction());
    } else {
      if (_walker.element is ExecutableElement) {
        element = _match(functionName, _walker.getFunction());
      } else if (property.keyword == Keyword.GET) {
        element = _match(functionName, _walker.getAccessor());
      } else {
        assert(property.keyword == Keyword.SET);
        element = _match(functionName, _walker.getAccessor(),
            elementName: functionName.name + '=');
      }
    }
    _setGenericFunctionType(node.returnType, element.returnType);
    (node.functionExpression as FunctionExpressionImpl).declaredElement =
        element;
    _walker._elementHolder?.addFunction(element);
    _walk(new ElementWalker.forExecutable(element, _enclosingUnit), () {
      super.visitFunctionDeclaration(node);
    });
    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      node.accept(_walker.elementBuilder);
    } else {
      super.visitFunctionExpression(node);
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElement element = _match(node.name, _walker.getTypedef());
    _walk(new ElementWalker.forTypedef(element), () {
      super.visitFunctionTypeAlias(node);
    });
    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      ParameterElement element =
          _match(node.identifier, _walker.getParameter());
      _walk(new ElementWalker.forParameter(element), () {
        super.visitFunctionTypedFormalParameter(node);
      });
      resolveMetadata(node, node.metadata, element);
    } else {
      super.visitFunctionTypedFormalParameter(node);
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    if (_walker.elementBuilder != null) {
      _walker.elementBuilder.visitGenericFunctionType(node);
    } else {
      DartType type = node.type;
      if (type != null) {
        Element element = type.element;
        if (element is GenericFunctionTypeElement) {
          _setGenericFunctionType(node.returnType, element.returnType);
          _walk(new ElementWalker.forGenericFunctionType(element), () {
            super.visitGenericFunctionType(node);
          });
        }
      }
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    GenericTypeAliasElementImpl element =
        _match(node.name, _walker.getTypedef());
    _setGenericFunctionType(node.functionType, element.function?.type);
    _walk(new ElementWalker.forGenericTypeAlias(element), () {
      super.visitGenericTypeAlias(node);
    });
    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    super.visitImportDirective(node);
    List<ElementAnnotation> annotations =
        _enclosingUnit.getAnnotations(node.offset);
    if (annotations.isEmpty && node.metadata.isNotEmpty) {
      int index = (node.parent as CompilationUnit)
          .directives
          .where((directive) => directive is ImportDirective)
          .toList()
          .indexOf(node);
      annotations = _walker.element.library.imports[index].metadata;
    }
    resolveAnnotations(node, node.metadata, annotations);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    bool onSwitchStatement = node.statement is SwitchStatement;
    _walker.elementBuilder
        .buildLabelElements(node.labels, onSwitchStatement, false);
    super.visitLabeledStatement(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    super.visitLibraryDirective(node);
    List<ElementAnnotation> annotations =
        _enclosingUnit.getAnnotations(node.offset);
    if (annotations.isEmpty && node.metadata.isNotEmpty) {
      annotations = _walker.element.library.metadata;
    }
    resolveAnnotations(node, node.metadata, annotations);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    Token property = node.propertyKeyword;
    SimpleIdentifier methodName = node.name;
    String nameOfMethod = methodName.name;
    ExecutableElement element;
    if (property == null) {
      String elementName = nameOfMethod == '-' &&
              node.parameters != null &&
              node.parameters.parameters.isEmpty
          ? 'unary-'
          : nameOfMethod;
      element =
          _match(methodName, _walker.getFunction(), elementName: elementName);
    } else {
      if (property.keyword == Keyword.GET) {
        element = _match(methodName, _walker.getAccessor());
      } else {
        assert(property.keyword == Keyword.SET);
        element = _match(methodName, _walker.getAccessor(),
            elementName: nameOfMethod + '=');
      }
    }
    _setGenericFunctionType(node.returnType, element.returnType);
    _walk(new ElementWalker.forExecutable(element, _enclosingUnit), () {
      super.visitMethodDeclaration(node);
    });
    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    ClassElement element = _match(node.name, _walker.getMixin());
    _walk(new ElementWalker.forClass(element), () {
      super.visitMixinDeclaration(node);
    });
    resolveMetadata(node, node.metadata, element);
  }

  @override
  void visitPartDirective(PartDirective node) {
    super.visitPartDirective(node);
    List<ElementAnnotation> annotations =
        _enclosingUnit.getAnnotations(node.offset);
    if (annotations.isEmpty && node.metadata.isNotEmpty) {
      int index = (node.parent as CompilationUnit)
          .directives
          .where((directive) => directive is PartDirective)
          .toList()
          .indexOf(node);
      annotations = _walker.element.library.parts[index].metadata;
    }
    resolveAnnotations(node, node.metadata, annotations);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    node.element = _enclosingUnit.library;
    super.visitPartOfDirective(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      ParameterElement element =
          _match(node.identifier, _walker.getParameter());
      (node as SimpleFormalParameterImpl).declaredElement = element;
      _setGenericFunctionType(node.type, element.type);
      _walk(new ElementWalker.forParameter(element), () {
        super.visitSimpleFormalParameter(node);
      });
      resolveMetadata(node, node.metadata, element);
    } else {
      super.visitSimpleFormalParameter(node);
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _walker.elementBuilder.buildLabelElements(node.labels, false, true);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _walker.elementBuilder.buildLabelElements(node.labels, false, true);
    super.visitSwitchDefault(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    super.visitTopLevelVariableDeclaration(node);
    VariableElement firstElement = node.variables.variables[0].declaredElement;
    resolveMetadata(node, node.metadata, firstElement);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (node.parent.parent is FunctionTypedFormalParameter) {
      // Work around dartbug.com/28515.
      // TODO(paulberry): remove this once dartbug.com/28515 is fixed.
      var element = new TypeParameterElementImpl.forNode(node.name);
      element.type = new TypeParameterTypeImpl(element);
      node.name?.staticElement = element;
    } else {
      TypeParameterElement element =
          _match(node.name, _walker.getTypeParameter());
      _setGenericFunctionType(node.bound, element.bound);
      super.visitTypeParameter(node);
      resolveMetadata(node, node.metadata, element);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    VariableElement element = _match(node.name, _walker.getVariable());
    Expression initializer = node.initializer;
    if (initializer != null) {
      _walk(
          new ElementWalker.forExecutable(element.initializer, _enclosingUnit),
          () {
        super.visitVariableDeclaration(node);
      });
    } else {
      super.visitVariableDeclaration(node);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (_walker.elementBuilder != null) {
      _walker.elementBuilder.visitVariableDeclarationList(node);
    } else {
      node.variables.accept(this);
      VariableElement firstVariable = node.variables[0].declaredElement;
      _setGenericFunctionType(node.type, firstVariable.type);
      node.type?.accept(this);
      if (node.parent is! FieldDeclaration &&
          node.parent is! TopLevelVariableDeclaration) {
        resolveMetadata(node, node.metadata, firstVariable);
      }
    }
  }

  /// Updates [identifier] to point to [element], after ensuring that the
  /// element has the expected name.
  ///
  /// If no [elementName] is given, it defaults to the name of the [identifier]
  /// (or the empty string if [identifier] is `null`).
  ///
  /// If [identifier] is `null`, nothing is updated, but the element name is
  /// still checked.
  E _match<E extends Element>(SimpleIdentifier identifier, E element,
      {String elementName, int offset}) {
    elementName ??= identifier?.name ?? '';
    offset ??= identifier?.offset ?? -1;
    if (element.name != elementName) {
      throw new StateError(
          'Expected an element matching `$elementName`, got `${element.name}`');
    }
    identifier?.staticElement = element;
    _matchOffset(element, offset);
    return element;
  }

  void _matchOffset(Element element, int offset) {
    if (element.nameOffset > 0 && element.nameOffset != offset) {
      throw new StateError('Element offset mismatch');
    } else {
      (element as ElementImpl).nameOffset = offset;
    }
  }

  /// If the given [typeNode] is a [GenericFunctionType], set its [type].
  void _setGenericFunctionType(TypeAnnotation typeNode, DartType type) {
    if (typeNode is GenericFunctionTypeImpl) {
      typeNode.type = type;
    } else if (typeNode is NamedType) {
      typeNode.type = type;
      if (type is ParameterizedType) {
        List<TypeAnnotation> nodes =
            typeNode.typeArguments?.arguments ?? const [];
        List<DartType> types = type.typeArguments;
        if (nodes.length == types.length) {
          for (int i = 0; i < nodes.length; i++) {
            _setGenericFunctionType(nodes[i], types[i]);
          }
        }
      }
    }
  }

  /// Recurses through the element model and AST, verifying that all elements
  /// are matched.
  ///
  /// Executes [callback] with [_walker] pointing to the given [walker] (which
  /// should be a new instance of [ElementWalker]).  Once [callback] returns,
  /// uses [ElementWalker.validate] to verify that all expected elements have
  /// been matched.
  void _walk(ElementWalker walker, void callback()) {
    ElementWalker outerWalker = _walker;
    _walker = walker;
    callback();
    walker.validate();
    _walker = outerWalker;
  }

  /// Apply the [type] that is created by the [constructorName] and the
  /// [constructorElement] it references.
  static void applyConstructorElement(
      LibraryElement enclosingLibraryElement,
      PrefixElement prefixElement,
      ConstructorElement constructorElement,
      DartType type,
      ConstructorName constructorName) {
    constructorName.staticElement = constructorElement;

    ClassElement classElement = constructorElement?.enclosingElement;

    Identifier typeIdentifier = constructorName.type.name;
    if (prefixElement != null) {
      PrefixedIdentifier prefixedTypeIdentifier = typeIdentifier;
      prefixedTypeIdentifier.staticType = type;

      prefixedTypeIdentifier.prefix.staticElement = prefixElement;

      SimpleIdentifier classNode = prefixedTypeIdentifier.identifier;
      classNode.staticElement = classElement;
      classNode.staticType = type;
    } else {
      if (typeIdentifier is SimpleIdentifier) {
        typeIdentifier.staticElement = classElement;
        typeIdentifier.staticType = type;
      } else if (typeIdentifier is PrefixedIdentifier) {
        constructorName.type = astFactory.typeName(typeIdentifier.prefix, null);
        constructorName.period = typeIdentifier.period;
        constructorName.name = typeIdentifier.identifier;
      }
    }

    constructorName.name?.staticElement = constructorElement;

    DeclarationResolver.applyToTypeAnnotation(
        enclosingLibraryElement, type, constructorName.type);
  }

  /// Apply the types of the [parameterElements] to the [parameterList] that
  /// have an explicit type annotation.
  static void applyParameters(
      LibraryElement enclosingLibraryElement,
      List<ParameterElement> parameterElements,
      FormalParameterList parameterList) {
    List<FormalParameter> parameters = parameterList.parameters;

    int length = parameterElements.length;
    if (parameters.length != length) {
      throw new StateError('Parameter counts do not match');
    }
    for (int i = 0; i < length; i++) {
      ParameterElementImpl element = parameterElements[i];
      FormalParameter parameter = parameters[i];

      DeclarationResolver.resolveMetadata(
          parameter, parameter.metadata, element);

      NormalFormalParameter normalParameter;
      if (parameter is NormalFormalParameter) {
        normalParameter = parameter;
      } else if (parameter is DefaultFormalParameter) {
        normalParameter = parameter.parameter;
      }
      assert(normalParameter != null);

      if (normalParameter is SimpleFormalParameterImpl) {
        normalParameter.declaredElement = element;
      }

      if (normalParameter.identifier != null) {
        element.nameOffset = normalParameter.identifier.offset;
        normalParameter.identifier.staticElement = element;
        normalParameter.identifier.staticType = element.type;
      }

      // Apply the type or the return type, if a function typed parameter.
      TypeAnnotation functionReturnType;
      FormalParameterList functionParameterList;
      if (normalParameter is SimpleFormalParameter) {
        applyToTypeAnnotation(
            enclosingLibraryElement, element.type, normalParameter.type);
      } else if (normalParameter is FunctionTypedFormalParameter) {
        functionReturnType = normalParameter.returnType;
        functionParameterList = normalParameter.parameters;
      } else if (normalParameter is FieldFormalParameter) {
        if (normalParameter.parameters == null) {
          applyToTypeAnnotation(
              enclosingLibraryElement, element.type, normalParameter.type);
        } else {
          functionReturnType = normalParameter.type;
          functionParameterList = normalParameter.parameters;
        }
      }

      if (functionParameterList != null) {
        FunctionType elementType = element.type;
        if (functionReturnType != null) {
          applyToTypeAnnotation(enclosingLibraryElement, elementType.returnType,
              functionReturnType);
        }
        applyParameters(enclosingLibraryElement, elementType.parameters,
            functionParameterList);
      }
    }
  }

  /// Apply the [type] to the [typeAnnotation] by setting the type of the
  /// [typeAnnotation] to the [type] and recursively applying each of the type
  /// arguments of the [type] to the corresponding type arguments of the
  /// [typeAnnotation].
  static void applyToTypeAnnotation(LibraryElement enclosingLibraryElement,
      DartType type, TypeAnnotation typeAnnotation) {
    if (typeAnnotation is GenericFunctionTypeImpl) {
      if (type is! FunctionType) {
        throw new StateError('Non-function type ($type) '
            'for generic function annotation ($typeAnnotation)');
      }
      FunctionType functionType = type;
      typeAnnotation.type = type;
      applyToTypeAnnotation(enclosingLibraryElement, functionType.returnType,
          typeAnnotation.returnType);
      applyParameters(enclosingLibraryElement, functionType.parameters,
          typeAnnotation.parameters);
    } else if (typeAnnotation is TypeNameImpl) {
      typeAnnotation.type = type;

      Identifier typeIdentifier = typeAnnotation.name;
      SimpleIdentifier typeName;
      if (typeIdentifier is PrefixedIdentifier) {
        if (enclosingLibraryElement != null) {
          String prefixName = typeIdentifier.prefix.name;
          for (var import in enclosingLibraryElement.imports) {
            if (import.prefix?.name == prefixName) {
              typeIdentifier.prefix.staticElement = import.prefix;
              break;
            }
          }
        }
        typeName = typeIdentifier.identifier;
      } else {
        typeName = typeIdentifier;
      }

      Element typeElement = type.element;
      if (typeElement is GenericFunctionTypeElement &&
          typeElement.enclosingElement is GenericTypeAliasElement) {
        typeElement = typeElement.enclosingElement;
      }

      typeName.staticElement = typeElement;
      typeName.staticType = type;
    }
    if (typeAnnotation is NamedType) {
      TypeArgumentList typeArguments = typeAnnotation.typeArguments;
      if (typeArguments != null) {
        _applyTypeArgumentsToList(
            enclosingLibraryElement, type, typeArguments.arguments);
      }
    }
  }

  /// Associate each of the annotation [nodes] with the corresponding
  /// [ElementAnnotation] in [annotations]. If there is a problem, report it
  /// against the given [parent] node.
  static void resolveAnnotations(AstNode parent, NodeList<Annotation> nodes,
      List<ElementAnnotation> annotations) {
    int nodeCount = nodes.length;
    if (nodeCount != annotations.length) {
      throw new StateError('Found $nodeCount annotation nodes and '
          '${annotations.length} element annotations');
    }
    for (int i = 0; i < nodeCount; i++) {
      nodes[i].elementAnnotation = annotations[i];
    }
  }

  /// If [element] is not `null`, associate each of the annotation [nodes] with
  /// the corresponding [ElementAnnotation] in [element.metadata]. If there is a
  /// problem, report it against the given [parent] node.
  ///
  /// If [element] is `null`, do nothing--this allows us to be robust in the
  /// case where we are operating on an element model that hasn't been fully
  /// built.
  static void resolveMetadata(
      AstNode parent, NodeList<Annotation> nodes, Element element) {
    if (element != null) {
      resolveAnnotations(parent, nodes, element.metadata);
    }
  }

  /// Recursively apply each of the type arguments of the [type] to the
  /// corresponding type arguments of the [typeArguments].
  static void _applyTypeArgumentsToList(LibraryElement enclosingLibraryElement,
      DartType type, List<TypeAnnotation> typeArguments) {
    if (type != null && type.isDynamic) {
      for (TypeAnnotation argument in typeArguments) {
        applyToTypeAnnotation(enclosingLibraryElement, type, argument);
      }
    } else if (type is ParameterizedType) {
      List<DartType> argumentTypes = type.typeArguments;
      int argumentCount = argumentTypes.length;
      if (argumentCount != typeArguments.length) {
        throw new StateError('Found $argumentCount argument types '
            'for ${typeArguments.length} type arguments');
      }
      for (int i = 0; i < argumentCount; i++) {
        applyToTypeAnnotation(
            enclosingLibraryElement, argumentTypes[i], typeArguments[i]);
      }
    } else {
      throw new StateError('Attempting to apply a non-parameterized type '
          '(${type.runtimeType}) to type arguments');
    }
  }

  static bool _isBodyToCreateElementsFor(FunctionBody node) {
    AstNode parent = node.parent;
    return parent is ConstructorDeclaration ||
        parent is MethodDeclaration ||
        parent.parent is FunctionDeclaration &&
            parent.parent.parent is CompilationUnit;
  }
}

/// Keeps track of the set of non-synthetic child elements of an element,
/// yielding them one at a time in response to "get" method calls.
class ElementWalker {
  /// The element whose child elements are being walked.
  final Element element;

  /// If [element] is an executable element, an element builder which is
  /// accumulating the executable element's local variables and labels.
  /// Otherwise `null`.
  LocalElementBuilder elementBuilder;

  /// If [element] is an executable element, the element holder associated with
  /// [elementBuilder].  Otherwise `null`.
  ElementHolder _elementHolder;

  List<PropertyAccessorElement> _accessors;
  int _accessorIndex = 0;
  List<ClassElement> _classes;
  int _classIndex = 0;
  List<ConstructorElement> _constructors;
  int _constructorIndex = 0;
  List<ClassElement> _enums;
  int _enumIndex = 0;
  List<ExecutableElement> _functions;
  int _functionIndex = 0;
  List<ClassElement> _mixins;
  int _mixinIndex = 0;
  List<ParameterElement> _parameters;
  int _parameterIndex = 0;
  List<FunctionTypeAliasElement> _typedefs;
  int _typedefIndex = 0;
  List<TypeParameterElement> _typeParameters;
  int _typeParameterIndex = 0;
  List<VariableElement> _variables;
  int _variableIndex = 0;

  /// Creates an [ElementWalker] which walks the child elements of a class
  /// element.
  ElementWalker.forClass(ClassElement element)
      : element = element,
        _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _constructors = element.isMixinApplication
            ? null
            : element.constructors.where(_isNotSynthetic).toList(),
        _functions = element.methods,
        _typeParameters = element.typeParameters,
        _variables = element.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forCompilationUnit(CompilationUnitElement compilationUnit)
      : element = compilationUnit,
        _accessors = compilationUnit.accessors.where(_isNotSynthetic).toList(),
        _classes = compilationUnit.types,
        _enums = compilationUnit.enums,
        _functions = compilationUnit.functions,
        _mixins = compilationUnit.mixins,
        _typedefs = compilationUnit.functionTypeAliases,
        _variables =
            compilationUnit.topLevelVariables.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forExecutable(
      ExecutableElement element, CompilationUnitElement compilationUnit)
      : this._forExecutable(element, compilationUnit, new ElementHolder());

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forGenericFunctionType(GenericFunctionTypeElement element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element defined using a generic function type.
  ElementWalker.forGenericTypeAlias(FunctionTypeAliasElement element)
      : element = element,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a parameter
  /// element.
  ElementWalker.forParameter(ParameterElement element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forTypedef(GenericTypeAliasElementImpl element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  ElementWalker._forExecutable(ExecutableElement element,
      CompilationUnitElement compilationUnit, ElementHolder elementHolder)
      : element = element,
        elementBuilder =
            new LocalElementBuilder(elementHolder, compilationUnit),
        _elementHolder = elementHolder,
        _functions = const <ExecutableElement>[],
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  void consumeLocalElements() {
    _functionIndex = _functions.length;
  }

  void consumeParameters() {
    _parameterIndex = _parameters.length;
  }

  /// Returns the next non-synthetic child of [element] which is an accessor;
  /// throws an [IndexError] if there are no more.
  PropertyAccessorElement getAccessor() => _accessors[_accessorIndex++];

  /// Returns the next non-synthetic child of [element] which is a class; throws
  /// an [IndexError] if there are no more.
  ClassElement getClass() => _classes[_classIndex++];

  /// Returns the next non-synthetic child of [element] which is a constructor;
  /// throws an [IndexError] if there are no more.
  ConstructorElement getConstructor() => _constructors[_constructorIndex++];

  /// Returns the next non-synthetic child of [element] which is an enum; throws
  /// an [IndexError] if there are no more.
  ClassElement getEnum() => _enums[_enumIndex++];

  /// Returns the next non-synthetic child of [element] which is a top level
  /// function, method, or local function; throws an [IndexError] if there are
  /// no more.
  ExecutableElement getFunction() => _functions[_functionIndex++];

  /// Returns the next non-synthetic child of [element] which is a mixin; throws
  /// an [IndexError] if there are no more.
  ClassElement getMixin() => _mixins[_mixinIndex++];

  /// Returns the next non-synthetic child of [element] which is a parameter;
  /// throws an [IndexError] if there are no more.
  ParameterElement getParameter() => _parameters[_parameterIndex++];

  /// Returns the next non-synthetic child of [element] which is a typedef;
  /// throws an [IndexError] if there are no more.
  FunctionTypeAliasElement getTypedef() => _typedefs[_typedefIndex++];

  /// Returns the next non-synthetic child of [element] which is a type
  /// parameter; throws an [IndexError] if there are no more.
  TypeParameterElement getTypeParameter() =>
      _typeParameters[_typeParameterIndex++];

  /// Returns the next non-synthetic child of [element] which is a top level
  /// variable, field, or local variable; throws an [IndexError] if there are no
  /// more.
  VariableElement getVariable() => _variables[_variableIndex++];

  /// Verifies that all non-synthetic children of [element] have been obtained
  /// from their corresponding "get" method calls; if not, throws a
  /// [StateError].
  void validate() {
    void check(List<Element> elements, int index) {
      if (elements != null && elements.length != index) {
        throw new StateError(
            'Unmatched ${elements[index].runtimeType} ${elements[index]}');
      }
    }

    check(_accessors, _accessorIndex);
    check(_classes, _classIndex);
    check(_constructors, _constructorIndex);
    check(_enums, _enumIndex);
    check(_functions, _functionIndex);
    check(_parameters, _parameterIndex);
    check(_typedefs, _typedefIndex);
    check(_typeParameters, _typeParameterIndex);
    check(_variables, _variableIndex);
    Element element = this.element;
    if (element is ExecutableElementImpl) {
      element.encloseElements(_elementHolder.functions);
      element.encloseElements(_elementHolder.labels);
      element.encloseElements(_elementHolder.localVariables);
    }
  }

  static bool _isNotSynthetic(Element e) => !e.isSynthetic;
}

class _ElementMismatchException extends AnalysisException {
  /// Creates an exception to refer to the given [compilationUnit], [element],
  /// and [cause].
  _ElementMismatchException(
      CompilationUnitElement compilationUnit, Element element,
      [CaughtException cause = null])
      : super('Element mismatch in $compilationUnit at $element', cause);
}
