// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

class Flutter {
  static final Flutter instance = Flutter();

  static const _nameAlign = 'Align';
  static const _nameCenter = 'Center';
  static const _nameContainer = 'Container';
  static const _namePadding = 'Padding';
  static const _nameSizedBox = 'SizedBox';
  static const _nameState = 'State';
  static const _nameStatefulWidget = 'StatefulWidget';
  static const _nameStatelessWidget = 'StatelessWidget';
  static const _nameStreamBuilder = 'StreamBuilder';
  static const _nameWidget = 'Widget';

  final String widgetsUri = 'package:flutter/widgets.dart';

  final Uri _uriAlignment = Uri.parse(
    'package:flutter/src/painting/alignment.dart',
  );
  final Uri _uriAsync = Uri.parse(
    'package:flutter/src/widgets/async.dart',
  );
  final Uri _uriBasic = Uri.parse(
    'package:flutter/src/widgets/basic.dart',
  );
  final Uri _uriContainer = Uri.parse(
    'package:flutter/src/widgets/container.dart',
  );
  final Uri _uriDiagnostics = Uri.parse(
    'package:flutter/src/foundation/diagnostics.dart',
  );
  final Uri _uriEdgeInsets = Uri.parse(
    'package:flutter/src/painting/edge_insets.dart',
  );
  final Uri _uriFramework = Uri.parse(
    'package:flutter/src/widgets/framework.dart',
  );
  final Uri _uriWidgetsIcon = Uri.parse(
    'package:flutter/src/widgets/icon.dart',
  );
  final Uri _uriWidgetsText = Uri.parse(
    'package:flutter/src/widgets/text.dart',
  );

  /// Return the argument with the given [index], or `null` if none.
  Expression argumentByIndex(List<Expression> arguments, int index) {
    if (index < arguments.length) {
      return arguments[index];
    }
    return null;
  }

  /// Return the named expression with the given [name], or `null` if none.
  NamedExpression argumentByName(List<Expression> arguments, String name) {
    for (var argument in arguments) {
      if (argument is NamedExpression && argument.name.label.name == name) {
        return argument;
      }
    }
    return null;
  }

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
    var childLoc = namedExp.offset + 'child'.length;
    _addInsertEdit(childLoc, 'ren');
    var listLoc = childArg.offset;
    String childArgSrc = getNodeText(childArg);
    if (!childArgSrc.contains(eol)) {
      _addInsertEdit(listLoc, '[');
      _addInsertEdit(listLoc + childArg.length, ']');
    } else {
      var newlineLoc = childArgSrc.lastIndexOf(eol);
      if (newlineLoc == childArgSrc.length) {
        newlineLoc -= 1;
      }
      String indentOld =
          getLinePrefix(childArg.offset + eol.length + newlineLoc);
      var indentNew = '$indentOld${getIndent(1)}';
      // The separator includes 'child:' but that has no newlines.
      String separator =
          getText(namedExp.offset, childArg.offset - namedExp.offset);
      var prefix = separator.contains(eol) ? '' : '$eol$indentNew';
      if (prefix.isEmpty) {
        _addInsertEdit(namedExp.offset + 'child:'.length, ' [');
        _addRemoveEdit(SourceRange(childArg.offset - 2, 2));
      } else {
        _addInsertEdit(listLoc, '[');
      }
      var newChildArgSrc = childArgSrc.replaceAll(
          RegExp('^$indentOld', multiLine: true), '$indentNew');
      newChildArgSrc = '$prefix$newChildArgSrc,$eol$indentOld]';
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
    var childLoc = namedExp.offset + 'child'.length;
    builder.addSimpleInsertion(childLoc, 'ren');
    var listLoc = childArg.offset;
    String childArgSrc = getNodeText(childArg);
    if (!childArgSrc.contains(eol)) {
      builder.addSimpleInsertion(listLoc, '[');
      builder.addSimpleInsertion(listLoc + childArg.length, ']');
    } else {
      var newlineLoc = childArgSrc.lastIndexOf(eol);
      if (newlineLoc == childArgSrc.length) {
        newlineLoc -= 1;
      }
      String indentOld =
          getLinePrefix(childArg.offset + eol.length + newlineLoc);
      var indentNew = '$indentOld${getIndent(1)}';
      // The separator includes 'child:' but that has no newlines.
      String separator =
          getText(namedExp.offset, childArg.offset - namedExp.offset);
      var prefix = separator.contains(eol) ? '' : '$eol$indentNew';
      if (prefix.isEmpty) {
        builder.addSimpleInsertion(namedExp.offset + 'child:'.length, ' [');
        builder.addDeletion(SourceRange(childArg.offset - 2, 2));
      } else {
        builder.addSimpleInsertion(listLoc, '[');
      }
      var newChildArgSrc = childArgSrc.replaceAll(
          RegExp('^$indentOld', multiLine: true), '$indentNew');
      newChildArgSrc = '$prefix$newChildArgSrc,$eol$indentOld]';
      builder.addSimpleReplacement(rangeNode(childArg), newChildArgSrc);
    }
  }

