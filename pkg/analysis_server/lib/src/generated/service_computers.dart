// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library service.computers;

import 'package:analyzer/src/generated/java_core.dart' show JavaStringBuilder, StringUtils;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart' as pae;
import 'package:analyzer/src/generated/element.dart' show DartType;
import 'package:analyzer/src/generated/source.dart';
import 'service_interfaces.dart' as psi;

/**
 * A computer for [HighlightRegion]s in a Dart [CompilationUnit].
 */
class DartUnitHighlightsComputer {
  final CompilationUnit _unit;

  List<psi.HighlightRegion> _regions = [];

  DartUnitHighlightsComputer(this._unit);

  /**
   * Returns the computed [HighlightRegion]s, not `null`.
   */
  List<psi.HighlightRegion> compute() {
    _unit.accept(new RecursiveAstVisitor_DartUnitHighlightsComputer_compute(this));
    return new List.from(_regions);
  }

  void _addIdentifierRegion(SimpleIdentifier node) {
    if (_addIdentifierRegion_keyword(node)) {
      return;
    }
    if (_addIdentifierRegion_class(node)) {
      return;
    }
    if (_addIdentifierRegion_constructor(node)) {
      return;
    }
    if (_addIdentifierRegion_dynamicType(node)) {
      return;
    }
    if (_addIdentifierRegion_getterSetterDeclaration(node)) {
      return;
    }
    if (_addIdentifierRegion_field(node)) {
      return;
    }
    if (_addIdentifierRegion_function(node)) {
      return;
    }
    if (_addIdentifierRegion_functionTypeAlias(node)) {
      return;
    }
    if (_addIdentifierRegion_importPrefix(node)) {
      return;
    }
    if (_addIdentifierRegion_localVariable(node)) {
      return;
    }
    if (_addIdentifierRegion_method(node)) {
      return;
    }
    if (_addIdentifierRegion_parameter(node)) {
      return;
    }
    if (_addIdentifierRegion_topLevelVariable(node)) {
      return;
    }
    if (_addIdentifierRegion_typeParameter(node)) {
      return;
    }
    _addRegion_node(node, psi.HighlightType.IDENTIFIER_DEFAULT);
  }

  void _addIdentifierRegion_annotation(Annotation node) {
    ArgumentList arguments = node.arguments;
    if (arguments == null) {
      _addRegion_node(node, psi.HighlightType.ANNOTATION);
    } else {
      _addRegion_nodeStart_tokenEnd(node, arguments.beginToken, psi.HighlightType.ANNOTATION);
      _addRegion_token(arguments.endToken, psi.HighlightType.ANNOTATION);
    }
  }

