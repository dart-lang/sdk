// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.outline;

import 'package:analysis_server/src/constants.dart';
import 'package:analyzer/src/generated/ast.dart';


/**
 * A computer for [CompilationUnit] outline.
 */
class DartUnitOutlineComputer {
  final CompilationUnit _unit;

  DartUnitOutlineComputer(this._unit);

  /**
   * Returns the computed outline, not `null`.
   */
  Map<String, Object> compute() {
    _Outline unitOutline = _newUnitOutline();
    for (CompilationUnitMember unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        ClassDeclaration classDeclaration = unitMember;
        _Outline classOutline = _newClassOutline(unitOutline, classDeclaration);
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
              String fieldTypeName = fieldType != null ? fieldType.toSource() : "";
              for (VariableDeclaration field in fields.variables) {
                _newVariableOutline(classOutline, fieldTypeName, _OutlineKind.FIELD, field, fieldDeclaration.isStatic);
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
          String fieldTypeName = fieldType != null ? fieldType.toSource() : "";
          for (VariableDeclaration field in fields.variables) {
            _newVariableOutline(unitOutline, fieldTypeName, _OutlineKind.TOP_LEVEL_VARIABLE, field, false);
          }
        }
      }
      if (unitMember is FunctionDeclaration) {
        FunctionDeclaration functionDeclaration = unitMember;
        _newFunctionOutline(unitOutline, functionDeclaration);
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
    return unitOutline.toJson();
  }

  void _addLocalFunctionOutlines(_Outline parent, FunctionBody body) {
    body.accept(new _LocalFunctionOutlinesVisitor(this, parent));
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

  _Outline _newClassOutline(_Outline parent, ClassDeclaration classDeclaration) {
    SimpleIdentifier nameNode = classDeclaration.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(classDeclaration);
    _Outline outline = new _Outline(
        _OutlineKind.CLASS, name,
        nameNode.offset, nameNode.length,
        sourceRegion.offset, sourceRegion.length,
        classDeclaration.isAbstract, false,
        null, null);
    parent.children.add(outline);
    return outline;
  }

  void _newClassTypeAlias(_Outline parent, ClassTypeAlias alias) {
    SimpleIdentifier nameNode = alias.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(alias);
    _Outline outline = new _Outline(
        _OutlineKind.CLASS_TYPE_ALIAS, name,
        nameNode.offset, nameNode.length,
        sourceRegion.offset, sourceRegion.length,
        alias.isAbstract, false,
        null, null);
    parent.children.add(outline);
  }

  void _newConstructorOutline(_Outline parent, ConstructorDeclaration constructor) {
    Identifier returnType = constructor.returnType;
    String name = returnType.name;
    int offset = returnType.offset;
    int length = returnType.length;
    SimpleIdentifier constructorNameNode = constructor.name;
    if (constructorNameNode != null) {
      String constructorName = constructorNameNode.name;
      name += ".${constructorName}";
      offset = constructorNameNode.offset;
      length = constructorNameNode.length;
    }
    _SourceRegion sourceRegion = _getSourceRegion(constructor);
    FormalParameterList parameters = constructor.parameters;
    String parametersStr = parameters != null ? parameters.toSource() : "";
    _Outline outline = new _Outline(
        _OutlineKind.CONSTRUCTOR, name,
        offset, length,
        sourceRegion.offset, sourceRegion.length,
        false, false,
        parametersStr, null);
    parent.children.add(outline);
    _addLocalFunctionOutlines(outline, constructor.body);
  }

  void _newFunctionOutline(_Outline parent, FunctionDeclaration function) {
    TypeName returnType = function.returnType;
    SimpleIdentifier nameNode = function.name;
    String name = nameNode.name;
    FunctionExpression functionExpression = function.functionExpression;
    FormalParameterList parameters = functionExpression.parameters;
    _OutlineKind kind;
    if (function.isGetter) {
      kind = _OutlineKind.GETTER;
    } else if (function.isSetter) {
      kind = _OutlineKind.SETTER;
    } else {
      kind = _OutlineKind.FUNCTION;
    }
    _SourceRegion sourceRegion = _getSourceRegion(function);
    String parametersStr = parameters != null ? parameters.toSource() : "";
    String returnTypeStr = returnType != null ? returnType.toSource() : "";
    _Outline outline = new _Outline(
        kind, name,
        nameNode.offset, nameNode.length,
        sourceRegion.offset, sourceRegion.length,
        false, false,
        parametersStr, returnTypeStr);
    parent.children.add(outline);
    _addLocalFunctionOutlines(outline, functionExpression.body);
  }

  void _newFunctionTypeAliasOutline(_Outline parent, FunctionTypeAlias alias) {
    TypeName returnType = alias.returnType;
    SimpleIdentifier nameNode = alias.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(alias);
    FormalParameterList parameters = alias.parameters;
    String parametersStr = parameters != null ? parameters.toSource() : "";
    String returnTypeStr = returnType != null ? returnType.toSource() : "";
    _Outline outline = new _Outline(
        _OutlineKind.FUNCTION_TYPE_ALIAS, name,
        nameNode.offset, nameNode.length,
        sourceRegion.offset, sourceRegion.length,
        false, false,
        parametersStr, returnTypeStr);
    parent.children.add(outline);
  }

  void _newMethodOutline(_Outline parent, MethodDeclaration method) {
    TypeName returnType = method.returnType;
    SimpleIdentifier nameNode = method.name;
    String name = nameNode.name;
    FormalParameterList parameters = method.parameters;
    _OutlineKind kind;
    if (method.isGetter) {
      kind = _OutlineKind.GETTER;
    } else if (method.isSetter) {
      kind = _OutlineKind.SETTER;
    } else {
      kind = _OutlineKind.METHOD;
    }
    _SourceRegion sourceRegion = _getSourceRegion(method);
    String parametersStr = parameters != null ? parameters.toSource() : "";
    String returnTypeStr = returnType != null ? returnType.toSource() : "";
    _Outline outline = new _Outline(
        kind, name,
        nameNode.offset, nameNode.length,
        sourceRegion.offset, sourceRegion.length,
        method.isAbstract, method.isStatic,
        parametersStr, returnTypeStr);
    parent.children.add(outline);
    _addLocalFunctionOutlines(outline, method.body);
  }

  _Outline _newUnitOutline() {
    return new _Outline(
        _OutlineKind.COMPILATION_UNIT, "<unit>",
        _unit.offset, _unit.length,
        _unit.offset, _unit.length,
        false, false,
        null, null);
  }

  void _newVariableOutline(_Outline parent, String typeName, _OutlineKind kind, VariableDeclaration variable, bool isStatic) {
    SimpleIdentifier nameNode = variable.name;
    String name = nameNode.name;
    _SourceRegion sourceRegion = _getSourceRegion(variable);
    _Outline outline = new _Outline(
        kind, name,
        nameNode.offset, nameNode.length,
        sourceRegion.offset, sourceRegion.length,
        false, isStatic,
        null, typeName);
    parent.children.add(outline);
  }
}


/**
 * A visitor for building local function outlines.
 */
class _LocalFunctionOutlinesVisitor extends RecursiveAstVisitor {
  final DartUnitOutlineComputer outlineComputer;
  final _Outline parent;

  _LocalFunctionOutlinesVisitor(this.outlineComputer, this.parent);

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    outlineComputer._newFunctionOutline(parent, node);
  }
}



/**
 * A range of characters.
 */
class _SourceRegion {
  final int offset;
  final int length;
  _SourceRegion(this.offset, this.length);
}


/**
 * Element outline kinds.
 */
class _OutlineKind {
  static const _OutlineKind CLASS = const _OutlineKind('CLASS');
  static const _OutlineKind CLASS_TYPE_ALIAS = const _OutlineKind('CLASS_TYPE_ALIAS');
  static const _OutlineKind COMPILATION_UNIT = const _OutlineKind('COMPILATION_UNIT');
  static const _OutlineKind CONSTRUCTOR = const _OutlineKind('CONSTRUCTOR');
  static const _OutlineKind GETTER = const _OutlineKind('GETTER');
  static const _OutlineKind FIELD = const _OutlineKind('FIELD');
  static const _OutlineKind FUNCTION = const _OutlineKind('FUNCTION');
  static const _OutlineKind FUNCTION_TYPE_ALIAS = const _OutlineKind('FUNCTION_TYPE_ALIAS');
  static const _OutlineKind LIBRARY = const _OutlineKind('LIBRARY');
  static const _OutlineKind METHOD = const _OutlineKind('METHOD');
  static const _OutlineKind SETTER = const _OutlineKind('SETTER');
  static const _OutlineKind TOP_LEVEL_VARIABLE = const _OutlineKind('TOP_LEVEL_VARIABLE');
  static const _OutlineKind UNKNOWN = const _OutlineKind('UNKNOWN');
  static const _OutlineKind UNIT_TEST_CASE = const _OutlineKind('UNIT_TEST_CASE');
  static const _OutlineKind UNIT_TEST_GROUP = const _OutlineKind('UNIT_TEST_GROUP');

