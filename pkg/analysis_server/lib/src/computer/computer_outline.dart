// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.outline;

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A computer for [CompilationUnit] outline.
 */
class DartUnitOutlineComputer {
  final CompilationUnit _unit;
  String file;
  LineInfo lineInfo;

  DartUnitOutlineComputer(AnalysisContext context, Source source, this._unit) {
    file = source.fullName;
    lineInfo = context.getLineInfo(source);
  }

  /**
   * Returns the computed outline, not `null`.
   */
  Outline compute() {
    Outline unitOutline = _newUnitOutline();
    for (CompilationUnitMember unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        ClassDeclaration classDeclaration = unitMember;
        Outline classOutline = _newClassOutline(unitOutline, classDeclaration);
        for (ClassMember classMember in classDeclaration.members) {
          if (classMember is ConstructorDeclaration) {
            ConstructorDeclaration constructorDeclaration = classMember;
            _newConstructorOutline(classOutline, constructorDeclaration);
          }
          if (classMember is FieldDeclaration) {
            FieldDeclaration fieldDeclaration = classMember;
            VariableDeclarationList fields = fieldDeclaration.fields;
            if (fields != null) {
              TypeName fieldType = fields.type;
              String fieldTypeName = fieldType != null ? fieldType.toSource() :
                  '';
              for (VariableDeclaration field in fields.variables) {
                _newVariableOutline(classOutline, fieldTypeName,
                    ElementKind.FIELD, field, fieldDeclaration.isStatic);
              }
            }
          }
          if (classMember is MethodDeclaration) {
            MethodDeclaration methodDeclaration = classMember;
            _newMethodOutline(classOutline, methodDeclaration);
          }
        }
      }
      if (unitMember is TopLevelVariableDeclaration) {
        TopLevelVariableDeclaration fieldDeclaration = unitMember;
        VariableDeclarationList fields = fieldDeclaration.variables;
        if (fields != null) {
          TypeName fieldType = fields.type;
          String fieldTypeName = fieldType != null ? fieldType.toSource() : '';
          for (VariableDeclaration field in fields.variables) {
            _newVariableOutline(unitOutline, fieldTypeName,
                ElementKind.TOP_LEVEL_VARIABLE, field, false);
          }
        }
      }
      if (unitMember is FunctionDeclaration) {
        FunctionDeclaration functionDeclaration = unitMember;
        _newFunctionOutline(unitOutline, functionDeclaration, true);
      }
      if (unitMember is ClassTypeAlias) {
        ClassTypeAlias alias = unitMember;
        _newClassTypeAlias(unitOutline, alias);
      }
      if (unitMember is FunctionTypeAlias) {
        FunctionTypeAlias alias = unitMember;
        _newFunctionTypeAliasOutline(unitOutline, alias);
      }
    }
    return unitOutline;
  }

  void _addLocalFunctionOutlines(Outline parent, FunctionBody body) {
    body.accept(new _LocalFunctionOutlinesVisitor(this, parent));
  }

  Location _getLocationNode(AstNode node) {
    int offset = node.offset;
    int length = node.length;
    return _getLocationOffsetLength(offset, length);
  }

  Location _getLocationOffsetLength(int offset, int length) {
    LineInfo_Location lineLocation = lineInfo.getLocation(offset);
    int startLine = lineLocation.lineNumber;
    int startColumn = lineLocation.columnNumber;
    return new Location(file, offset, length, startLine, startColumn);
  }

  /**
   * Returns the [AstNode]'s source region.
   */
  _SourceRegion _getSourceRegion(AstNode node) {
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
        return new _SourceRegion(firstOffset, endOffset - firstOffset);
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
      return new _SourceRegion(offset, endOffset - offset);
    }
    // first child: [endOfParent, endOfNode]
    int index = siblings.indexOf(node);
    if (index == 0) {
      return new _SourceRegion(firstOffset, endOffset - firstOffset);
    }
    // not first child: [endOfPreviousSibling, endOfNode]
    int prevSiblingEnd = siblings[index - 1].end;
    return new _SourceRegion(prevSiblingEnd, endOffset - prevSiblingEnd);
  }

  Outline _newClassOutline(Outline parent, ClassDeclaration classDeclaration) {
    SimpleIdentifier nameNode = classDeclaration.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(classDeclaration);
    Element element = new Element(ElementKind.CLASS, name, _getLocationNode(
        nameNode), Identifier.isPrivateName(name), _isDeprecated(classDeclaration),
        isAbstract: classDeclaration.isAbstract);
    Outline outline = new Outline(element, sourceRegion.offset,
        sourceRegion.length);
    parent.children.add(outline);
    return outline;
  }

  void _newClassTypeAlias(Outline parent, ClassTypeAlias alias) {
    SimpleIdentifier nameNode = alias.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(alias);
    Element element = new Element(ElementKind.CLASS_TYPE_ALIAS, name,
        _getLocationNode(nameNode), Identifier.isPrivateName(name), _isDeprecated(
        alias), isAbstract: alias.isAbstract);
    Outline outline = new Outline(element, sourceRegion.offset,
        sourceRegion.length);
    parent.children.add(outline);
  }

  void _newConstructorOutline(Outline parent,
      ConstructorDeclaration constructor) {
    Identifier returnType = constructor.returnType;
    String name = returnType.name;
    int offset = returnType.offset;
    int length = returnType.length;
    SimpleIdentifier constructorNameNode = constructor.name;
    bool isPrivate = false;
    if (constructorNameNode != null) {
      String constructorName = constructorNameNode.name;
      isPrivate = Identifier.isPrivateName(constructorName);
      name += '.${constructorName}';
      offset = constructorNameNode.offset;
      length = constructorNameNode.length;
    }
    _SourceRegion sourceRegion = _getSourceRegion(constructor);
    FormalParameterList parameters = constructor.parameters;
    String parametersStr = parameters != null ? parameters.toSource() : '';
    Element element = new Element(ElementKind.CONSTRUCTOR, name,
        _getLocationOffsetLength(offset, length), isPrivate, _isDeprecated(constructor),
        parameters: parametersStr);
    Outline outline = new Outline(element, sourceRegion.offset,
        sourceRegion.length);
    parent.children.add(outline);
    _addLocalFunctionOutlines(outline, constructor.body);
  }

  void _newFunctionOutline(Outline parent, FunctionDeclaration function,
      bool isStatic) {
    TypeName returnType = function.returnType;
    SimpleIdentifier nameNode = function.name;
    String name = nameNode.name;
    FunctionExpression functionExpression = function.functionExpression;
    FormalParameterList parameters = functionExpression.parameters;
    ElementKind kind;
    if (function.isGetter) {
      kind = ElementKind.GETTER;
    } else if (function.isSetter) {
      kind = ElementKind.SETTER;
    } else {
      kind = ElementKind.FUNCTION;
    }
    _SourceRegion sourceRegion = _getSourceRegion(function);
    String parametersStr = parameters != null ? parameters.toSource() : '';
    String returnTypeStr = returnType != null ? returnType.toSource() : '';
    Element element = new Element(kind, name, _getLocationNode(nameNode),
        Identifier.isPrivateName(name), _isDeprecated(function), parameters:
        parametersStr, returnType: returnTypeStr, isStatic: isStatic);
    Outline outline = new Outline(element, sourceRegion.offset,
        sourceRegion.length);
    parent.children.add(outline);
    _addLocalFunctionOutlines(outline, functionExpression.body);
  }

  void _newFunctionTypeAliasOutline(Outline parent, FunctionTypeAlias alias) {
    TypeName returnType = alias.returnType;
    SimpleIdentifier nameNode = alias.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(alias);
    FormalParameterList parameters = alias.parameters;
    String parametersStr = parameters != null ? parameters.toSource() : '';
    String returnTypeStr = returnType != null ? returnType.toSource() : '';
    Element element = new Element(ElementKind.FUNCTION_TYPE_ALIAS, name,
        _getLocationNode(nameNode), Identifier.isPrivateName(name), _isDeprecated(
        alias), parameters: parametersStr, returnType: returnTypeStr);
    Outline outline = new Outline(element, sourceRegion.offset,
        sourceRegion.length);
    parent.children.add(outline);
  }

  void _newMethodOutline(Outline parent, MethodDeclaration method) {
    TypeName returnType = method.returnType;
    SimpleIdentifier nameNode = method.name;
    String name = nameNode.name;
    FormalParameterList parameters = method.parameters;
    ElementKind kind;
    if (method.isGetter) {
      kind = ElementKind.GETTER;
    } else if (method.isSetter) {
      kind = ElementKind.SETTER;
    } else {
      kind = ElementKind.METHOD;
    }
    _SourceRegion sourceRegion = _getSourceRegion(method);
    String parametersStr = parameters != null ? parameters.toSource() : '';
    String returnTypeStr = returnType != null ? returnType.toSource() : '';
    Element element = new Element(kind, name, _getLocationNode(nameNode),
        Identifier.isPrivateName(name), _isDeprecated(method), parameters:
        parametersStr, returnType: returnTypeStr, isAbstract: method.isAbstract,
        isStatic: method.isStatic);
    Outline outline = new Outline(element, sourceRegion.offset,
        sourceRegion.length);
    parent.children.add(outline);
    _addLocalFunctionOutlines(outline, method.body);
  }

  Outline _newUnitOutline() {
    Element element = new Element(ElementKind.COMPILATION_UNIT, '<unit>',
        _getLocationNode(_unit), false, false);
    return new Outline(element, _unit.offset, _unit.length);
  }

  void _newVariableOutline(Outline parent, String typeName, ElementKind kind,
      VariableDeclaration variable, bool isStatic) {
    SimpleIdentifier nameNode = variable.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(variable);
    Element element = new Element(kind, name, _getLocationNode(nameNode),
        Identifier.isPrivateName(name), _isDeprecated(variable), returnType: typeName,
        isStatic: isStatic, isConst: variable.isConst, isFinal: variable.isFinal);
    Outline outline = new Outline(element, sourceRegion.offset,
        sourceRegion.length);
    parent.children.add(outline);
  }

  /**
   * Returns `true` if the given [element] is not `null` and deprecated.
   */
  static bool _isDeprecated(Declaration declaration) {
    engine.Element element = declaration.element;
    return element != null && element.isDeprecated;
  }
}