  bool _addIdentifierRegion_class(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.ClassElement) {
      return false;
    }
    return _addRegion_node(node, psi.HighlightType.CLASS);
  }

  bool _addIdentifierRegion_constructor(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.ConstructorElement) {
      return false;
    }
    return _addRegion_node(node, psi.HighlightType.CONSTRUCTOR);
  }

  bool _addIdentifierRegion_dynamicType(SimpleIdentifier node) {
    // should be variable
    pae.Element element = node.staticElement;
    if (element is! pae.VariableElement) {
      return false;
    }
    // has propagated type
    if (node.propagatedType != null) {
      return false;
    }
    // has dynamic static type
    DartType staticType = node.staticType;
    if (staticType == null || !staticType.isDynamic) {
      return false;
    }
    // OK
    return _addRegion_node(node, psi.HighlightType.DYNAMIC_TYPE);
  }

  bool _addIdentifierRegion_field(SimpleIdentifier node) {
    pae.Element element = node.bestElement;
    if (element is pae.FieldFormalParameterElement) {
      element = (element as pae.FieldFormalParameterElement).field;
    }
    if (element is pae.FieldElement) {
      if ((element as pae.FieldElement).isStatic) {
        return _addRegion_node(node, psi.HighlightType.FIELD_STATIC);
      } else {
        return _addRegion_node(node, psi.HighlightType.FIELD);
      }
    }
    if (element is pae.PropertyAccessorElement) {
      if ((element as pae.PropertyAccessorElement).isStatic) {
        return _addRegion_node(node, psi.HighlightType.FIELD_STATIC);
      } else {
        return _addRegion_node(node, psi.HighlightType.FIELD);
      }
    }
    return false;
  }

  bool _addIdentifierRegion_function(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.FunctionElement) {
      return false;
    }
    psi.HighlightType type;
    if (node.inDeclarationContext()) {
      type = psi.HighlightType.FUNCTION_DECLARATION;
    } else {
      type = psi.HighlightType.FUNCTION;
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_functionTypeAlias(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.FunctionTypeAliasElement) {
      return false;
    }
    return _addRegion_node(node, psi.HighlightType.FUNCTION_TYPE_ALIAS);
  }

  bool _addIdentifierRegion_getterSetterDeclaration(SimpleIdentifier node) {
    // should be declaration
    AstNode parent = node.parent;
    if (!(parent is MethodDeclaration || parent is FunctionDeclaration)) {
      return false;
    }
    // should be property accessor
    pae.Element element = node.staticElement;
    if (element is! pae.PropertyAccessorElement) {
      return false;
    }
    // getter or setter
    pae.PropertyAccessorElement propertyAccessorElement = element as pae.PropertyAccessorElement;
    if (propertyAccessorElement.isGetter) {
      return _addRegion_node(node, psi.HighlightType.GETTER_DECLARATION);
    } else {
      return _addRegion_node(node, psi.HighlightType.SETTER_DECLARATION);
    }
  }

  bool _addIdentifierRegion_importPrefix(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.PrefixElement) {
      return false;
    }
    return _addRegion_node(node, psi.HighlightType.IMPORT_PREFIX);
  }

  bool _addIdentifierRegion_keyword(SimpleIdentifier node) {
    String name = node.name;
    if (name == "void") {
      return _addRegion_node(node, psi.HighlightType.KEYWORD);
    }
    return false;
  }

  bool _addIdentifierRegion_localVariable(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.LocalVariableElement) {
      return false;
    }
    // OK
    psi.HighlightType type;
    if (node.inDeclarationContext()) {
      type = psi.HighlightType.LOCAL_VARIABLE_DECLARATION;
    } else {
      type = psi.HighlightType.LOCAL_VARIABLE;
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_method(SimpleIdentifier node) {
    pae.Element element = node.bestElement;
    if (element is! pae.MethodElement) {
      return false;
    }
    pae.MethodElement methodElement = element as pae.MethodElement;
    bool isStatic = methodElement.isStatic;
    // OK
    psi.HighlightType type;
    if (node.inDeclarationContext()) {
      if (isStatic) {
        type = psi.HighlightType.METHOD_DECLARATION_STATIC;
      } else {
        type = psi.HighlightType.METHOD_DECLARATION;
      }
    } else {
      if (isStatic) {
        type = psi.HighlightType.METHOD_STATIC;
      } else {
        type = psi.HighlightType.METHOD;
      }
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_parameter(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.ParameterElement) {
      return false;
    }
    return _addRegion_node(node, psi.HighlightType.PARAMETER);
  }

  bool _addIdentifierRegion_topLevelVariable(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.TopLevelVariableElement) {
      return false;
    }
    return _addRegion_node(node, psi.HighlightType.TOP_LEVEL_VARIABLE);
  }

  bool _addIdentifierRegion_typeParameter(SimpleIdentifier node) {
    pae.Element element = node.staticElement;
    if (element is! pae.TypeParameterElement) {
      return false;
    }
    return _addRegion_node(node, psi.HighlightType.TYPE_PARAMETER);
  }

  void _addRegion(int offset, int length, psi.HighlightType type) {
    _regions.add(new HighlightRegionImpl(offset, length, type));
  }

  bool _addRegion_node(AstNode node, psi.HighlightType type) {
    int offset = node.offset;
    int length = node.length;
    _addRegion(offset, length, type);
    return true;
  }

  void _addRegion_nodeStart_tokenEnd(AstNode a, Token b, psi.HighlightType type) {
    int offset = a.offset;
    int end = b.end;
    _addRegion(offset, end - offset, type);
  }

  void _addRegion_token(Token token, psi.HighlightType type) {
    if (token != null) {
      int offset = token.offset;
      int length = token.length;
      _addRegion(offset, length, type);
    }
  }

  void _addRegion_tokenStart_tokenEnd(Token a, Token b, psi.HighlightType type) {
    int offset = a.offset;
    int end = b.end;
    _addRegion(offset, end - offset, type);
  }
}

/**
 * A computer for [NavigationRegion]s in a Dart [CompilationUnit].
 */
class DartUnitNavigationComputer {
  final CompilationUnit _unit;

  List<psi.NavigationRegion> _regions = [];

  DartUnitNavigationComputer(this._unit);

  /**
   * Returns the computed [NavigationRegion]s, not `null`.
   */
  List<psi.NavigationRegion> compute() {
    _unit.accept(new RecursiveAstVisitor_DartUnitNavigationComputer_compute(this));
    return new List.from(_regions);
  }

  /**
   * If the given [Element] is not `null`, then creates a corresponding
   * [NavigationRegion].
   */
  void _addRegion(int offset, int length, pae.Element element) {
    psi.Element target = _createTarget(element);
    if (target == null) {
      return;
    }
    _regions.add(new NavigationRegionImpl(offset, length, <psi.Element> [target]));
  }

