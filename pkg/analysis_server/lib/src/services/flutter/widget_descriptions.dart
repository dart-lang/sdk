// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/flutter/class_description.dart';
import 'package:analysis_server/src/services/flutter/property.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/util/comment.dart';

/// The result of [WidgetDescriptions.setPropertyValue] invocation.
class SetPropertyValueResult {
  /// The error to report to the client, or `null` if OK.
  final protocol.RequestErrorCode errorCode;

  /// The change to apply, or `null` if [errorCode] is not `null`.
  final protocol.SourceChange change;

  SetPropertyValueResult._({this.errorCode, this.change});
}

class WidgetDescriptions {
  final ClassDescriptionRegistry _classRegistry = ClassDescriptionRegistry();

  /// The mapping of identifiers of previously returned properties.
  final Map<int, PropertyDescription> _properties = {};

  /// Return the description of the widget with [InstanceCreationExpression] in
  /// the [resolvedUnit] at the [offset], or `null` if the location does not
  /// correspond to a widget.
  Future<protocol.FlutterGetWidgetDescriptionResult> getDescription(
    ResolvedUnitResult resolvedUnit,
    int offset,
  ) async {
    var computer = _WidgetDescriptionComputer(
      _classRegistry,
      resolvedUnit,
      offset,
    );
    var widgetDescription = await computer.compute();

    if (widgetDescription == null) {
      return null;
    }

    var protocolProperties = _toProtocolProperties(
      widgetDescription.properties,
    );
    return protocol.FlutterGetWidgetDescriptionResult(protocolProperties);
  }

  Future<SetPropertyValueResult> setPropertyValue(
    int id,
    protocol.FlutterWidgetPropertyValue value,
  ) async {
    var property = _properties[id];
    if (property == null) {
      return SetPropertyValueResult._(
        errorCode: protocol
            .RequestErrorCode.FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID,
      );
    }

    if (value == null) {
      if (property.protocolProperty.isRequired) {
        return SetPropertyValueResult._(
          errorCode: protocol
              .RequestErrorCode.FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED,
        );
      }
      var change = await property.removeValue();
      return SetPropertyValueResult._(change: change);
    } else {
      var change = await property.changeValue(value);
      return SetPropertyValueResult._(change: change);
    }
  }

  List<protocol.FlutterWidgetProperty> _toProtocolProperties(
    List<PropertyDescription> properties,
  ) {
    var protocolProperties = <protocol.FlutterWidgetProperty>[];
    for (var property in properties) {
      var protocolProperty = property.protocolProperty;

      _properties[protocolProperty.id] = property;

      protocolProperty.children = _toProtocolProperties(property.children);
      protocolProperties.add(protocolProperty);
    }
    return protocolProperties;
  }
}

class _WidgetDescription {
  final List<PropertyDescription> properties;

  _WidgetDescription(this.properties);
}

class _WidgetDescriptionComputer {
  static int _nextPropertyId = 0;

  final ClassDescriptionRegistry classRegistry;

  /// The set of classes for which we are currently adding properties,
  /// used to prevent infinite recursion.
  final Set<ClassElement> classesBeingProcessed = Set<ClassElement>();

  /// The resolved unit with the widget [InstanceCreationExpression].
  final ResolvedUnitResult resolvedUnit;

  /// The offset of the widget expression.
  final int widgetOffset;

  /// The instance of [Flutter] support.
  final Flutter flutter;

  _WidgetDescriptionComputer(
    this.classRegistry,
    this.resolvedUnit,
    this.widgetOffset,
  ) : flutter = Flutter.of(resolvedUnit);

  Future<_WidgetDescription> compute() async {
    var node = NodeLocator2(widgetOffset).searchWithin(resolvedUnit.unit);
    var instanceCreation = flutter.identifyNewExpression(node);
    if (instanceCreation == null) {
      return null;
    }

    var constructorElement = instanceCreation.staticElement;
    if (constructorElement == null) {
      return null;
    }

    var properties = <PropertyDescription>[];
    _addProperties(
      properties: properties,
      instanceCreation: instanceCreation,
    );
    _addContainerProperty(properties, instanceCreation);

    return _WidgetDescription(properties);
  }

  void _addContainerProperty(
    List<PropertyDescription> properties,
    InstanceCreationExpression widgetCreation,
  ) {
    if (!flutter.isWidgetCreation(widgetCreation)) {
      return;
    }

    var childArgument = widgetCreation.parent;
    if (childArgument is NamedExpression &&
        childArgument.name.label.name == 'child') {
      var argumentList = childArgument.parent;
      var parentCreation = argumentList.parent;
      if (argumentList is ArgumentList &&
          parentCreation is InstanceCreationExpression) {
        if (flutter.isExactlyContainerCreation(parentCreation)) {
          var id = _nextPropertyId++;
          var containerProperty = PropertyDescription(
            null,
            resolvedUnit,
            null,
            parentCreation,
            null,
            null,
            null,
            protocol.FlutterWidgetProperty(id, true, false, 'Container'),
          );
          properties.add(containerProperty);

          _addProperties(
            properties: containerProperty.children,
            parent: containerProperty,
            instanceCreation: parentCreation,
          );

          containerProperty.children.removeWhere(
            (property) => property.protocolProperty.name == 'child',
          );
        }
      }
    }
  }

