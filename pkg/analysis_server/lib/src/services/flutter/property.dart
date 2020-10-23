// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/flutter/class_description.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

String getFieldDocumentation(FieldElement field) {
  var rawComment = field.documentationComment;
  return getDartDocPlainText(rawComment);
}

String getParameterDocumentation(ParameterElement parameter) {
  if (parameter is FieldFormalParameterElement) {
    var rawComment = parameter.field?.documentationComment;
    return getDartDocPlainText(rawComment);
  }
  return null;
}

class PropertyDescription {
  static int _nextPropertyId = 0;

  final PropertyDescription parent;

  /// The resolved unit, where the property value is.
  final ResolvedUnitResult resolvedUnit;

  /// The instance of [Flutter] support for the [resolvedUnit].
  final Flutter flutter;

  /// If the object that has this property is not materialized yet, so the
  /// [instanceCreation] is `null`, the description of the object to
  /// materialize.
  final ClassDescription classDescription;

  /// The instance creation of the object that has this property. Or `null`
  /// if the object is not materialized yet, in this case [classDescription]
  /// is set.
  final InstanceCreationExpression instanceCreation;

  /// Information about the `Container` property, which is not based on an
  /// actual [instanceCreation] of the `Container` widget, i.e. is not
  /// materialized.
  final VirtualContainerProperty virtualContainer;

  /// If the property is set, the full argument expression, might be a
  /// [NamedExpression].
  final Expression argumentExpression;

  /// If the property is set, the value part of the argument expression,
  /// the same as [argumentExpression] if a positional argument, or the
  /// expression part of the [NamedExpression].
  final Expression valueExpression;

  /// The parameter element in the object constructor that is actually
  /// invoked by [instanceCreation], or will be invoked when
  /// [classDescription] is materialized.
  final ParameterElement parameterElement;

  /// Optional nested properties.
  final List<PropertyDescription> children = [];

  final protocol.FlutterWidgetProperty protocolProperty;

  /// If this is a `EdgeInsets` typed property, the instance of helper.
  /// Otherwise `null`.
  _EdgeInsetsProperty _edgeInsetsProperty;

  PropertyDescription({
    this.parent,
    this.resolvedUnit,
    this.flutter,
    this.classDescription,
    this.instanceCreation,
    this.argumentExpression,
    this.valueExpression,
    this.parameterElement,
    this.protocolProperty,
    this.virtualContainer,
  });

  String get name => protocolProperty.name;

  /// This property has type `EdgeInsets`, add its nested properties.
  void addEdgeInsetsNestedProperties(ClassElement classEdgeInsets) {
    _edgeInsetsProperty = _EdgeInsetsProperty(classEdgeInsets, this);
    _edgeInsetsProperty.addNested();
  }

  Future<protocol.SourceChange> changeValue(
      protocol.FlutterWidgetPropertyValue value) async {
    if (parent?._edgeInsetsProperty != null) {
      return parent._edgeInsetsProperty.changeValue(this, value);
    }

    var builder = ChangeBuilder(session: resolvedUnit.session);

    ClassElement enumClassElement;
    var enumValue = value.enumValue;
    if (enumValue != null) {
      var helper = AnalysisSessionHelper(resolvedUnit.session);
      enumClassElement = await helper.getClass(
        enumValue.libraryUri,
        enumValue.className,
      );
    }

    await builder.addDartFileEdit(resolvedUnit.path, (builder) {
      _changeCode(builder, (builder) {
        if (value.expression != null) {
          builder.write(value.expression);
        } else if (enumClassElement != null) {
          builder.writeReference(enumClassElement);
          builder.write('.');
          builder.write(enumValue.name);
        } else {
          var code = _toPrimitiveValueCode(value);
          builder.write(code);
        }
      });
      _formatEnclosingFunctionBody(builder);
    });

    return builder.sourceChange;
  }

  Future<protocol.SourceChange> removeValue() async {
    var builder = ChangeBuilder(session: resolvedUnit.session);

    if (argumentExpression != null) {
      int endOffset;
      var argumentList = instanceCreation.argumentList;
      var arguments = argumentList.arguments;
      var argumentIndex = arguments.indexOf(argumentExpression);
      if (argumentIndex < arguments.length - 1) {
        endOffset = arguments[argumentIndex + 1].offset;
      } else {
        endOffset = argumentList.rightParenthesis.offset;
      }

      var beginOffset = argumentExpression.offset;
      await builder.addDartFileEdit(resolvedUnit.path, (builder) {
        builder.addDeletion(
          SourceRange(beginOffset, endOffset - beginOffset),
        );
      });
    }

    return builder.sourceChange;
  }

  void replaceChild(String name, PropertyDescription newChild) {
    assert(newChild.parent == this);
    for (var i = 0; i < children.length; i++) {
      if (children[i].name == name) {
        children[i] = newChild;
        break;
      }
    }
  }

