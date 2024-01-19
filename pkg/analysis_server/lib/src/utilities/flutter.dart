// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:collection/collection.dart';

abstract final class Flutter {
  static const _nameAlign = 'Align';
  static const _nameBuilder = 'Builder';
  static const _nameCenter = 'Center';
  static const _nameContainer = 'Container';
  static const _namePadding = 'Padding';
  static const _nameSizedBox = 'SizedBox';
  static const _nameState = 'State';
  static const _nameStatefulWidget = 'StatefulWidget';
  static const _nameStatelessWidget = 'StatelessWidget';
  static const _nameStreamBuilder = 'StreamBuilder';
  static const _nameWidget = 'Widget';

  static final String widgetsUri = 'package:flutter/widgets.dart';

  static final Uri _uriAlignment = Uri.parse(
    'package:flutter/src/painting/alignment.dart',
  );
  static final Uri _uriAsync = Uri.parse(
    'package:flutter/src/widgets/async.dart',
  );
  static final Uri _uriBasic = Uri.parse(
    'package:flutter/src/widgets/basic.dart',
  );
  static final Uri _uriContainer = Uri.parse(
    'package:flutter/src/widgets/container.dart',
  );
  static final Uri _uriDiagnostics = Uri.parse(
    'package:flutter/src/foundation/diagnostics.dart',
  );
  static final Uri _uriEdgeInsets = Uri.parse(
    'package:flutter/src/painting/edge_insets.dart',
  );
  static final Uri _uriFramework = Uri.parse(
    'package:flutter/src/widgets/framework.dart',
  );
  static final Uri _uriWidgetsIcon = Uri.parse(
    'package:flutter/src/widgets/icon.dart',
  );
  static final Uri _uriWidgetsText = Uri.parse(
    'package:flutter/src/widgets/text.dart',
  );

  static void convertChildToChildren2(
      DartFileEditBuilder builder,
      Expression childArg,
      NamedExpression namedExp,
      String eol,
      String Function(Expression) getNodeText,
      String Function(int) getLinePrefix,
      String Function(int) getIndent,
      String Function(int, int) getText,
      String Function(String, String, String,
              {bool includeLeading, bool ensureTrailingNewline})
          replaceSourceIndent,
      SourceRange Function(Expression) rangeNode) {
    var childLoc = namedExp.offset + 'child'.length;
    builder.addSimpleInsertion(childLoc, 'ren');
    var listLoc = childArg.offset;
    var childArgSrc = getNodeText(childArg);
    if (!childArgSrc.contains(eol)) {
      builder.addSimpleInsertion(listLoc, '[');
      builder.addSimpleInsertion(listLoc + childArg.length, ']');
    } else {
      var newlineLoc = childArgSrc.lastIndexOf(eol);
      if (newlineLoc == childArgSrc.length) {
        newlineLoc -= 1;
      }
      var indentOld = getLinePrefix(childArg.offset + eol.length + newlineLoc);
      var indentNew = '$indentOld${getIndent(1)}';
      // The separator includes 'child:' but that has no newlines.
      var separator =
          getText(namedExp.offset, childArg.offset - namedExp.offset);
      var prefix = separator.contains(eol) ? '' : '$eol$indentNew';
      if (prefix.isEmpty) {
        builder.addSimpleInsertion(namedExp.offset + 'child:'.length, ' [');
        builder.addDeletion(SourceRange(childArg.offset - 2, 2));
      } else {
        builder.addSimpleInsertion(listLoc, '[');
      }
      var newChildArgSrc = replaceSourceIndent(
        childArgSrc,
        indentOld,
        indentNew,
      );
      newChildArgSrc = '$prefix$newChildArgSrc,$eol$indentOld]';
      builder.addSimpleReplacement(rangeNode(childArg), newChildArgSrc);
    }
  }

  /// Returns the named expression representing the `builder` argument of the
  /// given [newExpr], or `null` if none.
  static NamedExpression? findBuilderArgument(
          InstanceCreationExpression newExpr) =>
      newExpr.argumentList.arguments
          .whereType<NamedExpression>()
          .firstWhereOrNull((argument) => isBuilderArgument(argument));

  /// Returns the named expression representing the `child` argument of the
  /// given [newExpr], or `null` if none.
  static NamedExpression? findChildArgument(
          InstanceCreationExpression newExpr) =>
      newExpr.argumentList.arguments
          .whereType<NamedExpression>()
          .firstWhereOrNull((argument) => isChildArgument(argument));

  /// Returns the named expression representing the `children` argument of the
  /// given [newExpr], or `null` if none.
  static NamedExpression? findChildrenArgument(
          InstanceCreationExpression newExpr) =>
      newExpr.argumentList.arguments
          .whereType<NamedExpression>()
          .firstWhereOrNull((argument) => isChildrenArgument(argument));

  /// Returns the Flutter instance creation expression that is the value of the
  /// 'child' argument of the given [newExpr], or `null` if none.
  static InstanceCreationExpression? findChildWidget(
      InstanceCreationExpression newExpr) {
    var child = findChildArgument(newExpr);
    var widget = getChildWidget(child);
    if (widget is InstanceCreationExpression) {
      return widget;
    }
    return null;
  }