/**
 * An element outline.
 */
class Outline implements HasToJson {
  static const List<Outline> EMPTY_ARRAY = const <Outline>[];

  /**
   * The children of the node.
   * The field will be omitted in JSON if the node has no children.
   */
  final List<Outline> children = <Outline>[];

  /**
   * A description of the element represented by this node.
   */
  final Element element;

  /**
   * The length of the element.
   */
  final int length;

  /**
   * The offset of the first character of the element.
   */
  final int offset;

  Outline(this.element, this.offset, this.length);

  factory Outline.fromJson(Map<String, Object> map) {
    Element element = new Element.fromJson(map[ELEMENT]);
    Outline outline = new Outline(element, map[OFFSET], map[LENGTH]);
    // add children
    List<Map<String, Object>> childrenMaps = map[CHILDREN];
    if (childrenMaps != null) {
      childrenMaps.forEach((childMap) {
        outline.children.add(new Outline.fromJson(childMap));
      });
    }
    // done
    return outline;
  }

  Map<String, Object> toJson() {
    Map<String, Object> json = {
      ELEMENT: element.toJson(),
      OFFSET: offset,
      LENGTH: length
    };
    if (children.isNotEmpty) {
      json[CHILDREN] = children.map((child) => child.toJson()).toList();
    }
    return json;
  }
}


/**
 * A visitor for building local function outlines.
 */
class _LocalFunctionOutlinesVisitor extends RecursiveAstVisitor {
  final DartUnitOutlineComputer outlineComputer;
  final Outline parent;

  _LocalFunctionOutlinesVisitor(this.outlineComputer, this.parent);

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    outlineComputer._newFunctionOutline(parent, node, false);
  }
}


/**
 * A range of characters.
 */
class _SourceRegion {
  final int length;
  final int offset;
  _SourceRegion(this.offset, this.length);
}