  /// Return the named expression representing the `child` argument of the given
  /// [newExpr], or `null` if none.
  NamedExpression findChildArgument(InstanceCreationExpression newExpr) =>
      newExpr.argumentList.arguments
          .firstWhere(isChildArgument, orElse: () => null);

  /// Return the named expression representing the `children` argument of the
  /// given [newExpr], or `null` if none.
  NamedExpression findChildrenArgument(InstanceCreationExpression newExpr) =>
      newExpr.argumentList.arguments
          .firstWhere(isChildrenArgument, orElse: () => null);

  /// Return the Flutter instance creation expression that is the value of the
  /// 'child' argument of the given [newExpr], or null if none.
  InstanceCreationExpression findChildWidget(
      InstanceCreationExpression newExpr) {
    var child = findChildArgument(newExpr);
    return getChildWidget(child);
  }

  /// Return the named expression with the given [name], or `null` if none.
  NamedExpression findNamedArgument(
    InstanceCreationExpression creation,
    String name,
  ) {
    var arguments = creation.argumentList.arguments;
    return argumentByName(arguments, name);
  }

  /// If the given [node] is a simple identifier, find the named expression
  /// whose name is the given [name] that is an argument to a Flutter instance
  /// creation expression. Return null if any condition cannot be satisfied.
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

  /// Return the expression that is a Flutter Widget that is the value of the
  /// given [child], or null if none.
  Expression getChildWidget(NamedExpression child) {
    var expression = child?.expression;
    if (isWidgetExpression(expression)) {
      return expression;
    }
    return null;
  }

  /// Return the presentation for the given Flutter `Widget` creation [node].
  String getWidgetPresentationText(InstanceCreationExpression node) {
    var element = node.constructorName.staticElement?.enclosingElement;
    if (!isWidget(element)) {
      return null;
    }
    List<Expression> arguments = node.argumentList.arguments;
    if (_isExactWidget(element, 'Icon', _uriWidgetsIcon)) {
      if (arguments.isNotEmpty) {
        var text = arguments[0].toString();
        var arg = shorten(text, 32);
        return 'Icon($arg)';
      } else {
        return 'Icon';
      }
    }
    if (_isExactWidget(element, 'Text', _uriWidgetsText)) {
      if (arguments.isNotEmpty) {
        var text = arguments[0].toString();
        var arg = shorten(text, 32);
        return 'Text($arg)';
      } else {
        return 'Text';
      }
    }
    return element.name;
  }

  /// Return the instance creation expression that surrounds the given
  /// [node], if any, else null. The [node] may be the instance creation
  /// expression itself or the identifier that names the constructor.
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

  /// Attempt to find and return the closest expression that encloses the [node]
  /// and is an independent Flutter `Widget`.  Return `null` if nothing found.
  Expression identifyWidgetExpression(AstNode node) {
    for (; node != null; node = node.parent) {
      if (isWidgetExpression(node)) {
        var parent = node.parent;

        if (node is AssignmentExpression) {
          return null;
        }
        if (parent is AssignmentExpression) {
          if (parent.rightHandSide == node) {
            return node;
          }
          return null;
        }

        if (parent is ArgumentList ||
            parent is ConditionalExpression && parent.thenExpression == node ||
            parent is ConditionalExpression && parent.elseExpression == node ||
            parent is ExpressionFunctionBody && parent.expression == node ||
            parent is ForElement && parent.body == node ||
            parent is IfElement && parent.thenElement == node ||
            parent is IfElement && parent.elseElement == node ||
            parent is ListLiteral ||
            parent is NamedExpression && parent.expression == node ||
            parent is Statement) {
          return node;
        }
      }
      if (node is ArgumentList || node is Statement || node is FunctionBody) {
        return null;
      }
    }
    return null;
  }

