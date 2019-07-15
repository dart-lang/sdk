// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/util/comment.dart';

class SetPropertyValueResult {
  final protocol.RequestErrorCode errorCode;
  final protocol.SourceChange change;

  SetPropertyValueResult({this.errorCode, this.change});
}

class WidgetDescriptions {
  /// The mapping of identifiers of previously returned properties.
  final Map<int, _PropertyDescription> _properties = {};

  /// Return the description of the widget with [InstanceCreationExpression] in
  /// the [resolvedUnit] at the [offset].
  protocol.FlutterGetWidgetDescriptionResult getDescription(
    ResolvedUnitResult resolvedUnit,
    int offset,
  ) {
    var computer = _WidgetDescriptionComputer(resolvedUnit, offset);
    var widgetDescription = computer.compute();

    if (widgetDescription == null) {
      return null;
    }

    var protocolProperties = <protocol.FlutterWidgetProperty>[];
    for (var property in widgetDescription.properties) {
      _properties[property.protocolProperty.id] = property;
      protocolProperties.add(property.protocolProperty);
    }

    return protocol.FlutterGetWidgetDescriptionResult(protocolProperties);
  }

  SetPropertyValueResult setPropertyValue(
    int id,
    protocol.FlutterWidgetPropertyValue value,
  ) {
    var property = _properties[id];
    if (property == null) {
      return SetPropertyValueResult(
        errorCode: protocol
            .RequestErrorCode.FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID,
      );
    }

    if (value == null) {
      if (property.protocolProperty.isRequired) {
        return SetPropertyValueResult(
          errorCode: protocol
              .RequestErrorCode.FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED,
        );
      }
      var change = property.removeValue();
      return SetPropertyValueResult(change: change);
    } else {
      var change = property.changeValue(value);
      return SetPropertyValueResult(change: change);
    }
  }
}

class _PropertyDescription {
  final String file;
  final InstanceCreationExpression instanceCreation;
  final Expression argumentExpression;
  final Expression valueExpression;
  final ParameterElement parameterElement;

  final protocol.FlutterWidgetProperty protocolProperty;

  _PropertyDescription(
    this.file,
    this.instanceCreation,
    this.argumentExpression,
    this.valueExpression,
    this.parameterElement,
    this.protocolProperty,
  );

  protocol.SourceChange changeValue(protocol.FlutterWidgetPropertyValue value) {
    var change = protocol.SourceChange('Change property value');

    var code = _toCode(value);

    if (valueExpression != null) {
      change.addEdit(
        file,
        0,
        protocol.SourceEdit(
          valueExpression.offset,
          valueExpression.length,
          code,
        ),
      );
    } else {
      var argumentList = instanceCreation.argumentList;

      var rightParenthesis = argumentList.rightParenthesis;

      var leadingComma = '';
      if (rightParenthesis.previous.type != TokenType.COMMA) {
        leadingComma = ', ';
      }

      change.addEdit(
        file,
        0,
        protocol.SourceEdit(
          rightParenthesis.offset,
          0,
          '$leadingComma${parameterElement.name}: $code, ',
        ),
      );
    }

    return change;
  }

  protocol.SourceChange removeValue() {
    var change = protocol.SourceChange('Remove property value');

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
      change.addEdit(
        file,
        0,
        protocol.SourceEdit(
          beginOffset,
          endOffset - beginOffset,
          '',
        ),
      );
    }

    return change;
  }

  String _toCode(protocol.FlutterWidgetPropertyValue value) {
    if (value.boolValue != null) {
      return '${value.boolValue}';
    }

    if (value.doubleValue != null) {
      return value.doubleValue.toStringAsFixed(1);
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

    throw StateError('Cannot how to encode: $value');
  }
}

class _WidgetDescription {
  final List<_PropertyDescription> properties;

  _WidgetDescription(this.properties);
}

class _WidgetDescriptionComputer {
  static int _nextPropertyId = 0;

  /// The resolved unit with the widget [InstanceCreationExpression].
  final ResolvedUnitResult resolvedUnit;

  /// The offset of the widget expression.
  final int widgetOffset;

  final Flutter flutter;

  _WidgetDescriptionComputer(this.resolvedUnit, this.widgetOffset)
      : flutter = Flutter.of(resolvedUnit);

