// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/collections.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/dart/element/type.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * A computer for [CompilationUnit] outline.
 */
class DartUnitOutlineComputer {
  final String file;
  final CompilationUnit unit;
  final LineInfo lineInfo;

  DartUnitOutlineComputer(this.file, this.lineInfo, this.unit);

  /**
   * Returns the computed outline, not `null`.
   */
  Outline compute() {
    List<Outline> unitContents = <Outline>[];
    for (CompilationUnitMember unitMember in unit.declarations) {
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
              TypeAnnotation fieldType = fields.type;
              String fieldTypeName = _safeToSource(fieldType);
              for (VariableDeclaration field in fields.variables) {
                classContents.add(_newVariableOutline(fieldTypeName,
                    ElementKind.FIELD, field, fieldDeclaration.isStatic));
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
      if (unitMember is EnumDeclaration) {
        EnumDeclaration enumDeclaration = unitMember;
        List<Outline> constantOutlines = <Outline>[];
        for (EnumConstantDeclaration constant in enumDeclaration.constants) {
          constantOutlines.add(_newEnumConstant(constant));
        }
        unitContents.add(_newEnumOutline(enumDeclaration, constantOutlines));
      }
      if (unitMember is TopLevelVariableDeclaration) {
        TopLevelVariableDeclaration fieldDeclaration = unitMember;
        VariableDeclarationList fields = fieldDeclaration.variables;
        if (fields != null) {
          TypeAnnotation fieldType = fields.type;
          String fieldTypeName = _safeToSource(fieldType);
          for (VariableDeclaration field in fields.variables) {
            unitContents.add(_newVariableOutline(
                fieldTypeName, ElementKind.TOP_LEVEL_VARIABLE, field, false));
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

  List<Outline> _addFunctionBodyOutlines(FunctionBody body) {
    List<Outline> contents = <Outline>[];
    body.accept(new _FunctionBodyOutlinesVisitor(this, contents));
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
  SourceRange _getSourceRange(AstNode node) {
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
        return new SourceRange(firstOffset, endOffset - firstOffset);
      }
    }
    // unit or class member
    if (parent is CompilationUnit) {
      firstOffset = node.offset;
      siblings = parent.declarations;
    } else if (parent is ClassDeclaration) {
      firstOffset = parent.leftBracket.end;
      siblings = parent.members;
    } else {
      int offset = node.offset;
      return new SourceRange(offset, endOffset - offset);
    }
    // first child: [endOfParent, endOfNode]
    int index = siblings.indexOf(node);
    if (index == 0) {
      return new SourceRange(firstOffset, endOffset - firstOffset);
    }
    // not first child: [endOfPreviousSibling, endOfNode]
    int prevSiblingEnd = siblings[index - 1].end;
    return new SourceRange(prevSiblingEnd, endOffset - prevSiblingEnd);
  }

  Outline _newClassOutline(ClassDeclaration node, List<Outline> classContents) {
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    SourceRange range = _getSourceRange(node);
    Element element = new Element(
        ElementKind.CLASS,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node),
            isAbstract: node.isAbstract),
        location: _getLocationNode(nameNode),
        typeParameters: _getTypeParametersStr(node.typeParameters));
    return new Outline(element, range.offset, range.length,
        children: nullIfEmpty(classContents));
  }

  Outline _newClassTypeAlias(ClassTypeAlias node) {
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    SourceRange range = _getSourceRange(node);
    Element element = new Element(
        ElementKind.CLASS_TYPE_ALIAS,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node),
            isAbstract: node.isAbstract),
        location: _getLocationNode(nameNode),
        typeParameters: _getTypeParametersStr(node.typeParameters));
    return new Outline(element, range.offset, range.length);
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
      name += '.$constructorName';
      offset = constructorNameNode.offset;
      length = constructorNameNode.length;
    }
    SourceRange range = _getSourceRange(constructor);
    FormalParameterList parameters = constructor.parameters;
    String parametersStr = _safeToSource(parameters);
    Element element = new Element(
        ElementKind.CONSTRUCTOR,
        name,
        Element.makeFlags(
            isPrivate: isPrivate, isDeprecated: _isDeprecated(constructor)),
        location: _getLocationOffsetLength(offset, length),
        parameters: parametersStr);
    List<Outline> contents = _addFunctionBodyOutlines(constructor.body);
    Outline outline = new Outline(element, range.offset, range.length,
        children: nullIfEmpty(contents));
    return outline;
  }

