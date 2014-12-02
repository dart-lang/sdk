// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_resolver;

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

import 'ast.dart';
import 'element.dart';
import 'engine.dart';
import 'error.dart';
import 'java_engine.dart';
import 'parser.dart';
import 'resolver.dart';
import 'scanner.dart';
import 'source.dart';


/**
 * Instances of the class [DeclarationMatcher] determine whether the element
 * model defined by a given AST structure matches an existing element model.
 */
class DeclarationMatcher extends RecursiveAstVisitor {
  /**
   * The libary containing the AST nodes being visited.
   */
  LibraryElement _enclosingLibrary;

  /**
   * The compilation unit containing the AST nodes being visited.
   */
  CompilationUnitElement _enclosingUnit;

  /**
   * The function type alias containing the AST nodes being visited, or `null` if we are not
   * in the scope of a function type alias.
   */
  FunctionTypeAliasElement _enclosingAlias;

  /**
   * The class containing the AST nodes being visited, or `null` if we are not
   * in the scope of a class.
   */
  ClassElement _enclosingClass;

  /**
   * The parameter containing the AST nodes being visited, or `null` if we are not in the
   * scope of a parameter.
   */
  ParameterElement _enclosingParameter;

  FieldDeclaration _enclosingFieldNode = null;
  bool _inTopLevelVariableDeclaration = false;

  /**
   * Is `true` if the current class declaration has a constructor.
   */
  bool _hasConstructor = false;

  /**
   * A set containing all of the elements in the element model that were defined by the old AST node
   * corresponding to the AST node being visited.
   */
  HashSet<Element> _allElements = new HashSet<Element>();

  /**
   * A set containing all of the elements in the element model that were defined by the old AST node
   * corresponding to the AST node being visited that have not already been matched to nodes in the
   * AST structure being visited.
   */
  HashSet<Element> _unmatchedElements = new HashSet<Element>();

  /**
   * Return `true` if the declarations within the given AST structure define an element model
   * that is equivalent to the corresponding elements rooted at the given element.
   *
   * @param node the AST structure being compared to the element model
   * @param element the root of the element model being compared to the AST structure
   * @return `true` if the AST structure defines the same elements as those in the given
   *         element model
   */
  bool matches(AstNode node, Element element) {
    _captureEnclosingElements(element);
    _gatherElements(element);
    try {
      node.accept(this);
    } on _DeclarationMismatchException catch (exception) {
      return false;
    }
    return _unmatchedElements.isEmpty;
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    // ignore bodies
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    String name = node.name.name;
    ClassElement element = _findElement(_enclosingUnit.types, name);
    _enclosingClass = element;
    _processElement(element);
    _assertSameTypeParameters(node.typeParameters, element.typeParameters);
    // check for missing clauses
    if (node.extendsClause == null) {
      _assertTrue(element.supertype.name == 'Object');
    }
    if (node.implementsClause == null) {
      _assertTrue(element.interfaces.isEmpty);
    }
    if (node.withClause == null) {
      _assertTrue(element.mixins.isEmpty);
    }
    // process clauses and members
    _hasConstructor = false;
    super.visitClassDeclaration(node);
    // process default constructor
    if (!_hasConstructor) {
      ConstructorElement constructor = element.unnamedConstructor;
      _processElement(constructor);
      if (!constructor.isSynthetic) {
        _assertEquals(constructor.parameters.length, 0);
      }
    }
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    String name = node.name.name;
    ClassElement element = _findElement(_enclosingUnit.types, name);
    _enclosingClass = element;
    _processElement(element);
    _assertSameTypeParameters(node.typeParameters, element.typeParameters);
    _processElement(element.unnamedConstructor);
    super.visitClassTypeAlias(node);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    _processElement(_enclosingUnit);
    super.visitCompilationUnit(node);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    _hasConstructor = true;
    SimpleIdentifier constructorName = node.name;
    ConstructorElement element = constructorName == null ?
        _enclosingClass.unnamedConstructor :
        _enclosingClass.getNamedConstructor(constructorName.name);
    _processElement(element);
    node.element = element;
    _assertCompatibleParameters(node.parameters, element.parameters);
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    String name = node.name.name;
    FieldElement element = _findElement(_enclosingClass.fields, name);
    _processElement(element);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    String name = node.name.name;
    ClassElement element = _findElement(_enclosingUnit.enums, name);
    _enclosingClass = element;
    _processElement(element);
    _assertTrue(element.isEnum);
    super.visitEnumDeclaration(node);
  }

  @override
  visitExportDirective(ExportDirective node) {
    String uri = _getStringValue(node.uri);
    if (uri != null) {
      ExportElement element =
          _findUriReferencedElement(_enclosingLibrary.exports, uri);
      _processElement(element);
      _assertCombinators(node.combinators, element.combinators);
    }
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    // ignore bodies
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    _assertSameType(node.superclass, _enclosingClass.supertype);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    _enclosingFieldNode = node;
    try {
      super.visitFieldDeclaration(node);
    } finally {
      _enclosingFieldNode = null;
    }
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    // prepare element name
    String name = node.name.name;
    if (node.isSetter) {
      name += '=';
    }
    // prepare element
    Token property = node.propertyKeyword;
    ExecutableElement element;
    if (property == null) {
      element = _findElement(_enclosingUnit.functions, name);
    } else {
      element = _findElement(_enclosingUnit.accessors, name);
    }
    // process element
    _processElement(element);
    node.name.staticElement = element;
    node.functionExpression.element = element;
    _assertFalse(element.isSynthetic);
    _assertSameType(node.returnType, element.returnType);
    _assertCompatibleParameters(
        node.functionExpression.parameters,
        element.parameters);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    String name = node.name.name;
    FunctionTypeAliasElement element =
        _findElement(_enclosingUnit.functionTypeAliases, name);
    _processElement(element);
    _assertSameTypeParameters(node.typeParameters, element.typeParameters);
    _assertSameType(node.returnType, element.returnType);
    _assertCompatibleParameters(node.parameters, element.parameters);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    List<TypeName> nodes = node.interfaces;
    List<InterfaceType> types = _enclosingClass.interfaces;
    _assertSameTypes(nodes, types);
  }

