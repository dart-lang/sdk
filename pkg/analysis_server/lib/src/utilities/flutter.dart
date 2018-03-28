// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

const WIDGETS_LIBRARY_URI = 'package:flutter/widgets.dart';

const _BASIC_URI = "package:flutter/src/widgets/basic.dart";
const _CENTER_NAME = "Center";
const _PADDING_NAME = "Padding";
const _STATE_NAME = "State";
const _STATEFUL_WIDGET_NAME = "StatefulWidget";
const _STATELESS_WIDGET_NAME = "StatelessWidget";
const _WIDGET_NAME = "Widget";
const _WIDGET_URI = "package:flutter/src/widgets/framework.dart";
final _frameworkUri = Uri.parse('package:flutter/src/widgets/framework.dart');

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
    Expression childArg,
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
 * Return the named expression representing the `child` argument of the given
 * [newExpr], or `null` if none.
 */
NamedExpression findChildArgument(InstanceCreationExpression newExpr) =>
    newExpr.argumentList.arguments.firstWhere(
        (arg) => arg is NamedExpression && arg.name.label.name == 'child',
        orElse: () => null);

/**
 * Return the named expression representing the `children` argument of the
 * given [newExpr], or `null` if none.
 */
NamedExpression findChildrenArgument(InstanceCreationExpression newExpr) =>
    newExpr.argumentList.arguments.firstWhere(
        (arg) => arg is NamedExpression && arg.name.label.name == 'children',
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

/**
 * Return the expression that is a Flutter Widget that is the value of the
 * given [child], or null if none.
 */
Expression getChildWidget(NamedExpression child) {
  Expression expression = child?.expression;
  if (isWidgetExpression(expression)) {
    return expression;
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
  List<Expression> arguments = node.argumentList.arguments;
  if (_isExactWidget(
      element, 'Icon', 'package:flutter/src/widgets/icon.dart')) {
    if (arguments.isNotEmpty) {
      String text = arguments[0].toString();
      String arg = shorten(text, 32);
      return 'Icon($arg)';
    } else {
      return 'Icon';
    }
  }
  if (_isExactWidget(
      element, 'Text', 'package:flutter/src/widgets/text.dart')) {
    if (arguments.isNotEmpty) {
      String text = arguments[0].toString();
      String arg = shorten(text, 32);
      return 'Text($arg)';
    } else {
      return 'Text';
    }
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
 * Attempt to find and return the closest expression that encloses the [node]
 * and is a Flutter `Widget`.  Return `null` if nothing found.
 */
Expression identifyWidgetExpression(AstNode node) {
  for (; node != null; node = node.parent) {
    if (isWidgetExpression(node)) {
      return node;
    }
    if (node is ArgumentList || node is Statement || node is FunctionBody) {
      return null;
    }
  }
  return null;
}

/**
 * Return `true` if the given [type] is the Flutter class `StatefulWidget`.
 */
bool isExactlyStatefulWidgetType(DartType type) {
  return type is InterfaceType &&
      _isExactWidget(type.element, _STATEFUL_WIDGET_NAME, _WIDGET_URI);
}

/**
 * Return `true` if the given [type] is the Flutter class `StatelessWidget`.
 */
bool isExactlyStatelessWidgetType(DartType type) {
  return type is InterfaceType &&
      _isExactWidget(type.element, _STATELESS_WIDGET_NAME, _WIDGET_URI);
}

/// Return `true` if the given [element] is the Flutter class `State`.
bool isExactState(ClassElement element) {
  return _isExactWidget(element, _STATE_NAME, _WIDGET_URI);
}

/**
 * Return `true` if the given [type] is the Flutter class `Center`.
 */
bool isExactWidgetTypeCenter(DartType type) {
  return type is InterfaceType &&
      _isExactWidget(type.element, _CENTER_NAME, _BASIC_URI);
}

/**
 * Return `true` if the given [type] is the Flutter class `Padding`.
 */
bool isExactWidgetTypePadding(DartType type) {
  return type is InterfaceType &&
      _isExactWidget(type.element, _PADDING_NAME, _BASIC_URI);
}

/**
 * Return `true` if the given [type] is the Flutter class `Widget`, or its
 * subtype.
 */
bool isListOfWidgetsType(DartType type) {
  return type is InterfaceType &&
      type.element.library.isDartCore &&
      type.element.name == 'List' &&
      type.typeArguments.length == 1 &&
      isWidgetType(type.typeArguments[0]);
}

/// Return `true` if the given [element] has the Flutter class `State` as
/// a superclass.
bool isState(ClassElement element) {
  return _hasSupertype(element, _frameworkUri, _STATE_NAME);
}

/**
 * Return `true` if the given [element] is the Flutter class `Widget`, or its
 * subtype.
 */
bool isWidget(ClassElement element) {
  if (element == null) {
    return false;
  }
  if (_isExactWidget(element, _WIDGET_NAME, _WIDGET_URI)) {
    return true;
  }
  for (InterfaceType type in element.allSupertypes) {
    if (_isExactWidget(type.element, _WIDGET_NAME, _WIDGET_URI)) {
      return true;
    }
  }
  return false;
}

/**
 * Return `true` if the given [expr] is a constructor invocation for a
 * class that has the Flutter class `Widget` as a superclass.
 */
bool isWidgetCreation(InstanceCreationExpression expr) {
  ClassElement element = expr?.staticElement?.enclosingElement;
  return isWidget(element);
}

/**
 * Return `true` if the given [node] is the Flutter class `Widget`, or its
 * subtype.
 */
bool isWidgetExpression(AstNode node) {
  if (node?.parent is TypeName || node?.parent?.parent is TypeName) {
    return false;
  }
  if (node is NamedExpression) {
    return false;
  }
  if (node is Expression) {
    return isWidgetType(node.staticType);
  }
  return false;
}

/**
 * Return `true` if the given [type] is the Flutter class `Widget`, or its
 * subtype.
 */
bool isWidgetType(DartType type) {
  return type is InterfaceType && isWidget(type.element);
}

/// Return `true` if the given [element] has a supertype with the [requiredName]
/// defined in the file with the [requiredUri].
bool _hasSupertype(ClassElement element, Uri requiredUri, String requiredName) {
  if (element == null) {
    return false;
  }
  for (InterfaceType type in element.allSupertypes) {
    if (type.name == requiredName) {
      Uri uri = type.element.source.uri;
      if (uri == requiredUri) {
        return true;
      }
    }
  }
  return false;
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
