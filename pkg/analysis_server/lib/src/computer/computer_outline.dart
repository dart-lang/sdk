// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.outline;

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/protocol.dart';
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
    List<Outline> unitContents = <Outline>[];
    for (CompilationUnitMember unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        ClassDeclaration classDeclaration = unitMember;
        List<Outline> classContents = <Outline>[];
        for (ClassMember classMember in classDeclaration.members) {
          if (classMember is ConstructorDeclaration) {
            ConstructorDeclaration constructorDeclaration = classMember;
            classContents.add(_newConstructorOutline(constructorDeclaration));
          }
          if (classMember is FieldDeclaration) {
            FieldDeclaration fieldDeclaration = classMember;
            VariableDeclarationList fields = fieldDeclaration.fields;
            if (fields != null) {
              TypeName fieldType = fields.type;
              String fieldTypeName =
                  fieldType != null ? fieldType.toSource() : '';
              for (VariableDeclaration field in fields.variables) {
                classContents.add(
                    _newVariableOutline(
                        fieldTypeName,
                        ElementKind.FIELD,
                        field,
                        fieldDeclaration.isStatic));
              }
            }
          }
          if (classMember is MethodDeclaration) {
            MethodDeclaration methodDeclaration = classMember;
            classContents.add(_newMethodOutline(methodDeclaration));
          }
        }
        unitContents.add(_newClassOutline(classDeclaration, classContents));
      }
      if (unitMember is TopLevelVariableDeclaration) {
        TopLevelVariableDeclaration fieldDeclaration = unitMember;
        VariableDeclarationList fields = fieldDeclaration.variables;
        if (fields != null) {
          TypeName fieldType = fields.type;
          String fieldTypeName = fieldType != null ? fieldType.toSource() : '';
          for (VariableDeclaration field in fields.variables) {
            unitContents.add(
                _newVariableOutline(
                    fieldTypeName,
                    ElementKind.TOP_LEVEL_VARIABLE,
                    field,
                    false));
          }
        }
      }
      if (unitMember is FunctionDeclaration) {
        FunctionDeclaration functionDeclaration = unitMember;
        unitContents.add(_newFunctionOutline(functionDeclaration, true));
      }
      if (unitMember is ClassTypeAlias) {
        ClassTypeAlias alias = unitMember;
        unitContents.add(_newClassTypeAlias(alias));
      }
      if (unitMember is FunctionTypeAlias) {
        FunctionTypeAlias alias = unitMember;
        unitContents.add(_newFunctionTypeAliasOutline(alias));
      }
    }
    Outline unitOutline = _newUnitOutline(unitContents);
    return unitOutline;
  }

  List<Outline> _addLocalFunctionOutlines(FunctionBody body) {
    List<Outline> contents = <Outline>[];
    body.accept(new _LocalFunctionOutlinesVisitor(this, contents));
    return contents;
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

  Outline _newClassOutline(ClassDeclaration classDeclaration,
      List<Outline> classContents) {
    SimpleIdentifier nameNode = classDeclaration.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(classDeclaration);
    Element element = new Element(
        ElementKind.CLASS,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(classDeclaration),
            isAbstract: classDeclaration.isAbstract),
        location: _getLocationNode(nameNode));
    return new Outline(
        element,
        sourceRegion.offset,
        sourceRegion.length,
        children: nullIfEmpty(classContents));
  }

  Outline _newClassTypeAlias(ClassTypeAlias alias) {
    SimpleIdentifier nameNode = alias.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(alias);
    Element element = new Element(
        ElementKind.CLASS_TYPE_ALIAS,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(alias),
            isAbstract: alias.isAbstract),
        location: _getLocationNode(nameNode));
    return new Outline(element, sourceRegion.offset, sourceRegion.length);
  }

  Outline _newConstructorOutline(ConstructorDeclaration constructor) {
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
    Element element = new Element(
        ElementKind.CONSTRUCTOR,
        name,
        Element.makeFlags(
            isPrivate: isPrivate,
            isDeprecated: _isDeprecated(constructor)),
        location: _getLocationOffsetLength(offset, length),
        parameters: parametersStr);
    List<Outline> contents = _addLocalFunctionOutlines(constructor.body);
    Outline outline = new Outline(
        element,
        sourceRegion.offset,
        sourceRegion.length,
        children: nullIfEmpty(contents));
    return outline;
  }

  Outline _newFunctionOutline(FunctionDeclaration function, bool isStatic) {
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
    Element element = new Element(
        kind,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(function),
            isStatic: isStatic),
        location: _getLocationNode(nameNode),
        parameters: parametersStr,
        returnType: returnTypeStr);
    List<Outline> contents = _addLocalFunctionOutlines(functionExpression.body);
    Outline outline = new Outline(
        element,
        sourceRegion.offset,
        sourceRegion.length,
        children: nullIfEmpty(contents));
    return outline;
  }

  Outline _newFunctionTypeAliasOutline(FunctionTypeAlias alias) {
    TypeName returnType = alias.returnType;
    SimpleIdentifier nameNode = alias.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(alias);
    FormalParameterList parameters = alias.parameters;
    String parametersStr = parameters != null ? parameters.toSource() : '';
    String returnTypeStr = returnType != null ? returnType.toSource() : '';
    Element element = new Element(
        ElementKind.FUNCTION_TYPE_ALIAS,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(alias)),
        location: _getLocationNode(nameNode),
        parameters: parametersStr,
        returnType: returnTypeStr);
    return new Outline(element, sourceRegion.offset, sourceRegion.length);
  }

  Outline _newMethodOutline(MethodDeclaration method) {
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
    Element element = new Element(
        kind,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(method),
            isAbstract: method.isAbstract,
            isStatic: method.isStatic),
        location: _getLocationNode(nameNode),
        parameters: parametersStr,
        returnType: returnTypeStr);
    List<Outline> contents = _addLocalFunctionOutlines(method.body);
    Outline outline = new Outline(
        element,
        sourceRegion.offset,
        sourceRegion.length,
        children: nullIfEmpty(contents));
    return outline;
  }

  Outline _newUnitOutline(List<Outline> unitContents) {
    Element element = new Element(
        ElementKind.COMPILATION_UNIT,
        '<unit>',
        Element.makeFlags(),
        location: _getLocationNode(_unit));
    return new Outline(
        element,
        _unit.offset,
        _unit.length,
        children: nullIfEmpty(unitContents));
  }

  Outline _newVariableOutline(String typeName, ElementKind kind,
      VariableDeclaration variable, bool isStatic) {
    SimpleIdentifier nameNode = variable.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(variable);
    Element element = new Element(
        kind,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(variable),
            isStatic: isStatic,
            isConst: variable.isConst,
            isFinal: variable.isFinal),
        location: _getLocationNode(nameNode),
        returnType: typeName);
    Outline outline =
        new Outline(element, sourceRegion.offset, sourceRegion.length);
    return outline;
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
 * A visitor for building local function outlines.
 */
class _LocalFunctionOutlinesVisitor extends RecursiveAstVisitor {
  final DartUnitOutlineComputer outlineComputer;
  final List<Outline> contents;

  _LocalFunctionOutlinesVisitor(this.outlineComputer, this.contents);

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    contents.add(outlineComputer._newFunctionOutline(node, false));
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
