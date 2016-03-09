// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.incremental_resolver;

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/incremental_logger.dart'
    show logger, LoggingTimer;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart' show CONTENT, LINE_INFO;
import 'package:analyzer/task/model.dart';

/**
 * If `true`, an attempt to resolve API-changing modifications is made.
 */
bool _resolveApiChanges = false;

/**
 * This method is used to enable/disable API-changing modifications resolution.
 */
void set test_resolveApiChanges(bool value) {
  _resolveApiChanges = value;
}

/**
 * Instances of the class [DeclarationMatcher] determine whether the element
 * model defined by a given AST structure matches an existing element model.
 */
class DeclarationMatcher extends RecursiveAstVisitor {
  /**
   * The library containing the AST nodes being visited.
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
  ClassElementImpl _enclosingClass;

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
   * A set containing all of the elements were defined in the old element model,
   * but are not defined in the new element model.
   */
  HashSet<Element> _removedElements = new HashSet<Element>();

  /**
   * A set containing all of the elements are defined in the new element model,
   * but were not defined in the old element model.
   */
  HashSet<Element> _addedElements = new HashSet<Element>();

  /**
   * Determines how elements model corresponding to the given [node] differs
   * from the [element].
   */
  DeclarationMatchKind matches(AstNode node, Element element) {
    logger.enter('match $element @ ${element.nameOffset}');
    try {
      _captureEnclosingElements(element);
      _gatherElements(element);
      node.accept(this);
    } on _DeclarationMismatchException {
      logger.log("mismatched");
      return DeclarationMatchKind.MISMATCH;
    } finally {
      logger.exit();
    }
    // no API changes
    if (_removedElements.isEmpty && _addedElements.isEmpty) {
      logger.log("no API changes");
      return DeclarationMatchKind.MATCH;
    }
    // simple API change
    logger.log('_removedElements: $_removedElements');
    logger.log('_addedElements: $_addedElements');
    _removedElements.forEach(_removeElement);
    if (_removedElements.length <= 1 && _addedElements.length == 1) {
      return DeclarationMatchKind.MISMATCH_OK;
    }
    // something more complex
    return DeclarationMatchKind.MISMATCH;
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
    _assertSameAnnotations(node, element);
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
    // matches, set the element
    node.name.staticElement = element;
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    String name = node.name.name;
    ClassElement element = _findElement(_enclosingUnit.types, name);
    _enclosingClass = element;
    _processElement(element);
    _assertSameTypeParameters(node.typeParameters, element.typeParameters);
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
    ConstructorElementImpl element = constructorName == null
        ? _enclosingClass.unnamedConstructor
        : _enclosingClass.getNamedConstructor(constructorName.name);
    _processElement(element);
    _assertEquals(node.constKeyword != null, element.isConst);
    _assertEquals(node.factoryKeyword != null, element.isFactory);
    _assertCompatibleParameters(node.parameters, element.parameters);
    // matches, update the existing element
    ExecutableElement newElement = node.element;
    node.element = element;
    _setLocalElements(element, newElement);
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
    ExecutableElementImpl element;
    if (property == null) {
      element = _findElement(_enclosingUnit.functions, name);
    } else {
      element = _findElement(_enclosingUnit.accessors, name);
    }
    // process element
    _processElement(element);
    _assertSameAnnotations(node, element);
    _assertFalse(element.isSynthetic);
    _assertSameType(node.returnType, element.returnType);
    _assertCompatibleParameters(
        node.functionExpression.parameters, element.parameters);
    _assertBody(node.functionExpression.body, element);
    // matches, update the existing element
    ExecutableElement newElement = node.element;
    node.name.staticElement = element;
    node.functionExpression.element = element;
    _setLocalElements(element, newElement);
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
    ExecutableElementImpl element;
    if (property == null) {
      element = _findElement(_enclosingClass.methods, name);
    } else {
      element = _findElement(_enclosingClass.accessors, name);
    }
    // process element
    ExecutableElement newElement = node.element;
    try {
      _assertNotNull(element);
      _assertSameAnnotations(node, element);
      _assertEquals(node.isStatic, element.isStatic);
      _assertSameType(node.returnType, element.returnType);
      _assertCompatibleParameters(node.parameters, element.parameters);
      _assertBody(node.body, element);
      _removedElements.remove(element);
      // matches, update the existing element
      node.name.staticElement = element;
      _setLocalElements(element, newElement);
    } on _DeclarationMismatchException {
      _removeElement(element);
      // add new element
      if (newElement != null) {
        _addedElements.add(newElement);
        if (newElement is MethodElement) {
          List<MethodElement> methods = _enclosingClass.methods.toList();
          methods.add(newElement);
          _enclosingClass.methods = methods;
        } else {
          List<PropertyAccessorElement> accessors =
              _enclosingClass.accessors.toList();
          accessors.add(newElement);
          _enclosingClass.accessors = accessors;
        }
      }
    }
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
    PropertyInducingElement newElement = node.name.staticElement;
    _processElement(element);
    _assertSameAnnotations(node, element);
    _assertEquals(node.isConst, element.isConst);
    _assertEquals(node.isFinal, element.isFinal);
    if (_enclosingFieldNode != null) {
      _assertEquals(_enclosingFieldNode.isStatic, element.isStatic);
    }
    _assertSameType(
        (node.parent as VariableDeclarationList).type, element.type);
    // matches, restore the existing element
    node.name.staticElement = element;
    if (element is VariableElementImpl) {
      (element as VariableElementImpl).initializer = newElement.initializer;
    }
  }

  @override
  visitWithClause(WithClause node) {
    List<TypeName> nodes = node.mixinTypes;
    List<InterfaceType> types = _enclosingClass.mixins;
    _assertSameTypes(nodes, types);
  }