  void _addRegion_tokenStart_nodeEnd(Token a, AstNode b, pae.Element element) {
    int offset = a.offset;
    int length = b.end - offset;
    _addRegion(offset, length, element);
  }

  /**
   * If the given [Element] is not `null`, then creates a corresponding
   * [NavigationRegion].
   */
  void _addRegionForNode(AstNode node, pae.Element element) {
    int offset = node.offset;
    int length = node.length;
    _addRegion(offset, length, element);
  }

  /**
   * If the given [Element] is not `null`, then creates a corresponding
   * [NavigationRegion].
   */
  void _addRegionForToken(Token token, pae.Element element) {
    int offset = token.offset;
    int length = token.length;
    _addRegion(offset, length, element);
  }

  /**
   * Returns the [com.google.dart.server.Element] for the given [Element], maybe
   * `null` if `null` was given.
   */
  psi.Element _createTarget(pae.Element element) {
    if (element == null) {
      return null;
    }
    if (element is pae.FieldFormalParameterElement) {
      element = (element as pae.FieldFormalParameterElement).field;
    }
    return ElementImpl.create(element);
  }
}

/**
 * A computer for [Outline]s in a Dart [CompilationUnit].
 */
class DartUnitOutlineComputer {
  static String _UNITTEST_LIBRARY = "unittest";

  final Source _source;

  final CompilationUnit _unit;

  DartUnitOutlineComputer(this._source, this._unit);