  void _changeCode(
    DartFileEditBuilder builder,
    void Function(DartEditBuilder builder) buildCode,
  ) {
    if (valueExpression != null) {
      builder.addReplacement(range.node(valueExpression), buildCode);
    } else {
      var parameterName = parameterElement.name;
      if (instanceCreation != null) {
        var argumentList = instanceCreation.argumentList;

        var insertOffset = 0;
        for (var argument in argumentList.arguments) {
          if (argument is NamedExpression) {
            var argumentName = argument.name.label.name;

            if (argumentName.compareTo(parameterName) > 0 ||
                _isChildArgument(argument) ||
                _isChildrenArgument(argument)) {
              insertOffset = argument.offset;
              break;
            }
          }
        }

        var needsLeadingComma = false;
        if (insertOffset == 0) {
          var rightParenthesis = argumentList.rightParenthesis;
          insertOffset = rightParenthesis.offset;
          var previous = rightParenthesis.previous;
          if (previous.type != TokenType.COMMA &&
              previous != argumentList.leftParenthesis) {
            needsLeadingComma = true;
          }
        }

        builder.addInsertion(insertOffset, (builder) {
          if (needsLeadingComma) {
            builder.write(', ');
          }

          builder.write(parameterName);
          builder.write(': ');

          buildCode(builder);
          builder.write(', ');
        });
      } else {
        if (parent.virtualContainer != null) {
          parent._changeCodeVirtualContainer(builder, parameterName, buildCode);
        } else {
          parent._changeCode(builder, (builder) {
            builder.writeReference(classDescription.element);
            // TODO(scheglov) constructor name
            builder.write('(');
            builder.write(parameterName);
            builder.write(': ');
            buildCode(builder);
            builder.write(', ');
            builder.write(')');
          });
        }
      }
    }
  }

  void _changeCodeVirtualContainer(
    DartFileEditBuilder builder,
    String parameterName,
    void Function(DartEditBuilder builder) writeArgumentValue,
  ) {
    if (virtualContainer._parentCreation != null) {
      // `new Padding(...)` -> `Container(...)`
      builder.addReplacement(
        range.startEnd(
          virtualContainer._parentCreation,
          virtualContainer._parentCreation.constructorName,
        ),
        (builder) {
          builder.writeReference(virtualContainer.containerElement);
        },
      );

      var existingArgument = virtualContainer._parentArgumentToMove;
      var existingName = existingArgument.name.label.name;

      int parameterOffset;
      var leadingComma = false;
      var trailingComma = false;
      if (existingName.compareTo(parameterName) > 0) {
        // `Container(padding: ..., child: ...)`
        //    ->
        // `Container(alignment: ..., padding: ..., child: ...)`
        parameterOffset = existingArgument.offset;
        trailingComma = true;
      } else {
        // `Container(alignment: ..., child: ...)`
        //    ->
        // `Container(alignment: ..., padding: ..., child: ...)`
        parameterOffset = existingArgument.end;
        leadingComma = true;
      }

      builder.addInsertion(
        parameterOffset,
        (builder) {
          if (leadingComma) {
            builder.write(', ');
          }

          builder.write(parameterName);
          builder.write(': ');
          writeArgumentValue(builder);

          if (trailingComma) {
            builder.write(', ');
          }
        },
      );
    } else {
      builder.addInsertion(
        virtualContainer.widgetCreation.offset,
        (builder) {
          builder.writeReference(virtualContainer.containerElement);
          builder.write('(');

          builder.write(parameterName);
          builder.write(': ');
          writeArgumentValue(builder);
          builder.write(', ');

          builder.write('child: ');
        },
      );
      builder.addSimpleInsertion(virtualContainer.widgetCreation.end, ',)');
    }
  }

  FunctionBody _enclosingFunctionBody() {
    if (parent != null) {
      return parent._enclosingFunctionBody();
    }
    var anchorExpr = virtualContainer?.widgetCreation ?? instanceCreation;
    return anchorExpr.thisOrAncestorOfType<FunctionBody>();
  }

  void _formatEnclosingFunctionBody(DartFileEditBuilder builder) {
    var functionBody = _enclosingFunctionBody();
    builder.format(range.node(functionBody));
  }

  /// TODO(scheglov) Generalize to identifying by type.
  bool _isChildArgument(NamedExpression argument) {
    var argumentName = argument.name.label.name;
    return argumentName == 'child';
  }

  /// TODO(scheglov) Generalize to identifying by type.
  bool _isChildrenArgument(NamedExpression argument) {
    var argumentName = argument.name.label.name;
    return argumentName == 'children';
  }