  /**
   * Assert that the given [body] is compatible with the given [element].
   * It should not be empty if the [element] is not an abstract class member.
   * If it is present, it should have the same async / generator modifiers.
   */
  void _assertBody(FunctionBody body, ExecutableElementImpl element) {
    if (body is EmptyFunctionBody) {
      _assertTrue(element.isAbstract);
    } else {
      _assertFalse(element.isAbstract);
      _assertEquals(body.isSynchronous, element.isSynchronous);
      _assertEquals(body.isGenerator, element.isGenerator);
    }
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

  void _assertCompatibleParameter(
      FormalParameter node, ParameterElement element) {
    _assertEquals(node.kind, element.parameterKind);
    if (node.kind == ParameterKind.NAMED ||
        element.enclosingElement is ConstructorElement) {
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
      _assertCompatibleParameter(node.parameter, element);
    } else if (node is FieldFormalParameter) {
      _assertTrue(element.isInitializingFormal);
      DartType parameterType = element.type;
      if (node.type == null && node.parameters == null) {
        FieldFormalParameterElement parameterElement = element;
        if (!parameterElement.hasImplicitType) {
          _assertTrue(parameterType == null || parameterType.isDynamic);
        }
        if (parameterElement.field != null) {
          _assertEquals(node.identifier.name, element.name);
        }
      } else {
        if (node.parameters != null) {
          _assertTrue(parameterType is FunctionType);
          FunctionType parameterFunctionType = parameterType;
          _assertSameType(node.type, parameterFunctionType.returnType);
        } else {
          _assertSameType(node.type, parameterType);
        }
      }
      _assertCompatibleParameters(node.parameters, element.parameters);
    } else if (node is FunctionTypedFormalParameter) {
      _assertFalse(element.isInitializingFormal);
      _assertTrue(element.type is FunctionType);
      FunctionType elementType = element.type;
      _assertCompatibleParameters(node.parameters, element.parameters);
      _assertSameType(node.returnType, elementType.returnType);
    } else if (node is SimpleFormalParameter) {
      _assertFalse(element.isInitializingFormal);
      _assertSameType(node.type, element.type);
    }
  }

  void _assertCompatibleParameters(
      FormalParameterList nodes, List<ParameterElement> elements) {
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

  /**
   * Asserts that there is an import with the same prefix as the given
   * [prefixNode], which exposes the given [element].
   */
  void _assertElementVisibleWithPrefix(
      SimpleIdentifier prefixNode, Element element) {
    if (prefixNode == null) {
      return;
    }
    String prefixName = prefixNode.name;
    for (ImportElement import in _enclosingLibrary.imports) {
      if (import.prefix != null && import.prefix.name == prefixName) {
        Namespace namespace =
            new NamespaceBuilder().createImportNamespaceForDirective(import);
        Iterable<Element> visibleElements = namespace.definedNames.values;
        if (visibleElements.contains(element)) {
          return;
        }
      }
    }
    _assertTrue(false);
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

  void _assertSameAnnotation(Annotation node, ElementAnnotation annotation) {
    Element element = annotation.element;
    if (element is ConstructorElement) {
      _assertTrue(node.name is SimpleIdentifier);
      _assertNull(node.constructorName);
      TypeName nodeType = new TypeName(node.name, null);
      _assertSameType(nodeType, element.returnType);
      // TODO(scheglov) validate arguments
    }
    if (element is PropertyAccessorElement) {
      _assertTrue(node.name is SimpleIdentifier);
      String nodeName = node.name.name;
      String elementName = element.displayName;
      _assertEquals(nodeName, elementName);
    }
  }

  void _assertSameAnnotations(AnnotatedNode node, Element element) {
    List<Annotation> nodeAnnotations = node.metadata;
    List<ElementAnnotation> elementAnnotations = element.metadata;
    int length = nodeAnnotations.length;
    _assertEquals(elementAnnotations.length, length);
    for (int i = 0; i < length; i++) {
      _assertSameAnnotation(nodeAnnotations[i], elementAnnotations[i]);
    }
  }

  void _assertSameType(TypeName node, DartType type) {
    // no type == dynamic
    if (node == null) {
      return _assertTrue(type == null || type.isDynamic);
    }
    if (type == null) {
      return _assertTrue(false);
    }
    // prepare name
    SimpleIdentifier prefixIdentifier = null;
    Identifier nameIdentifier = node.name;
    if (nameIdentifier is PrefixedIdentifier) {
      PrefixedIdentifier prefixedIdentifier = nameIdentifier;
      prefixIdentifier = prefixedIdentifier.prefix;
      nameIdentifier = prefixedIdentifier.identifier;
    }
    String nodeName = nameIdentifier.name;
    // check specific type kinds
    if (type is ParameterizedType) {
      _assertEquals(nodeName, type.name);
      _assertElementVisibleWithPrefix(prefixIdentifier, type.element);
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
      logger.log('node: $node type: $type  type.type: ${type.runtimeType}');
      _assertTrue(false);
    }
  }

  void _assertSameTypeParameter(
      TypeParameter node, TypeParameterElement element) {
    _assertSameType(node.bound, element.bound);
  }

  void _assertSameTypeParameters(
      TypeParameterList nodesList, List<TypeParameterElement> elements) {
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
        _enclosingUnit = parent;
        _enclosingLibrary = element.library;
      } else if (parent is ClassElement) {
        if (_enclosingClass == null) {
          _enclosingClass = parent;
        }
      } else if (parent is FunctionTypeAliasElement) {
        if (_enclosingAlias == null) {
          _enclosingAlias = parent;
        }
      } else if (parent is ParameterElement) {
        if (_enclosingParameter == null) {
          _enclosingParameter = parent;
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
    _removedElements.remove(element);
  }

  void _removeElement(Element element) {
    if (element != null) {
      Element enclosingElement = element.enclosingElement;
      if (element is MethodElement) {
        ClassElement classElement = enclosingElement;
        _removeIdenticalElement(classElement.methods, element);
      } else if (element is PropertyAccessorElement) {
        if (enclosingElement is ClassElement) {
          _removeIdenticalElement(enclosingElement.accessors, element);
        }
        if (enclosingElement is CompilationUnitElement) {
          _removeIdenticalElement(enclosingElement.accessors, element);
        }
      }
    }
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
  static UriReferencedElement _findUriReferencedElement(
      List<UriReferencedElement> elements, String uri) {
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

  /**
   * Removes the first element identical to the given [element] from [elements].
   */
  static void _removeIdenticalElement(List elements, Object element) {
    int length = elements.length;
    for (int i = 0; i < length; i++) {
      if (identical(elements[i], element)) {
        elements.removeAt(i);
        return;
      }
    }
  }

  static void _setLocalElements(
      ExecutableElementImpl to, ExecutableElement from) {
    if (from != null) {
      to.functions = from.functions;
      to.labels = from.labels;
      to.localVariables = from.localVariables;
      to.parameters = from.parameters;
    }
  }
}

/**
 * Describes how declarations match an existing elements model.
 */
class DeclarationMatchKind {
  /**
   * Complete match, no API changes.
   */
  static const MATCH = const DeclarationMatchKind('MATCH');

  /**
   * Has API changes that we might be able to resolve incrementally.
   */
  static const MISMATCH_OK = const DeclarationMatchKind('MISMATCH_OK');

  /**
   * Has API changes that we cannot resolve incrementally.
   */
  static const MISMATCH = const DeclarationMatchKind('MISMATCH');

  final String name;

  const DeclarationMatchKind(this.name);

  @override
  String toString() => name;
}

/**
 * The [Delta] implementation used by incremental resolver.
 * It keeps Dart results that are either don't change or are updated.
 */
class IncrementalBodyDelta extends Delta {
  /**
   * The offset of the changed contents.
   */
  final int updateOffset;

  /**
   * The end of the changed contents in the old unit.
   */
  final int updateEndOld;

  /**
   * The end of the changed contents in the new unit.
   */
  final int updateEndNew;

  /**
   * The delta between [updateEndNew] and [updateEndOld].
   */
  final int updateDelta;

  IncrementalBodyDelta(Source source, this.updateOffset, this.updateEndOld,
      this.updateEndNew, this.updateDelta)
      : super(source);

  @override
  DeltaResult validate(InternalAnalysisContext context, AnalysisTarget target,
      ResultDescriptor descriptor) {
    // A body change delta should never leak outside its source.
    // It can cause invalidation of results (e.g. hints) in other sources,
    // but only when a result in the updated source is INVALIDATE_NO_DELTA.
    if (target.source != source) {
      return DeltaResult.STOP;
    }
    // don't invalidate results of standard Dart tasks
    bool isByTask(TaskDescriptor taskDescriptor) {
      return taskDescriptor.results.contains(descriptor);
    }
    if (descriptor == CONTENT) {
      return DeltaResult.KEEP_CONTINUE;
    }
    if (target is LibrarySpecificUnit && target.unit != source) {
      if (isByTask(GatherUsedLocalElementsTask.DESCRIPTOR) ||
          isByTask(GatherUsedImportedElementsTask.DESCRIPTOR)) {
        return DeltaResult.KEEP_CONTINUE;
      }
    }
    if (isByTask(BuildCompilationUnitElementTask.DESCRIPTOR) ||
        isByTask(BuildDirectiveElementsTask.DESCRIPTOR) ||
        isByTask(BuildEnumMemberElementsTask.DESCRIPTOR) ||
        isByTask(BuildExportNamespaceTask.DESCRIPTOR) ||
        isByTask(BuildLibraryElementTask.DESCRIPTOR) ||
        isByTask(BuildPublicNamespaceTask.DESCRIPTOR) ||
        isByTask(BuildSourceExportClosureTask.DESCRIPTOR) ||
        isByTask(ComputeConstantDependenciesTask.DESCRIPTOR) ||
        isByTask(ComputeConstantValueTask.DESCRIPTOR) ||
        isByTask(ComputeLibraryCycleTask.DESCRIPTOR) ||
        isByTask(ComputePropagableVariableDependenciesTask.DESCRIPTOR) ||
        isByTask(DartErrorsTask.DESCRIPTOR) ||
        isByTask(ReadyLibraryElement2Task.DESCRIPTOR) ||
        isByTask(ReadyLibraryElement5Task.DESCRIPTOR) ||
        isByTask(ReadyLibraryElement6Task.DESCRIPTOR) ||
        isByTask(ReadyResolvedUnitTask.DESCRIPTOR) ||
        isByTask(EvaluateUnitConstantsTask.DESCRIPTOR) ||
        isByTask(GenerateHintsTask.DESCRIPTOR) ||
        isByTask(InferInstanceMembersInUnitTask.DESCRIPTOR) ||
        isByTask(InferStaticVariableTypesInUnitTask.DESCRIPTOR) ||
        isByTask(LibraryErrorsReadyTask.DESCRIPTOR) ||
        isByTask(LibraryUnitErrorsTask.DESCRIPTOR) ||
        isByTask(ParseDartTask.DESCRIPTOR) ||
        isByTask(PartiallyResolveUnitReferencesTask.DESCRIPTOR) ||
        isByTask(PropagateVariableTypesInLibraryClosureTask.DESCRIPTOR) ||
        isByTask(PropagateVariableTypesInLibraryTask.DESCRIPTOR) ||
        isByTask(PropagateVariableTypesInUnitTask.DESCRIPTOR) ||
        isByTask(PropagateVariableTypeTask.DESCRIPTOR) ||
        isByTask(ScanDartTask.DESCRIPTOR) ||
        isByTask(ResolveConstantExpressionTask.DESCRIPTOR) ||
        isByTask(ResolveInstanceFieldsInUnitTask.DESCRIPTOR) ||
        isByTask(ResolveLibraryReferencesTask.DESCRIPTOR) ||
        isByTask(ResolveLibraryTask.DESCRIPTOR) ||
        isByTask(ResolveLibraryTypeNamesTask.DESCRIPTOR) ||
        isByTask(ResolveUnitTask.DESCRIPTOR) ||
        isByTask(ResolveUnitTypeNamesTask.DESCRIPTOR) ||
        isByTask(ResolveVariableReferencesTask.DESCRIPTOR) ||
        isByTask(StrongModeVerifyUnitTask.DESCRIPTOR) ||
        isByTask(VerifyUnitTask.DESCRIPTOR)) {
      return DeltaResult.KEEP_CONTINUE;
    }
    // invalidate all the other results
    return DeltaResult.INVALIDATE_NO_DELTA;
  }
}

/**
 * Instances of the class [IncrementalResolver] resolve the smallest portion of
 * an AST structure that we currently know how to resolve.
 */
class IncrementalResolver {
  /**
   * The element of the compilation unit being resolved.
   */
  final CompilationUnitElementImpl _definingUnit;

  /**
   * The context the compilation unit being resolved in.
   */
  final AnalysisContext _context;

  /**
   * The object used to access the types from the core library.
   */
  final TypeProvider _typeProvider;

  /**
   * The type system primitives.
   */
  final TypeSystem _typeSystem;

  /**
   * The element for the library containing the compilation unit being resolved.
   */
  final LibraryElementImpl _definingLibrary;

  final AnalysisCache _cache;

  /**
   * The [CacheEntry] corresponding to the source being resolved.
   */
  final CacheEntry newSourceEntry;

  /**
   * The [CacheEntry] corresponding to the [LibrarySpecificUnit] being resolved.
   */
  final CacheEntry newUnitEntry;

  /**
   * The source representing the compilation unit being visited.
   */
  final Source _source;

  /**
   * The source representing the library of the compilation unit being visited.
   */
  final Source _librarySource;

  /**
   * The offset of the changed contents.
   */
  final int _updateOffset;

  /**
   * The end of the changed contents in the old unit.
   */
  final int _updateEndOld;

  /**
   * The end of the changed contents in the new unit.
   */
  final int _updateEndNew;

  /**
   * The delta between [_updateEndNew] and [_updateEndOld].
   */
  final int _updateDelta;

  /**
   * The set of [AnalysisError]s that have been already shifted.
   */
  final Set<AnalysisError> _alreadyShiftedErrors = new HashSet.identity();

  final RecordingErrorListener errorListener = new RecordingErrorListener();
  ResolutionContext _resolutionContext;

  List<AnalysisError> _resolveErrors = AnalysisError.NO_ERRORS;
  List<AnalysisError> _verifyErrors = AnalysisError.NO_ERRORS;

  /**
   * Initialize a newly created incremental resolver to resolve a node in the
   * given source in the given library.
   */
  IncrementalResolver(
      this._cache,
      this.newSourceEntry,
      this.newUnitEntry,
      CompilationUnitElementImpl definingUnit,
      this._updateOffset,
      int updateEndOld,
      int updateEndNew)
      : _definingUnit = definingUnit,
        _context = definingUnit.context,
        _typeProvider = definingUnit.context.typeProvider,
        _typeSystem = definingUnit.context.typeSystem,
        _definingLibrary = definingUnit.library,
        _source = definingUnit.source,
        _librarySource = definingUnit.library.source,
        _updateEndOld = updateEndOld,
        _updateEndNew = updateEndNew,
        _updateDelta = updateEndNew - updateEndOld;

  /**
   * Resolve [node], reporting any errors or warnings to the given listener.
   *
   * [node] - the root of the AST structure to be resolved.
   *
   * Returns `true` if resolution was successful.
   */
  bool resolve(AstNode node) {
    logger.enter('resolve: $_definingUnit');
    try {
      AstNode rootNode = _findResolutionRoot(node);
      _prepareResolutionContext(rootNode);
      // update elements
      _updateCache();
      _updateElementNameOffsets();
      _buildElements(rootNode);
      if (!_canBeIncrementallyResolved(rootNode)) {
        return false;
      }
      // resolve
      _resolveReferences(rootNode);
      _computeConstants(rootNode);
      _resolveErrors = errorListener.getErrorsForSource(_source);
      // verify
      _verify(rootNode);
      _context.invalidateLibraryHints(_librarySource);
      // update entry errors
      _updateEntry();
      // OK
      return true;
    } finally {
      logger.exit();
    }
  }

  void _buildElements(AstNode node) {
    LoggingTimer timer = logger.startTimer();
    try {
      ElementHolder holder = new ElementHolder();
      ElementBuilder builder = new ElementBuilder(holder, _definingUnit);
      if (_resolutionContext.enclosingClassDeclaration != null) {
        builder.visitClassDeclarationIncrementally(
            _resolutionContext.enclosingClassDeclaration);
      }
      node.accept(builder);
    } finally {
      timer.stop('build elements');
    }
  }

  /**
   * Return `true` if [node] does not have element model changes, or these
   * changes can be incrementally propagated.
   */
  bool _canBeIncrementallyResolved(AstNode node) {
    // If we are replacing the whole declaration, this means that its signature
    // is changed. It might be an API change, or not.
    //
    // If, for example, a required parameter is changed, it is not an API
    // change, but we want to find the existing corresponding Element in the
    // enclosing one, set it for the node and update as needed.
    //
    // If, for example, the name of a method is changed, it is an API change,
    // we need to know the old Element and the new Element. Again, we need to
    // check the whole enclosing Element.
    if (node is Declaration) {
      node = node.parent;
    }
    Element element = _getElement(node);
    DeclarationMatcher matcher = new DeclarationMatcher();
    DeclarationMatchKind matchKind = matcher.matches(node, element);
    if (matchKind == DeclarationMatchKind.MATCH) {
      return true;
    }
    // mismatch that cannot be incrementally fixed
    return false;
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
      node is MethodDeclaration ||
      node is TopLevelVariableDeclaration;

  /**
   * Compute a value for all of the constants in the given [node].
   */
  void _computeConstants(AstNode node) {
    // compute values
    {
      CompilationUnit unit = node.getAncestor((n) => n is CompilationUnit);
      ConstantValueComputer computer = new ConstantValueComputer(_context,
          _typeProvider, _context.declaredVariables, null, _typeSystem);
      computer.add(unit, _source, _librarySource);
      computer.computeValues();
    }
    // validate
    {
      ErrorReporter errorReporter = new ErrorReporter(errorListener, _source);
      ConstantVerifier constantVerifier = new ConstantVerifier(errorReporter,
          _definingLibrary, _typeProvider, _context.declaredVariables);
      node.accept(constantVerifier);
    }
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

  void _prepareResolutionContext(AstNode node) {
    if (_resolutionContext == null) {
      _resolutionContext =
          ResolutionContextBuilder.contextFor(node, errorListener);
    }
  }

  _resolveReferences(AstNode node) {
    LoggingTimer timer = logger.startTimer();
    try {
      _prepareResolutionContext(node);
      Scope scope = _resolutionContext.scope;
      // resolve types
      {
        TypeResolverVisitor visitor = new TypeResolverVisitor(
            _definingLibrary, _source, _typeProvider, errorListener,
            nameScope: scope);
        node.accept(visitor);
      }
      // resolve variables
      {
        VariableResolverVisitor visitor = new VariableResolverVisitor(
            _definingLibrary, _source, _typeProvider, errorListener,
            nameScope: scope);
        node.accept(visitor);
      }
      // resolve references
      {
        ResolverVisitor visitor = new ResolverVisitor(
            _definingLibrary, _source, _typeProvider, errorListener,
            nameScope: scope);
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
    } finally {
      timer.stop('resolve references');
    }
  }

  void _shiftEntryErrors() {
    _shiftErrors_NEW(HINTS);
    _shiftErrors_NEW(LINTS);
    _shiftErrors_NEW(LIBRARY_UNIT_ERRORS);
    _shiftErrors_NEW(RESOLVE_TYPE_NAMES_ERRORS);
    _shiftErrors_NEW(RESOLVE_UNIT_ERRORS);
    _shiftErrors_NEW(STRONG_MODE_ERRORS);
    _shiftErrors_NEW(VARIABLE_REFERENCE_ERRORS);
    _shiftErrors_NEW(VERIFY_ERRORS);
  }

  void _shiftErrors(List<AnalysisError> errors) {
    for (AnalysisError error in errors) {
      if (_alreadyShiftedErrors.add(error)) {
        int errorOffset = error.offset;
        if (errorOffset > _updateOffset) {
          error.offset += _updateDelta;
        }
      }
    }
  }

  void _shiftErrors_NEW(ResultDescriptor<List<AnalysisError>> descriptor) {
    List<AnalysisError> errors = newUnitEntry.getValue(descriptor);
    _shiftErrors(errors);
  }

  void _updateCache() {
    if (newSourceEntry != null) {
      LoggingTimer timer = logger.startTimer();
      try {
        newSourceEntry.setState(CONTENT, CacheState.INVALID,
            delta: new IncrementalBodyDelta(_source, _updateOffset,
                _updateEndOld, _updateEndNew, _updateDelta));
      } finally {
        timer.stop('invalidate cache with delta');
      }
    }
  }

  void _updateElementNameOffsets() {
    LoggingTimer timer = logger.startTimer();
    try {
      _definingUnit.accept(
          new _ElementOffsetUpdater(_updateOffset, _updateDelta, _cache));
      _definingUnit.afterIncrementalResolution();
    } finally {
      timer.stop('update element offsets');
    }
  }

  void _updateEntry() {
    _updateErrors_NEW(RESOLVE_TYPE_NAMES_ERRORS, []);
    _updateErrors_NEW(RESOLVE_UNIT_ERRORS, _resolveErrors);
    _updateErrors_NEW(VARIABLE_REFERENCE_ERRORS, []);
    _updateErrors_NEW(VERIFY_ERRORS, _verifyErrors);
    // invalidate results we don't update incrementally
    newUnitEntry.setState(STRONG_MODE_ERRORS, CacheState.INVALID);
    newUnitEntry.setState(USED_IMPORTED_ELEMENTS, CacheState.INVALID);
    newUnitEntry.setState(USED_LOCAL_ELEMENTS, CacheState.INVALID);
    newUnitEntry.setState(HINTS, CacheState.INVALID);
    newUnitEntry.setState(LINTS, CacheState.INVALID);
  }

  List<AnalysisError> _updateErrors(
      List<AnalysisError> oldErrors, List<AnalysisError> newErrors) {
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

  void _updateErrors_NEW(ResultDescriptor<List<AnalysisError>> descriptor,
      List<AnalysisError> newErrors) {
    List<AnalysisError> oldErrors = newUnitEntry.getValue(descriptor);
    List<AnalysisError> errors = _updateErrors(oldErrors, newErrors);
    newUnitEntry.setValueIncremental(descriptor, errors, true);
  }

  void _verify(AstNode node) {
    LoggingTimer timer = logger.startTimer();
    try {
      RecordingErrorListener errorListener = new RecordingErrorListener();
      ErrorReporter errorReporter = new ErrorReporter(errorListener, _source);
      ErrorVerifier errorVerifier = new ErrorVerifier(
          errorReporter,
          _definingLibrary,
          _typeProvider,
          new InheritanceManager(_definingLibrary),
          _context.analysisOptions.enableSuperMixins,
          _context.analysisOptions.enableAssertMessage);
      if (_resolutionContext.enclosingClassDeclaration != null) {
        errorVerifier.visitClassDeclarationIncrementally(
            _resolutionContext.enclosingClassDeclaration);
      }
      node.accept(errorVerifier);
      _verifyErrors = errorListener.getErrorsForSource(_source);
    } finally {
      timer.stop('verify');
    }
  }
}

class PoorMansIncrementalResolver {
  final TypeProvider _typeProvider;
  final Source _unitSource;
  final AnalysisCache _cache;

  /**
   * The [CacheEntry] corresponding to the source being resolved.
   */
  final CacheEntry _sourceEntry;

  /**
   * The [CacheEntry] corresponding to the [LibrarySpecificUnit] being resolved.
   */
  final CacheEntry _unitEntry;

  final CompilationUnit _oldUnit;
  CompilationUnitElement _unitElement;

  int _updateOffset;
  int _updateDelta;
  int _updateEndOld;
  int _updateEndNew;

  LineInfo _newLineInfo;
  List<AnalysisError> _newScanErrors = <AnalysisError>[];
  List<AnalysisError> _newParseErrors = <AnalysisError>[];

  PoorMansIncrementalResolver(
      this._typeProvider,
      this._unitSource,
      this._cache,
      this._sourceEntry,
      this._unitEntry,
      this._oldUnit,
      bool resolveApiChanges) {
    _resolveApiChanges = resolveApiChanges;
  }

  /**
   * Attempts to update [_oldUnit] to the state corresponding to [newCode].
   * Returns `true` if success, or `false` otherwise.
   * The [_oldUnit] might be damaged.
   */
  bool resolve(String newCode) {
    logger.enter('diff/resolve $_unitSource');
    try {
      // prepare old unit
      if (!_areCurlyBracketsBalanced(_oldUnit.beginToken)) {
        logger.log('Unbalanced number of curly brackets in the old unit.');
        return false;
      }
      _unitElement = _oldUnit.element;
      // prepare new unit
      CompilationUnit newUnit = _parseUnit(newCode);
      if (!_areCurlyBracketsBalanced(newUnit.beginToken)) {
        logger.log('Unbalanced number of curly brackets in the new unit.');
        return false;
      }
      // find difference
      _TokenPair firstPair =
          _findFirstDifferentToken(_oldUnit.beginToken, newUnit.beginToken);
      _TokenPair lastPair =
          _findLastDifferentToken(_oldUnit.endToken, newUnit.endToken);
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
          _updateEndNew = endOffsetNew;
          _updateDelta = newUnit.length - _oldUnit.length;
          // A Dart documentation comment change.
          if (firstPair.kind == _TokenDifferenceKind.COMMENT_DOC) {
            bool success = _resolveCommentDoc(newUnit, firstPair);
            logger.log('Documentation comment resolved: $success');
            return success;
          }
          // A pure whitespace change.
          if (firstPair.kind == _TokenDifferenceKind.OFFSET) {
            logger.log('Whitespace change.');
            _shiftTokens(firstPair.oldToken);
            {
              IncrementalResolver incrementalResolver = new IncrementalResolver(
                  _cache,
                  _sourceEntry,
                  _unitEntry,
                  _unitElement,
                  _updateOffset,
                  _updateEndOld,
                  _updateEndNew);
              incrementalResolver._updateCache();
              incrementalResolver._updateElementNameOffsets();
              incrementalResolver._shiftEntryErrors();
            }
            _updateEntry();
            logger.log('Success.');
            return true;
          }
          // fall-through, end-of-line comment
        }
        // Find nodes covering the "old" and "new" token ranges.
        AstNode oldNode =
            _findNodeCovering(_oldUnit, beginOffsetOld, endOffsetOld - 1);
        AstNode newNode =
            _findNodeCovering(newUnit, beginOffsetNew, endOffsetNew - 1);
        logger.log(() => 'oldNode: $oldNode');
        logger.log(() => 'newNode: $newNode');
        // Try to find the smallest common node, a FunctionBody currently.
        {
          List<AstNode> oldParents = _getParents(oldNode);
          List<AstNode> newParents = _getParents(newNode);
          // fail if an initializer change
          if (oldParents.any((n) => n is ConstructorInitializer) ||
              newParents.any((n) => n is ConstructorInitializer)) {
            logger.log('Failure: a change in a constructor initializer');
            return false;
          }
          // find matching methods / bodies
          int length = math.min(oldParents.length, newParents.length);
          bool found = false;
          for (int i = 0; i < length; i++) {
            AstNode oldParent = oldParents[i];
            AstNode newParent = newParents[i];
            if (oldParent is CompilationUnit && newParent is CompilationUnit) {
              int oldLength = oldParent.declarations.length;
              int newLength = newParent.declarations.length;
              if (oldLength != newLength) {
                logger.log(
                    'Failure: unit declarations mismatch $oldLength vs. $newLength');
                return false;
              }
            } else if (oldParent is ClassDeclaration &&
                newParent is ClassDeclaration) {
              int oldLength = oldParent.members.length;
              int newLength = newParent.members.length;
              if (oldLength != newLength) {
                logger.log(
                    'Failure: class declarations mismatch $oldLength vs. $newLength');
                return false;
              }
            } else if (oldParent is FunctionDeclaration &&
                    newParent is FunctionDeclaration ||
                oldParent is ConstructorDeclaration &&
                    newParent is ConstructorDeclaration ||
                oldParent is MethodDeclaration &&
                    newParent is MethodDeclaration) {
              Element oldElement = (oldParent as Declaration).element;
              if (new DeclarationMatcher().matches(newParent, oldElement) ==
                  DeclarationMatchKind.MATCH) {
                oldNode = oldParent;
                newNode = newParent;
                found = true;
              } else {
                return false;
              }
            } else if (oldParent is FunctionBody && newParent is FunctionBody) {
              if (oldParent is BlockFunctionBody &&
                  newParent is BlockFunctionBody) {
                oldNode = oldParent;
                newNode = newParent;
                found = true;
                break;
              }
              logger.log('Failure: not a block function body.');
              return false;
            } else if (oldParent is FunctionExpression &&
                newParent is FunctionExpression) {
              // skip
            } else {
              logger.log('Failure: old and new parent mismatch'
                  ' ${oldParent.runtimeType} vs. ${newParent.runtimeType}');
              return false;
            }
          }
          if (!found) {
            logger.log('Failure: no enclosing function body or executable.');
            return false;
          }
          // fail if a comment change outside the bodies
          if (firstPair.kind == _TokenDifferenceKind.COMMENT) {
            if (beginOffsetOld <= oldNode.offset ||
                beginOffsetNew <= newNode.offset) {
              logger.log('Failure: comment outside a function body.');
              return false;
            }
          }
        }
        logger.log(() => 'oldNode: $oldNode');
        logger.log(() => 'newNode: $newNode');
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
            _oldUnit.beginToken = newBeginToken;
          } else {
            oldBeginToken.previous.setNext(newBeginToken);
          }
          newNode.endToken.setNext(oldNode.endToken.next);
          _shiftTokens(oldNode.endToken.next);
        }
        // perform incremental resolution
        IncrementalResolver incrementalResolver = new IncrementalResolver(
            _cache,
            _sourceEntry,
            _unitEntry,
            _unitElement,
            _updateOffset,
            _updateEndOld,
            _updateEndNew);
        bool success = incrementalResolver.resolve(newNode);
        // check if success
        if (!success) {
          logger.log('Failure: element model changed.');
          return false;
        }
        // update DartEntry
        _updateEntry();
        logger.log('Success.');
        return true;
      }
    } catch (e, st) {
      logger.logException(e, st);
      logger.log('Failure: exception.');
      // The incremental resolver log is usually turned off,
      // so also log the exception to the instrumentation log.
      AnalysisEngine.instance.logger.logError(
          'Failure in incremental resolver', new CaughtException(e, st));
    } finally {
      logger.exit();
    }
    return false;
  }

  CompilationUnit _parseUnit(String code) {
    LoggingTimer timer = logger.startTimer();
    try {
      Token token = _scan(code);
      RecordingErrorListener errorListener = new RecordingErrorListener();
      Parser parser = new Parser(_unitSource, errorListener);
      AnalysisOptions options = _unitElement.context.analysisOptions;
      parser.parseConditionalDirectives = options.enableConditionalDirectives;
      parser.parseGenericMethods = options.enableGenericMethods;
      CompilationUnit unit = parser.parseCompilationUnit(token);
      _newParseErrors = errorListener.errors;
      return unit;
    } finally {
      timer.stop('parse');
    }
  }

  /**
   * Attempts to resolve a documentation comment change.
   * Returns `true` if success.
   */
  bool _resolveCommentDoc(CompilationUnit newUnit, _TokenPair firstPair) {
    Token oldToken = firstPair.oldToken;
    Token newToken = firstPair.newToken;
    CommentToken oldComments = oldToken.precedingComments;
    CommentToken newComments = newToken.precedingComments;
    if (oldComments == null || newComments == null) {
      return false;
    }
    // find nodes
    int offset = oldComments.offset;
    logger.log('offset: $offset');
    AstNode oldNode = _findNodeCovering(_oldUnit, offset, offset);
    AstNode newNode = _findNodeCovering(newUnit, offset, offset);
    if (oldNode is! Comment || newNode is! Comment) {
      return false;
    }
    Comment oldComment = oldNode;
    Comment newComment = newNode;
    logger.log('oldComment.beginToken: ${oldComment.beginToken}');
    logger.log('newComment.beginToken: ${newComment.beginToken}');
    _updateOffset = oldToken.offset - 1;
    // update token references
    _shiftTokens(firstPair.oldToken);
    _setPrecedingComments(oldToken, newComment.tokens.first);
    // replace node
    NodeReplacer.replace(oldComment, newComment);
    // update elements
    IncrementalResolver incrementalResolver = new IncrementalResolver(
        _cache,
        _sourceEntry,
        _unitEntry,
        _unitElement,
        _updateOffset,
        _updateEndOld,
        _updateEndNew);
    incrementalResolver._updateCache();
    incrementalResolver._updateElementNameOffsets();
    incrementalResolver._shiftEntryErrors();
    _updateEntry();
    // resolve references in the comment
    incrementalResolver._resolveReferences(newComment);
    // OK
    return true;
  }

  Token _scan(String code) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    CharSequenceReader reader = new CharSequenceReader(code);
    Scanner scanner = new Scanner(_unitSource, reader, errorListener);
    Token token = scanner.tokenize();
    _newLineInfo = new LineInfo(scanner.lineStarts);
    _newScanErrors = errorListener.errors;
    return token;
  }

  /**
   * Set the given [comment] as a "precedingComments" for [token].
   */
  void _setPrecedingComments(Token token, CommentToken comment) {
    if (token is BeginTokenWithComment) {
      token.precedingComments = comment;
    } else if (token is KeywordTokenWithComment) {
      token.precedingComments = comment;
    } else if (token is StringTokenWithComment) {
      token.precedingComments = comment;
    } else if (token is TokenWithComment) {
      token.precedingComments = comment;
    } else {
      Type parentType = token != null ? token.runtimeType : null;
      throw new AnalysisException('Uknown parent token type: $parentType');
    }
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
    // scan results
    _sourceEntry.setValueIncremental(SCAN_ERRORS, _newScanErrors, true);
    _sourceEntry.setValueIncremental(LINE_INFO, _newLineInfo, false);
    // parse results
    _sourceEntry.setValueIncremental(PARSE_ERRORS, _newParseErrors, true);
    _sourceEntry.setValueIncremental(PARSED_UNIT, _oldUnit, false);
  }

  /**
   * Checks if [token] has a balanced number of open and closed curly brackets.
   */
  static bool _areCurlyBracketsBalanced(Token token) {
    int numOpen = _getTokenCount(token, TokenType.OPEN_CURLY_BRACKET);
    int numOpen2 =
        _getTokenCount(token, TokenType.STRING_INTERPOLATION_EXPRESSION);
    int numClosed = _getTokenCount(token, TokenType.CLOSE_CURLY_BRACKET);
    return numOpen + numOpen2 == numClosed;
  }

  static _TokenDifferenceKind _compareToken(
      Token oldToken, Token newToken, int delta, bool forComment) {
    while (true) {
      if (oldToken == null && newToken == null) {
        return null;
      }
      if (oldToken == null || newToken == null) {
        return _TokenDifferenceKind.CONTENT;
      }
      if (oldToken.type != newToken.type) {
        return _TokenDifferenceKind.CONTENT;
      }
      if (oldToken.lexeme != newToken.lexeme) {
        return _TokenDifferenceKind.CONTENT;
      }
      if (newToken.offset - oldToken.offset != delta) {
        return _TokenDifferenceKind.OFFSET;
      }
      // continue if comment tokens are being checked
      if (!forComment) {
        break;
      }
      oldToken = oldToken.next;
      newToken = newToken.next;
    }
    return null;
  }

  static _TokenPair _findFirstDifferentToken(Token oldToken, Token newToken) {
    while (true) {
      if (oldToken.type == TokenType.EOF && newToken.type == TokenType.EOF) {
        return null;
      }
      if (oldToken.type == TokenType.EOF || newToken.type == TokenType.EOF) {
        return new _TokenPair(_TokenDifferenceKind.CONTENT, oldToken, newToken);
      }
      // compare comments
      {
        Token oldComment = oldToken.precedingComments;
        Token newComment = newToken.precedingComments;
        if (_compareToken(oldComment, newComment, 0, true) != null) {
          _TokenDifferenceKind diffKind = _TokenDifferenceKind.COMMENT;
          if (oldComment is DocumentationCommentToken &&
              newComment is DocumentationCommentToken) {
            diffKind = _TokenDifferenceKind.COMMENT_DOC;
          }
          return new _TokenPair(diffKind, oldToken, newToken);
        }
      }
      // compare tokens
      _TokenDifferenceKind diffKind =
          _compareToken(oldToken, newToken, 0, false);
      if (diffKind != null) {
        return new _TokenPair(diffKind, oldToken, newToken);
      }
      // next tokens
      oldToken = oldToken.next;
      newToken = newToken.next;
    }
    // no difference
    return null;
  }

  static _TokenPair _findLastDifferentToken(Token oldToken, Token newToken) {
    int delta = newToken.offset - oldToken.offset;
    while (oldToken.previous != oldToken && newToken.previous != newToken) {
      // compare tokens
      _TokenDifferenceKind diffKind =
          _compareToken(oldToken, newToken, delta, false);
      if (diffKind != null) {
        return new _TokenPair(diffKind, oldToken.next, newToken.next);
      }
      // compare comments
      {
        Token oldComment = oldToken.precedingComments;
        Token newComment = newToken.precedingComments;
        if (_compareToken(oldComment, newComment, delta, true) != null) {
          _TokenDifferenceKind diffKind = _TokenDifferenceKind.COMMENT;
          if (oldComment is DocumentationCommentToken &&
              newComment is DocumentationCommentToken) {
            diffKind = _TokenDifferenceKind.COMMENT_DOC;
          }
          return new _TokenPair(diffKind, oldToken, newToken);
        }
      }
      // next tokens
      oldToken = oldToken.previous;
      newToken = newToken.previous;
    }
    return null;
  }

  static AstNode _findNodeCovering(AstNode root, int offset, int end) {
    NodeLocator nodeLocator = new NodeLocator(offset, end);
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
   * Returns number of tokens with the given [type].
   */
  static int _getTokenCount(Token token, TokenType type) {
    int count = 0;
    while (token.type != TokenType.EOF) {
      if (token.type == type) {
        count++;
      }
      token = token.next;
    }
    return count;
  }
}

/**
 * The context to resolve an [AstNode] in.
 */
class ResolutionContext {
  CompilationUnitElement enclosingUnit;
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
   * The class containing the enclosing [CompilationUnitElement].
   */
  CompilationUnitElement _enclosingUnit;

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
          new TypeParameterScope(scope, _enclosingClass), _enclosingClass);
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
    _enclosingUnit = node.element;
    if (_enclosingUnit == null) {
      throw new AnalysisException(
          "Cannot create scope: compilation unit is not resolved");
    }
    LibraryElement libraryElement = _enclosingUnit.library;
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
  static ResolutionContext contextFor(
      AstNode node, AnalysisErrorListener errorListener) {
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
    context.enclosingUnit = builder._enclosingUnit;
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
class _DeclarationMismatchException {}

/**
 * Adjusts the location of each Element that moved.
 *
 * Since `==` and `hashCode` of a local variable or function Element are based
 * on the element name offsets, we also need to remove these elements from the
 * cache to avoid a memory leak. TODO(scheglov) fix and remove this
 */
class _ElementOffsetUpdater extends GeneralizingElementVisitor {
  final int updateOffset;
  final int updateDelta;
  final AnalysisCache cache;

  _ElementOffsetUpdater(this.updateOffset, this.updateDelta, this.cache);

  @override
  visitElement(Element element) {
    // name offset
    int nameOffset = element.nameOffset;
    if (nameOffset > updateOffset) {
      // TODO(scheglov) make sure that we don't put local variables
      // and functions into the cache at all.
      try {
        (element as ElementImpl).nameOffset = nameOffset + updateDelta;
      } on FrozenHashCodeException {
        cache.remove(element);
        (element as ElementImpl).nameOffset = nameOffset + updateDelta;
      }
      if (element is ConstVariableElement) {
        ConstVariableElement constVariable = element as ConstVariableElement;
        Expression initializer = constVariable.constantInitializer;
        if (initializer != null) {
          _shiftTokens(initializer.beginToken);
        }
      }
    }
    // code range
    if (element is ElementImpl) {
      int oldOffset = element.codeOffset;
      int oldLength = element.codeLength;
      if (oldOffset != null) {
        int newOffset = oldOffset;
        int newLength = oldLength;
        newOffset += oldOffset > updateOffset ? updateDelta : 0;
        if (oldOffset <= updateOffset && updateOffset < oldOffset + oldLength) {
          newLength += updateDelta;
        }
        if (newOffset != oldOffset || newLength != oldLength) {
          element.setCodeRange(newOffset, newLength);
        }
      }
    }
    // visible range
    if (element is LocalElement) {
      SourceRange visibleRange = element.visibleRange;
      if (visibleRange != null) {
        int oldOffset = visibleRange.offset;
        int oldLength = visibleRange.length;
        int newOffset = oldOffset;
        int newLength = oldLength;
        newOffset += oldOffset > updateOffset ? updateDelta : 0;
        newLength += visibleRange.contains(updateOffset) ? updateDelta : 0;
        if (newOffset != oldOffset || newLength != oldLength) {
          if (element is FunctionElementImpl) {
            element.setVisibleRange(newOffset, newLength);
          } else if (element is LocalVariableElementImpl) {
            element.setVisibleRange(newOffset, newLength);
          } else if (element is ParameterElementImpl) {
            element.setVisibleRange(newOffset, newLength);
          }
        }
      }
    }
    super.visitElement(element);
  }

  void _shiftTokens(Token token) {
    while (token != null) {
      if (token.offset > updateOffset) {
        token.offset += updateDelta;
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
  visitParameterElement(ParameterElement element) {}

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
  visitTypeParameterElement(TypeParameterElement element) {}

  void _addElement(Element element) {
    if (element != null) {
      matcher._allElements.add(element);
      matcher._removedElements.add(element);
    }
  }
}

/**
 * Describes how two [Token]s are different.
 */
class _TokenDifferenceKind {
  static const COMMENT = const _TokenDifferenceKind('COMMENT');
  static const COMMENT_DOC = const _TokenDifferenceKind('COMMENT_DOC');
  static const CONTENT = const _TokenDifferenceKind('CONTENT');
  static const OFFSET = const _TokenDifferenceKind('OFFSET');

  final String name;

  const _TokenDifferenceKind(this.name);

  @override
  String toString() => name;
}

class _TokenPair {
  final _TokenDifferenceKind kind;
  final Token oldToken;
  final Token newToken;
  _TokenPair(this.kind, this.oldToken, this.newToken);
}