  /**
   * Returns the computed [Outline]s, not `null`.
   */
  psi.Outline compute() {
    OutlineImpl unitOutline = _newUnitOutline();
    List<psi.Outline> unitChildren = [];
    for (CompilationUnitMember unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        ClassDeclaration classDeclartion = unitMember;
        OutlineImpl classOutline = _newClassOutline(unitOutline, unitChildren, classDeclartion);
        List<psi.Outline> classChildren = [];
        for (ClassMember classMember in classDeclartion.members) {
          if (classMember is ConstructorDeclaration) {
            ConstructorDeclaration constructorDeclaration = classMember;
            _newConstructorOutline(classOutline, classChildren, constructorDeclaration);
          }
          if (classMember is FieldDeclaration) {
            FieldDeclaration fieldDeclaration = classMember;
            VariableDeclarationList fields = fieldDeclaration.fields;
            if (fields != null) {
              TypeName fieldType = fields.type;
              String fieldTypeName = fieldType != null ? fieldType.toSource() : "";
              for (VariableDeclaration field in fields.variables) {
                _newField(classOutline, classChildren, fieldTypeName, field, fieldDeclaration.isStatic);
              }
            }
          }
          if (classMember is MethodDeclaration) {
            MethodDeclaration methodDeclaration = classMember;
            _newMethodOutline(classOutline, classChildren, methodDeclaration);
          }
        }
        classOutline.children = new List.from(classChildren);
      }
      if (unitMember is FunctionDeclaration) {
        FunctionDeclaration functionDeclaration = unitMember;
        _newFunctionOutline(unitOutline, unitChildren, functionDeclaration);
      }
      if (unitMember is ClassTypeAlias) {
        ClassTypeAlias alias = unitMember;
        _newClassTypeAlias(unitOutline, unitChildren, alias);
      }
      if (unitMember is FunctionTypeAlias) {
        FunctionTypeAlias alias = unitMember;
        _newFunctionTypeAliasOutline(unitOutline, unitChildren, alias);
      }
    }
    unitOutline.children = new List.from(unitChildren);
    return unitOutline;
  }

  void _addLocalFunctionOutlines(OutlineImpl parent, FunctionBody body) {
    List<psi.Outline> localOutlines = [];
    body.accept(new RecursiveAstVisitor_DartUnitOutlineComputer_addLocalFunctionOutlines(this, parent, localOutlines));
    parent.children = new List.from(localOutlines);
  }

  bool _addUnitTestOutlines(OutlineImpl parent, List<psi.Outline> children, MethodInvocation node) {
    psi.ElementKind unitTestKind = null;
    if (_isUnitTestFunctionInvocation(node, "group")) {
      unitTestKind = psi.ElementKind.UNIT_TEST_GROUP;
    } else if (_isUnitTestFunctionInvocation(node, "test")) {
      unitTestKind = psi.ElementKind.UNIT_TEST_CASE;
    } else {
      return false;
    }
    ArgumentList argumentList = node.argumentList;
    if (argumentList != null) {
      List<Expression> arguments = argumentList.arguments;
      if (arguments.length == 2 && arguments[1] is FunctionExpression) {
        // prepare name
        String name;
        int nameOffset;
        int nameLength;
        {
          Expression nameNode = arguments[0];
          if (nameNode is SimpleStringLiteral) {
            SimpleStringLiteral nameLiteral = arguments[0] as SimpleStringLiteral;
            name = nameLiteral.value;
            nameOffset = nameLiteral.valueOffset;
            nameLength = name.length;
          } else {
            name = "??????????";
            nameOffset = nameNode.offset;
            nameLength = nameNode.length;
          }
        }
        // add a new outline
        FunctionExpression functionExpression = arguments[1] as FunctionExpression;
        SourceRegionImpl sourceRegion = new SourceRegionImpl(node.offset, node.length);
        ElementImpl element = new ElementImpl(null, _source, unitTestKind, name, nameOffset, nameLength, null, null, false, false, false);
        OutlineImpl outline = new OutlineImpl(parent, element, sourceRegion);
        children.add(outline);
        _addLocalFunctionOutlines(outline, functionExpression.body);
        return true;
      }
    }
    return false;
  }

  /**
   * Returns the [AstNode]'s source region.
   */
  psi.SourceRegion _getSourceRegion(AstNode node) {
    int endOffset = node.end;
    // prepare position of the node among its siblings
    int firstOffset;
    List<AstNode> siblings;
    AstNode parent = node.parent;
    // field
    if (parent is VariableDeclarationList) {
      VariableDeclarationList variableList = parent as VariableDeclarationList;
      List<VariableDeclaration> variables = variableList.variables;
      int variableIndex = variables.indexOf(node);
      if (variableIndex == variables.length - 1) {
        endOffset = variableList.parent.end;
      }
      if (variableIndex == 0) {
        node = parent.parent;
        parent = node.parent;
      } else if (variableIndex >= 1) {
        firstOffset = variables[variableIndex - 1].end;
        return new SourceRegionImpl(firstOffset, endOffset - firstOffset);
      }
    }
    // unit or class member
    if (parent is CompilationUnit) {
      firstOffset = 0;
      siblings = (parent as CompilationUnit).declarations;
    } else if (parent is ClassDeclaration) {
      ClassDeclaration classDeclaration = parent as ClassDeclaration;
      firstOffset = classDeclaration.leftBracket.end;
      siblings = classDeclaration.members;
    } else {
      int offset = node.offset;
      return new SourceRegionImpl(offset, endOffset - offset);
    }
    // first child: [endOfParent, endOfNode]
    int index = siblings.indexOf(node);
    if (index == 0) {
      return new SourceRegionImpl(firstOffset, endOffset - firstOffset);
    }
    // not first child: [endOfPreviousSibling, endOfNode]
    int prevSiblingEnd = siblings[index - 1].end;
    return new SourceRegionImpl(prevSiblingEnd, endOffset - prevSiblingEnd);
  }

  /**
   * Returns `true` if the given [MethodInvocation] is invocation of the function with
   * the given name from the "unittest" library.
   */
  bool _isUnitTestFunctionInvocation(MethodInvocation node, String name) {
    SimpleIdentifier methodName = node.methodName;
    if (methodName != null) {
      pae.Element element = methodName.staticElement;
      if (element is pae.FunctionElement) {
        pae.FunctionElement functionElement = element;
        if (name == functionElement.name) {
          pae.LibraryElement libraryElement = functionElement.library;
          return libraryElement != null && _UNITTEST_LIBRARY == libraryElement.name;
        }
      }
    }
    return false;
  }

  OutlineImpl _newClassOutline(psi.Outline unitOutline, List<psi.Outline> unitChildren, ClassDeclaration classDeclaration) {
    SimpleIdentifier nameNode = classDeclaration.name;
    String name = nameNode.name;
    ElementImpl element = new ElementImpl(ElementImpl.createId(classDeclaration.element), _source, psi.ElementKind.CLASS, name, nameNode.offset, name.length, null, null, classDeclaration.isAbstract, false, StringUtilities.startsWithChar(name, 0x5F));
    psi.SourceRegion sourceRegion = _getSourceRegion(classDeclaration);
    OutlineImpl outline = new OutlineImpl(unitOutline, element, sourceRegion);
    unitChildren.add(outline);
    return outline;
  }

  void _newClassTypeAlias(psi.Outline unitOutline, List<psi.Outline> unitChildren, ClassTypeAlias alias) {
    SimpleIdentifier nameNode = alias.name;
    String name = nameNode.name;
    ElementImpl element = new ElementImpl(ElementImpl.createId(alias.element), _source, psi.ElementKind.CLASS_TYPE_ALIAS, name, nameNode.offset, nameNode.length, null, null, alias.isAbstract, false, StringUtilities.startsWithChar(name, 0x5F));
    psi.SourceRegion sourceRegion = _getSourceRegion(alias);
    OutlineImpl outline = new OutlineImpl(unitOutline, element, sourceRegion);
    unitChildren.add(outline);
  }

  void _newConstructorOutline(OutlineImpl classOutline, List<psi.Outline> children, ConstructorDeclaration constructorDeclaration) {
    Identifier returnType = constructorDeclaration.returnType;
    String name = returnType.name;
    int offset = returnType.offset;
    int length = returnType.length;
    bool isPrivate = false;
    SimpleIdentifier constructorNameNode = constructorDeclaration.name;
    if (constructorNameNode != null) {
      String constructorName = constructorNameNode.name;
      isPrivate = StringUtilities.startsWithChar(constructorName, 0x5F);
      name += ".${constructorName}";
      offset = constructorNameNode.offset;
      length = constructorNameNode.length;
    }
    FormalParameterList parameters = constructorDeclaration.parameters;
    ElementImpl element = new ElementImpl(ElementImpl.createId(constructorDeclaration.element), _source, psi.ElementKind.CONSTRUCTOR, name, offset, length, parameters != null ? parameters.toSource() : "", null, false, false, isPrivate);
    psi.SourceRegion sourceRegion = _getSourceRegion(constructorDeclaration);
    OutlineImpl outline = new OutlineImpl(classOutline, element, sourceRegion);
    children.add(outline);
    _addLocalFunctionOutlines(outline, constructorDeclaration.body);
  }

  void _newField(OutlineImpl classOutline, List<psi.Outline> children, String fieldTypeName, VariableDeclaration field, bool isStatic) {
    SimpleIdentifier nameNode = field.name;
    String name = nameNode.name;
    ElementImpl element = new ElementImpl(ElementImpl.createId(field.element), _source, psi.ElementKind.FIELD, name, nameNode.offset, nameNode.length, null, fieldTypeName, false, isStatic, StringUtilities.startsWithChar(name, 0x5F));
    psi.SourceRegion sourceRegion = _getSourceRegion(field);
    OutlineImpl outline = new OutlineImpl(classOutline, element, sourceRegion);
    children.add(outline);
  }

  void _newFunctionOutline(psi.Outline parent, List<psi.Outline> children, FunctionDeclaration functionDeclaration) {
    TypeName returnType = functionDeclaration.returnType;
    SimpleIdentifier nameNode = functionDeclaration.name;
    String name = nameNode.name;
    FunctionExpression functionExpression = functionDeclaration.functionExpression;
    FormalParameterList parameters = functionExpression.parameters;
    psi.ElementKind kind;
    if (functionDeclaration.isGetter) {
      kind = psi.ElementKind.GETTER;
    } else if (functionDeclaration.isSetter) {
      kind = psi.ElementKind.SETTER;
    } else {
      kind = psi.ElementKind.FUNCTION;
    }
    ElementImpl element = new ElementImpl(ElementImpl.createId(functionDeclaration.element), _source, kind, name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : "", false, false, StringUtilities.startsWithChar(name, 0x5F));
    psi.SourceRegion sourceRegion = _getSourceRegion(functionDeclaration);
    OutlineImpl outline = new OutlineImpl(parent, element, sourceRegion);
    children.add(outline);
    _addLocalFunctionOutlines(outline, functionExpression.body);
  }

  void _newFunctionTypeAliasOutline(psi.Outline unitOutline, List<psi.Outline> unitChildren, FunctionTypeAlias alias) {
    TypeName returnType = alias.returnType;
    SimpleIdentifier nameNode = alias.name;
    String name = nameNode.name;
    FormalParameterList parameters = alias.parameters;
    ElementImpl element = new ElementImpl(ElementImpl.createId(alias.element), _source, psi.ElementKind.FUNCTION_TYPE_ALIAS, name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : "", false, false, StringUtilities.startsWithChar(name, 0x5F));
    psi.SourceRegion sourceRegion = _getSourceRegion(alias);
    OutlineImpl outline = new OutlineImpl(unitOutline, element, sourceRegion);
    unitChildren.add(outline);
  }

  void _newMethodOutline(OutlineImpl classOutline, List<psi.Outline> children, MethodDeclaration methodDeclaration) {
    TypeName returnType = methodDeclaration.returnType;
    SimpleIdentifier nameNode = methodDeclaration.name;
    String name = nameNode.name;
    FormalParameterList parameters = methodDeclaration.parameters;
    psi.ElementKind kind;
    if (methodDeclaration.isGetter) {
      kind = psi.ElementKind.GETTER;
    } else if (methodDeclaration.isSetter) {
      kind = psi.ElementKind.SETTER;
    } else {
      kind = psi.ElementKind.METHOD;
    }
    ElementImpl element = new ElementImpl(ElementImpl.createId(methodDeclaration.element), _source, kind, name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : "", methodDeclaration.isAbstract, methodDeclaration.isStatic, StringUtilities.startsWithChar(name, 0x5F));
    psi.SourceRegion sourceRegion = _getSourceRegion(methodDeclaration);
    OutlineImpl outline = new OutlineImpl(classOutline, element, sourceRegion);
    children.add(outline);
    _addLocalFunctionOutlines(outline, methodDeclaration.body);
  }

  OutlineImpl _newUnitOutline() {
    ElementImpl element = new ElementImpl(ElementImpl.createId(_unit.element), _source, psi.ElementKind.COMPILATION_UNIT, null, 0, 0, null, null, false, false, false);
    return new OutlineImpl(null, element, new SourceRegionImpl(_unit.offset, _unit.length));
  }
}

