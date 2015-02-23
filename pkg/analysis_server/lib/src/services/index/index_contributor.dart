// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.index.index_contributor;

import 'dart:collection' show Queue;

import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/index_store.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/html.dart' as ht;
import 'package:analyzer/src/generated/java_engine.dart';
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
  store.doneIndex();
}


/**
 * Visits a resolved AST and adds relationships into [IndexStore].
 */
class _IndexContributor extends GeneralizingAstVisitor {
  final IndexStore _store;

  LibraryElement _libraryElement;

  Map<ImportElement, Set<Element>> _importElementsMap = {};

  /**
   * A stack whose top element (the element with the largest index) is an
   * element representing the inner-most enclosing scope.
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
  visitAssignmentExpression(AssignmentExpression node) {
    _recordOperatorReference(node.operator, node.bestElement);
    super.visitAssignmentExpression(node);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    _recordOperatorReference(node.operator, node.bestElement);
    super.visitBinaryExpression(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    ClassElement element = node.element;
    enterScope(element);
    try {
      _recordElementDefinition(element);
      {
        ExtendsClause extendsClause = node.extendsClause;
        if (extendsClause != null) {
          TypeName superclassNode = extendsClause.superclass;
          _recordSuperType(superclassNode, IndexConstants.IS_EXTENDED_BY);
        } else {
          InterfaceType superType = element.supertype;
          if (superType != null) {
            ClassElement objectElement = superType.element;
            recordRelationship(
                objectElement,
                IndexConstants.IS_EXTENDED_BY,
                _createLocationForOffset(node.name.offset, 0));
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
      super.visitClassDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement element = node.element;
    enterScope(element);
    try {
      _recordElementDefinition(element);
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
      super.visitClassTypeAlias(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    CompilationUnitElement unitElement = node.element;
    if (unitElement != null) {
      _elementStack.add(unitElement);
      _libraryElement = unitElement.enclosingElement;
      if (_libraryElement != null) {
        super.visitCompilationUnit(node);
      }
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElement element = node.element;
    enterScope(element);
    try {
      super.visitConstructorDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    SimpleIdentifier fieldName = node.fieldName;
    Expression expression = node.expression;
    // field reference is write here
    if (fieldName != null) {
      Element element = fieldName.staticElement;
      Location location = _createLocationForNode(fieldName);
      _store.recordRelationship(
          element,
          IndexConstants.IS_WRITTEN_BY,
          location);
    }
    // index expression
    if (expression != null) {
      expression.accept(this);
    }
  }

  @override
  visitConstructorName(ConstructorName node) {
    ConstructorElement element = node.staticElement;
    // in 'class B = A;' actually A constructors are invoked
    if (element != null &&
        element.isSynthetic &&
        element.redirectedConstructor != null) {
      element = element.redirectedConstructor;
    }
    // prepare location
    Location location;
    if (node.name != null) {
      int start = node.period.offset;
      int end = node.name.end;
      location = _createLocationForOffset(start, end - start);
    } else {
      int start = node.type.end;
      location = _createLocationForOffset(start, 0);
    }
    // record relationship
    recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    super.visitConstructorName(node);
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    LocalVariableElement element = node.element;
    enterScope(element);
    try {
      super.visitDeclaredIdentifier(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    ClassElement element = node.element;
    enterScope(element);
    try {
      _recordElementDefinition(element);
      super.visitEnumDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitExportDirective(ExportDirective node) {
    ExportElement element = node.element;
    if (element != null) {
      LibraryElement expLibrary = element.exportedLibrary;
      _recordLibraryReference(node, expLibrary);
    }
    super.visitExportDirective(node);
  }

  @override
  visitFormalParameter(FormalParameter node) {
    ParameterElement element = node.element;
    enterScope(element);
    try {
      super.visitFormalParameter(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    Element element = node.element;
    _recordElementDefinition(element);
    enterScope(element);
    try {
      super.visitFunctionDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    Element element = node.element;
    _recordElementDefinition(element);
    super.visitFunctionTypeAlias(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    ImportElement element = node.element;
    if (element != null) {
      LibraryElement impLibrary = element.importedLibrary;
      _recordLibraryReference(node, impLibrary);
    }
    super.visitImportDirective(node);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    MethodElement element = node.bestElement;
    if (element is MethodElement) {
      Token operator = node.leftBracket;
      Location location = _createLocationForToken(operator, element != null);
      recordRelationship(element, IndexConstants.IS_INVOKED_BY, location);
    }
    super.visitIndexExpression(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement element = node.element;
    enterScope(element);
    try {
      super.visitMethodDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier name = node.methodName;
    Location location = _createLocationForNode(name);
    // element invocation
    Element element = name.bestElement;
    if (element is MethodElement ||
        element is PropertyAccessorElement ||
        element is FunctionElement ||
        element is VariableElement) {
      recordRelationship(element, IndexConstants.IS_INVOKED_BY, location);
    }
    // name invocation
    {
      Element nameElement = new NameElement(name.name);
      _store.recordRelationship(
          nameElement,
          IndexConstants.IS_INVOKED_BY,
          location);
    }
    _recordImportElementReferenceWithoutPrefix(name);
    super.visitMethodInvocation(node);
  }

  @override
  visitPartDirective(PartDirective node) {
    Element element = node.element;
    Location location = _createLocationForNode(node.uri);
    recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    super.visitPartDirective(node);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    Location location = _createLocationForNode(node.libraryName);
    recordRelationship(node.element, IndexConstants.IS_REFERENCED_BY, location);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    _recordOperatorReference(node.operator, node.bestElement);
    super.visitPostfixExpression(node);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    _recordOperatorReference(node.operator, node.bestElement);
    super.visitPrefixExpression(node);
  }

  @override
  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    ConstructorElement element = node.staticElement;
    Location location;
    if (node.constructorName != null) {
      int start = node.period.offset;
      int end = node.constructorName.end;
      location = _createLocationForOffset(start, end - start);
    } else {
      int start = node.keyword.end;
      location = _createLocationForOffset(start, 0);
    }
    recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    Element nameElement = new NameElement(node.name);
    Location location = _createLocationForNode(node);
    // name in declaration
    if (node.inDeclarationContext()) {
      recordRelationship(
          nameElement,
          IndexConstants.NAME_IS_DEFINED_BY,
          location);
      return;
    }
    // prepare information
    Element element = node.bestElement;
    // stop if already handled
    if (_isAlreadyHandledName(node)) {
      return;
    }
    // record name read/write
    if (element != null && element.enclosingElement is ClassElement ||
        element == null && location.isQualified) {
      bool inGetterContext = node.inGetterContext();
      bool inSetterContext = node.inSetterContext();
      if (inGetterContext && inSetterContext) {
        _store.recordRelationship(
            nameElement,
            IndexConstants.IS_READ_WRITTEN_BY,
            location);
      } else if (inGetterContext) {
        _store.recordRelationship(
            nameElement,
            IndexConstants.IS_READ_BY,
            location);
      } else if (inSetterContext) {
        _store.recordRelationship(
            nameElement,
            IndexConstants.IS_WRITTEN_BY,
            location);
      }
    }
    // this.field parameter
    if (element is FieldFormalParameterElement) {
      Relationship relationship = peekElement() == element ?
          IndexConstants.IS_WRITTEN_BY :
          IndexConstants.IS_REFERENCED_BY;
      _store.recordRelationship(element.field, relationship, location);
      return;
    }
    // record specific relations
    if (element is ClassElement ||
        element is FunctionElement ||
        element is FunctionTypeAliasElement ||
        element is LabelElement ||
        element is MethodElement ||
        element is PropertyAccessorElement ||
        element is PropertyInducingElement ||
        element is TypeParameterElement) {
      recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    } else if (element is PrefixElement) {
      recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
      _recordImportElementReferenceWithPrefix(node);
    } else if (element is ParameterElement || element is LocalVariableElement) {
      bool inGetterContext = node.inGetterContext();
      bool inSetterContext = node.inSetterContext();
      if (inGetterContext && inSetterContext) {
        recordRelationship(
            element,
            IndexConstants.IS_READ_WRITTEN_BY,
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
    super.visitSimpleIdentifier(node);
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ConstructorElement element = node.staticElement;
    Location location;
    if (node.constructorName != null) {
      int start = node.period.offset;
      int end = node.constructorName.end;
      location = _createLocationForOffset(start, end - start);
    } else {
      int start = node.keyword.end;
      location = _createLocationForOffset(start, 0);
    }
    recordRelationship(element, IndexConstants.IS_REFERENCED_BY, location);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    VariableDeclarationList variables = node.variables;
    for (VariableDeclaration variableDeclaration in variables.variables) {
      Element element = variableDeclaration.element;
      _recordElementDefinition(element);
    }
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  visitTypeParameter(TypeParameter node) {
    TypeParameterElement element = node.element;
    enterScope(element);
    try {
      super.visitTypeParameter(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    VariableElement element = node.element;
    // record declaration
    {
      SimpleIdentifier name = node.name;
      Location location = _createLocationForNode(name);
      location = _getLocationWithExpressionType(location, node.initializer);
      recordRelationship(element, IndexConstants.NAME_IS_DEFINED_BY, location);
    }
    // visit
    enterScope(element);
    try {
      super.visitVariableDeclaration(node);
    } finally {
      _exitScope();
    }
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
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
  }

  /**
   * @return the [Location] representing location of the [AstNode].
   */
  Location _createLocationForNode(AstNode node) {
    bool isQualified = _isQualifiedClassMemberAccess(node);
    bool isResolved = true;
    if (node is SimpleIdentifier) {
      isResolved = node.bestElement != null;
    }
    Element element = peekElement();
    return new Location(
        element,
        node.offset,
        node.length,
        isQualified: isQualified,
        isResolved: isResolved);
  }