  /// Return `true` is the given [argument] is the `child` argument.
  bool isChildArgument(Expression argument) =>
      argument is NamedExpression && argument.name.label.name == 'child';

  /// Return `true` is the given [argument] is the `child` argument.
  bool isChildrenArgument(Expression argument) =>
      argument is NamedExpression && argument.name.label.name == 'children';

  /// Return `true` if the given [type] is the dart.ui class `Color`, or its
  /// subtype.
  bool isColor(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    bool isColorElement(ClassElement element) {
      if (element == null) {
        return false;
      }

      bool isExactColor(ClassElement element) =>
          element?.name == 'Color' && element.library.name == 'dart.ui';
      if (isExactColor(element)) {
        return true;
      }
      for (var type in element.allSupertypes) {
        if (isExactColor(type.element)) {
          return true;
        }
      }
      return false;
    }

    return isColorElement(type.element);
  }

  /// Return `true` if the given [type] is the flutter mixin `Diagnosticable`
  /// or its subtype.
  bool isDiagnosticable(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    bool isDiagnosticableElement(ClassElement element) {
      if (element == null) {
        return false;
      }

      bool isExactDiagnosticable(ClassElement element) =>
          element?.name == 'Diagnosticable' &&
          element.source.uri == _uriDiagnostics;
      if (isExactDiagnosticable(element)) {
        return true;
      }
      for (var type in element.allSupertypes) {
        if (isExactDiagnosticable(type.element)) {
          return true;
        }
      }
      return false;
    }

    return isDiagnosticableElement(type.element);
  }

  /// Return `true` if the [element] is the Flutter class `Alignment`.
  bool isExactAlignment(ClassElement element) {
    return _isExactWidget(element, 'Alignment', _uriAlignment);
  }

  /// Return `true` if the [element] is the Flutter class
  /// `AlignmentDirectional`.
  bool isExactAlignmentDirectional(ClassElement element) {
    return _isExactWidget(element, 'AlignmentDirectional', _uriAlignment);
  }

  /// Return `true` if the [element] is the Flutter class `AlignmentGeometry`.
  bool isExactAlignmentGeometry(ClassElement element) {
    return _isExactWidget(element, 'AlignmentGeometry', _uriAlignment);
  }