  final String name;

  const _OutlineKind(this.name);
}


/**
 * An element outline.
 */
class _Outline {
  static const List<_Outline> EMPTY_ARRAY = const <_Outline>[];

  final _OutlineKind kind;
  final String name;
  final int nameOffset;
  final int nameLength;
  final int elementOffset;
  final int elementLength;
  final bool isAbstract;
  final bool isStatic;
  final String parameters;
  final String returnType;
  final List<_Outline> children = <_Outline>[];

  _Outline(this.kind, this.name,
           this.nameOffset, this.nameLength,
           this.elementOffset, this.elementLength,
           this.isAbstract, this.isStatic,
           this.parameters, this.returnType);

  Map<String, Object> toJson() {
    Map<String, Object> json = {
      KIND: kind.name,
      NAME: name,
      NAME_OFFSET: nameOffset,
      NAME_LENGTH: nameLength,
      ELEMENT_OFFSET: elementOffset,
      ELEMENT_LENGTH: elementLength,
      IS_ABSTRACT: isAbstract,
      IS_STATIC: isStatic
    };
    if (parameters != null) {
      json[PARAMETERS] = parameters;
    }
    if (returnType != null) {
      json[RETURN_TYPE] = returnType;
    }
    if (children.isNotEmpty) {
      json[CHILDREN] = children.map((child) => child.toJson()).toList();
    }
    return json;
  }
}
