// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// A computer for [CompilationUnit] outline.
class DartUnitOutlineComputer {
  final ResolvedUnitResult resolvedUnit;
  final bool withBasicFlutter;

  DartUnitOutlineComputer(this.resolvedUnit, {this.withBasicFlutter = false});

  /// Returns the computed outline, not `null`.
  Outline compute() {
    var unitContents = <Outline>[];
    for (var unitMember in resolvedUnit.unit.declarations) {
      if (unitMember is ClassDeclaration) {
        unitContents.add(_newClassOutline(
            unitMember, _outlinesForMembers(unitMember.members)));
      } else if (unitMember is MixinDeclaration) {
        unitContents.add(_newMixinOutline(
            unitMember, _outlinesForMembers(unitMember.members)));
      } else if (unitMember is EnumDeclaration) {
        var enumDeclaration = unitMember;
        var constantOutlines = <Outline>[];
        for (var constant in enumDeclaration.constants) {
          constantOutlines.add(_newEnumConstant(constant));
        }
        unitContents.add(_newEnumOutline(enumDeclaration, constantOutlines));
      } else if (unitMember is ExtensionDeclaration) {
        unitContents.add(_newExtensionOutline(
            unitMember, _outlinesForMembers(unitMember.members)));
      } else if (unitMember is TopLevelVariableDeclaration) {
        var fieldDeclaration = unitMember;
        var fields = fieldDeclaration.variables;
        if (fields != null) {
          var fieldType = fields.type;
          var fieldTypeName = _safeToSource(fieldType);
          for (var field in fields.variables) {
            unitContents.add(_newVariableOutline(
                fieldTypeName, ElementKind.TOP_LEVEL_VARIABLE, field, false));
          }
        }
      } else if (unitMember is FunctionDeclaration) {
        var functionDeclaration = unitMember;
        unitContents.add(_newFunctionOutline(functionDeclaration, true));
      } else if (unitMember is ClassTypeAlias) {
        var alias = unitMember;
        unitContents.add(_newClassTypeAlias(alias));
      } else if (unitMember is FunctionTypeAlias) {
        var alias = unitMember;
        unitContents.add(_newFunctionTypeAliasOutline(alias));
      } else if (unitMember is GenericTypeAlias) {
        var alias = unitMember;
        unitContents.add(_newGenericTypeAliasOutline(alias));
      }
    }
    var unitOutline = _newUnitOutline(unitContents);
    return unitOutline;
  }

  List<Outline> _addFunctionBodyOutlines(FunctionBody body) {
    var contents = <Outline>[];
    body.accept(_FunctionBodyOutlinesVisitor(this, contents));
    return contents;
  }

  Location _getLocationNode(AstNode node) {
    var offset = node.offset;
    var length = node.length;
    return _getLocationOffsetLength(offset, length);
  }

  Location _getLocationOffsetLength(int offset, int length) {
    CharacterLocation lineLocation = resolvedUnit.lineInfo.getLocation(offset);
    var startLine = lineLocation.lineNumber;
    var startColumn = lineLocation.columnNumber;
    return Location(resolvedUnit.path, offset, length, startLine, startColumn);
  }

  Outline _newClassOutline(ClassDeclaration node, List<Outline> classContents) {
    var nameNode = node.name;
    var name = nameNode.name;
    var element = Element(
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
    var nameNode = node.name;
    var name = nameNode.name;
    var element = Element(
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
    var returnType = constructor.returnType;
    var name = returnType.name;
    var offset = returnType.offset;
    var length = returnType.length;
    var constructorNameNode = constructor.name;
    var isPrivate = false;
    if (constructorNameNode != null) {
      var constructorName = constructorNameNode.name;
      isPrivate = Identifier.isPrivateName(constructorName);
      name += '.$constructorName';
      offset = constructorNameNode.offset;
      length = constructorNameNode.length;
    }
    var parameters = constructor.parameters;
    var parametersStr = _safeToSource(parameters);
    var element = Element(
        ElementKind.CONSTRUCTOR,
        name,
        Element.makeFlags(
            isPrivate: isPrivate, isDeprecated: _isDeprecated(constructor)),
        location: _getLocationOffsetLength(offset, length),
        parameters: parametersStr);
    var contents = _addFunctionBodyOutlines(constructor.body);
    return _nodeOutline(constructor, element, contents);
  }

  Outline _newEnumConstant(EnumConstantDeclaration node) {
    var nameNode = node.name;
    var name = nameNode.name;
    var element = Element(
        ElementKind.ENUM_CONSTANT,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode));
    return _nodeOutline(node, element);
  }

  Outline _newEnumOutline(EnumDeclaration node, List<Outline> children) {
    var nameNode = node.name;
    var name = nameNode.name;
    var element = Element(
        ElementKind.ENUM,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode));
    return _nodeOutline(node, element, children);
  }

