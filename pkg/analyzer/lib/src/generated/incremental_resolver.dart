// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_resolver;

import 'dart:collection';

import 'ast.dart';
import 'element.dart';
import 'error.dart';
import 'java_engine.dart';
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
   * The class containing the AST nodes being visited, or `null` if we are not in the scope of
   * a class.
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
    String name = node.name.name;
    Token property = node.propertyKeyword;
    ExecutableElement element;
    if (property == null) {
      element = _findElement(_enclosingUnit.functions, name);
      _processElement(element);
    } else {
      PropertyAccessorElement accessor =
          _findElement(_enclosingUnit.accessors, name);
      _assertNotNull(accessor);
      _assertFalse(element.isSynthetic);
      _assertEquals(node.isGetter, accessor.isGetter);
      _assertEquals(node.isSetter, accessor.isSetter);
      element = accessor;
    }
    _processElement(element);
    // TODO(scheglov) test returnType
    _assertSameType(node.returnType, element.returnType);
    _assertCompatibleParameters(
        node.functionExpression.parameters,
        element.parameters);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElement outerAlias = _enclosingAlias;
    try {
      SimpleIdentifier aliasName = node.name;
      _enclosingAlias =
          _findIdentifier(_enclosingUnit.functionTypeAliases, aliasName);
      _processElement(_enclosingAlias);
      super.visitFunctionTypeAlias(node);
    } finally {
      _enclosingAlias = outerAlias;
    }
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
    // prepare element
    Token property = node.propertyKeyword;
    ExecutableElement element;
    if (property == null) {
      element = _findElement(_enclosingClass.methods, name);
    } else {
      PropertyAccessorElement accessor =
          _findElement(_enclosingClass.accessors, name);
      _assertNotNull(accessor);
      _assertFalse(element.isSynthetic);
      _assertEquals(node.isGetter, accessor.isGetter);
      _assertEquals(node.isSetter, accessor.isSetter);
      element = accessor;
    }
    // process element
    _processElement(element);
    // TODO(scheglov) test returnType
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
  visitTypeParameter(TypeParameter node) {
    String name = node.name.name;
    TypeParameterElement element = null;
    if (_enclosingClass != null) {
      element = _findElement(_enclosingClass.typeParameters, name);
    } else if (_enclosingAlias != null) {
      element = _findElement(_enclosingAlias.typeParameters, name);
    }
    _processElement(element);
    _assertSameType(node.bound, element.bound);
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
    if (node is SimpleFormalParameter) {
      _assertSameType(node.type, element.type);
    } else {
      // TODO(scheglov) support other parameter types
      _assertTrue(false);
    }
    // TODO(scheglov) check names of named parameters
  }

  void _assertCompatibleParameters(FormalParameterList nodes,
      List<ParameterElement> elements) {
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

  void _assertNotNull(Element element) {
    if (element == null) {
      throw new _DeclarationMismatchException();
    }
  }

  void _assertNull(Element element) {
    if (element != null) {
      throw new _DeclarationMismatchException();
    }
  }

  void _assertSameType(TypeName node, DartType type) {
    // no return type == dynamic
    if (node == null) {
      return _assertTrue(type == null || type.isDynamic);
    }
    // check specific type kinds
    String nodeName = node.name.name;
    if (type is InterfaceType) {
      _assertEquals(nodeName, type.name);
      // check arguments
      TypeArgumentList nodeArgumentList = node.typeArguments;
      List<DartType> typeArguments = type.typeArguments;
      if (nodeArgumentList == null) {
        _assertTrue(typeArguments.isEmpty);
      } else {
        List<TypeName> nodeArguments = nodeArgumentList.arguments;
        _assertSameTypes(nodeArguments, typeArguments);
      }
    } else if (type is TypeParameterType) {
      _assertEquals(nodeName, type.name);
      // TODO(scheglov) it should be possible to rename type parameters
    } else {
      // TODO(scheglov) support other types
      _assertTrue(false);
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

  /**
   * Return the [Element] in [elements] with the given [name].
   */
  Element _findElement(List<Element> elements, String name) {
    for (Element element in elements) {
      if (element.displayName == name) {
        return element;
      }
    }
    return null;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name.
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param identifier the name node in the declaration of the element to be returned
   * @return the element created for the declaration with the given name
   */
  Element _findIdentifier(List<Element> elements,
      SimpleIdentifier identifier) =>
      _findWithNameAndOffset(elements, identifier.name, identifier.offset);

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name at the given offset.
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param name the name of the element to be returned
   * @param offset the offset of the name of the element to be returned
   * @return the element with the given name and offset
   */
  Element _findWithNameAndOffset(List<Element> elements, String name,
      int offset) {
    for (Element element in elements) {
      if (element.displayName == name && element.nameOffset == offset) {
        return element;
      }
    }
    return null;
  }

  void _gatherElements(Element element) {
    _ElementsGatherer gatherer = new _ElementsGatherer(this);
    element.accept(gatherer);
    // TODO(scheglov) push into CompilationUnitElement
    if (identical(_enclosingUnit, _enclosingLibrary.definingCompilationUnit)) {
      gatherer.addElements(_enclosingLibrary.imports);
      gatherer.addElements(_enclosingLibrary.exports);
      gatherer.addElements(_enclosingLibrary.parts);
    }
  }

  /**
   * Return the value of the given string literal, or `null` if the string is not a constant
   * string without any string interpolation.
   *
   * @param literal the string literal whose value is to be returned
   * @return the value of the given string literal
   */
  String _getStringValue(StringLiteral literal) {
    if (literal is StringInterpolation) {
      return null;
    }
    return literal.stringValue;
  }

  void _processElement(Element element) {
    _assertNotNull(element);
    if (!_allElements.contains(element)) {
      throw new _DeclarationMismatchException();
    }
    _unmatchedElements.remove(element);
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
}


/**
 * Instances of the class [IncrementalResolver] resolve the smallest portion of
 * an AST structure that we currently know how to resolve.
 */
class IncrementalResolver {
  /**
   * The error listener that will be informed of any errors that are found
   * during resolution.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * The object used to access the types from the core library.
   */
  final TypeProvider _typeProvider;

  /**
   * The element for the library containing the compilation unit being resolved.
   */
  final LibraryElement _definingLibrary;

  /**
   * The element of the compilation unit being resolved.
   */
  final CompilationUnitElement _definingUnit;

  /**
   * The source representing the compilation unit being visited.
   */
  final Source _source;

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

  /**
   * Initialize a newly created incremental resolver to resolve a node in the
   * given source in the given library, reporting errors to the given error
   * listener.
   */
  IncrementalResolver(this._errorListener, this._typeProvider,
      this._definingLibrary, this._definingUnit, this._source, this._updateOffset,
      this._updateOldLength, this._updateNewLength);

  /**
   * Resolve [node], reporting any errors or warnings to the given listener.
   *
   * [node] - the root of the AST structure to be resolved.
   */
  void resolve(AstNode node) {
    AstNode rootNode = _findResolutionRoot(node);
    if (_elementModelChanged(rootNode)) {
      throw new AnalysisException("Cannot resolve node: element model changed");
    }
    // update elements
    _definingUnit.accept(
        new _ElementNameOffsetUpdater(
            _updateOffset,
            _updateNewLength - _updateOldLength));
    _updateElements(rootNode);
    // resolve root in scope
    Scope scope = ScopeBuilder.scopeFor(rootNode, _errorListener);
    _resolveTypes(rootNode, scope);
    _resolveVariables(rootNode, scope);
    _resolveReferences(rootNode, scope);
  }

  /**
   * Return `true` if the given node can be resolved independently of any other
   * nodes.
   *
   * *Note*: This method needs to be kept in sync with
   * [ScopeBuilder.scopeForAstNode].
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

  void _resolveReferences(AstNode node, Scope scope) {
    ResolverVisitor visitor = new ResolverVisitor.con3(
        _definingLibrary,
        _source,
        _typeProvider,
        scope,
        _errorListener);
    node.accept(visitor);
  }

  void _resolveTypes(AstNode node, Scope scope) {
    TypeResolverVisitor visitor = new TypeResolverVisitor.con3(
        _definingLibrary,
        _source,
        _typeProvider,
        scope,
        _errorListener);
    node.accept(visitor);
  }

  void _resolveVariables(AstNode node, Scope scope) {
    VariableResolverVisitor visitor = new VariableResolverVisitor.con2(
        _definingLibrary,
        _source,
        _typeProvider,
        scope,
        _errorListener);
    node.accept(visitor);
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
      FunctionElementImpl oldElement = node.element;
      FunctionElementImpl newElement = holder.functions[0];
      oldElement.labels = newElement.labels;
      oldElement.localVariables = newElement.localVariables;
    }
    if (node is MethodDeclaration) {
      MethodElementImpl oldElement = node.element;
      MethodElementImpl newElement = holder.methods[0];
      oldElement.labels = newElement.labels;
      oldElement.localVariables = newElement.localVariables;
    }
  }
}


/**
 * Instances of the class [ScopeBuilder] build the scope for a given node in an
 * AST structure. At the moment, this class only handles top-level and
 * class-level declarations.
 */
class ScopeBuilder {
  /**
   * The listener to which analysis errors will be reported.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * Initialize a newly created scope builder to generate a scope that will report errors to the
   * given listener.
   *
   * @param errorListener the listener to which analysis errors will be reported
   */
  ScopeBuilder(this._errorListener);

  /**
   * Return the scope in which the given AST structure should be resolved.
   *
   * <b>Note:</b> This method needs to be kept in sync with
   * [IncrementalResolver.canBeResolved].
   *
   * @param node the root of the AST structure to be resolved
   * @return the scope in which the given AST structure should be resolved
   * @throws AnalysisException if the AST structure has not been resolved or is not part of a
   *           [CompilationUnit]
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
      ClassElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved class");
      }
      scope = new ClassScope(new TypeParameterScope(scope, element), element);
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
   * Return the scope in which the given AST structure should be resolved.
   *
   * @param node the root of the AST structure to be resolved
   * @param errorListener the listener to which analysis errors will be reported
   * @return the scope in which the given AST structure should be resolved
   * @throws AnalysisException if the AST structure has not been resolved or is not part of a
   *           [CompilationUnit]
   */
  static Scope scopeFor(AstNode node, AnalysisErrorListener errorListener) {
    if (node == null) {
      throw new AnalysisException("Cannot create scope: node is null");
    } else if (node is CompilationUnit) {
      ScopeBuilder builder = new ScopeBuilder(errorListener);
      return builder._scopeForAstNode(node);
    }
    AstNode parent = node.parent;
    if (parent == null) {
      throw new AnalysisException(
          "Cannot create scope: node is not part of a CompilationUnit");
    }
    ScopeBuilder builder = new ScopeBuilder(errorListener);
    return builder._scopeForAstNode(parent);
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
    if (nameOffset >= updateOffset) {
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
