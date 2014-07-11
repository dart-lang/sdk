// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.index.index_contributor;

import 'dart:collection' show Queue;

import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/index_store.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/html.dart' as ht;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Adds data to [store] based on the resolved Dart [unit].
 */
void indexDartUnit(IndexStore store, AnalysisContext context,
    CompilationUnit unit) {
  // check unit
  if (unit == null) {
    return;
  }
  // prepare unit element
  CompilationUnitElement unitElement = unit.element;
  if (unitElement == null) {
    return;
  }
  // about to index
  bool mayIndex = store.aboutToIndexDart(context, unitElement);
  if (!mayIndex) {
    return;
  }
  // do index
  unit.accept(new _IndexContributor(store));
  unit.accept(new _AngularDartIndexContributor(store));
  store.doneIndex();
}


/**
 * Adds data to [store] based on the resolved HTML [unit].
 */
void indexHtmlUnit(IndexStore store, AnalysisContext context, ht.HtmlUnit unit)
    {
  // check unit
  if (unit == null) {
    return;
  }
  // prepare unit element
  HtmlElement unitElement = unit.element;
  if (unitElement == null) {
    return;
  }
  // about to index
  bool mayIndex = store.aboutToIndexHtml(context, unitElement);
  if (!mayIndex) {
    return;
  }
  // do index
  unit.accept(new _AngularHtmlIndexContributor(store));
  store.doneIndex();
}


/**
 * Visits resolved [CompilationUnit] and adds Angular specific relationships
 * into [IndexStore].
 */
class _AngularDartIndexContributor extends GeneralizingAstVisitor<Object> {
  final IndexStore _store;

