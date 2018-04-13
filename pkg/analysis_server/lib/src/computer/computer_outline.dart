// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/utilities/flutter.dart' as flutter;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/dart/element/type.dart' as engine;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * A computer for [CompilationUnit] outline.
 */
class DartUnitOutlineComputer {
  final String file;
  final CompilationUnit unit;
  final LineInfo lineInfo;
  final bool withBasicFlutter;

  DartUnitOutlineComputer(this.file, this.lineInfo, this.unit,
      {this.withBasicFlutter: false});

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
    CharacterLocation lineLocation = lineInfo.getLocation(offset);
    int startLine = lineLocation.lineNumber;
    int startColumn = lineLocation.columnNumber;
    return new Location(file, offset, length, startLine, startColumn);
  }

  Outline _newClassOutline(ClassDeclaration node, List<Outline> classContents) {
    node.firstTokenAfterCommentAndMetadata;
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    Element element = new Element(
        ElementKind.CLASS,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node),
            isAbstract: node.isAbstract),
        location: _getLocationNode(nameNode),
        typeParameters: _getTypeParametersStr(node.typeParameters));
    return _nodeOutline(node, element, classContents);
  }

  Outline _newClassTypeAlias(ClassTypeAlias node) {
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    Element element = new Element(
        ElementKind.CLASS_TYPE_ALIAS,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node),
            isAbstract: node.isAbstract),
        location: _getLocationNode(nameNode),
        typeParameters: _getTypeParametersStr(node.typeParameters));
    return _nodeOutline(node, element);
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
    return _nodeOutline(constructor, element, contents);
  }

  Outline _newEnumConstant(EnumConstantDeclaration node) {
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    Element element = new Element(
        ElementKind.ENUM_CONSTANT,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode));
    return _nodeOutline(node, element);
  }

  Outline _newEnumOutline(EnumDeclaration node, List<Outline> children) {
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
    Element element = new Element(
        ElementKind.ENUM,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode));
    return _nodeOutline(node, element, children);
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
        returnType: returnTypeStr,
        typeParameters:
            _getTypeParametersStr(functionExpression.typeParameters));
    List<Outline> contents = _addFunctionBodyOutlines(functionExpression.body);
    return _nodeOutline(function, element, contents);
  }

  Outline _newFunctionTypeAliasOutline(FunctionTypeAlias node) {
    TypeAnnotation returnType = node.returnType;
    SimpleIdentifier nameNode = node.name;
    String name = nameNode.name;
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
    return _nodeOutline(node, element);
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
        returnType: returnTypeStr,
        typeParameters: _getTypeParametersStr(method.typeParameters));
    List<Outline> contents = _addFunctionBodyOutlines(method.body);
    return _nodeOutline(method, element, contents);
  }

  Outline _newUnitOutline(List<Outline> unitContents) {
    Element element = new Element(
        ElementKind.COMPILATION_UNIT, '<unit>', Element.makeFlags(),
        location: _getLocationNode(unit));
    return _nodeOutline(unit, element, unitContents);
  }

  Outline _newVariableOutline(String typeName, ElementKind kind,
      VariableDeclaration variable, bool isStatic) {
    SimpleIdentifier nameNode = variable.name;
    String name = nameNode.name;
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
    return _nodeOutline(variable, element);
  }

  Outline _nodeOutline(AstNode node, Element element,
      [List<Outline> children]) {
    int offset = node.offset;
    int end = node.end;
    if (node is VariableDeclaration) {
      AstNode parent = node.parent;
      if (parent is VariableDeclarationList && parent.variables.isNotEmpty) {
        if (parent.variables[0] == node) {
          offset = parent.parent.offset;
        }
        if (parent.variables.last == node) {
          end = parent.parent.end;
        }
      }
    }

    int codeOffset = node.offset;
    if (node is AnnotatedNode) {
      codeOffset = node.firstTokenAfterCommentAndMetadata.offset;
    }

    int length = end - offset;
    int codeLength = node.end - codeOffset;
    return new Outline(element, offset, length, codeOffset, codeLength,
        children: nullIfEmpty(children));
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
    return element != null && element.hasDeprecated;
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
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (outlineComputer.withBasicFlutter && flutter.isWidgetCreation(node)) {
      List<Outline> children = <Outline>[];
      node.argumentList
          .accept(new _FunctionBodyOutlinesVisitor(outlineComputer, children));

      String text = flutter.getWidgetPresentationText(node);
      Element element = new Element(ElementKind.CONSTRUCTOR_INVOCATION, text, 0,
          location: outlineComputer._getLocationOffsetLength(node.offset, 0));

      contents.add(new Outline(
          element, node.offset, node.length, node.offset, node.length,
          children: nullIfEmpty(children)));
    } else {
      super.visitInstanceCreationExpression(node);
    }
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

    void addOutlineNode(ElementKind kind, [List<Outline> children]) {
      String kindName = kind == ElementKind.UNIT_TEST_GROUP ? 'group' : 'test';
      String name = '$kindName("${extractString(
          node.argumentList?.arguments)}")';
      Element element = new Element(kind, name, 0,
          location: outlineComputer._getLocationNode(nameNode));
      contents.add(new Outline(
          element, node.offset, node.length, node.offset, node.length,
          children: nullIfEmpty(children)));
    }

    if (isGroup(executableElement)) {
      List<Outline> groupContents = <Outline>[];
      node.argumentList.accept(
          new _FunctionBodyOutlinesVisitor(outlineComputer, groupContents));
      addOutlineNode(ElementKind.UNIT_TEST_GROUP, groupContents);
    } else if (isTest(executableElement)) {
      addOutlineNode(ElementKind.UNIT_TEST_TEST);
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