  @override
  visitImportDirective(ImportDirective node) {
    String uri = _getStringValue(node.uri);
    if (uri != null) {
      ImportElement element =
          _findUriReferencedElement(_enclosingLibrary.imports, uri);
      _processElement(element);
      // match the prefix
      SimpleIdentifier prefixNode = node.prefix;
      PrefixElement prefixElement = element.prefix;
      if (prefixNode == null) {
        _assertNull(prefixElement);
      } else {
        _assertNotNull(prefixElement);
        _assertEquals(prefixNode.name, prefixElement.name);
      }
      // match combinators
      _assertCombinators(node.combinators, element.combinators);
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    // prepare element name
    String name = node.name.name;
    if (name == TokenType.MINUS.lexeme &&
        node.parameters.parameters.length == 0) {
      name = "unary-";
    }
    if (node.isSetter) {
      name += '=';
    }
    // prepare element
    Token property = node.propertyKeyword;
    ExecutableElement element;
    if (property == null) {
      element = _findElement(_enclosingClass.methods, name);
    } else {
      element = _findElement(_enclosingClass.accessors, name);
    }
    // process element
    _processElement(element);
    _assertEquals(node.isStatic, element.isStatic);
    node.name.staticElement = element;
    _assertSameType(node.returnType, element.returnType);
    _assertCompatibleParameters(node.parameters, element.parameters);
  }

  @override
  visitPartDirective(PartDirective node) {
    String uri = _getStringValue(node.uri);
    if (uri != null) {
      CompilationUnitElement element =
          _findUriReferencedElement(_enclosingLibrary.parts, uri);
      _processElement(element);
    }
    super.visitPartDirective(node);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _inTopLevelVariableDeclaration = true;
    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      _inTopLevelVariableDeclaration = false;
    }
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    // prepare variable
    String name = node.name.name;
    PropertyInducingElement element;
    if (_inTopLevelVariableDeclaration) {
      element = _findElement(_enclosingUnit.topLevelVariables, name);
    } else {
      element = _findElement(_enclosingClass.fields, name);
    }
    // verify
    _assertNotNull(element);
    _processElement(element);
    _assertEquals(node.isConst, element.isConst);
    _assertEquals(node.isFinal, element.isFinal);
    if (_enclosingFieldNode != null) {
      _assertEquals(_enclosingFieldNode.isStatic, element.isStatic);
    }
    _assertSameType(
        (node.parent as VariableDeclarationList).type,
        element.type);
  }

  @override
  visitWithClause(WithClause node) {
    List<TypeName> nodes = node.mixinTypes;
    List<InterfaceType> types = _enclosingClass.mixins;
    _assertSameTypes(nodes, types);
  }

  void _assertCombinators(List<Combinator> nodeCombinators,
      List<NamespaceCombinator> elementCombinators) {
    // prepare shown/hidden names in the element
    Set<String> showNames = new Set<String>();
    Set<String> hideNames = new Set<String>();
    for (NamespaceCombinator combinator in elementCombinators) {
      if (combinator is ShowElementCombinator) {
        showNames.addAll(combinator.shownNames);
      } else if (combinator is HideElementCombinator) {
        hideNames.addAll(combinator.hiddenNames);
      }
    }
    // match combinators with the node
    for (Combinator combinator in nodeCombinators) {
      if (combinator is ShowCombinator) {
        for (SimpleIdentifier nameNode in combinator.shownNames) {
          String name = nameNode.name;
          _assertTrue(showNames.remove(name));
        }
      } else if (combinator is HideCombinator) {
        for (SimpleIdentifier nameNode in combinator.hiddenNames) {
          String name = nameNode.name;
          _assertTrue(hideNames.remove(name));
        }
      }
    }
    _assertTrue(showNames.isEmpty);
    _assertTrue(hideNames.isEmpty);
  }

  void _assertCompatibleParameter(FormalParameter node,
      ParameterElement element) {
    _assertEquals(node.kind, element.parameterKind);
    if (node.kind == ParameterKind.NAMED) {
      _assertEquals(node.identifier.name, element.name);
    }
    // check parameter type specific properties
    if (node is DefaultFormalParameter) {
      Expression nodeDefault = node.defaultValue;
      if (nodeDefault == null) {
        _assertNull(element.defaultValueCode);
      } else {
        _assertEquals(nodeDefault.toSource(), element.defaultValueCode);
      }
    } else if (node is FieldFormalParameter) {
      _assertTrue(element.isInitializingFormal);
    } else if (node is FunctionTypedFormalParameter) {
      _assertTrue(element.type is FunctionType);
      FunctionType elementType = element.type;
      _assertCompatibleParameters(node.parameters, element.parameters);
      _assertSameType(node.returnType, elementType.returnType);
    } else if (node is SimpleFormalParameter) {
      _assertSameType(node.type, element.type);
      node.identifier.staticElement = element;
      (element as ElementImpl).nameOffset = node.identifier.offset;
      (element as ElementImpl).name = node.identifier.name;
    }
  }

  void _assertCompatibleParameters(FormalParameterList nodes,
      List<ParameterElement> elements) {
    if (nodes == null) {
      return _assertEquals(elements.length, 0);
    }
    List<FormalParameter> parameters = nodes.parameters;
    int length = parameters.length;
    _assertEquals(length, elements.length);
    for (int i = 0; i < length; i++) {
      _assertCompatibleParameter(parameters[i], elements[i]);
    }
  }

