// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.correction.flutter_util;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

const _FLUTTER_WIDGET_NAME = "Widget";
const _FLUTTER_WIDGET_URI = "package:flutter/src/widgets/framework.dart";

void convertFlutterChildToChildren(
    InstanceCreationExpression childArg,
    NamedExpression namedExp,
    String eol,
    Function getNodeText,
    Function getLinePrefix,
    Function getIndent,
    Function getText,
    Function _addInsertEdit,
    Function _addRemoveEdit,
    Function _addReplaceEdit,
    Function rangeStartLength,
    Function rangeNode) {
  int childLoc = namedExp.offset + 'child'.length;
  _addInsertEdit(childLoc, 'ren');
  int listLoc = childArg.offset;
  String childArgSrc = getNodeText(childArg);
  if (!childArgSrc.contains(eol)) {
    _addInsertEdit(listLoc, '<Widget>[');
    _addInsertEdit(listLoc + childArg.length, ']');
  } else {
    int newlineLoc = childArgSrc.lastIndexOf(eol);
    if (newlineLoc == childArgSrc.length) {
      newlineLoc -= 1;
    }
    String indentOld = getLinePrefix(childArg.offset + 1 + newlineLoc);
    String indentNew = '$indentOld${getIndent(1)}';
    // The separator includes 'child:' but that has no newlines.
    String separator =
        getText(namedExp.offset, childArg.offset - namedExp.offset);
    String prefix = separator.contains(eol) ? "" : "$eol$indentNew";
    if (prefix.isEmpty) {
      _addInsertEdit(namedExp.offset + 'child:'.length, ' <Widget>[');
      _addRemoveEdit(rangeStartLength(childArg.offset - 2, 2));
    } else {
      _addInsertEdit(listLoc, '<Widget>[');
    }
    String newChildArgSrc = childArgSrc.replaceAll(
        new RegExp("^$indentOld", multiLine: true), "$indentNew");
    newChildArgSrc = "$prefix$newChildArgSrc,$eol$indentOld]";
    _addReplaceEdit(rangeNode(childArg), newChildArgSrc);
  }
}

/**
 * Return the named expression representing the 'child' argument of the given
 * [newExpr], or null if none.
 */
NamedExpression findChildArgument(InstanceCreationExpression newExpr) =>
    newExpr.argumentList.arguments.firstWhere(
        (arg) => arg is NamedExpression && arg.name.label.name == 'child',
        orElse: () => null);

/**
 * Return the Flutter instance creation expression that is the value of the
 * 'child' argument of the given [newExpr], or null if none.
 */
InstanceCreationExpression findChildWidget(InstanceCreationExpression newExpr) {
  NamedExpression child = findChildArgument(newExpr);
  return getChildWidget(child);
}

/**
 * If the given [node] is a simple identifier, find the named expression whose
 * name is the given [name] that is an argument to a Flutter instance creation
 * expression. Return null if any condition cannot be satisfied.
 */
NamedExpression findFlutterNamedExpression(AstNode node, String name) {
  if (node is! SimpleIdentifier) {
    return null;
  }
  SimpleIdentifier namedArg = node;
  NamedExpression namedExp;
  if (namedArg.parent is Label && namedArg.parent.parent is NamedExpression) {
    namedExp = namedArg.parent.parent;
    if (namedArg.name != name || namedExp.expression == null) {
      return null;
    }
  } else {
    return null;
  }
  if (namedExp.parent?.parent is! InstanceCreationExpression) {
    return null;
  }
  InstanceCreationExpression newExpr = namedExp.parent.parent;
  if (newExpr == null || !isFlutterInstanceCreationExpression(newExpr)) {
    return null;
  }
  return namedExp;
}

ListLiteral getChildList(NamedExpression child) {
  if (child.expression is ListLiteral) {
    ListLiteral list = child.expression;
    if (list.elements.isEmpty ||
        list.elements.every((element) =>
            element is InstanceCreationExpression &&
            isFlutterInstanceCreationExpression(element))) {
      return list;
    }
  }
  return null;
}

/**
 * Return the Flutter instance creation expression that is the value of the
 * given [child], or null if none. If [strict] is true, require the value to
 * also have a 'child' argument.
 */
InstanceCreationExpression getChildWidget(NamedExpression child,
    [bool strict = false]) {
  if (child?.expression is InstanceCreationExpression) {
    InstanceCreationExpression childNewExpr = child.expression;
    if (isFlutterInstanceCreationExpression(childNewExpr)) {
      if (!strict || (findChildArgument(childNewExpr) != null)) {
        return childNewExpr;
      }
    }
  }
  return null;
}

/**
 * Return the instance creation expression that surrounds the given
 * [node], if any, else null. The [node] may be the instance creation
 * expression itself or the identifier that names the constructor.
 */
InstanceCreationExpression identifyNewExpression(AstNode node) {
  InstanceCreationExpression newExpr;
  if (node is SimpleIdentifier) {
    if (node.parent is ConstructorName &&
        node.parent.parent is InstanceCreationExpression) {
      newExpr = node.parent.parent;
    } else if (node.parent?.parent is ConstructorName &&
        node.parent.parent?.parent is InstanceCreationExpression) {
      newExpr = node.parent.parent.parent;
    }
  } else if (node is InstanceCreationExpression) {
    newExpr = node;
  }
  return newExpr;
}

/**
 * Return `true` if the given [newExpr] is a constructor invocation for a
 * class that has the Flutter class Widget as a superclass.
 */
bool isFlutterInstanceCreationExpression(InstanceCreationExpression newExpr) {
  ClassElement classElement = newExpr.staticElement?.enclosingElement;
  return isFlutterWidget(classElement);
}

/**
 * Return `true` if the given [classElement] has the Flutter class Widget as a
 * superclass.
 */
bool isFlutterWidget(ClassElement classElement) {
  InterfaceType superType = classElement?.allSupertypes?.firstWhere(
      (InterfaceType type) => _FLUTTER_WIDGET_NAME == type.name,
      orElse: () => null);
  if (superType == null) {
    return false;
  }
  Uri uri = superType.element?.source?.uri;
  if (uri.toString() != _FLUTTER_WIDGET_URI) {
    return false;
  }
  return true;
}
