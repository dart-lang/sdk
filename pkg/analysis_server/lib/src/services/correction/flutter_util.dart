// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

const _WIDGET_NAME = "Widget";
const _WIDGET_URI = "package:flutter/src/widgets/framework.dart";

void convertChildToChildren(
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
      _addRemoveEdit(new SourceRange(childArg.offset - 2, 2));
    } else {
      _addInsertEdit(listLoc, '<Widget>[');
    }
    String newChildArgSrc = childArgSrc.replaceAll(
        new RegExp("^$indentOld", multiLine: true), "$indentNew");
    newChildArgSrc = "$prefix$newChildArgSrc,$eol$indentOld]";
    _addReplaceEdit(rangeNode(childArg), newChildArgSrc);
  }
}

void convertChildToChildren2(
    DartFileEditBuilder builder,
    InstanceCreationExpression childArg,
    NamedExpression namedExp,
    String eol,
    Function getNodeText,
    Function getLinePrefix,
    Function getIndent,
    Function getText,
    Function rangeNode) {
  int childLoc = namedExp.offset + 'child'.length;
  builder.addSimpleInsertion(childLoc, 'ren');
  int listLoc = childArg.offset;
  String childArgSrc = getNodeText(childArg);
  if (!childArgSrc.contains(eol)) {
    builder.addSimpleInsertion(listLoc, '<Widget>[');
    builder.addSimpleInsertion(listLoc + childArg.length, ']');
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
      builder.addSimpleInsertion(
          namedExp.offset + 'child:'.length, ' <Widget>[');
      builder.addDeletion(new SourceRange(childArg.offset - 2, 2));
    } else {
      builder.addSimpleInsertion(listLoc, '<Widget>[');
    }
    String newChildArgSrc = childArgSrc.replaceAll(
        new RegExp("^$indentOld", multiLine: true), "$indentNew");
    newChildArgSrc = "$prefix$newChildArgSrc,$eol$indentOld]";
    builder.addSimpleReplacement(rangeNode(childArg), newChildArgSrc);
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
NamedExpression findNamedExpression(AstNode node, String name) {
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
  if (newExpr == null || !isWidgetCreation(newExpr)) {
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
            isWidgetCreation(element))) {
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
    if (isWidgetCreation(childNewExpr)) {
      if (!strict || (findChildArgument(childNewExpr) != null)) {
        return childNewExpr;
      }
    }
  }
  return null;
}

/**
 * Return the presentation for the given Flutter `Widget` creation [node].
 */
String getWidgetPresentationText(InstanceCreationExpression node) {
  ClassElement element = node.staticElement?.enclosingElement;
  if (!isWidget(element)) {
    return null;
  }
  // TODO(scheglov) check that the required argument is actually provided.
  List<Expression> arguments = node.argumentList.arguments;
  if (_isExactWidget(
      element, 'Icon', 'package:flutter/src/widgets/icon.dart')) {
    String text = arguments[0].toString();
    String arg = shorten(text, 32);
    return 'Icon($arg)';
  }
  if (_isExactWidget(
      element, 'Text', 'package:flutter/src/widgets/text.dart')) {
    String text = arguments[0].toString();
    String arg = shorten(text, 32);
    return 'Text($arg)';
  }
  return element.name;
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
 * Return `true` if the given [element] has the Flutter class `Widget` as
 * a superclass.
 */
bool isWidget(ClassElement element) {
  if (element == null) {
    return false;
  }
  for (InterfaceType type in element.allSupertypes) {
    if (type.name == _WIDGET_NAME) {
      Uri uri = type.element.source.uri;
      if (uri.toString() == _WIDGET_URI) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Return `true` if the given [expr] is a constructor invocation for a
 * class that has the Flutter class `Widget` as a superclass.
 */
bool isWidgetCreation(InstanceCreationExpression expr) {
  ClassElement element = expr.staticElement?.enclosingElement;
  return isWidget(element);
}

/**
 * Return `true` if the given [element] is the exact [type] defined in the
 * file with the given [uri].
 */
bool _isExactWidget(ClassElement element, String type, String uri) {
  return element != null &&
      element.name == type &&
      element.source.uri.toString() == uri;
}