  _WidgetDescription compute() {
    var node = NodeLocator2(widgetOffset).searchWithin(resolvedUnit.unit);
    var creation = flutter.identifyNewExpression(node);
    if (creation == null) {
      return null;
    }

    var constructorElement = creation.staticElement;
    if (constructorElement == null) {
      return null;
    }

    var properties = <_PropertyDescription>[];
    _addProperties(creation, constructorElement, properties);

    return _WidgetDescription(properties);
  }

  void _addProperties(
    InstanceCreationExpression instanceCreation,
    ConstructorElement constructorElement,
    List<_PropertyDescription> properties,
  ) {
    var existingNamed = Set<ParameterElement>();
    for (var argumentExpression in instanceCreation.argumentList.arguments) {
      var parameter = argumentExpression.staticParameterElement;
      if (parameter == null) continue;

      Expression valueExpression;
      if (argumentExpression is NamedExpression) {
        valueExpression = argumentExpression.expression;
        existingNamed.add(parameter);
      } else {
        valueExpression = argumentExpression;
      }

      _addProperty(
        properties,
        parameter,
        instanceCreation,
        argumentExpression,
        valueExpression,
      );
    }

    for (var parameter in constructorElement.parameters) {
      if (!parameter.isNamed) continue;
      if (existingNamed.contains(parameter)) continue;

      _addProperty(properties, parameter, instanceCreation, null, null);
    }
  }

  void _addProperty(
    List<_PropertyDescription> properties,
    ParameterElement parameter,
    InstanceCreationExpression instanceCreation,
    Expression argumentExpression,
    Expression valueExpression,
  ) {
    String documentation;
    if (parameter is FieldFormalParameterElement) {
      var rawComment = parameter.field.documentationComment;
      documentation = getDartDocPlainText(rawComment);
    }

    String valueExpressionCode;
    if (valueExpression != null) {
      valueExpressionCode = resolvedUnit.content.substring(
        valueExpression.offset,
        valueExpression.end,
      );
    }

    var isSafeToUpdate = false;
    protocol.FlutterWidgetPropertyValue value;
    if (valueExpression != null) {
      if (valueExpression is BooleanLiteral) {
        isSafeToUpdate = true;
        value = protocol.FlutterWidgetPropertyValue(
          boolValue: valueExpression.value,
        );
      } else if (valueExpression is DoubleLiteral) {
        isSafeToUpdate = true;
        value = protocol.FlutterWidgetPropertyValue(
          doubleValue: valueExpression.value,
        );
      } else if (valueExpression is IntegerLiteral) {
        isSafeToUpdate = true;
        value = protocol.FlutterWidgetPropertyValue(
          intValue: valueExpression.value,
        );
      } else if (valueExpression is SimpleStringLiteral) {
        isSafeToUpdate = true;
        value = protocol.FlutterWidgetPropertyValue(
          stringValue: valueExpression.value,
        );
      }
    } else {
      isSafeToUpdate = true;
    }

    var id = _nextPropertyId++;
    properties.add(
      _PropertyDescription(
        resolvedUnit.path,
        instanceCreation,
        argumentExpression,
        valueExpression,
        parameter,
        protocol.FlutterWidgetProperty(
          id,
          parameter.isRequiredPositional,
          isSafeToUpdate,
          parameter.name,
          children: [], // TODO
          documentation: documentation,
          editor: _getEditor(parameter.type),
          expression: valueExpressionCode,
          value: value,
        ),
      ),
    );
  }

  protocol.FlutterWidgetPropertyEditor _getEditor(DartType type) {
    if (type.isDartCoreBool) {
      return protocol.FlutterWidgetPropertyEditor(
        protocol.FlutterWidgetPropertyEditorKind.BOOL,
      );
    }
    if (type.isDartCoreDouble) {
      return protocol.FlutterWidgetPropertyEditor(
        protocol.FlutterWidgetPropertyEditorKind.DOUBLE,
      );
    }
    if (type.isDartCoreInt) {
      return protocol.FlutterWidgetPropertyEditor(
        protocol.FlutterWidgetPropertyEditorKind.INT,
      );
    }
    if (type.isDartCoreString) {
      return protocol.FlutterWidgetPropertyEditor(
        protocol.FlutterWidgetPropertyEditorKind.STRING,
      );
    }
    return null;
  }
}