/**
 * A concrete implementation of [Element].
 */
class ElementImpl implements psi.Element {
  /**
   * Creates an [ElementImpl] instance for the given
   * [com.google.dart.engine.element.Element].
   */
  static ElementImpl create(pae.Element element) {
    // prepare name
    String name = element.displayName;
    int nameOffset = element.nameOffset;
    int nameLength = name != null ? name.length : 0;
    // prepare element kind specific information
    psi.ElementKind outlineKind;
    bool isAbstract = false;
    bool isStatic = false;
    bool isPrivate = element.isPrivate;
    while (true) {
      if (element.kind == pae.ElementKind.CLASS) {
        outlineKind = psi.ElementKind.CLASS;
        isAbstract = (element as pae.ClassElement).isAbstract;
      } else if (element.kind == pae.ElementKind.COMPILATION_UNIT) {
        outlineKind = psi.ElementKind.COMPILATION_UNIT;
        nameOffset = -1;
        nameLength = 0;
      } else if (element.kind == pae.ElementKind.CONSTRUCTOR) {
        outlineKind = psi.ElementKind.CONSTRUCTOR;
        String className = element.enclosingElement.name;
        if (name.length != 0) {
          name = "${className}.${name}";
        } else {
          name = className;
        }
      } else if (element.kind == pae.ElementKind.FUNCTION) {
        outlineKind = psi.ElementKind.FUNCTION;
      } else if (element.kind == pae.ElementKind.FUNCTION_TYPE_ALIAS) {
        outlineKind = psi.ElementKind.FUNCTION_TYPE_ALIAS;
      } else if (element.kind == pae.ElementKind.LIBRARY) {
        outlineKind = psi.ElementKind.LIBRARY;
      } else if (element.kind == pae.ElementKind.METHOD) {
        outlineKind = psi.ElementKind.METHOD;
        isAbstract = (element as pae.MethodElement).isAbstract;
      } else {
        outlineKind = psi.ElementKind.UNKNOWN;
      }
      break;
    }
    // extract return type and parameters from toString()
    // TODO(scheglov) we need a way to get this information directly from an Element
    String parameters;
    String returnType;
    {
      String str = element.toString();
      // return type
      String rightArrow = pae.Element.RIGHT_ARROW;
      int returnIndex = str.lastIndexOf(rightArrow);
      if (returnIndex != -1) {
        returnType = str.substring(returnIndex + rightArrow.length);
        str = str.substring(0, returnIndex);
      } else {
        returnType = null;
      }
      // parameters
      int parametersIndex = str.indexOf("(");
      if (parametersIndex != -1) {
        parameters = str.substring(parametersIndex);
      } else {
        parameters = null;
      }
    }
    // new element
    return new ElementImpl(createId(element), element.source, outlineKind, name, nameOffset, nameLength, parameters, returnType, isAbstract, isStatic, isPrivate);
  }