  void _assertEquals(Object a, Object b) {
    if (a != b) {
      throw new _DeclarationMismatchException();
    }
  }

  void _assertFalse(bool condition) {
    if (condition) {
      throw new _DeclarationMismatchException();
    }
  }

  void _assertNotNull(Object object) {
    if (object == null) {
      throw new _DeclarationMismatchException();
    }
  }

  void _assertNull(Object object) {
    if (object != null) {
      throw new _DeclarationMismatchException();
    }
  }

  void _assertSameType(TypeName node, DartType type) {
    // no return type == dynamic
    if (node == null) {
      return _assertTrue(type == null || type.isDynamic);
    }
    if (type == null) {
      return _assertTrue(false);
    }
    // prepare name
    Identifier nameIdentifier = node.name;
    if (nameIdentifier is PrefixedIdentifier) {
      nameIdentifier = (nameIdentifier as PrefixedIdentifier).identifier;
    }
    String nodeName = nameIdentifier.name;
    // check specific type kinds
    if (type is InterfaceType) {
      _assertEquals(nodeName, type.name);
      // check arguments
      TypeArgumentList nodeArgumentList = node.typeArguments;
      List<DartType> typeArguments = type.typeArguments;
      if (nodeArgumentList == null) {
        // Node doesn't have type arguments, so all type arguments of the
        // element must be "dynamic".
        for (DartType typeArgument in typeArguments) {
          _assertTrue(typeArgument.isDynamic);
        }
      } else {
        List<TypeName> nodeArguments = nodeArgumentList.arguments;
        _assertSameTypes(nodeArguments, typeArguments);
      }
    } else if (type is TypeParameterType) {
      _assertEquals(nodeName, type.name);
      // TODO(scheglov) it should be possible to rename type parameters
    } else if (type.isVoid) {
      _assertEquals(nodeName, 'void');
    } else if (type.isDynamic) {
      _assertEquals(nodeName, 'dynamic');
    } else {
      // TODO(scheglov) support other types
//      print('node: $node type: $type  type.type: ${type.runtimeType}');
      _assertTrue(false);
    }
  }

  void _assertSameTypeParameter(TypeParameter node,
      TypeParameterElement element) {
    _assertSameType(node.bound, element.bound);
  }

  void _assertSameTypeParameters(TypeParameterList nodesList,
      List<TypeParameterElement> elements) {
    if (nodesList == null) {
      return _assertEquals(elements.length, 0);
    }
    List<TypeParameter> nodes = nodesList.typeParameters;
    int length = nodes.length;
    _assertEquals(length, elements.length);
    for (int i = 0; i < length; i++) {
      _assertSameTypeParameter(nodes[i], elements[i]);
    }
  }

  void _assertSameTypes(List<TypeName> nodes, List<DartType> types) {
    int length = nodes.length;
    _assertEquals(length, types.length);
    for (int i = 0; i < length; i++) {
      _assertSameType(nodes[i], types[i]);
    }
  }

  void _assertTrue(bool condition) {
    if (!condition) {
      throw new _DeclarationMismatchException();
    }
  }

  /**
   * Given that the comparison is to begin with the given [element], capture
   * the enclosing elements that might be used while performing the comparison.
   */
  void _captureEnclosingElements(Element element) {
    Element parent =
        element is CompilationUnitElement ? element : element.enclosingElement;
    while (parent != null) {
      if (parent is CompilationUnitElement) {
        _enclosingUnit = parent as CompilationUnitElement;
        _enclosingLibrary = element.library;
      } else if (parent is ClassElement) {
        if (_enclosingClass == null) {
          _enclosingClass = parent as ClassElement;
        }
      } else if (parent is FunctionTypeAliasElement) {
        if (_enclosingAlias == null) {
          _enclosingAlias = parent as FunctionTypeAliasElement;
        }
      } else if (parent is ParameterElement) {
        if (_enclosingParameter == null) {
          _enclosingParameter = parent as ParameterElement;
        }
      }
      parent = parent.enclosingElement;
    }
  }

  void _gatherElements(Element element) {
    _ElementsGatherer gatherer = new _ElementsGatherer(this);
    element.accept(gatherer);
    // TODO(scheglov) what if a change in a directive?
    if (identical(element, _enclosingLibrary.definingCompilationUnit)) {
      gatherer.addElements(_enclosingLibrary.imports);
      gatherer.addElements(_enclosingLibrary.exports);
      gatherer.addElements(_enclosingLibrary.parts);
    }
  }

  void _processElement(Element element) {
    _assertNotNull(element);
    if (!_allElements.contains(element)) {
      throw new _DeclarationMismatchException();
    }
    _unmatchedElements.remove(element);
  }

  /**
   * Return the [Element] in [elements] with the given [name].
   */
  static Element _findElement(List<Element> elements, String name) {
    for (Element element in elements) {
      if (element.name == name) {
        return element;
      }
    }
    return null;
  }

  /**
   * Return the [UriReferencedElement] from [elements] with the given [uri], or
   * `null` if there is no such element.
   */
  static UriReferencedElement
      _findUriReferencedElement(List<UriReferencedElement> elements, String uri) {
    for (UriReferencedElement element in elements) {
      if (element.uri == uri) {
        return element;
      }
    }
    return null;
  }

  /**
   * Return the value of [literal], or `null` if the string is not a constant
   * string without any string interpolation.
   */
  static String _getStringValue(StringLiteral literal) {
    if (literal is StringInterpolation) {
      return null;
    }
    return literal.stringValue;
  }
}