  void _addProperties({
    List<PropertyDescription> properties,
    PropertyDescription parent,
    ClassDescription classDescription,
    InstanceCreationExpression instanceCreation,
    ConstructorElement constructorElement,
  }) {
    constructorElement ??= instanceCreation?.staticElement;
    if (constructorElement == null) return;

    var classElement = constructorElement.enclosingElement;
    if (!classesBeingProcessed.add(classElement)) return;

    var existingNamed = Set<ParameterElement>();
    if (instanceCreation != null) {
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
          properties: properties,
          parent: parent,
          parameter: parameter,
          classDescription: classDescription,
          instanceCreation: instanceCreation,
          argumentExpression: argumentExpression,
          valueExpression: valueExpression,
        );
      }
    }

    for (var parameter in constructorElement.parameters) {
      if (!parameter.isNamed) continue;
      if (existingNamed.contains(parameter)) continue;

      _addProperty(
        properties: properties,
        parent: parent,
        parameter: parameter,
        classDescription: classDescription,
        instanceCreation: instanceCreation,
      );
    }

    classesBeingProcessed.remove(classElement);
  }

  void _addProperty({
    List<PropertyDescription> properties,
    PropertyDescription parent,
    ParameterElement parameter,
    ClassDescription classDescription,
    InstanceCreationExpression instanceCreation,
    Expression argumentExpression,
    Expression valueExpression,
  }) {
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
      value = _toValue(valueExpression);
      isSafeToUpdate = value != null;
    } else {
      isSafeToUpdate = true;
    }

    var id = _nextPropertyId++;
    var propertyDescription = PropertyDescription(
      parent,
      resolvedUnit,
      classDescription,
      instanceCreation,
      argumentExpression,
      valueExpression,
      parameter,
      protocol.FlutterWidgetProperty(
        id,
        parameter.isRequiredPositional,
        isSafeToUpdate,
        parameter.name,
        documentation: documentation,
        editor: _getEditor(parameter.type),
        expression: valueExpressionCode,
        value: value,
      ),
    );
    properties.add(propertyDescription);

    if (valueExpression is InstanceCreationExpression) {
      var type = valueExpression.staticType;
      if (classRegistry.hasNestedProperties(type)) {
        _addProperties(
          properties: propertyDescription.children,
          parent: propertyDescription,
          instanceCreation: valueExpression,
        );
      }
    } else if (valueExpression == null) {
      var classDescription = classRegistry.get(
        parameter.type,
      );
      if (classDescription != null) {
        _addProperties(
          properties: propertyDescription.children,
          parent: propertyDescription,
          classDescription: classDescription,
          constructorElement: classDescription.constructor,
        );
      }
    }
  }

  List<protocol.FlutterWidgetPropertyValueEnumItem> _enumItemsForEnum(
    ClassElement element,
  ) {
    return element.fields
        .where((field) => field.isStatic && field.isEnumConstant)
        .map(_toEnumItem)
        .toList();
  }

  List<protocol.FlutterWidgetPropertyValueEnumItem> _enumItemsForStaticFields(
      ClassElement classElement) {
    return classElement.fields
        .where((f) => f.isStatic)
        .map(_toEnumItem)
        .toList();
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
    if (type is InterfaceType) {
      var classElement = type.element;
      if (classElement.isEnum) {
        return protocol.FlutterWidgetPropertyEditor(
          protocol.FlutterWidgetPropertyEditorKind.ENUM,
          enumItems: _enumItemsForEnum(classElement),
        );
      }
    }
    return null;
  }

  protocol.FlutterWidgetPropertyValueEnumItem _toEnumItem(FieldElement field) {
    var classElement = field.enclosingElement as ClassElement;
    var libraryUriStr = '${classElement.library.source.uri}';

    var rawComment = field.documentationComment;
    var documentation = getDartDocPlainText(rawComment);

    return protocol.FlutterWidgetPropertyValueEnumItem(
      libraryUriStr,
      classElement.name,
      field.name,
      documentation: documentation,
    );
  }

  protocol.FlutterWidgetPropertyValue _toValue(Expression valueExpression) {
    if (valueExpression is BooleanLiteral) {
      return protocol.FlutterWidgetPropertyValue(
        boolValue: valueExpression.value,
      );
    } else if (valueExpression is DoubleLiteral) {
      return protocol.FlutterWidgetPropertyValue(
        doubleValue: valueExpression.value,
      );
    } else if (valueExpression is Identifier) {
      var element = valueExpression.staticElement;
      if (element is PropertyAccessorElement && element.isGetter) {
        var field = element.variable;
        if (field is FieldElement && field.isStatic) {
          var enclosingClass = field.enclosingElement as ClassElement;
          if (field.isEnumConstant) {
            return protocol.FlutterWidgetPropertyValue(
              enumValue: _toEnumItem(field),
            );
          }
        }
      }
    } else if (valueExpression is IntegerLiteral) {
      return protocol.FlutterWidgetPropertyValue(
        intValue: valueExpression.value,
      );
    } else if (valueExpression is SimpleStringLiteral) {
      return protocol.FlutterWidgetPropertyValue(
        stringValue: valueExpression.value,
      );
    }
    return null;
  }
}