  String _toPrimitiveValueCode(protocol.FlutterWidgetPropertyValue value) {
    if (value.boolValue != null) {
      return '${value.boolValue}';
    }

    if (value.doubleValue != null) {
      var code = value.doubleValue.toStringAsFixed(1);
      if (code.endsWith('.0')) {
        code = code.substring(0, code.length - 2);
      }
      return code;
    }

    if (value.intValue != null) {
      return '${value.intValue}';
    }

    if (value.stringValue != null) {
      var code = value.stringValue;
      if (code.contains("'")) {
        code = code.replaceAll("'", r"\'");
      }
      return "'$code'";
    }

    throw StateError('Not a primitive value: $value');
  }

  static int nextId() => _nextPropertyId++;
}

/// Every widget has the `Container` property, either based of an actual
/// `Container` widget instance creation, or virtual, materialized when a
/// nested property is set.
///
/// This class provides information necessary for such materialization.
class VirtualContainerProperty {
  final ClassElement containerElement;
  final InstanceCreationExpression widgetCreation;

  /// The existing wrapper around the widget, with semantic that is a subset
  /// of the `Container` semantic, such as `Padding`. Such wrapper should be
  /// replaced with full `Container` when `Container` is materialized.
  ///
  /// Might be `null`, if no existing replacable wrapped.
  InstanceCreationExpression _parentCreation;

  /// The argument from the [_parentCreation] that should be moved into
  /// the new `Container` creation during its materialization.
  NamedExpression _parentArgumentToMove;

  VirtualContainerProperty(
    this.containerElement,
    this.widgetCreation,
  );

  void setParentCreation(
    InstanceCreationExpression parentCreation,
    NamedExpression parentArgumentToMove,
  ) {
    _parentCreation = parentCreation;
    _parentArgumentToMove = parentArgumentToMove;
  }
}

/// Support for `EdgeInsets` typed properties.
///
/// We try to generate nice looking code for `EdgeInsets` instances.
class _EdgeInsetsProperty {
  final ClassElement classEdgeInsets;

  /// The property that has type `EdgeInsets`.
  final PropertyDescription property;

  /// The constructor `EdgeInsets.only`.
  ConstructorElement onlyConstructor;

  double leftValue;
  double topValue;
  double rightValue;
  double bottomValue;

  PropertyDescription leftProperty;
  PropertyDescription topProperty;
  PropertyDescription rightProperty;
  PropertyDescription bottomProperty;

  _EdgeInsetsProperty(this.classEdgeInsets, this.property);

  Flutter get flutter => property.flutter;

  void addNested() {
    Expression leftExpression;
    Expression topExpression;
    Expression rightExpression;
    Expression bottomExpression;
    var propertyExpression = property.valueExpression;
    if (propertyExpression is InstanceCreationExpression) {
      var constructor = propertyExpression.constructorName.staticElement;
      if (constructor?.enclosingElement == classEdgeInsets) {
        var arguments = propertyExpression.argumentList.arguments;
        if (constructor.name == 'all') {
          var expression = flutter.argumentByIndex(arguments, 0);
          leftExpression = expression;
          topExpression = expression;
          rightExpression = expression;
          bottomExpression = expression;
        } else if (constructor.name == 'fromLTRB') {
          leftExpression = flutter.argumentByIndex(arguments, 0);
          topExpression = flutter.argumentByIndex(arguments, 1);
          rightExpression = flutter.argumentByIndex(arguments, 2);
          bottomExpression = flutter.argumentByIndex(arguments, 3);
        } else if (constructor.name == 'only') {
          var leftArgument = flutter.argumentByName(arguments, 'left');
          var topArgument = flutter.argumentByName(arguments, 'top');
          var rightArgument = flutter.argumentByName(arguments, 'right');
          var bottomArgument = flutter.argumentByName(arguments, 'bottom');
          leftExpression = leftArgument?.expression;
          topExpression = topArgument?.expression;
          rightExpression = rightArgument?.expression;
          bottomExpression = bottomArgument?.expression;
        } else if (constructor.name == 'symmetric') {
          var hArgument = flutter.argumentByName(arguments, 'horizontal');
          var vArgument = flutter.argumentByName(arguments, 'vertical');
          leftExpression = hArgument?.expression;
          topExpression = vArgument?.expression;
          rightExpression = hArgument?.expression;
          bottomExpression = vArgument?.expression;
        }

        leftValue = _valueDouble(leftExpression);
        topValue = _valueDouble(topExpression);
        rightValue = _valueDouble(rightExpression);
        bottomValue = _valueDouble(bottomExpression);
      }
    }

    onlyConstructor = classEdgeInsets.getNamedConstructor('only');

    leftProperty = _addNestedProperty(
      name: 'left',
      expression: leftExpression,
      value: leftValue,
    );
    topProperty = _addNestedProperty(
      name: 'top',
      expression: topExpression,
      value: topValue,
    );
    rightProperty = _addNestedProperty(
      name: 'right',
      expression: rightExpression,
      value: rightValue,
    );
    bottomProperty = _addNestedProperty(
      name: 'bottom',
      expression: bottomExpression,
      value: bottomValue,
    );
  }