  /// If the given [node] is a simple identifier, finds the named expression
  /// whose name is the given [name] that is an argument to a Flutter instance
  /// creation expression.
  ///
  /// Returns `null` if any condition cannot be satisfied.
  static NamedExpression? findNamedExpression(AstNode node, String name) {
    if (node is! SimpleIdentifier) {
      return null;
    }
    var parent = node.parent;
    var grandParent = parent?.parent;
    if (parent is Label && grandParent is NamedExpression) {
      if (node.name != name) {
        return null;
      }
    } else {
      return null;
    }
    var invocation = grandParent.parent?.parent;
    if (invocation is! InstanceCreationExpression ||
        !isWidgetCreation(invocation)) {
      return null;
    }
    return grandParent;
  }

  /// Returns the expression that is a Flutter Widget that is the value of the
  /// given [child], or `null` if none.
  static Expression? getChildWidget(NamedExpression? child) {
    var expression = child?.expression;
    if (isWidgetExpression(expression)) {
      return expression;
    }
    return null;
  }

  /// Returns the presentation for the given Flutter `Widget` creation [node].
  static String? getWidgetPresentationText(InstanceCreationExpression node) {
    var element = node
        .constructorName.staticElement?.enclosingElement.augmented?.declaration;
    if (!isWidget(element)) {
      return null;
    }
    var arguments = node.argumentList.arguments;
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
    return element?.name;
  }

  /// Returns the instance creation expression that surrounds the given
  /// [node], if any, else null.
  ///
  /// The [node] may be the instance creation expression itself or an
  /// (optionally prefixed) identifier that names the constructor.
  static InstanceCreationExpression? identifyNewExpression(AstNode? node) {
    InstanceCreationExpression? newExpr;
    if (node is ImportPrefixReference) {
      node = node.parent;
    }
    if (node is SimpleIdentifier) {
      node = node.parent;
    }
    if (node is PrefixedIdentifier) {
      node = node.parent;
    }
    if (node is NamedType) {
      node = node.parent;
    }
    if (node is ConstructorName) {
      node = node.parent;
    }
    if (node is InstanceCreationExpression) {
      newExpr = node;
    }
    return newExpr;
  }