  Outline _newExtensionOutline(
      ExtensionDeclaration node, List<Outline> extensionContents) {
    var nameNode = node.name;
    var name = nameNode?.name ?? '';
    var element = Element(
        ElementKind.EXTENSION,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode ?? node.extendedType),
        typeParameters: _getTypeParametersStr(node.typeParameters));
    return _nodeOutline(node, element, extensionContents);
  }

  Outline _newFunctionOutline(FunctionDeclaration function, bool isStatic) {
    var returnType = function.returnType;
    var nameNode = function.name;
    var name = nameNode.name;
    var functionExpression = function.functionExpression;
    var parameters = functionExpression.parameters;
    ElementKind kind;
    if (function.isGetter) {
      kind = ElementKind.GETTER;
    } else if (function.isSetter) {
      kind = ElementKind.SETTER;
    } else {
      kind = ElementKind.FUNCTION;
    }
    var parametersStr = _safeToSource(parameters);
    var returnTypeStr = _safeToSource(returnType);
    var element = Element(
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
    var contents = _addFunctionBodyOutlines(functionExpression.body);
    return _nodeOutline(function, element, contents);
  }

  Outline _newFunctionTypeAliasOutline(FunctionTypeAlias node) {
    var returnType = node.returnType;
    var nameNode = node.name;
    var name = nameNode.name;
    var parameters = node.parameters;
    var parametersStr = _safeToSource(parameters);
    var returnTypeStr = _safeToSource(returnType);
    var element = Element(
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

  Outline _newGenericTypeAliasOutline(GenericTypeAlias node) {
    var functionType = node.functionType;
    var returnType = functionType?.returnType;
    var nameNode = node.name;
    var name = nameNode.name;
    var parameters = functionType?.parameters;
    var parametersStr = _safeToSource(parameters);
    var returnTypeStr = _safeToSource(returnType);
    var element = Element(
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
    var returnType = method.returnType;
    var nameNode = method.name;
    var name = nameNode.name;
    var parameters = method.parameters;
    ElementKind kind;
    if (method.isGetter) {
      kind = ElementKind.GETTER;
    } else if (method.isSetter) {
      kind = ElementKind.SETTER;
    } else {
      kind = ElementKind.METHOD;
    }
    var parametersStr = parameters?.toSource();
    var returnTypeStr = _safeToSource(returnType);
    var element = Element(
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
    var contents = _addFunctionBodyOutlines(method.body);
    return _nodeOutline(method, element, contents);
  }

  Outline _newMixinOutline(MixinDeclaration node, List<Outline> mixinContents) {
    node.firstTokenAfterCommentAndMetadata;
    var nameNode = node.name;
    var name = nameNode.name;
    var element = Element(
        ElementKind.MIXIN,
        name,
        Element.makeFlags(
            isPrivate: Identifier.isPrivateName(name),
            isDeprecated: _isDeprecated(node)),
        location: _getLocationNode(nameNode),
        typeParameters: _getTypeParametersStr(node.typeParameters));
    return _nodeOutline(node, element, mixinContents);
  }

  Outline _newUnitOutline(List<Outline> unitContents) {
    var element = Element(
        ElementKind.COMPILATION_UNIT, '<unit>', Element.makeFlags(),
        location: _getLocationNode(resolvedUnit.unit));
    return _nodeOutline(resolvedUnit.unit, element, unitContents);
  }

  Outline _newVariableOutline(String typeName, ElementKind kind,
      VariableDeclaration variable, bool isStatic) {
    var nameNode = variable.name;
    var name = nameNode.name;
    var element = Element(
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
    var offset = node.offset;
    var end = node.end;
    if (node is VariableDeclaration) {
      var parent = node.parent;
      if (parent is VariableDeclarationList && parent.variables.isNotEmpty) {
        if (parent.variables[0] == node) {
          offset = parent.parent.offset;
        }
        if (parent.variables.last == node) {
          end = parent.parent.end;
        }
      }
    }

    var codeOffset = node.offset;
    if (node is AnnotatedNode) {
      codeOffset = node.firstTokenAfterCommentAndMetadata.offset;
    }

    var length = end - offset;
    var codeLength = node.end - codeOffset;
    return Outline(element, offset, length, codeOffset, codeLength,
        children: nullIfEmpty(children));
  }

  List<Outline> _outlinesForMembers(List<ClassMember> members) {
    var memberOutlines = <Outline>[];
    for (var classMember in members) {
      if (classMember is ConstructorDeclaration) {
        var constructorDeclaration = classMember;
        memberOutlines.add(_newConstructorOutline(constructorDeclaration));
      }
      if (classMember is FieldDeclaration) {
        var fieldDeclaration = classMember;
        var fields = fieldDeclaration.fields;
        if (fields != null) {
          var fieldType = fields.type;
          var fieldTypeName = _safeToSource(fieldType);
          for (var field in fields.variables) {
            memberOutlines.add(_newVariableOutline(fieldTypeName,
                ElementKind.FIELD, field, fieldDeclaration.isStatic));
          }
        }
      }
      if (classMember is MethodDeclaration) {
        var methodDeclaration = classMember;
        memberOutlines.add(_newMethodOutline(methodDeclaration));
      }
    }
    return memberOutlines;
  }

  static String _getTypeParametersStr(TypeParameterList parameters) {
    if (parameters == null) {
      return null;
    }
    return parameters.toSource();
  }

  /// Returns `true` if the given [element] is not `null` and deprecated.
  static bool _isDeprecated(Declaration declaration) {
    var element = declaration.declaredElement;
    return element != null && element.hasDeprecated;
  }

  static String _safeToSource(AstNode node) =>
      node == null ? '' : node.toSource();
}

/// A visitor for building local function outlines.
class _FunctionBodyOutlinesVisitor extends RecursiveAstVisitor<void> {
  final DartUnitOutlineComputer outlineComputer;
  final List<Outline> contents;

  _FunctionBodyOutlinesVisitor(this.outlineComputer, this.contents);

  Flutter get _flutter => Flutter.instance;

  /// Return `true` if the given [element] is the method 'group' defined in the
  /// test package.
  bool isGroup(engine.ExecutableElement element) {
    if (element != null && element.hasIsTestGroup) {
      return true;
    }
    return element is engine.FunctionElement &&
        element.name == 'group' &&
        _isInsideTestPackage(element);
  }

  /// Return `true` if the given [element] is the method 'test' defined in the
  /// test package.
  bool isTest(engine.ExecutableElement element) {
    if (element != null && element.hasIsTest) {
      return true;
    }
    return element is engine.FunctionElement &&
        element.name == 'test' &&
        _isInsideTestPackage(element);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    contents.add(outlineComputer._newFunctionOutline(node, false));
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (outlineComputer.withBasicFlutter && _flutter.isWidgetCreation(node)) {
      var children = <Outline>[];
      node.argumentList
          .accept(_FunctionBodyOutlinesVisitor(outlineComputer, children));

      var text = _flutter.getWidgetPresentationText(node);
      var element = Element(ElementKind.CONSTRUCTOR_INVOCATION, text, 0,
          location: outlineComputer._getLocationOffsetLength(node.offset, 0));

      contents.add(Outline(
          element, node.offset, node.length, node.offset, node.length,
          children: nullIfEmpty(children)));
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var nameNode = node.methodName;

    var nameElement = nameNode.staticElement;
    if (nameElement is! engine.ExecutableElement) {
      return;
    }
    engine.ExecutableElement executableElement = nameElement;

    String extractString(NodeList<Expression> arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        var argument = arguments[0];
        if (argument is StringLiteral) {
          var value = argument.stringValue;
          if (value != null) {
            return value;
          }
        }
        return argument.toSource();
      }
      return 'unnamed';
    }

    void addOutlineNode(ElementKind kind, [List<Outline> children]) {
      var executableName = nameNode.name;
      var description = extractString(node.argumentList?.arguments);
      var name = '$executableName("$description")';
      var element = Element(kind, name, 0,
          location: outlineComputer._getLocationNode(nameNode));
      contents.add(Outline(
          element, node.offset, node.length, node.offset, node.length,
          children: nullIfEmpty(children)));
    }

    if (isGroup(executableElement)) {
      var groupContents = <Outline>[];
      node.argumentList
          .accept(_FunctionBodyOutlinesVisitor(outlineComputer, groupContents));
      addOutlineNode(ElementKind.UNIT_TEST_GROUP, groupContents);
    } else if (isTest(executableElement)) {
      addOutlineNode(ElementKind.UNIT_TEST_TEST);
    } else {
      super.visitMethodInvocation(node);
    }
  }

  /// Return `true` if the given [element] is a top-level member of the test
  /// package.
  bool _isInsideTestPackage(engine.FunctionElement element) {
    var parent = element.enclosingElement;
    return parent is engine.CompilationUnitElement &&
        parent.source.fullName.endsWith('test.dart');
  }
}