  /**
   * Returns an identifier of the given [Element], maybe `null` if `null` given.
   */
  static String createId(pae.Element element) {
    if (element == null) {
      return null;
    }
    return element.location.encoding;
  }

  final String id;

  final Source source;

  final psi.ElementKind kind;

  final String name;

  final int offset;

  final int length;

  final String parameters;

  final String returnType;

  final bool isAbstract;

  final bool isPrivate;

  final bool isStatic;

  ElementImpl(this.id, this.source, this.kind, this.name, this.offset, this.length, this.parameters, this.returnType, this.isAbstract, this.isStatic, this.isPrivate);

  @override
  bool operator ==(Object obj) {
    if (identical(obj, this)) {
      return true;
    }
    if (obj is! ElementImpl) {
      return false;
    }
    ElementImpl other = obj as ElementImpl;
    return other.kind == kind && (other.source == source) && (name == other.name);
  }

  @override
  int get hashCode {
    if (name == null) {
      return source.hashCode;
    }
    return ObjectUtilities.combineHashCodes(source.hashCode, name.hashCode);
  }

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[name=");
    builder.append(name);
    builder.append(", kind=");
    builder.append(kind);
    builder.append(", offset=");
    builder.append(offset);
    builder.append(", length=");
    builder.append(length);
    builder.append(", parameters=");
    builder.append(parameters);
    builder.append(", return=");
    builder.append(returnType);
    builder.append("]");
    return builder.toString();
  }
}