/**
 * Instances of the class [IncrementalResolver] resolve the smallest portion of
 * an AST structure that we currently know how to resolve.
 */
class IncrementalResolver {
  /**
   * The object used to access the types from the core library.
   */
  final TypeProvider _typeProvider;

  /**
   * The element of the compilation unit being resolved.
   */
  final CompilationUnitElement _definingUnit;

  /**
   * The element for the library containing the compilation unit being resolved.
   */
  LibraryElement _definingLibrary;

  /**
   * The source representing the compilation unit being visited.
   */
  Source _source;

  /**
   * The offset of the changed contents.
   */
  final int _updateOffset;

  /**
   * The number of characters in the original contents that were replaced.
   */
  final int _updateOldLength;

  /**
   * The number of characters in the replacement text.
   */
  final int _updateNewLength;

  ResolutionContext _resolutionContext;

  List<AnalysisError> _resolveErrors = AnalysisError.NO_ERRORS;
  List<AnalysisError> _verifyErrors = AnalysisError.NO_ERRORS;
  List<AnalysisError> _hints = AnalysisError.NO_ERRORS;

  /**
   * Initialize a newly created incremental resolver to resolve a node in the
   * given source in the given library.
   */
  IncrementalResolver(this._typeProvider, this._definingUnit,
      this._updateOffset, this._updateOldLength, this._updateNewLength) {
    _definingLibrary = _definingUnit.library;
    _source = _definingUnit.source;
  }

  /**
   * Resolve [node], reporting any errors or warnings to the given listener.
   *
   * [node] - the root of the AST structure to be resolved.
   */
  void resolve(AstNode node) {
    AstNode rootNode = _findResolutionRoot(node);
    // update elements
    _updateElementNameOffsets(
        _definingUnit,
        _updateOffset,
        _updateNewLength - _updateOldLength);
    if (_elementModelChanged(rootNode)) {
      throw new AnalysisException("Cannot resolve node: element model changed");
    }
    _updateElements(rootNode);
    // resolve
    _resolveReferences(rootNode);
    // verify
    _verify(rootNode);
    _generateHints(rootNode);
  }

  /**
   * Return `true` if the given node can be resolved independently of any other
   * nodes.
   *
   * *Note*: This method needs to be kept in sync with
   * [ScopeBuilder.ContextBuilder].
   *
   * [node] - the node being tested.
   */
  bool _canBeResolved(AstNode node) =>
      node is ClassDeclaration ||
          node is ClassTypeAlias ||
          node is CompilationUnit ||
          node is ConstructorDeclaration ||
          node is FunctionDeclaration ||
          node is FunctionTypeAlias ||
          node is MethodDeclaration;

  /**
   * Return `true` if the portion of the element model defined by the given node
   * has changed.
   *
   * [node] - the node defining the portion of the element model being tested.
   *
   * Throws [AnalysisException] if the correctness of the element model cannot
   * be determined.
   */
  bool _elementModelChanged(AstNode node) {
    // If we are replacing the whole declaration (e.g. rename a parameter), we
    // can try to find the corresponding Element in the enclosing one, see if it
    // is compatible, and if 'yes', then restore and update it.
    // TODO(scheglov) This should be rewritten. It causes validating the whole
    // class, when just one method is changed.
    if (node is Declaration) {
      node = node.parent;
    }
    Element element = _getElement(node);
    if (element == null) {
      throw new AnalysisException(
          "Cannot resolve node: a ${node.runtimeType} does not define an element");
    }
    DeclarationMatcher matcher = new DeclarationMatcher();
    return !matcher.matches(node, element);
  }

  /**
   * Starting at [node], find the smallest AST node that can be resolved
   * independently of any other nodes. Return the node that was found.
   *
   * [node] - the node at which the search is to begin
   *
   * Throws [AnalysisException] if there is no such node.
   */
  AstNode _findResolutionRoot(AstNode node) {
    while (node != null) {
      if (_canBeResolved(node)) {
        return node;
      }
      node = node.parent;
    }
    throw new AnalysisException("Cannot resolve node: no resolvable node");
  }