  /// The value of the [nested] property is changed, make changes to the
  /// value of the [property] is a whole, to generate nice code.
  Future<protocol.SourceChange> changeValue(
    PropertyDescription nested,
    protocol.FlutterWidgetPropertyValue value,
  ) async {
    var doubleValue = value.doubleValue;
    if (doubleValue == null) return null;

    if (nested == leftProperty) {
      leftValue = doubleValue;
    } else if (nested == topProperty) {
      topValue = doubleValue;
    } else if (nested == rightProperty) {
      rightValue = doubleValue;
    } else if (nested == bottomProperty) {
      bottomValue = doubleValue;
    }

    var leftCode = _toDoubleCode(leftValue);
    var topCode = _toDoubleCode(topValue);
    var rightCode = _toDoubleCode(rightValue);
    var bottomCode = _toDoubleCode(bottomValue);

    if (leftCode == '0' &&
        topCode == '0' &&
        rightCode == '0' &&
        bottomCode == '0') {
      return property.removeValue();
    }

    var builder = ChangeBuilder(session: property.resolvedUnit.session);

    await builder.addDartFileEdit(property.resolvedUnit.path, (builder) {
      property._changeCode(builder, (builder) {
        if (leftCode == rightCode && topCode == bottomCode) {
          builder.writeReference(classEdgeInsets);
          if (leftCode == topCode) {
            builder.write('.all(');
            builder.write(leftCode);
            builder.write(')');
          } else {
            var hasHorizontal = false;
            builder.write('.symmetric(');
            if (leftCode != '0') {
              builder.write('horizontal: ');
              builder.write(leftCode);
              hasHorizontal = true;
            }
            if (topCode != '0') {
              if (hasHorizontal) {
                builder.write(', ');
              }
              builder.write('vertical: ');
              builder.write(topCode);
            }
            builder.write(')');
          }
        } else {
          builder.writeReference(classEdgeInsets);
          builder.write('.only(');
          var needsComma = false;
          if (leftCode != '0') {
            builder.write('left: ');
            builder.write(leftCode);
            needsComma = true;
          }
          if (topCode != '0') {
            if (needsComma) {
              builder.write(', ');
            }
            builder.write('top: ');
            builder.write(topCode);
            needsComma = true;
          }
          if (rightCode != '0') {
            if (needsComma) {
              builder.write(', ');
            }
            builder.write('right: ');
            builder.write(rightCode);
            needsComma = true;
          }
          if (bottomCode != '0') {
            if (needsComma) {
              builder.write(', ');
            }
            builder.write('bottom: ');
            builder.write(bottomCode);
            needsComma = true;
          }
          builder.write(')');
        }
      });
      property._formatEnclosingFunctionBody(builder);
    });

    return builder.sourceChange;
  }

  PropertyDescription _addNestedProperty({
    String name,
    Expression expression,
    double value,
  }) {
    var parameter = onlyConstructor.parameters.singleWhere(
      (p) => p.name == name,
    );
    var parameterDocumentation = getParameterDocumentation(parameter);
    var nested = PropertyDescription(
      parent: property,
      resolvedUnit: property.resolvedUnit,
      valueExpression: expression,
      parameterElement: parameter,
      protocolProperty: protocol.FlutterWidgetProperty(
        PropertyDescription.nextId(),
        true,
        true,
        name,
        documentation: parameterDocumentation,
        expression: _expressionCode(expression),
        value: _protocolValueDouble(value),
        editor: protocol.FlutterWidgetPropertyEditor(
          protocol.FlutterWidgetPropertyEditorKind.DOUBLE,
        ),
      ),
    );
    property.children.add(nested);
    return nested;
  }

  String _expressionCode(Expression expression) {
    if (expression != null) {
      var content = property.resolvedUnit.content;
      return content.substring(expression.offset, expression.end);
    }
    return null;
  }

  static protocol.FlutterWidgetPropertyValue _protocolValueDouble(
    double value,
  ) {
    if (value != null) {
      return protocol.FlutterWidgetPropertyValue(
        doubleValue: value,
      );
    }
    return null;
  }

  static String _toDoubleCode(double value) {
    if (value == null) {
      return '0';
    }

    var code = value.toStringAsFixed(1);
    if (code.endsWith('.0')) {
      code = code.substring(0, code.length - 2);
    }
    return code;
  }

  static double _valueDouble(Expression expression) {
    if (expression is DoubleLiteral) {
      return expression.value;
    }
    if (expression is IntegerLiteral) {
      return expression.value.toDouble();
    }
    return null;
  }
}