  /// Attempts to find and return the closest expression that encloses the [node]
  /// and is an independent Flutter `Widget`.
  ///
  /// Returns `null` if nothing is found.
  static Expression? identifyWidgetExpression(AstNode? node) {
    for (; node != null; node = node.parent) {
      if (isWidgetExpression(node)) {
        var parent = node.parent;

        if (node is AssignmentExpression) {
          return null;
        }
        if (parent is AssignmentExpression) {
          if (parent.rightHandSide == node) {
            return node as Expression;
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
            parent is Statement ||
            parent is SwitchExpressionCase && parent.expression == node ||
            parent is VariableDeclaration) {
          return node as Expression;
        }
      }
      if (node is ArgumentList || node is Statement || node is FunctionBody) {
        return null;
      }
    }
    return null;
  }

  /// Whether the given [argument] is the `builder` argument.
  static bool isBuilderArgument(Expression argument) =>
      argument is NamedExpression && argument.name.label.name == 'builder';

  /// Whether the given [argument] is the `child` argument.
  static bool isChildArgument(Expression argument) =>
      argument is NamedExpression && argument.name.label.name == 'child';

  /// Whether the given [argument] is the `child` argument.
  static bool isChildrenArgument(Expression argument) =>
      argument is NamedExpression && argument.name.label.name == 'children';

  /// Whether the given [type] is the 'dart.ui' class `Color`, or its subtype.
  static bool isColor(DartType? type) {
    if (type is! InterfaceType) {
      return false;
    }

    return [type, ...type.element.allSupertypes].any((t) =>
        t.element.name == 'Color' && t.element.library.name == 'dart.ui');
  }

  /// Whether the given [type] is the flutter mixin `Diagnosticable` or its
  /// subtype.
  static bool isDiagnosticable(DartType? type) {
    if (type is! InterfaceType) {
      return false;
    }

    return [type, ...type.element.allSupertypes].any((t) =>
        t.element.name == 'Diagnosticable' &&
        t.element.source.uri == _uriDiagnostics);
  }

  /// Whether the [element] is the Flutter class `Alignment`.
  static bool isExactAlignment(InterfaceElement element) {
    return _isExactWidget(element, 'Alignment', _uriAlignment);
  }

  /// Whether if the [element] is the Flutter class
  /// `AlignmentDirectional`.
  static bool isExactAlignmentDirectional(InterfaceElement element) {
    return _isExactWidget(element, 'AlignmentDirectional', _uriAlignment);
  }

  /// Whether if the [element] is the Flutter class `AlignmentGeometry`.
  static bool isExactAlignmentGeometry(InterfaceElement element) {
    return _isExactWidget(element, 'AlignmentGeometry', _uriAlignment);
  }

  /// Whether the [type] is the Flutter type `EdgeInsetsGeometry`.
  static bool isExactEdgeInsetsGeometryType(DartType type) {
    return type is InterfaceType &&
        _isExactWidget(type.element, 'EdgeInsetsGeometry', _uriEdgeInsets);
  }

  /// Whether the [node] is creation of `Align`.
  static bool isExactlyAlignCreation(InstanceCreationExpression node) =>
      isExactWidgetTypeAlign(node.staticType);

  /// Whether the [node] is creation of `Container`.
  static bool isExactlyContainerCreation(InstanceCreationExpression? node) =>
      isExactWidgetTypeContainer(node?.staticType);

  /// Whether the [node] is creation of `Padding`.
  static bool isExactlyPaddingCreation(InstanceCreationExpression node) =>
      isExactWidgetTypePadding(node.staticType);

  /// Whether the given [type] is the Flutter class `StatefulWidget`.
  static bool isExactlyStatefulWidgetType(DartType? type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameStatefulWidget, _uriFramework);

  /// Whether the given [type] is the Flutter class `StatelessWidget`.
  static bool isExactlyStatelessWidgetType(DartType type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameStatelessWidget, _uriFramework);

  /// Whether the given [element] is the Flutter class `State`.
  static bool isExactState(ClassElement element) =>
      _isExactWidget(element, _nameState, _uriFramework);

  /// Whether the given [type] is the Flutter class `Align`.
  static bool isExactWidgetTypeAlign(DartType? type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameAlign, _uriBasic);

  /// Whether the given [type] is the Flutter class `StreamBuilder`.
  static bool isExactWidgetTypeBuilder(DartType type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameBuilder, _uriBasic);

  /// Whether the given [type] is the Flutter class `Center`.
  static bool isExactWidgetTypeCenter(DartType type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameCenter, _uriBasic);

  /// Whether the given [type] is the Flutter class `Container`.
  static bool isExactWidgetTypeContainer(DartType? type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameContainer, _uriContainer);

  /// Whether the given [type] is the Flutter class `Padding`.
  static bool isExactWidgetTypePadding(DartType? type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _namePadding, _uriBasic);

  /// Whether the given [type] is the Flutter class `SizedBox`.
  static bool isExactWidgetTypeSizedBox(DartType type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameSizedBox, _uriBasic);

  /// Whether the given [type] is the Flutter class `StreamBuilder`.
  static bool isExactWidgetTypeStreamBuilder(DartType type) =>
      type is InterfaceType &&
      _isExactWidget(type.element, _nameStreamBuilder, _uriAsync);

  /// Whether the given [type] is the Flutter class `Widget`, or its subtype.
  static bool isListOfWidgetsType(DartType type) =>
      type is InterfaceType &&
      type.isDartCoreList &&
      isWidgetType(type.typeArguments[0]);

  /// Whether the given [type] is the vector_math_64 class `Matrix4`, or its
  /// subtype.
  static bool isMatrix4(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    return [type, ...type.element.allSupertypes].any((t) =>
        t.element.name == 'Matrix4' &&
        t.element.library.name == 'vector_math_64');
  }

  /// Whether the given [element] has the Flutter class `State` as
  /// a superclass.
  static bool isState(ClassElement? element) =>
      _hasSupertype(element, _uriFramework, _nameState);

  /// Whether the given [element] is a [ClassElement] that extends the Flutter
  /// class `StatefulWidget`.
  static bool isStatefulWidgetDeclaration(Element element) =>
      element is ClassElement && isExactlyStatefulWidgetType(element.supertype);

  /// Whether the given [element] is the Flutter class `Widget`, or its
  /// subtype.
  static bool isWidget(InterfaceElement? element) {
    if (element is! ClassElement) {
      return false;
    }
    if (_isExactWidget(element, _nameWidget, _uriFramework)) {
      return true;
    }
    return element.allSupertypes.any(
        (type) => _isExactWidget(type.element, _nameWidget, _uriFramework));
  }

  /// Whether the given [expr] is a constructor invocation for a class that has
  /// the Flutter class `Widget` as a superclass.
  static bool isWidgetCreation(InstanceCreationExpression? expr) {
    var element = expr?.constructorName.staticElement?.enclosingElement
        .augmented?.declaration;
    return isWidget(element);
  }

  /// Whether the given [node] is the Flutter class `Widget`, or its subtype.
  static bool isWidgetExpression(AstNode? node) {
    if (node == null) {
      return false;
    }
    if (node.parent is NamedType || node.parent?.parent is NamedType) {
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

  /// Whether the given [type] is the Flutter class `Widget`, or its subtype.
  static bool isWidgetType(DartType? type) =>
      type is InterfaceType && isWidget(type.element);

  /// Whether the given [element] has a supertype with the [requiredName]
  /// defined in the file with the [requiredUri].
  static bool _hasSupertype(
      InterfaceElement? element, Uri requiredUri, String requiredName) {
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

  /// Whether the given [element] is the exact [type] defined in the file with
  /// the given [uri].
  static bool _isExactWidget(InterfaceElement? element, String type, Uri uri) =>
      element is ClassElement &&
      element.name == type &&
      element.source.uri == uri;
}