  void _generateHints(AstNode node) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    CompilationUnit unit = node.getAncestor((n) => n is CompilationUnit);
    AnalysisContext analysisContext = _definingLibrary.context;
    HintGenerator hintGenerator =
        new HintGenerator(<CompilationUnit>[unit], analysisContext, errorListener);
    hintGenerator.generateForLibrary();
    _hints = errorListener.getErrorsForSource(_source);
  }

  /**
   * Return the element defined by [node], or `null` if the node does not
   * define an element.
   */
  Element _getElement(AstNode node) {
    if (node is Declaration) {
      return node.element;
    } else if (node is CompilationUnit) {
      return node.element;
    }
    return null;
  }

  _resolveReferences(AstNode node) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    // prepare context
    _resolutionContext =
        ResolutionContextBuilder.contextFor(node, errorListener);
    Scope scope = _resolutionContext.scope;
    // resolve types
    {
      TypeResolverVisitor visitor = new TypeResolverVisitor.con3(
          _definingLibrary,
          _source,
          _typeProvider,
          scope,
          errorListener);
      node.accept(visitor);
    }
    // resolve variables
    {
      VariableResolverVisitor visitor = new VariableResolverVisitor.con2(
          _definingLibrary,
          _source,
          _typeProvider,
          scope,
          errorListener);
      node.accept(visitor);
    }
    // resolve references
    {
      ResolverVisitor visitor = new ResolverVisitor.con3(
          _definingLibrary,
          _source,
          _typeProvider,
          _resolutionContext.scope,
          errorListener);
      if (_resolutionContext.enclosingClassDeclaration != null) {
        visitor.visitClassDeclarationIncrementally(
            _resolutionContext.enclosingClassDeclaration);
      }
      if (node is Comment) {
        visitor.resolveOnlyCommentInFunctionBody = true;
        node = node.parent;
      }
      visitor.initForIncrementalResolution();
      node.accept(visitor);
    }
    // remember errors
    _resolveErrors = errorListener.getErrorsForSource(_source);
  }

  void _updateElements(AstNode node) {
    // build elements in node
    ElementHolder holder;
    _ElementsRestorer elementsRestorer = new _ElementsRestorer(node);
    try {
      holder = new ElementHolder();
      ElementBuilder builder = new ElementBuilder(holder);
      node.accept(builder);
    } finally {
      elementsRestorer.restore();
    }
    // apply compatible changes to elements
    if (node is FunctionDeclaration) {
      ExecutableElementImpl oldElement = node.element;
      // prepare the new element
      ExecutableElement newElement;
      {
        List<FunctionElement> holderFunctions = holder.functions;
        List<PropertyAccessorElement> holderAccessors = holder.accessors;
        if (holderFunctions.isNotEmpty) {
          newElement = holderFunctions[0];
        } else if (holderAccessors.isNotEmpty) {
          newElement = holderAccessors[0];
        }
      }
      // update the old Element
      oldElement.labels = newElement.labels;
      oldElement.localVariables = newElement.localVariables;
    }
    if (node is MethodDeclaration) {
      ExecutableElementImpl oldElement = node.element;
      // prepare the new element
      ExecutableElement newElement;
      {
        List<MethodElement> holderMethods = holder.methods;
        List<PropertyAccessorElement> holderAccessors = holder.accessors;
        if (holderMethods.isNotEmpty) {
          newElement = holderMethods[0];
        } else if (holderAccessors.isNotEmpty) {
          newElement = holderAccessors[0];
        }
      }
      // update the old Element
      oldElement.labels = newElement.labels;
      oldElement.localVariables = newElement.localVariables;
    }
  }

  void _verify(AstNode node) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, _source);
    ErrorVerifier errorVerifier = new ErrorVerifier(
        errorReporter,
        _definingLibrary,
        _typeProvider,
        new InheritanceManager(_definingLibrary));
    if (_resolutionContext.enclosingClassDeclaration != null) {
      errorVerifier.visitClassDeclarationIncrementally(
          _resolutionContext.enclosingClassDeclaration);
    }
    node.accept(errorVerifier);
    _verifyErrors = errorListener.getErrorsForSource(_source);
  }

  static void _updateElementNameOffsets(Element root, int offset, int delta) {
    root.accept(new _ElementNameOffsetUpdater(offset, delta));
  }
}


class PoorMansIncrementalResolver {
  final TypeProvider _typeProvider;
  final Source _unitSource;
  final Source _librarySource;
  final DartEntry _entry;

  int _updateOffset;
  int _updateDelta;
  int _updateEndOld;
  int _updateEndNew;

  List<AnalysisError> _newScanErrors = <AnalysisError>[];
  List<AnalysisError> _newParseErrors = <AnalysisError>[];
  List<AnalysisError> _newResolveErrors = <AnalysisError>[];
  List<AnalysisError> _newVerifyErrors = <AnalysisError>[];
  List<AnalysisError> _newHints = <AnalysisError>[];

  PoorMansIncrementalResolver(this._typeProvider, this._unitSource,
      this._librarySource, this._entry);

  /**
   * Attempts to update [oldUnit] to the state corresponding to [newCode].
   * Returns `true` if success, or `false` otherwise.
   * The [oldUnit] might be damaged.
   */
  bool resolve(CompilationUnit oldUnit, String newCode) {
    try {
      CompilationUnit newUnit = _parseUnit(newCode);
      _TokenPair firstPair =
          _findFirstDifferentToken(oldUnit.beginToken, newUnit.beginToken);
      _TokenPair lastPair =
          _findLastDifferentToken(oldUnit.endToken, newUnit.endToken);
      if (firstPair != null && lastPair != null) {
        int firstOffsetOld = firstPair.oldToken.offset;
        int firstOffsetNew = firstPair.newToken.offset;
        int lastOffsetOld = lastPair.oldToken.end;
        int lastOffsetNew = lastPair.newToken.end;
        int beginOffsetOld = math.min(firstOffsetOld, lastOffsetOld);
        int endOffsetOld = math.max(firstOffsetOld, lastOffsetOld);
        int beginOffsetNew = math.min(firstOffsetNew, lastOffsetNew);
        int endOffsetNew = math.max(firstOffsetNew, lastOffsetNew);
        // check for a whitespace only change
        if (identical(lastPair.oldToken, firstPair.oldToken) &&
            identical(lastPair.newToken, firstPair.newToken)) {
          _updateOffset = beginOffsetOld - 1;
          _updateEndOld = endOffsetOld;
          _updateDelta = newUnit.length - oldUnit.length;
          if (firstPair.atComment && lastPair.atComment) {
            _resolveComment(oldUnit, newUnit, firstPair);
          } else {
            _shiftTokens(firstPair.oldToken);
            IncrementalResolver._updateElementNameOffsets(
                oldUnit.element,
                _updateOffset,
                _updateDelta);
            _updateEntry();
          }
          return true;
        }
        // Find nodes covering the "old" and "new" token ranges.
        AstNode oldNode =
            _findNodeCovering(oldUnit, beginOffsetOld, endOffsetOld);
        AstNode newNode =
            _findNodeCovering(newUnit, beginOffsetNew, endOffsetNew);
//        print('oldNode: $oldNode');
//        print('newNode: $newNode');
        // Try to find the smallest common node, a FunctionBody currently.
        {
          List<AstNode> oldParents = _getParents(oldNode);
          List<AstNode> newParents = _getParents(newNode);
          int length = math.min(oldParents.length, newParents.length);
          bool found = false;
          for (int i = 0; i < length; i++) {
            AstNode oldParent = oldParents[i];
            AstNode newParent = newParents[i];
            if (oldParent is FunctionDeclaration &&
                newParent is FunctionDeclaration ||
                oldParent is MethodDeclaration && newParent is MethodDeclaration ||
                oldParent is ConstructorDeclaration && newParent is ConstructorDeclaration) {
              oldNode = oldParent;
              newNode = newParent;
              found = true;
            }
            if (oldParent is FunctionBody && newParent is FunctionBody) {
              oldNode = oldParent;
              newNode = newParent;
              found = true;
              break;
            }
          }
          if (!found) {
            return false;
          }
        }
//        print('oldNode: $oldNode');
//        print('newNode: $newNode');
        // prepare update range
        _updateOffset = oldNode.offset;
        _updateEndOld = oldNode.end;
        _updateEndNew = newNode.end;
        _updateDelta = _updateEndNew - _updateEndOld;
        // replace node
        NodeReplacer.replace(oldNode, newNode);
        // update token references
        {
          Token oldBeginToken = _getBeginTokenNotComment(oldNode);
          Token newBeginToken = _getBeginTokenNotComment(newNode);
          if (oldBeginToken.previous.type == TokenType.EOF) {
            oldUnit.beginToken = newBeginToken;
          } else {
            oldBeginToken.previous.setNext(newBeginToken);
          }
          newNode.endToken.setNext(oldNode.endToken.next);
          _shiftTokens(oldNode.endToken.next);
        }
        // perform incremental resolution
        CompilationUnitElement oldUnitElement = oldUnit.element;
        IncrementalResolver incrementalResolver = new IncrementalResolver(
            _typeProvider,
            oldUnitElement,
            _updateOffset,
            oldNode.length,
            newNode.length);
        incrementalResolver.resolve(newNode);
        _newResolveErrors = incrementalResolver._resolveErrors;
        _newVerifyErrors = incrementalResolver._verifyErrors;
        _newHints = incrementalResolver._hints;
        _updateEntry();
//        print('Successfully incrementally resolved.');
        return true;
      }
    } catch (e) {
      // TODO(scheglov) find a way to log these exceptions
//      print(e);
//      print(st);
    }
    return false;
  }