  _AngularDartIndexContributor(this._store);

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement classElement = node.element;
    if (classElement != null) {
      List<ToolkitObjectElement> toolkitObjects = classElement.toolkitObjects;
      for (ToolkitObjectElement object in toolkitObjects) {
        if (object is AngularComponentElement) {
          _indexComponent(object);
        }
        if (object is AngularDecoratorElement) {
          AngularDecoratorElement directive = object;
          _indexDirective(directive);
        }
      }
    }
    // stop visiting
    return null;
  }

  @override
  Object visitCompilationUnitMember(CompilationUnitMember node) => null;

  void _indexComponent(AngularComponentElement component) {
    _indexProperties(component.properties);
  }

  void _indexDirective(AngularDecoratorElement directive) {
    _indexProperties(directive.properties);
  }

  /**
   * Index [FieldElement] references from [AngularPropertyElement]s.
   */
  void _indexProperties(List<AngularPropertyElement> properties) {
    for (AngularPropertyElement property in properties) {
      FieldElement field = property.field;
      if (field != null) {
        int offset = property.fieldNameOffset;
        if (offset == -1) {
          continue;
        }
        int length = field.name.length;
        Location location = new Location(property, offset, length);
        // getter reference
        if (property.propertyKind.callsGetter()) {
          PropertyAccessorElement getter = field.getter;
          if (getter != null) {
            _store.recordRelationship(getter,
                IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
          }
        }
        // setter reference
        if (property.propertyKind.callsSetter()) {
          PropertyAccessorElement setter = field.setter;
          if (setter != null) {
            _store.recordRelationship(setter,
                IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
          }
        }
      }
    }
  }
}


/**
 * Visits resolved [HtmlUnit] and adds relationships into [IndexStore].
 */
class _AngularHtmlIndexContributor extends _ExpressionVisitor {
  /**
   * The [IndexStore] to record relations into.
   */
  final IndexStore _store;

  /**
   * The index contributor used to index Dart [Expression]s.
   */
  _IndexContributor _indexContributor;

  HtmlElement _htmlUnitElement;

  /**
   * Initialize a newly created Angular HTML index contributor.
   *
   * [store] - the [IndexStore] to record relations into.
   */
  _AngularHtmlIndexContributor(this._store) {
    _indexContributor = new _AngularHtmlIndexContributor_forEmbeddedDart(_store,
        this);
  }

  @override
  void visitExpression(Expression expression) {
    // Formatter
    if (expression is SimpleIdentifier) {
      Element element = expression.bestElement;
      if (element is AngularElement) {
        _store.recordRelationship(element, IndexConstants.ANGULAR_REFERENCE,
            _createLocationForIdentifier(expression));
        return;
      }
    }
    // index as a normal Dart expression
    expression.accept(_indexContributor);
  }

  @override
  Object visitHtmlUnit(ht.HtmlUnit node) {
    _htmlUnitElement = node.element;
    CompilationUnitElement dartUnitElement =
        _htmlUnitElement.angularCompilationUnit;
    _indexContributor.enterScope(dartUnitElement);
    return super.visitHtmlUnit(node);
  }

  @override
  Object visitXmlAttributeNode(ht.XmlAttributeNode node) {
    Element element = node.element;
    if (element != null) {
      ht.Token nameToken = node.nameToken;
      Location location = _createLocationForToken(nameToken);
      _store.recordRelationship(element, IndexConstants.ANGULAR_REFERENCE,
          location);
    }
    return super.visitXmlAttributeNode(node);
  }

  @override
  Object visitXmlTagNode(ht.XmlTagNode node) {
    Element element = node.element;
    if (element != null) {
      // tag
      {
        ht.Token tagToken = node.tagToken;
        Location location = _createLocationForToken(tagToken);
        _store.recordRelationship(element, IndexConstants.ANGULAR_REFERENCE,
            location);
      }
      // maybe add closing tag range
      ht.Token closingTag = node.closingTag;
      if (closingTag != null) {
        Location location = _createLocationForToken(closingTag);
        _store.recordRelationship(element,
            IndexConstants.ANGULAR_CLOSING_TAG_REFERENCE, location);
      }
    }
    return super.visitXmlTagNode(node);
  }

  Location _createLocationForIdentifier(SimpleIdentifier identifier) =>
      new Location(_htmlUnitElement, identifier.offset, identifier.length);

  Location _createLocationForToken(ht.Token token) => new Location(
      _htmlUnitElement, token.offset, token.length);
}


class _AngularHtmlIndexContributor_forEmbeddedDart extends _IndexContributor {
  final _AngularHtmlIndexContributor angularContributor;

  _AngularHtmlIndexContributor_forEmbeddedDart(IndexStore store,
      this.angularContributor) : super(store);

  @override
  Element peekElement() => angularContributor._htmlUnitElement;

  @override
  void recordRelationship(Element element, Relationship relationship,
      Location location) {
    AngularElement angularElement = AngularHtmlUnitResolver.getAngularElement(
        element);
    if (angularElement != null) {
      element = angularElement;
      relationship = IndexConstants.ANGULAR_REFERENCE;
    }
    super.recordRelationship(element, relationship, location);
  }
}


/**
 * Recursively visits an [HtmlUnit] and every embedded [Expression].
 */
abstract class _ExpressionVisitor extends ht.RecursiveXmlVisitor<Object> {
  /**
   * Visits the given [Expression]s embedded into tag or attribute.
   *
   * [expression] - the [Expression] to visit, not `null`
   */
  void visitExpression(Expression expression);

  @override
  Object visitXmlAttributeNode(ht.XmlAttributeNode node) {
    _visitExpressions(node.expressions);
    return super.visitXmlAttributeNode(node);
  }

  @override
  Object visitXmlTagNode(ht.XmlTagNode node) {
    _visitExpressions(node.expressions);
    return super.visitXmlTagNode(node);
  }

  /**
   * Visits [Expression]s of the given [XmlExpression]s.
   */
  void _visitExpressions(List<ht.XmlExpression> expressions) {
    for (ht.XmlExpression xmlExpression in expressions) {
      if (xmlExpression is AngularXmlExpression) {
        AngularXmlExpression angularXmlExpression = xmlExpression;
        List<Expression> dartExpressions =
            angularXmlExpression.expression.expressions;
        for (Expression dartExpression in dartExpressions) {
          visitExpression(dartExpression);
        }
      }
      if (xmlExpression is ht.RawXmlExpression) {
        ht.RawXmlExpression rawXmlExpression = xmlExpression;
        visitExpression(rawXmlExpression.expression);
      }
    }
  }
}


/**
 * Information about [ImportElement] and place where it is referenced using
 * [PrefixElement].
 */
class _ImportElementInfo {
  ImportElement _element;

  int _periodEnd = 0;
}


/**
 * Visits a resolved AST and adds relationships into [IndexStore].
 */
class _IndexContributor extends GeneralizingAstVisitor<Object> {
  final IndexStore _store;

  LibraryElement _libraryElement;

  Map<ImportElement, Set<Element>> _importElementsMap = {};

  /**
   * A stack whose top element (the element with the largest index) is an element representing the
   * inner-most enclosing scope.
   */
  Queue<Element> _elementStack = new Queue();

  _IndexContributor(this._store);

  /**
   * Enter a new scope represented by the given [Element].
   */
  void enterScope(Element element) {
    _elementStack.addFirst(element);
  }

  /**
   * @return the inner-most enclosing [Element], may be `null`.
   */
  Element peekElement() {
    for (Element element in _elementStack) {
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  /**
   * Record the given relationship between the given [Element] and [Location].
   */
  void recordRelationship(Element element, Relationship relationship,
      Location location) {
    if (element != null && location != null) {
      _store.recordRelationship(element, relationship, location);
    }
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    _recordOperatorReference(node.operator, node.bestElement);
    return super.visitAssignmentExpression(node);
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    _recordOperatorReference(node.operator, node.bestElement);
    return super.visitBinaryExpression(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement element = node.element;
    enterScope(element);
    try {
      _recordElementDefinition(element, IndexConstants.DEFINES_CLASS);
      {
        ExtendsClause extendsClause = node.extendsClause;
        if (extendsClause != null) {
          TypeName superclassNode = extendsClause.superclass;
          _recordSuperType(superclassNode, IndexConstants.IS_EXTENDED_BY);
        } else {
          InterfaceType superType = element.supertype;
          if (superType != null) {
            ClassElement objectElement = superType.element;
            recordRelationship(objectElement, IndexConstants.IS_EXTENDED_BY,
                _createLocationFromOffset(node.name.offset, 0));
          }
        }
      }
      {
        WithClause withClause = node.withClause;
        if (withClause != null) {
          for (TypeName mixinNode in withClause.mixinTypes) {
            _recordSuperType(mixinNode, IndexConstants.IS_MIXED_IN_BY);
          }
        }
      }
      {
        ImplementsClause implementsClause = node.implementsClause;
        if (implementsClause != null) {
          for (TypeName interfaceNode in implementsClause.interfaces) {
            _recordSuperType(interfaceNode, IndexConstants.IS_IMPLEMENTED_BY);
          }
        }
      }
      return super.visitClassDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement element = node.element;
    enterScope(element);
    try {
      _recordElementDefinition(element, IndexConstants.DEFINES_CLASS_ALIAS);
      {
        TypeName superclassNode = node.superclass;
        if (superclassNode != null) {
          _recordSuperType(superclassNode, IndexConstants.IS_EXTENDED_BY);
        }
      }
      {
        WithClause withClause = node.withClause;
        if (withClause != null) {
          for (TypeName mixinNode in withClause.mixinTypes) {
            _recordSuperType(mixinNode, IndexConstants.IS_MIXED_IN_BY);
          }
        }
      }
      {
        ImplementsClause implementsClause = node.implementsClause;
        if (implementsClause != null) {
          for (TypeName interfaceNode in implementsClause.interfaces) {
            _recordSuperType(interfaceNode, IndexConstants.IS_IMPLEMENTED_BY);
          }
        }
      }
      return super.visitClassTypeAlias(node);
    } finally {
      _exitScope();
    }
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    CompilationUnitElement unitElement = node.element;
    if (unitElement != null) {
      _elementStack.add(unitElement);
      _libraryElement = unitElement.enclosingElement;
      if (_libraryElement != null) {
        return super.visitCompilationUnit(node);
      }
    }
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElement element = node.element;
    // define
    {
      Location location;
      if (node.name != null) {
        int start = node.period.offset;
        int end = node.name.end;
        location = _createLocationFromOffset(start, end - start);
      } else {
        int start = node.returnType.end;
        location = _createLocationFromOffset(start, 0);
      }
      recordRelationship(element, IndexConstants.IS_DEFINED_BY, location);
    }
    // visit children
    enterScope(element);
    try {
      return super.visitConstructorDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    ConstructorElement element = node.staticElement;
    // in 'class B = A;' actually A constructors are invoked
    if (element != null && element.isSynthetic && element.redirectedConstructor
        != null) {
      element = element.redirectedConstructor;
    }
    // prepare location
    Location location;
    if (node.name != null) {
      int start = node.period.offset;
      int end = node.name.end;
      location = _createLocationFromOffset(start, end - start);
    } else {
      int start = node.type.end;
      location = _createLocationFromOffset(start, 0);
    }
    // record relationship
    recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    return super.visitConstructorName(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    ExportElement element = node.element;
    if (element != null) {
      LibraryElement expLibrary = element.exportedLibrary;
      _recordLibraryReference(node, expLibrary);
    }
    return super.visitExportDirective(node);
  }

  @override
  Object visitFormalParameter(FormalParameter node) {
    ParameterElement element = node.element;
    enterScope(element);
    try {
      return super.visitFormalParameter(node);
    } finally {
      _exitScope();
    }
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    Element element = node.element;
    _recordElementDefinition(element, IndexConstants.DEFINES_FUNCTION);
    enterScope(element);
    try {
      return super.visitFunctionDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    Element element = node.element;
    _recordElementDefinition(element, IndexConstants.DEFINES_FUNCTION_TYPE);
    return super.visitFunctionTypeAlias(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    ImportElement element = node.element;
    if (element != null) {
      LibraryElement impLibrary = element.importedLibrary;
      _recordLibraryReference(node, impLibrary);
    }
    return super.visitImportDirective(node);
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    MethodElement element = node.bestElement;
    if (element is MethodElement) {
      Token operator = node.leftBracket;
      Location location = _createLocationFromToken(operator);
      recordRelationship(element, IndexConstants.IS_INVOKED_BY_QUALIFIED,
          location);
    }
    return super.visitIndexExpression(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement element = node.element;
    enterScope(element);
    try {
      return super.visitMethodDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier name = node.methodName;
    Element element = name.bestElement;
    if (element is MethodElement || element is PropertyAccessorElement) {
      Location location = _createLocationFromNode(name);
      Relationship relationship;
      if (node.target != null) {
        relationship = IndexConstants.IS_INVOKED_BY_QUALIFIED;
      } else {
        relationship = IndexConstants.IS_INVOKED_BY_UNQUALIFIED;
      }
      recordRelationship(element, relationship, location);
    }
    if (element is FunctionElement || element is VariableElement) {
      Location location = _createLocationFromNode(name);
      recordRelationship(element, IndexConstants.IS_INVOKED_BY, location);
    }
    // name invocation
    {
      Element nameElement = new NameElement(name.name);
      Location location = _createLocationFromNode(name);
      Relationship kind = element != null ?
          IndexConstants.NAME_IS_INVOKED_BY_RESOLVED :
          IndexConstants.NAME_IS_INVOKED_BY_UNRESOLVED;
      _store.recordRelationship(nameElement, kind, location);
    }
    _recordImportElementReferenceWithoutPrefix(name);
    return super.visitMethodInvocation(node);
  }

  @override
  Object visitPartDirective(PartDirective node) {
    Element element = node.element;
    Location location = _createLocationFromNode(node.uri);
    recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    Location location = _createLocationFromNode(node.libraryName);
    recordRelationship(node.element, IndexConstants.IS_REFERENCED_BY, location);
    return null;
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    _recordOperatorReference(node.operator, node.bestElement);
    return super.visitPostfixExpression(node);
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    _recordOperatorReference(node.operator, node.bestElement);
    return super.visitPrefixExpression(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element nameElement = new NameElement(node.name);
    Location location = _createLocationFromNode(node);
    // name in declaration
    if (node.inDeclarationContext()) {
      recordRelationship(nameElement, IndexConstants.IS_DEFINED_BY, location);
      return null;
    }
    // prepare information
    Element element = node.bestElement;
    // TODO(scheglov) fix resolver to resolve to Field, not an accessor
    if (node.parent is Combinator && element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    // qualified name reference
    _recordQualifiedMemberReference(node, element, nameElement, location);
    // stop if already handled
    if (_isAlreadyHandledName(node)) {
      return null;
    }
    // record name read/write
    {
      bool inGetterContext = node.inGetterContext();
      bool inSetterContext = node.inSetterContext();
      if (inGetterContext && inSetterContext) {
        Relationship kind = element != null ?
            IndexConstants.NAME_IS_READ_WRITTEN_BY_RESOLVED :
            IndexConstants.NAME_IS_READ_WRITTEN_BY_UNRESOLVED;
        _store.recordRelationship(nameElement, kind, location);
      } else if (inGetterContext) {
        Relationship kind = element != null ?
            IndexConstants.NAME_IS_READ_BY_RESOLVED :
            IndexConstants.NAME_IS_READ_BY_UNRESOLVED;
        _store.recordRelationship(nameElement, kind, location);
      } else if (inSetterContext) {
        Relationship kind = element != null ?
            IndexConstants.NAME_IS_WRITTEN_BY_RESOLVED :
            IndexConstants.NAME_IS_WRITTEN_BY_UNRESOLVED;
        _store.recordRelationship(nameElement, kind, location);
      }
    }
    // record specific relations
    if (element is ClassElement || element is FunctionElement || element is
        FunctionTypeAliasElement || element is LabelElement || element is
        TypeParameterElement) {
      recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    } else if (element is PropertyInducingElement) {
      location = _getLocationWithInitializerType(node, location);
      recordRelationship(element,
          IndexConstants.IS_REFERENCED_BY_QUALIFIED,
          location);
    } else if (element is FieldFormalParameterElement) {
      FieldFormalParameterElement fieldParameter = element;
      FieldElement field = fieldParameter.field;
      recordRelationship(field, IndexConstants.IS_REFERENCED_BY_QUALIFIED,
          location);
    } else if (element is PrefixElement) {
      _recordImportElementReferenceWithPrefix(node);
    } else if (element is PropertyAccessorElement || element is MethodElement) {
      location = _getLocationWithTypeAssignedToField(node, element, location);
      if (node.isQualified) {
        recordRelationship(element, IndexConstants.IS_REFERENCED_BY_QUALIFIED,
            location);
      } else {
        recordRelationship(element, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED,
            location);
      }
    } else if (element is ParameterElement || element is LocalVariableElement) {
      bool inGetterContext = node.inGetterContext();
      bool inSetterContext = node.inSetterContext();
      if (inGetterContext && inSetterContext) {
        recordRelationship(element, IndexConstants.IS_READ_WRITTEN_BY,
            location);
      } else if (inGetterContext) {
        recordRelationship(element, IndexConstants.IS_READ_BY, location);
      } else if (inSetterContext) {
        recordRelationship(element, IndexConstants.IS_WRITTEN_BY, location);
      } else {
        recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
      }
    }
    _recordImportElementReferenceWithoutPrefix(node);
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ConstructorElement element = node.staticElement;
    Location location;
    if (node.constructorName != null) {
      int start = node.period.offset;
      int end = node.constructorName.end;
      location = _createLocationFromOffset(start, end - start);
    } else {
      int start = node.keyword.end;
      location = _createLocationFromOffset(start, 0);
    }
    recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    return super.visitSuperConstructorInvocation(node);
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    VariableDeclarationList variables = node.variables;
    for (VariableDeclaration variableDeclaration in variables.variables) {
      Element element = variableDeclaration.element;
      _recordElementDefinition(element, IndexConstants.DEFINES_VARIABLE);
    }
    return super.visitTopLevelVariableDeclaration(node);
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    TypeParameterElement element = node.element;
    enterScope(element);
    try {
      return super.visitTypeParameter(node);
    } finally {
      _exitScope();
    }
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    VariableElement element = node.element;
    // record declaration
    {
      SimpleIdentifier name = node.name;
      Location location = _createLocationFromNode(name);
      location = _getLocationWithExpressionType(location, node.initializer);
      recordRelationship(element, IndexConstants.IS_DEFINED_BY, location);
    }
    // visit
    enterScope(element);
    try {
      return super.visitVariableDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    NodeList<VariableDeclaration> variables = node.variables;
    if (variables != null) {
      // use first VariableDeclaration as Element for Location(s) in type
      {
        TypeName type = node.type;
        if (type != null) {
          for (VariableDeclaration variableDeclaration in variables) {
            enterScope(variableDeclaration.element);
            try {
              type.accept(this);
            } finally {
              _exitScope();
            }
            // only one iteration
            break;
          }
        }
      }
      // visit variables
      variables.accept(this);
    }
    return null;
  }

  /**
   * @return the [Location] representing location of the [AstNode].
   */
  Location _createLocationFromNode(AstNode node) => _createLocationFromOffset(
      node.offset, node.length);

  /**
   * [offset] - the offset of the location within [Source].
   * [length] - the length of the location.
   *
   * Returns the [Location] representing the given offset and length within the
   * inner-most [Element].
   */
  Location _createLocationFromOffset(int offset, int length) {
    Element element = peekElement();
    return new Location(element, offset, length);
  }

  /**
   * @return the [Location] representing location of the [Token].
   */
  Location _createLocationFromToken(Token token) => _createLocationFromOffset(
      token.offset, token.length);

  /**
   * Exit the current scope.
   */
  void _exitScope() {
    _elementStack.removeFirst();
  }

  /**
   * @return `true` if given node already indexed as more interesting reference, so it should
   *         not be indexed again.
   */
  bool _isAlreadyHandledName(SimpleIdentifier node) {
    AstNode parent = node.parent;
    if (parent is MethodInvocation) {
      return identical(parent.methodName, node);
    }
    return false;
  }

  /**
   * Records the [Element] definition in the library and universe.
   */
  void _recordElementDefinition(Element element, Relationship relationship) {
    Location location = createLocation(element);
    recordRelationship(_libraryElement, relationship, location);
    recordRelationship(IndexConstants.UNIVERSE, relationship, location);
  }

  /**
   * Records [ImportElement] that declares given prefix and imports library with element used
   * with given prefix node.
   */
  void _recordImportElementReferenceWithPrefix(SimpleIdentifier prefixNode) {
    _ImportElementInfo info = getImportElementInfo(prefixNode);
    if (info != null) {
      int offset = prefixNode.offset;
      int length = info._periodEnd - offset;
      Location location = _createLocationFromOffset(offset, length);
      recordRelationship(info._element, IndexConstants.IS_REFERENCED_BY,
          location);
    }
  }

  /**
   * Records [ImportElement] reference if given [SimpleIdentifier] references some
   * top-level element and not qualified with import prefix.
   */
  void _recordImportElementReferenceWithoutPrefix(SimpleIdentifier node) {
    if (_isIdentifierInImportCombinator(node)) {
      return;
    }
    if (_isIdentifierInPrefixedIdentifier(node)) {
      return;
    }
    Element element = node.staticElement;
    ImportElement importElement = _internalGetImportElement(_libraryElement,
        null, element, _importElementsMap);
    if (importElement != null) {
      Location location = _createLocationFromOffset(node.offset, 0);
      recordRelationship(importElement, IndexConstants.IS_REFERENCED_BY,
          location);
    }
  }

  /**
   * Records reference to defining [CompilationUnitElement] of the given
   * [LibraryElement].
   */
  void _recordLibraryReference(UriBasedDirective node, LibraryElement library) {
    if (library != null) {
      Location location = _createLocationFromNode(node.uri);
      recordRelationship(library.definingCompilationUnit,
          IndexConstants.IS_REFERENCED_BY, location);
    }
  }

  /**
   * Record reference to the given operator [Element] and name.
   */
  void _recordOperatorReference(Token operator, Element element) {
    // prepare location
    Location location = _createLocationFromToken(operator);
    // record name reference
    {
      String name = operator.lexeme;
      if (name == "++") {
        name = "+";
      }
      if (name == "--") {
        name = "-";
      }
      if (StringUtilities.endsWithChar(name, 0x3D) && name != "==") {
        name = name.substring(0, name.length - 1);
      }
      Element nameElement = new NameElement(name);
      Relationship relationship = element != null ?
          IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED :
          IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED;
      recordRelationship(nameElement, relationship, location);
    }
    // record element reference
    if (element != null) {
      recordRelationship(element, IndexConstants.IS_INVOKED_BY_QUALIFIED,
          location);
    }
  }

  /**
   * Records reference if the given [SimpleIdentifier] looks like a qualified property access
   * or method invocation.
   */
  void _recordQualifiedMemberReference(SimpleIdentifier node, Element element,
      Element nameElement, Location location) {
    if (node.isQualified) {
      Relationship relationship = element != null ?
          IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED :
          IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED;
      recordRelationship(nameElement, relationship, location);
    }
  }

  /**
   * Records extends/implements relationships between given [ClassElement] and [Type] of
   * "superNode".
   */
  void _recordSuperType(TypeName superNode, Relationship relationship) {
    if (superNode != null) {
      Identifier superName = superNode.name;
      if (superName != null) {
        Element superElement = superName.staticElement;
        recordRelationship(superElement, relationship, _createLocationFromNode(
            superNode));
      }
    }
  }

  /**
   * @return the [Location] representing location of the [Element].
   */
  static Location createLocation(Element element) {
    if (element != null) {
      int offset = element.nameOffset;
      int length = element.displayName.length;
      return new Location(element, offset, length);
    }
    return null;
  }

  /**
   * @return the [ImportElement] that is referenced by this node with [PrefixElement],
   *         may be `null`.
   */
  static ImportElement getImportElement(SimpleIdentifier prefixNode) {
    _ImportElementInfo info = getImportElementInfo(prefixNode);
    return info != null ? info._element : null;
  }

  /**
   * @return the [ImportElementInfo] with [ImportElement] that is referenced by this
   *         node with [PrefixElement], may be `null`.
   */
  static _ImportElementInfo getImportElementInfo(SimpleIdentifier prefixNode) {
    _ImportElementInfo info = new _ImportElementInfo();
    // prepare environment
    AstNode parent = prefixNode.parent;
    CompilationUnit unit = prefixNode.getAncestor((node) => node is
        CompilationUnit);
    LibraryElement libraryElement = unit.element.library;
    // prepare used element
    Element usedElement = null;
    if (parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = parent;
      if (identical(prefixed.prefix, prefixNode)) {
        usedElement = prefixed.staticElement;
        info._periodEnd = prefixed.period.end;
      }
    }
    if (parent is MethodInvocation) {
      MethodInvocation invocation = parent;
      if (identical(invocation.target, prefixNode)) {
        usedElement = invocation.methodName.staticElement;
        info._periodEnd = invocation.period.end;
      }
    }
    // we need used Element
    if (usedElement == null) {
      return null;
    }
    // find ImportElement
    String prefix = prefixNode.name;
    Map<ImportElement, Set<Element>> importElementsMap = {};
    info._element = _internalGetImportElement(libraryElement, prefix,
        usedElement, importElementsMap);
    if (info._element == null) {
      return null;
    }
    return info;
  }

  /**
   * If the given expression has resolved type, returns the new location with this type.
   *
   * [location] - the base location
   * [expression] - the expression assigned at the given location
   */
  static Location _getLocationWithExpressionType(Location location,
      Expression expression) {
    if (expression != null) {
      return new LocationWithData<DartType>(location, expression.bestType);
    }
    return location;
  }

  /**
   * If the given node is the part of the [ConstructorFieldInitializer], returns location with
   * type of the initializer expression.
   */
  static Location _getLocationWithInitializerType(SimpleIdentifier node,
      Location location) {
    if (node.parent is ConstructorFieldInitializer) {
      ConstructorFieldInitializer initializer = node.parent as
          ConstructorFieldInitializer;
      if (identical(initializer.fieldName, node)) {
        location = _getLocationWithExpressionType(location,
            initializer.expression);
      }
    }
    return location;
  }

  /**
   * If the given identifier has a synthetic [PropertyAccessorElement], i.e.
   * accessor for normal field, and it is LHS of assignment, then include [Type]
   * of the assigned value into the [Location].
   *
   * [identifier] - the identifier to record location.
   * [element] - the [Element] of the identifier.
   * [location] - the raw location
   *
   * Returns the [Location] with the type of the assigned value
   */
  static Location
      _getLocationWithTypeAssignedToField(SimpleIdentifier identifier,
      Element element, Location location) {
    // TODO(scheglov) decide if we want to remember assigned types
    // we need accessor
    if (element is! PropertyAccessorElement) {
      return location;
    }
    PropertyAccessorElement accessor = element as PropertyAccessorElement;
    // should be setter
    if (!accessor.isSetter) {
      return location;
    }
    // accessor should be synthetic, i.e. field normal
    if (!accessor.isSynthetic) {
      return location;
    }
    // should be LHS of assignment
    AstNode parent;
    {
      AstNode node = identifier;
      parent = node.parent;
      // new T().field = x;
      if (parent is PropertyAccess) {
        PropertyAccess propertyAccess = parent as PropertyAccess;
        if (identical(propertyAccess.propertyName, node)) {
          node = propertyAccess;
          parent = propertyAccess.parent;
        }
      }
      // obj.field = x;
      if (parent is PrefixedIdentifier) {
        PrefixedIdentifier prefixedIdentifier = parent as PrefixedIdentifier;
        if (identical(prefixedIdentifier.identifier, node)) {
          node = prefixedIdentifier;
          parent = prefixedIdentifier.parent;
        }
      }
    }
    // OK, remember the type
    if (parent is AssignmentExpression) {
      AssignmentExpression assignment = parent as AssignmentExpression;
      Expression rhs = assignment.rightHandSide;
      location = _getLocationWithExpressionType(location, rhs);
    }
    // done
    return location;
  }

  /**
   * @return the [ImportElement] that declares given [PrefixElement] and imports library
   *         with given "usedElement".
   */
  static ImportElement _internalGetImportElement(LibraryElement libraryElement,
      String prefix, Element usedElement, Map<ImportElement,
      Set<Element>> importElementsMap) {
    // validate Element
    if (usedElement == null) {
      return null;
    }
    if (usedElement.enclosingElement is! CompilationUnitElement) {
      return null;
    }
    LibraryElement usedLibrary = usedElement.library;
    // find ImportElement that imports used library with used prefix
    List<ImportElement> candidates = null;
    for (ImportElement importElement in libraryElement.imports) {
      // required library
      if (importElement.importedLibrary != usedLibrary) {
        continue;
      }
      // required prefix
      PrefixElement prefixElement = importElement.prefix;
      if (prefix == null) {
        if (prefixElement != null) {
          continue;
        }
      } else {
        if (prefixElement == null) {
          continue;
        }
        if (prefix != prefixElement.name) {
          continue;
        }
      }
      // no combinators => only possible candidate
      if (importElement.combinators.length == 0) {
        return importElement;
      }
      // OK, we have candidate
      if (candidates == null) {
        candidates = [];
      }
      candidates.add(importElement);
    }
    // no candidates, probably element is defined in this library
    if (candidates == null) {
      return null;
    }
    // one candidate
    if (candidates.length == 1) {
      return candidates[0];
    }
    // ensure that each ImportElement has set of elements
    for (ImportElement importElement in candidates) {
      if (importElementsMap.containsKey(importElement)) {
        continue;
      }
      Namespace namespace = new NamespaceBuilder(
          ).createImportNamespaceForDirective(importElement);
      Set<Element> elements = new Set.from(namespace.definedNames.values);
      importElementsMap[importElement] = elements;
    }
    // use import namespace to choose correct one
    for (MapEntry<ImportElement, Set<Element>> entry in getMapEntrySet(
        importElementsMap)) {
      if (entry.getValue().contains(usedElement)) {
        return entry.getKey();
      }
    }
    // not found
    return null;
  }

  /**
   * @return `true` if given "node" is part of an import [Combinator].
   */
  static bool _isIdentifierInImportCombinator(SimpleIdentifier node) {
    AstNode parent = node.parent;
    return parent is Combinator;
  }

  /**
   * @return `true` if given "node" is part of [PrefixedIdentifier] "prefix.node".
   */
  static bool _isIdentifierInPrefixedIdentifier(SimpleIdentifier node) {
    AstNode parent = node.parent;
    return parent is PrefixedIdentifier && identical(parent.identifier, node);
  }
}