  Outline _newEnumConstant(EnumConstantDeclaration node) {
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    SourceRange range = _getSourceRange(node);
    Element element = new Element(
        ElementKind.ENUM_CONSTANT,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode));
    return new Outline(element, range.offset, range.length);
  }

  Outline _newEnumOutline(EnumDeclaration node, List<Outline> children) {
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    SourceRange range = _getSourceRange(node);
    Element element = new Element(
        ElementKind.ENUM,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode));
    return new Outline(element, range.offset, range.length,
        children: nullIfEmpty(children));
  }

  Outline _newFunctionOutline(FunctionDeclaration function, bool isStatic) {
    TypeAnnotation returnType = function.returnType;
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
    SourceRange range = _getSourceRange(function);
    String parametersStr = _safeToSource(parameters);
    String returnTypeStr = _safeToSource(returnType);
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
    List<Outline> contents = _addFunctionBodyOutlines(functionExpression.body);
    Outline outline = new Outline(element, range.offset, range.length,
        children: nullIfEmpty(contents));
    return outline;
  }

  Outline _newFunctionTypeAliasOutline(FunctionTypeAlias node) {
    TypeAnnotation returnType = node.returnType;
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    SourceRange range = _getSourceRange(node);
    FormalParameterList parameters = node.parameters;
    String parametersStr = _safeToSource(parameters);
    String returnTypeStr = _safeToSource(returnType);
    Element element = new Element(
        ElementKind.FUNCTION_TYPE_ALIAS,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode),
        parameters: parametersStr,
        returnType: returnTypeStr,
        typeParameters: _getTypeParametersStr(node.typeParameters));
    return new Outline(element, range.offset, range.length);
  }

  Outline _newMethodOutline(MethodDeclaration method) {
    TypeAnnotation returnType = method.returnType;
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
    SourceRange range = _getSourceRange(method);
    String parametersStr = parameters?.toSource();
    String returnTypeStr = _safeToSource(returnType);
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
    List<Outline> contents = _addFunctionBodyOutlines(method.body);
    Outline outline = new Outline(element, range.offset, range.length,
        children: nullIfEmpty(contents));
    return outline;
  }

  Outline _newUnitOutline(List<Outline> unitContents) {
    Element element = new Element(
        ElementKind.COMPILATION_UNIT, '<unit>', Element.makeFlags(),
        location: _getLocationNode(unit));
    return new Outline(element, unit.offset, unit.length,
        children: nullIfEmpty(unitContents));
  }

  Outline _newVariableOutline(String typeName, ElementKind kind,
      VariableDeclaration variable, bool isStatic) {
    SimpleIdentifier nameNode = variable.name;
    String name = nameNode.name;
    SourceRange range = _getSourceRange(variable);
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
    Outline outline = new Outline(element, range.offset, range.length);
    return outline;
  }

  static String _getTypeParametersStr(TypeParameterList parameters) {
    if (parameters == null) {
      return null;
    }
    return parameters.toSource();
  }

  /**
   * Returns `true` if the given [element] is not `null` and deprecated.
   */
  static bool _isDeprecated(Declaration declaration) {
    engine.Element element = declaration.element;
    return element != null && element.isDeprecated;
  }

  static String _safeToSource(AstNode node) =>
      node == null ? '' : node.toSource();
}

/**
 * A visitor for building local function outlines.
 */
class _FunctionBodyOutlinesVisitor extends RecursiveAstVisitor {
  final DartUnitOutlineComputer outlineComputer;
  final List<Outline> contents;

  _FunctionBodyOutlinesVisitor(this.outlineComputer, this.contents);

  /**
   * Return `true` if the given [element] is the method 'group' defined in the
   * test package.
   */
  bool isGroup(engine.ExecutableElement element) {
    return element is engine.FunctionElement &&
        element.name == 'group' &&
        _isInsideTestPackage(element);
  }

  /**
   * Return `true` if the given [element] is the method 'test' defined in the
   * test package.
   */
  bool isTest(engine.ExecutableElement element) {
    return element is engine.FunctionElement &&
        element.name == 'test' &&
        _isInsideTestPackage(element);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    contents.add(outlineComputer._newFunctionOutline(node, false));
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier nameNode = node.methodName;
    engine.ExecutableElement executableElement = nameNode.bestElement;

    String extractString(NodeList<Expression> arguments) {
      if (arguments != null && arguments.length > 0) {
        Expression argument = arguments[0];
        if (argument is StringLiteral) {
          String value = argument.stringValue;
          if (value != null) {
            return value;
          }
        }
        return argument.toSource();
      }
      return 'unnamed';
    }

    void addOutline(String kind, [List<Outline> children]) {
      SourceRange range = outlineComputer._getSourceRange(node);
      String name = kind + ' ' + extractString(node.argumentList?.arguments);
      Element element = new Element(ElementKind.UNKNOWN, name, 0,
          location: outlineComputer._getLocationNode(nameNode));
      contents.add(new Outline(element, range.offset, range.length,
          children: nullIfEmpty(children)));
    }

    if (isGroup(executableElement)) {
      List<Outline> groupContents = <Outline>[];
      node.argumentList.accept(
          new _FunctionBodyOutlinesVisitor(outlineComputer, groupContents));
      addOutline('group', groupContents);
    } else if (isTest(executableElement)) {
      addOutline('test');
    } else {
      super.visitMethodInvocation(node);
    }
  }

  /**
   * Return `true` if the given [element] is a top-level member of the test
   * package.
   */
  bool _isInsideTestPackage(engine.FunctionElement element) {
    engine.Element parent = element.enclosingElement;
    return parent is engine.CompilationUnitElement &&
        parent.source.fullName.endsWith('test.dart');
  }
}
