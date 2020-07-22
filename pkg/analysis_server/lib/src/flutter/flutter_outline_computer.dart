// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// Computer for Flutter specific outlines.
class FlutterOutlineComputer {
  final ResolvedUnitResult resolvedUnit;

  final List<protocol.FlutterOutline> _depthFirstOrder = [];

  FlutterOutlineComputer(this.resolvedUnit);

  Flutter get _flutter => Flutter.instance;

  protocol.FlutterOutline compute() {
    var dartOutline = DartUnitOutlineComputer(
      resolvedUnit,
      withBasicFlutter: false,
    ).compute();

    // Convert Dart outlines into Flutter outlines.
    var flutterDartOutline = _convert(dartOutline);

    // Create outlines for widgets.
    var visitor = _FlutterOutlineBuilder(this);
    resolvedUnit.unit.accept(visitor);

    // Associate Flutter outlines with Dart outlines.
    for (var outline in visitor.outlines) {
      for (var parent in _depthFirstOrder) {
        if (parent.offset < outline.offset &&
            outline.offset + outline.length < parent.offset + parent.length) {
          parent.children ??= <protocol.FlutterOutline>[];
          parent.children.add(outline);
          break;
        }
      }
    }

    return flutterDartOutline;
  }

  /// If the given [argument] for the [parameter] can be represented as a
  /// Flutter attribute, add it to the [attributes].
  void _addAttribute(List<protocol.FlutterOutlineAttribute> attributes,
      Expression argument, ParameterElement parameter) {
    if (parameter == null) {
      return;
    }

    protocol.Location nameLocation;
    if (argument is NamedExpression) {
      NamedExpression namedExpression = argument;
      nameLocation = protocol.newLocation_fromNode(namedExpression.name.label);
      argument = namedExpression.expression;
    }

    var valueLocation = protocol.newLocation_fromNode(argument);

    var name = parameter.displayName;

    var label = resolvedUnit.content.substring(argument.offset, argument.end);
    if (label.contains('\n')) {
      label = '…';
    }

    bool literalValueBoolean;
    int literalValueInteger;
    String literalValueString;
    if (argument is BooleanLiteral) {
      literalValueBoolean = argument.value;
    } else if (argument is IntegerLiteral) {
      literalValueInteger = argument.value;
    } else if (argument is StringLiteral) {
      literalValueString = argument.stringValue;
    } else {
      if (argument is FunctionExpression) {
        var hasParameters = argument.parameters != null &&
            argument.parameters.parameters.isNotEmpty;
        if (argument.body is ExpressionFunctionBody) {
          label = hasParameters ? '(…) => …' : '() => …';
        } else {
          label = hasParameters ? '(…) { … }' : '() { … }';
        }
      } else if (argument is ListLiteral) {
        label = '[…]';
      } else if (argument is SetOrMapLiteral) {
        label = '{…}';
      }
    }

    attributes.add(protocol.FlutterOutlineAttribute(
      name,
      label,
      literalValueBoolean: literalValueBoolean,
      literalValueInteger: literalValueInteger,
      literalValueString: literalValueString,
      nameLocation: nameLocation,
      valueLocation: valueLocation,
    ));
  }

  protocol.FlutterOutline _convert(protocol.Outline dartOutline) {
    var flutterOutline = protocol.FlutterOutline(
        protocol.FlutterOutlineKind.DART_ELEMENT,
        dartOutline.offset,
        dartOutline.length,
        dartOutline.codeOffset,
        dartOutline.codeLength,
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
    var type = node.staticType;
    if (!_flutter.isWidgetType(type)) {
      return null;
    }
    var className = type.element.displayName;

    if (node is InstanceCreationExpression) {
      var attributes = <protocol.FlutterOutlineAttribute>[];
      var children = <protocol.FlutterOutline>[];
      for (var argument in node.argumentList.arguments) {
        var isWidgetArgument = _flutter.isWidgetType(argument.staticType);
        var isWidgetListArgument =
            _flutter.isListOfWidgetsType(argument.staticType);

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
              void addChildrenFrom(CollectionElement element) {
                if (element is Expression) {
                  var child = _createOutline(element, true);
                  if (child != null) {
                    children.add(child);
                  }
                } else if (element is IfElement) {
                  addChildrenFrom(element.thenElement);
                  addChildrenFrom(element.elseElement);
                } else if (element is ForElement) {
                  addChildrenFrom(element.body);
                } else if (element is SpreadElement) {
                  // Ignored. It's possible that we might be able to extract
                  // some information from some spread expressions, but it seems
                  // unlikely enough that we're not handling it at the moment.
                }
              }

              addChildrenFrom(element);
            }
          }
        } else {
          var visitor = _FlutterOutlineBuilder(this);
          argument.accept(visitor);
          if (visitor.outlines.isNotEmpty) {
            children.addAll(visitor.outlines);
          } else {
            var parameter = argument.staticParameterElement;
            _addAttribute(attributes, argument, parameter);
          }
        }
      }

      return protocol.FlutterOutline(protocol.FlutterOutlineKind.NEW_INSTANCE,
          node.offset, node.length, node.offset, node.length,
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

      return protocol.FlutterOutline(
          kind, node.offset, node.length, node.offset, node.length,
          className: className, variableName: variableName, label: label);
    }

    return null;
  }

  String _getShortLabel(AstNode node) {
    if (node is MethodInvocation) {
      var buffer = StringBuffer();

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
  final List<protocol.FlutterOutline> outlines = [];

  _FlutterOutlineBuilder(this.computer);

  @override
  void visitExpression(Expression node) {
    var outline = computer._createOutline(node, false);
    if (outline != null) {
      outlines.add(outline);
    } else {
      super.visitExpression(node);
    }
  }
}