/**
 * A concrete implementation of [HighlightRegion].
 */
class HighlightRegionImpl extends SourceRegionImpl implements psi.HighlightRegion {
  final psi.HighlightType type;

  HighlightRegionImpl(int offset, int length, this.type) : super(offset, length);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[offset=");
    builder.append(offset);
    builder.append(", length=");
    builder.append(length);
    builder.append(", type=");
    builder.append(type);
    builder.append("]");
    return builder.toString();
  }
}

/**
 * A concrete implementation of [NavigationRegion].
 */
class NavigationRegionImpl extends SourceRegionImpl implements psi.NavigationRegion {
  final List<psi.Element> targets;

  NavigationRegionImpl(int offset, int length, this.targets) : super(offset, length);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append(super.toString());
    builder.append(" -> [");
    builder.append(StringUtils.join(targets, ", "));
    builder.append("]");
    return builder.toString();
  }
}

/**
 * A concrete implementation of [Outline].
 */
class OutlineImpl implements psi.Outline {
  final psi.Outline parent;

  final psi.Element element;

  final psi.SourceRegion sourceRegion;

  List<psi.Outline> children = psi.Outline.EMPTY_ARRAY;

  OutlineImpl(this.parent, this.element, this.sourceRegion);

  @override
  bool operator ==(Object obj) {
    if (identical(obj, this)) {
      return true;
    }
    if (obj is! OutlineImpl) {
      return false;
    }
    OutlineImpl other = obj as OutlineImpl;
    return (other.element == element) && (other.parent == parent);
  }

  @override
  int get hashCode {
    if (parent == null) {
      return element.hashCode;
    }
    return ObjectUtilities.combineHashCodes(parent.hashCode, element.hashCode);
  }

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[element=");
    builder.append(element);
    builder.append(", children=[");
    builder.append(StringUtils.join(children, ", "));
    builder.append("]]");
    return builder.toString();
  }
}

class RecursiveAstVisitor_DartUnitHighlightsComputer_compute extends RecursiveAstVisitor<Object> {
  final DartUnitHighlightsComputer DartUnitHighlightsComputer_this;

  RecursiveAstVisitor_DartUnitHighlightsComputer_compute(this.DartUnitHighlightsComputer_this) : super();

  @override
  Object visitAnnotation(Annotation node) {
    DartUnitHighlightsComputer_this._addIdentifierRegion_annotation(node);
    return super.visitAnnotation(node);
  }

  @override
  Object visitAsExpression(AsExpression node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.asOperator, psi.HighlightType.BUILT_IN);
    return super.visitAsExpression(node);
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    DartUnitHighlightsComputer_this._addRegion_node(node, psi.HighlightType.LITERAL_BOOLEAN);
    return super.visitBooleanLiteral(node);
  }

  @override
  Object visitCatchClause(CatchClause node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.onKeyword, psi.HighlightType.BUILT_IN);
    return super.visitCatchClause(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.abstractKeyword, psi.HighlightType.BUILT_IN);
    return super.visitClassDeclaration(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.externalKeyword, psi.HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.factoryKeyword, psi.HighlightType.BUILT_IN);
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    DartUnitHighlightsComputer_this._addRegion_node(node, psi.HighlightType.LITERAL_DOUBLE);
    return super.visitDoubleLiteral(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    return super.visitExportDirective(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.staticKeyword, psi.HighlightType.BUILT_IN);
    return super.visitFieldDeclaration(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.externalKeyword, psi.HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.propertyKeyword, psi.HighlightType.BUILT_IN);
    return super.visitFunctionDeclaration(node);
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    return super.visitFunctionTypeAlias(node);
  }

  @override
  Object visitHideCombinator(HideCombinator node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    return super.visitHideCombinator(node);
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    return super.visitImplementsClause(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.deferredToken, psi.HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.asToken, psi.HighlightType.BUILT_IN);
    return super.visitImportDirective(node);
  }

  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    DartUnitHighlightsComputer_this._addRegion_node(node, psi.HighlightType.LITERAL_INTEGER);
    return super.visitIntegerLiteral(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.externalKeyword, psi.HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.modifierKeyword, psi.HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.operatorKeyword, psi.HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.propertyKeyword, psi.HighlightType.BUILT_IN);
    return super.visitMethodDeclaration(node);
  }

  @override
  Object visitNativeClause(NativeClause node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    return super.visitNativeClause(node);
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.nativeToken, psi.HighlightType.BUILT_IN);
    return super.visitNativeFunctionBody(node);
  }

  @override
  Object visitPartDirective(PartDirective node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    DartUnitHighlightsComputer_this._addRegion_tokenStart_tokenEnd(node.partToken, node.ofToken, psi.HighlightType.BUILT_IN);
    return super.visitPartOfDirective(node);
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, psi.HighlightType.BUILT_IN);
    return super.visitShowCombinator(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    DartUnitHighlightsComputer_this._addIdentifierRegion(node);
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    DartUnitHighlightsComputer_this._addRegion_node(node, psi.HighlightType.LITERAL_STRING);
    return super.visitSimpleStringLiteral(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    DartType type = node.type;
    if (type != null) {
      if (type.isDynamic && node.name.name == "dynamic") {
        DartUnitHighlightsComputer_this._addRegion_node(node, psi.HighlightType.TYPE_NAME_DYNAMIC);
        return null;
      }
    }
    return super.visitTypeName(node);
  }
}

