// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/// Computer for Flutter specific outlines.
class FlutterOutlineComputer {
  final String file;
  final LineInfo lineInfo;
  final CompilationUnit unit;
  final TypeProvider typeProvider;

  final List<protocol.FlutterOutline> _depthFirstOrder = [];

  FlutterOutlineComputer(this.file, this.lineInfo, this.unit)
      : typeProvider = unit.element.context.typeProvider;

  protocol.FlutterOutline compute() {
    protocol.Outline dartOutline = new DartUnitOutlineComputer(
            file, lineInfo, unit,
            withBasicFlutter: false)
        .compute();
    var flutterDartOutline = _convert(dartOutline);
    unit.accept(new _FlutterOutlineBuilder(this));
    return flutterDartOutline;
  }

  /// If the given [argument] for the [parameter] can be represented as a
  /// Flutter attribute, add it to the [attributes].
  void _addAttribute(List<protocol.FlutterOutlineAttribute> attributes,
      Expression argument, ParameterElement parameter) {
    if (argument is NamedExpression) {
      argument = (argument as NamedExpression).expression;
    }
    String label = argument.toString();
    if (argument is BooleanLiteral) {
      attributes.add(new protocol.FlutterOutlineAttribute(
          parameter.displayName, label,
          literalValueBoolean: argument.value));
    } else if (argument is IntegerLiteral) {
      attributes.add(new protocol.FlutterOutlineAttribute(
          parameter.displayName, label,
          literalValueInteger: argument.value));
    } else if (argument is StringLiteral) {
      attributes.add(new protocol.FlutterOutlineAttribute(
          parameter.displayName, label,
          literalValueString: argument.stringValue));
    } else {
      attributes.add(
          new protocol.FlutterOutlineAttribute(parameter.displayName, label));
    }
  }

  protocol.FlutterOutline _convert(protocol.Outline dartOutline) {
    protocol.FlutterOutline flutterOutline = new protocol.FlutterOutline(
        protocol.FlutterOutlineKind.DART_ELEMENT,
        dartOutline.offset,
        dartOutline.length,
        dartElement: dartOutline.element);
    if (dartOutline.children != null) {
      flutterOutline.children = dartOutline.children.map(_convert).toList();
    }
    _depthFirstOrder.add(flutterOutline);
    return flutterOutline;
  }

  /// If the [node] is a supported Flutter widget creation, create a new
  /// outline item for it. If the node is not a widget creation, but its type
  /// is a Flutter Widget class subtype, and [withGeneric] is `true`, return
  /// a widget reference outline item.
  protocol.FlutterOutline _createOutline(Expression node, bool withGeneric) {
    DartType type = node.staticType;
    if (!isWidgetType(type)) {
      return null;
    }
    String className = type.element.displayName;

    if (node is InstanceCreationExpression) {
      var attributes = <protocol.FlutterOutlineAttribute>[];
      var children = <protocol.FlutterOutline>[];
      for (var argument in node.argumentList.arguments) {
        ParameterElement parameter = argument.staticParameterElement;

        bool isWidgetArgument = isWidgetType(argument.staticType);
        bool isWidgetListArgument = isListOfWidgetsType(argument.staticType);

        String parentAssociationLabel;
        Expression childrenExpression;

        if (argument is NamedExpression) {
          parentAssociationLabel = argument.name.label.name;
          childrenExpression = argument.expression;
        } else {
          childrenExpression = argument;
        }

        if (isWidgetArgument) {
          var child = _createOutline(childrenExpression, true);
          if (child != null) {
            child.parentAssociationLabel = parentAssociationLabel;
            children.add(child);
          }
        } else if (isWidgetListArgument) {
          if (childrenExpression is ListLiteral) {
            for (var element in childrenExpression.elements) {
              var child = _createOutline(element, true);
              if (child != null) {
                children.add(child);
              }
            }
          }
        } else {
          _addAttribute(attributes, argument, parameter);
        }
      }

      return new protocol.FlutterOutline(
          protocol.FlutterOutlineKind.NEW_INSTANCE, node.offset, node.length,
          className: className, attributes: attributes, children: children);
    }

    // A generic Widget typed expression.
    if (withGeneric) {
      var kind = protocol.FlutterOutlineKind.GENERIC;

      String variableName;
      if (node is SimpleIdentifier) {
        kind = protocol.FlutterOutlineKind.VARIABLE;
        variableName = node.name;
      }

      String label;
      if (kind == protocol.FlutterOutlineKind.GENERIC) {
        label = _getShortLabel(node);
      }

      return new protocol.FlutterOutline(kind, node.offset, node.length,
          className: className, variableName: variableName, label: label);
    }

    return null;
  }

  String _getShortLabel(AstNode node) {
    if (node is MethodInvocation) {
      var buffer = new StringBuffer();

      if (node.target != null) {
        buffer.write(_getShortLabel(node.target));
        buffer.write('.');
      }

      buffer.write(node.methodName.name);

      if (node.argumentList == null || node.argumentList.arguments.isEmpty) {
        buffer.write('()');
      } else {
        buffer.write('(…)');
      }

      return buffer.toString();
    }
    return node.toString();
  }
}

class _FlutterOutlineBuilder extends GeneralizingAstVisitor<void> {
  final FlutterOutlineComputer computer;

  _FlutterOutlineBuilder(this.computer);

  @override
  void visitExpression(Expression node) {
    var outline = computer._createOutline(node, false);
    if (outline != null) {
      for (var parent in computer._depthFirstOrder) {
        if (parent.offset < outline.offset &&
            outline.offset + outline.length < parent.offset + parent.length) {
          parent.children ??= <protocol.FlutterOutline>[];
          parent.children.add(outline);
          return;
        }
      }
    } else {
      super.visitExpression(node);
    }
  }
}