  CompilationUnit _parseUnit(String code) {
    Token token = _scan(code);
    RecordingErrorListener errorListener = new RecordingErrorListener();
    Parser parser = new Parser(_unitSource, errorListener);
    CompilationUnit unit = parser.parseCompilationUnit(token);
    _newParseErrors = errorListener.errors;
    return unit;
  }

  void _resolveComment(CompilationUnit oldUnit, CompilationUnit newUnit,
      _TokenPair firstPair) {
    Token oldToken = firstPair.oldToken;
    int offset = oldToken.precedingComments.offset;
    Comment oldComment = _findNodeCovering(oldUnit, offset, offset);
    Comment newComment = _findNodeCovering(newUnit, offset, offset);
    _updateOffset = oldToken.offset - 1;
    // update token references
    _shiftTokens(firstPair.oldToken);
    _setPrecedingComments(oldToken, newComment.tokens.first);
    // replace node
    NodeReplacer.replace(oldComment, newComment);
    // update elements
    IncrementalResolver._updateElementNameOffsets(
        oldUnit.element,
        _updateOffset,
        _updateDelta);
    _updateEntry();
    // resolve references in the comment
    CompilationUnitElement oldUnitElement = oldUnit.element;
    IncrementalResolver incrementalResolver =
        new IncrementalResolver(_typeProvider, oldUnitElement, _updateOffset, 0, 0);
    incrementalResolver._resolveReferences(newComment);
  }