class RecursiveAstVisitor_DartUnitNavigationComputer_compute extends RecursiveAstVisitor<Object> {
  final DartUnitNavigationComputer DartUnitNavigationComputer_this;

  RecursiveAstVisitor_DartUnitNavigationComputer_compute(this.DartUnitNavigationComputer_this) : super();

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.operator, node.bestElement);
    return super.visitAssignmentExpression(node);
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.operator, node.bestElement);
    return super.visitBinaryExpression(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    pae.ExportElement exportElement = node.element;
    if (exportElement != null) {
      pae.Element element = exportElement.exportedLibrary;
      DartUnitNavigationComputer_this._addRegion_tokenStart_nodeEnd(node.keyword, node.uri, element);
    }
    return super.visitExportDirective(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    pae.ImportElement importElement = node.element;
    if (importElement != null) {
      pae.Element element = importElement.importedLibrary;
      DartUnitNavigationComputer_this._addRegion_tokenStart_nodeEnd(node.keyword, node.uri, element);
    }
    return super.visitImportDirective(node);
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.rightBracket, node.bestElement);
    return super.visitIndexExpression(node);
  }

  @override
  Object visitPartDirective(PartDirective node) {
    DartUnitNavigationComputer_this._addRegion_tokenStart_nodeEnd(node.keyword, node.uri, node.element);
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    DartUnitNavigationComputer_this._addRegion_tokenStart_nodeEnd(node.keyword, node.libraryName, node.element);
    return super.visitPartOfDirective(node);
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.operator, node.bestElement);
    return super.visitPostfixExpression(node);
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.operator, node.bestElement);
    return super.visitPrefixExpression(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    DartUnitNavigationComputer_this._addRegionForNode(node, node.bestElement);
    return super.visitSimpleIdentifier(node);
  }
}

class RecursiveAstVisitor_DartUnitOutlineComputer_addLocalFunctionOutlines extends RecursiveAstVisitor<Object> {
  final DartUnitOutlineComputer DartUnitOutlineComputer_this;

  OutlineImpl parent;

  List<psi.Outline> localOutlines;

  RecursiveAstVisitor_DartUnitOutlineComputer_addLocalFunctionOutlines(this.DartUnitOutlineComputer_this, this.parent, this.localOutlines) : super();

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    DartUnitOutlineComputer_this._newFunctionOutline(parent, localOutlines, node);
    return null;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    bool handled = DartUnitOutlineComputer_this._addUnitTestOutlines(parent, localOutlines, node);
    if (handled) {
      return null;
    }
    return super.visitMethodInvocation(node);
  }
}

/**
 * A concrete implementation of [SearchResult].
 */
class SearchResultImpl implements psi.SearchResult {
  final List<psi.Element> path;

  final Source source;

  final psi.SearchResultKind kind;

  final int offset;

  final int length;

  SearchResultImpl(this.path, this.source, this.kind, this.offset, this.length);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[source=");
    builder.append(source);
    builder.append(", kind=");
    builder.append(kind);
    builder.append(", offset=");
    builder.append(offset);
    builder.append(", length=");
    builder.append(length);
    builder.append(", path=");
    builder.append(path);
    builder.append("]");
    return builder.toString();
  }
}

/**
 * A concrete implementation of [SourceRegion].
 */
class SourceRegionImpl implements psi.SourceRegion {
  final int offset;

  final int length;

  SourceRegionImpl(this.offset, this.length);

  @override
  bool containsInclusive(int x) => offset <= x && x <= offset + length;

  @override
  bool operator ==(Object obj) {
    if (identical(obj, this)) {
      return true;
    }
    if (obj is! psi.SourceRegion) {
      return false;
    }
    psi.SourceRegion other = obj as psi.SourceRegion;
    return other.offset == offset && other.length == length;
  }

  @override
  int get hashCode => ObjectUtilities.combineHashCodes(offset, length);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[offset=");
    builder.append(offset);
    builder.append(", length=");
    builder.append(length);
    builder.append("]");
    return builder.toString();
  }
}