  /// Return `true` if the [type] is the Flutter type `EdgeInsetsGeometry`.
  bool isExactEdgeInsetsGeometryType(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, 'EdgeInsetsGeometry', _uriEdgeInsets);
  }

  /// Return `true` if the [node] is creation of `Align`.
  bool isExactlyAlignCreation(InstanceCreationExpression node) {
    var type = node?.staticType;
    return isExactWidgetTypeAlign(type);
  }

  /// Return `true` if the [node] is creation of `Container`.
  bool isExactlyContainerCreation(InstanceCreationExpression node) {
    var type = node?.staticType;
    return isExactWidgetTypeContainer(type);
  }

  /// Return `true` if the [node] is creation of `Padding`.
  bool isExactlyPaddingCreation(InstanceCreationExpression node) {
    var type = node?.staticType;
    return isExactWidgetTypePadding(type);
  }

  /// Return `true` if the given [type] is the Flutter class `StatefulWidget`.
  bool isExactlyStatefulWidgetType(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, _nameStatefulWidget, _uriFramework);
  }

  /// Return `true` if the given [type] is the Flutter class `StatelessWidget`.
  bool isExactlyStatelessWidgetType(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, _nameStatelessWidget, _uriFramework);
  }

  /// Return `true` if the given [element] is the Flutter class `State`.
  bool isExactState(ClassElement element) {
    return _isExactWidget(element, _nameState, _uriFramework);
  }

  /// Return `true` if the given [type] is the Flutter class `Align`.
  bool isExactWidgetTypeAlign(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, _nameAlign, _uriBasic);
  }

  /// Return `true` if the given [type] is the Flutter class `Center`.
  bool isExactWidgetTypeCenter(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, _nameCenter, _uriBasic);
  }

  /// Return `true` if the given [type] is the Flutter class `Container`.
  bool isExactWidgetTypeContainer(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, _nameContainer, _uriContainer);
  }

  /// Return `true` if the given [type] is the Flutter class `Padding`.
  bool isExactWidgetTypePadding(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, _namePadding, _uriBasic);
  }

  /// Return `true` if the given [type] is the Flutter class `SizedBox`.
  bool isExactWidgetTypeSizedBox(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, _nameSizedBox, _uriBasic);
  }

  /// Return `true` if the given [type] is the Flutter class `StreamBuilder`.
  bool isExactWidgetTypeStreamBuilder(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, _nameStreamBuilder, _uriAsync);
  }

  /// Return `true` if the given [type] is the Flutter class `Widget`, or its
  /// subtype.
  bool isListOfWidgetsType(DartType type) {
    return type is InterfaceType &&
        type.isDartCoreList &&
        isWidgetType(type.typeArguments[0]);
  }

  /// Return `true` if the given [type] is the vector_math_64 class `Matrix4`,
  /// or its subtype.
  bool isMatrix4(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    bool isMatrix4Element(ClassElement element) {
      if (element == null) {
        return false;
      }

      bool isExactMatrix4(ClassElement element) =>
          element?.name == 'Matrix4' &&
          element.library.name == 'vector_math_64';
      if (isExactMatrix4(element)) {
        return true;
      }
      for (var type in element.allSupertypes) {
        if (isExactMatrix4(type.element)) {
          return true;
        }
      }
      return false;
    }

    return isMatrix4Element(type.element);
  }

  /// Return `true` if the given [element] has the Flutter class `State` as
  /// a superclass.
  bool isState(ClassElement element) {
    return _hasSupertype(element, _uriFramework, _nameState);
  }

  /// Return `true` if the given [element] is a [ClassElement] that extends
  /// the Flutter class `StatefulWidget`.
  bool isStatefulWidgetDeclaration(Element element) {
    if (element is ClassElement) {
      return isExactlyStatefulWidgetType(element.supertype);
    }
    return false;
  }

  /// Return `true` if the given [element] is the Flutter class `Widget`, or its
  /// subtype.
  bool isWidget(ClassElement element) {
    if (element == null) {
      return false;
    }
    if (_isExactWidget(element, _nameWidget, _uriFramework)) {
      return true;
    }
    for (var type in element.allSupertypes) {
      if (_isExactWidget(type.element, _nameWidget, _uriFramework)) {
        return true;
      }
    }
    return false;
  }

  /// Return `true` if the given [expr] is a constructor invocation for a
  /// class that has the Flutter class `Widget` as a superclass.
  bool isWidgetCreation(InstanceCreationExpression expr) {
    var element = expr?.constructorName?.staticElement?.enclosingElement;
    return isWidget(element);
  }

  /// Return `true` if the given [node] is the Flutter class `Widget`, or its
  /// subtype.
  bool isWidgetExpression(AstNode node) {
    if (node == null) {
      return false;
    }
    if (node.parent is TypeName || node.parent?.parent is TypeName) {
      return false;
    }
    if (node.parent is ConstructorName) {
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

  /// Return `true` if the given [type] is the Flutter class `Widget`, or its
  /// subtype.
  bool isWidgetType(DartType type) {
    return type is InterfaceType && isWidget(type.element);
  }

  /// Return `true` if the given [element] has a supertype with the
  /// [requiredName] defined in the file with the [requiredUri].
  bool _hasSupertype(
      ClassElement element, Uri requiredUri, String requiredName) {
    if (element == null) {
      return false;
    }
    for (var type in element.allSupertypes) {
      if (type.element.name == requiredName) {
        var uri = type.element.source.uri;
        if (uri == requiredUri) {
          return true;
        }
      }
    }
    return false;
  }

  /// Return `true` if the given [element] is the exact [type] defined in the
  /// file with the given [uri].
  bool _isExactWidget(ClassElement element, String type, Uri uri) {
    return element != null && element.name == type && element.source.uri == uri;
  }
}