  Token _scan(String code) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    CharSequenceReader reader = new CharSequenceReader(code);
    Scanner scanner = new Scanner(_unitSource, reader, errorListener);
    Token token = scanner.tokenize();
    _newScanErrors = errorListener.errors;
    return token;
  }

  void _shiftTokens(Token token) {
    while (token != null) {
      if (token.offset > _updateOffset) {
        token.offset += _updateDelta;
      }
      // comments
      _shiftTokens(token.precedingComments);
      if (token is DocumentationCommentToken) {
        for (Token reference in token.references) {
          _shiftTokens(reference);
        }
      }
      // next
      if (token.type == TokenType.EOF) {
        break;
      }
      token = token.next;
    }
  }

  void _updateEntry() {
    _entry.setValue(DartEntry.SCAN_ERRORS, _newScanErrors);
    _entry.setValue(DartEntry.PARSE_ERRORS, _newParseErrors);
    {
      List<AnalysisError> oldErrors =
          _entry.getValueInLibrary(DartEntry.RESOLUTION_ERRORS, _librarySource);
      List<AnalysisError> errors = _updateErrors(oldErrors, _newResolveErrors);
      _entry.setValueInLibrary(
          DartEntry.RESOLUTION_ERRORS,
          _librarySource,
          errors);
    }
    {
      List<AnalysisError> oldErrors =
          _entry.getValueInLibrary(DartEntry.VERIFICATION_ERRORS, _librarySource);
      List<AnalysisError> errors = _updateErrors(oldErrors, _newVerifyErrors);
      _entry.setValueInLibrary(
          DartEntry.VERIFICATION_ERRORS,
          _librarySource,
          errors);
    }
    {
      List<AnalysisError> oldErrors =
          _entry.getValueInLibrary(DartEntry.HINTS, _librarySource);
      List<AnalysisError> errors = _updateErrors(oldErrors, _newHints);
      _entry.setValueInLibrary(DartEntry.HINTS, _librarySource, errors);
    }
  }

  List<AnalysisError> _updateErrors(List<AnalysisError> oldErrors,
      List<AnalysisError> newErrors) {
    List<AnalysisError> errors = new List<AnalysisError>();
    // add updated old errors
    for (AnalysisError error in oldErrors) {
      int errorOffset = error.offset;
      if (errorOffset < _updateOffset) {
        errors.add(error);
      } else if (errorOffset > _updateEndOld) {
        error.offset += _updateDelta;
        errors.add(error);
      }
    }
    // add new errors
    for (AnalysisError error in newErrors) {
      int errorOffset = error.offset;
      if (errorOffset > _updateOffset && errorOffset < _updateEndNew) {
        errors.add(error);
      }
    }
    // done
    return errors;
  }

  static bool _equalToken(Token oldToken, Token newToken, int delta) {
    if (oldToken.type != newToken.type) {
      return false;
    }
    if (newToken.offset - oldToken.offset != delta) {
      return false;
    }
    return oldToken.lexeme == newToken.lexeme;
  }

  static _TokenPair _findFirstDifferentToken(Token oldToken, Token newToken) {
//    print('first ------------');
    while (oldToken.type != TokenType.EOF && newToken.type != TokenType.EOF) {
//      print('old: $oldToken @ ${oldToken.offset}');
//      print('new: $newToken @ ${newToken.offset}');
      {
        Token oldComment = oldToken.precedingComments;
        Token newComment = newToken.precedingComments;
        if (oldComment != null && newComment != null) {
          if (!_equalToken(oldComment, newComment, 0)) {
            return new _TokenPair(oldToken, newToken, true);
          }
        }
      }
      if (!_equalToken(oldToken, newToken, 0)) {
        return new _TokenPair(oldToken, newToken);
      }
      oldToken = oldToken.next;
      newToken = newToken.next;
    }
    return null;
  }

  static _TokenPair _findLastDifferentToken(Token oldToken, Token newToken) {
//    print('last ------------');
    int delta = newToken.offset - oldToken.offset;
    while (oldToken.previous != oldToken && newToken.previous != newToken) {
//      print('old: $oldToken @ ${oldToken.offset}');
//      print('new: $newToken @ ${newToken.offset}');
      if (!_equalToken(oldToken, newToken, delta)) {
        return new _TokenPair(oldToken.next, newToken.next);
      }
      {
        Token oldComment = oldToken.precedingComments;
        Token newComment = newToken.precedingComments;
        if (oldComment != null && newComment != null) {
          if (!_equalToken(oldComment, newComment, delta)) {
            return new _TokenPair(oldToken, newToken, true);
          }
        }
      }
      oldToken = oldToken.previous;
      newToken = newToken.previous;
    }
    return null;
  }

  static AstNode _findNodeCovering(AstNode root, int offset, int end) {
    NodeLocator nodeLocator = new NodeLocator.con2(offset, end);
    return nodeLocator.searchWithin(root);
  }

  static Token _getBeginTokenNotComment(AstNode node) {
    Token oldBeginToken = node.beginToken;
    if (oldBeginToken is CommentToken) {
      oldBeginToken = (oldBeginToken as CommentToken).parent;
    }
    return oldBeginToken;
  }


  static List<AstNode> _getParents(AstNode node) {
    List<AstNode> parents = <AstNode>[];
    while (node != null) {
      parents.insert(0, node);
      node = node.parent;
    }
    return parents;
  }

  /**
   * Set the given [comment] as a "precedingComments" for [parent].
   */
  static void _setPrecedingComments(Token parent, CommentToken comment) {
    if (parent is BeginTokenWithComment) {
      parent.precedingComments = comment;
    } else if (parent is KeywordTokenWithComment) {
      parent.precedingComments = comment;
    } else if (parent is StringTokenWithComment) {
      parent.precedingComments = comment;
    } else if (parent is TokenWithComment) {
      parent.precedingComments = comment;
    } else {
      Type parentType = parent != null ? parent.runtimeType : null;
      throw new AnalysisException('Uknown parent token type: $parentType');
    }
  }
}


/**
 * The context to resolve an [AstNode] in.
 */
class ResolutionContext {
  ClassDeclaration enclosingClassDeclaration;
  ClassElement enclosingClass;
  Scope scope;
}


/**
 * Instances of the class [ResolutionContextBuilder] build the context for a
 * given node in an AST structure. At the moment, this class only handles
 * top-level and class-level declarations.
 */
class ResolutionContextBuilder {
  /**
   * The listener to which analysis errors will be reported.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * The class containing the enclosing [ClassDeclaration], or `null` if we are
   * not in the scope of a class.
   */
  ClassDeclaration _enclosingClassDeclaration;

  /**
   * The class containing the enclosing [ClassElement], or `null` if we are not
   * in the scope of a class.
   */
  ClassElement _enclosingClass;

  /**
   * Initialize a newly created scope builder to generate a scope that will
   * report errors to the given listener.
   */
  ResolutionContextBuilder(this._errorListener);

  Scope _scopeFor(AstNode node) {
    if (node is CompilationUnit) {
      return _scopeForAstNode(node);
    }
    AstNode parent = node.parent;
    if (parent == null) {
      throw new AnalysisException(
          "Cannot create scope: node is not part of a CompilationUnit");
    }
    return _scopeForAstNode(parent);
  }