  /**
   * [offset] - the offset of the location within [Source].
   * [length] - the length of the location.
   *
   * Returns the [Location] representing the given offset and length within the
   * inner-most [Element].
   */
  Location _createLocationForOffset(int offset, int length) {
    Element element = peekElement();
    return new Location(element, offset, length);
  }

  /**
   * @return the [Location] representing location of the [Token].
   */
  Location _createLocationForToken(Token token, bool isResolved) {
    Element element = peekElement();
    return new Location(
        element,
        token.offset,
        token.length,
        isQualified: true,
        isResolved: isResolved);
  }

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
      return parent.methodName == node;
    }
    return false;
  }

  bool _isQualifiedClassMemberAccess(AstNode node) {
    if (node is SimpleIdentifier) {
      AstNode parent = node.parent;
      if (parent is PrefixedIdentifier && parent.identifier == node) {
        return parent.prefix.staticElement is! PrefixElement;
      }
      if (parent is PropertyAccess && parent.propertyName == node) {
        return parent.realTarget != null;
      }
      if (parent is MethodInvocation && parent.methodName == node) {
        Expression target = parent.realTarget;
        if (target is SimpleIdentifier &&
            target.staticElement is PrefixElement) {
          return false;
        }
        return target != null;
      }
    }
    return false;
  }

  /**
   * Records the [Element] definition in the library and universe.
   */
  void _recordElementDefinition(Element element) {
    Location location = createLocation(element);
    Relationship relationship = IndexConstants.DEFINES;
    recordRelationship(_libraryElement, relationship, location);
    recordRelationship(UniverseElement.INSTANCE, relationship, location);
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
    ImportElement importElement =
        internal_getImportElement(_libraryElement, null, element, _importElementsMap);
    if (importElement != null) {
      Location location = _createLocationForOffset(node.offset, 0);
      recordRelationship(
          importElement,
          IndexConstants.IS_REFERENCED_BY,
          location);
    }
  }

  /**
   * Records [ImportElement] that declares given prefix and imports library with element used
   * with given prefix node.
   */
  void _recordImportElementReferenceWithPrefix(SimpleIdentifier prefixNode) {
    ImportElementInfo info = internal_getImportElementInfo(prefixNode);
    if (info != null) {
      int offset = prefixNode.offset;
      int length = info.periodEnd - offset;
      Location location = _createLocationForOffset(offset, length);
      recordRelationship(
          info.element,
          IndexConstants.IS_REFERENCED_BY,
          location);
    }
  }

  /**
   * Records reference to defining [CompilationUnitElement] of the given
   * [LibraryElement].
   */
  void _recordLibraryReference(UriBasedDirective node, LibraryElement library) {
    if (library != null) {
      Location location = _createLocationForNode(node.uri);
      recordRelationship(
          library.definingCompilationUnit,
          IndexConstants.IS_REFERENCED_BY,
          location);
    }
  }

  /**
   * Record reference to the given operator [Element] and name.
   */
  void _recordOperatorReference(Token operator, Element element) {
    // prepare location
    Location location = _createLocationForToken(operator, element != null);
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
      recordRelationship(nameElement, IndexConstants.IS_INVOKED_BY, location);
    }
    // record element reference
    if (element != null) {
      recordRelationship(element, IndexConstants.IS_INVOKED_BY, location);
    }
  }

  /**
   * Records a relation between [superNode] and its [Element].
   */
  void _recordSuperType(TypeName superNode, Relationship relationship) {
    if (superNode != null) {
      Identifier superName = superNode.name;
      if (superName != null) {
        Element superElement = superName.staticElement;
        recordRelationship(
            superElement,
            relationship,
            _createLocationForNode(superNode));
      }
    }
  }

  /**
   * Creates a [Location] representing declaration of the [Element].
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
    return parent is PrefixedIdentifier && parent.identifier == node;
  }
}