  /**
   * Return the scope in which the given AST structure should be resolved.
   *
   * *Note:* This method needs to be kept in sync with
   * [IncrementalResolver.canBeResolved].
   *
   * [node] - the root of the AST structure to be resolved.
   *
   * Throws [AnalysisException] if the AST structure has not been resolved or
   * is not part of a [CompilationUnit]
   */
  Scope _scopeForAstNode(AstNode node) {
    if (node is CompilationUnit) {
      return _scopeForCompilationUnit(node);
    }
    AstNode parent = node.parent;
    if (parent == null) {
      throw new AnalysisException(
          "Cannot create scope: node is not part of a CompilationUnit");
    }
    Scope scope = _scopeForAstNode(parent);
    if (node is ClassDeclaration) {
      _enclosingClassDeclaration = node;
      _enclosingClass = node.element;
      if (_enclosingClass == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved class");
      }
      scope = new ClassScope(
          new TypeParameterScope(scope, _enclosingClass),
          _enclosingClass);
    } else if (node is ClassTypeAlias) {
      ClassElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved class type alias");
      }
      scope = new ClassScope(new TypeParameterScope(scope, element), element);
    } else if (node is ConstructorDeclaration) {
      ConstructorElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved constructor");
      }
      FunctionScope functionScope = new FunctionScope(scope, element);
      functionScope.defineParameters();
      scope = functionScope;
    } else if (node is FunctionDeclaration) {
      ExecutableElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved function");
      }
      FunctionScope functionScope = new FunctionScope(scope, element);
      functionScope.defineParameters();
      scope = functionScope;
    } else if (node is FunctionTypeAlias) {
      scope = new FunctionTypeScope(scope, node.element);
    } else if (node is MethodDeclaration) {
      ExecutableElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved method");
      }
      FunctionScope functionScope = new FunctionScope(scope, element);
      functionScope.defineParameters();
      scope = functionScope;
    }
    return scope;
  }

  Scope _scopeForCompilationUnit(CompilationUnit node) {
    CompilationUnitElement unitElement = node.element;
    if (unitElement == null) {
      throw new AnalysisException(
          "Cannot create scope: compilation unit is not resolved");
    }
    LibraryElement libraryElement = unitElement.library;
    if (libraryElement == null) {
      throw new AnalysisException(
          "Cannot create scope: compilation unit is not part of a library");
    }
    return new LibraryScope(libraryElement, _errorListener);
  }

  /**
   * Return the context in which the given AST structure should be resolved.
   *
   * [node] - the root of the AST structure to be resolved.
   * [errorListener] - the listener to which analysis errors will be reported.
   *
   * Throws [AnalysisException] if the AST structure has not been resolved or
   * is not part of a [CompilationUnit]
   */
  static ResolutionContext contextFor(AstNode node,
      AnalysisErrorListener errorListener) {
    if (node == null) {
      throw new AnalysisException("Cannot create context: node is null");
    }
    // build scope
    ResolutionContextBuilder builder =
        new ResolutionContextBuilder(errorListener);
    Scope scope = builder._scopeFor(node);
    // prepare context
    ResolutionContext context = new ResolutionContext();
    context.scope = scope;
    context.enclosingClassDeclaration = builder._enclosingClassDeclaration;
    context.enclosingClass = builder._enclosingClass;
    return context;
  }
}


/**
 * Instances of the class [_DeclarationMismatchException] represent an exception
 * that is thrown when the element model defined by a given AST structure does
 * not match an existing element model.
 */
class _DeclarationMismatchException {
}


class _ElementNameOffsetUpdater extends GeneralizingElementVisitor {
  final int updateOffset;
  final int updateDelta;

  _ElementNameOffsetUpdater(this.updateOffset, this.updateDelta);

  @override
  visitElement(Element element) {
    int nameOffset = element.nameOffset;
    if (nameOffset > updateOffset) {
      (element as ElementImpl).nameOffset = nameOffset + updateDelta;
    }
    super.visitElement(element);
  }
}


class _ElementsGatherer extends GeneralizingElementVisitor {
  final DeclarationMatcher matcher;

  _ElementsGatherer(this.matcher);

  void addElements(List<Element> elements) {
    for (Element element in elements) {
      if (!element.isSynthetic) {
        _addElement(element);
      }
    }
  }

  @override
  visitElement(Element element) {
    _addElement(element);
    super.visitElement(element);
  }

  @override
  visitExecutableElement(ExecutableElement element) {
    _addElement(element);
  }

  @override
  visitParameterElement(ParameterElement element) {
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!element.isSynthetic) {
      _addElement(element);
    }
    // Don't visit children (such as synthetic setter parameters).
  }

  @override
  visitPropertyInducingElement(PropertyInducingElement element) {
    if (!element.isSynthetic) {
      _addElement(element);
    }
    // Don't visit children (such as property accessors).
  }

  @override
  visitTypeParameterElement(TypeParameterElement element) {
  }

  void _addElement(Element element) {
    if (element != null) {
      matcher._allElements.add(element);
      matcher._unmatchedElements.add(element);
    }
  }
}


/**
 * [ElementBuilder] not just builds elements, it also applies them to nodes.
 * But we want to keep externally visible (and referenced) elements instances.
 * So, we need to remember them and restore.
 */
class _ElementsRestorer extends RecursiveAstVisitor {
  final Map<AstNode, Element> _elements = <AstNode, Element>{};

  _ElementsRestorer(AstNode root) {
    root.accept(this);
  }

  void restore() {
    _elements.forEach((AstNode node, Element element) {
      if (node is ConstructorDeclaration) {
        node.element = element;
      } else if (node is FunctionExpression) {
        node.element = element;
      } else if (node is SimpleIdentifier) {
        node.staticElement = element;
      }
    });
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    _elements[node] = node.element;
    super.visitConstructorDeclaration(node);
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _elements[node] = node.element;
    super.visitFunctionExpression(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    _elements[node] = node.staticElement;
  }
}


class _TokenPair {
  final Token oldToken;
  final Token newToken;
  final bool atComment;
  _TokenPair(this.oldToken, this.newToken, [this.atComment = false]);
}
