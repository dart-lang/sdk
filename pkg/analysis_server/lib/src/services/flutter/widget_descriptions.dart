// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/flutter/class_description.dart';
import 'package:analysis_server/src/services/flutter/property.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:dart_style/dart_style.dart';

/// The result of [WidgetDescriptions.setPropertyValue] invocation.
class SetPropertyValueResult {
  /// The error to report to the client, or `null` if OK.
  final protocol.RequestErrorCode? errorCode;

  /// The change to apply, or `null` if [errorCode] is not `null`.
  final protocol.SourceChange? change;

  SetPropertyValueResult._({this.errorCode, this.change});
}

class WidgetDescriptions {
  final ClassDescriptionRegistry _classRegistry = ClassDescriptionRegistry();

  /// The mapping of identifiers of previously returned properties.
  final Map<int, PropertyDescription> _properties = {};

  /// Flush all data, because there was a change to a file.
  void flush() {
    _classRegistry.flush();
    _properties.clear();
  }

  /// Return the description of the widget with [InstanceCreationExpression] in
  /// the [resolvedUnit] at the [offset], or `null` if the location does not
  /// correspond to a widget.
  Future<protocol.FlutterGetWidgetDescriptionResult?> getDescription(
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
    protocol.FlutterWidgetPropertyValue? value,
  ) async {
    var property = _properties[id];
    if (property == null) {
      return SetPropertyValueResult._(
        errorCode:
            protocol
                .RequestErrorCode
                .FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID,
      );
    }

    if (value == null) {
      if (property.protocolProperty.isRequired) {
        return SetPropertyValueResult._(
          errorCode:
              protocol
                  .RequestErrorCode
                  .FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED,
        );
      }
      var change = await property.removeValue();
      return SetPropertyValueResult._(change: change);
    } else {
      try {
        var change = await property.changeValue(value);
        return SetPropertyValueResult._(change: change);
      } on FormatterException {
        return SetPropertyValueResult._(
          errorCode:
              protocol
                  .RequestErrorCode
                  .FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION,
        );
      }
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
  final ClassDescriptionRegistry classRegistry;

  /// The set of classes for which we are currently adding properties,
  /// used to prevent infinite recursion.
  final Set<InterfaceElement> elementsBeingProcessed = {};

  /// The resolved unit with the widget [InstanceCreationExpression].
  final ResolvedUnitResult resolvedUnit;

  /// The offset of the widget expression.
  final int widgetOffset;

  ClassElement? _classAlignment;
  ClassElement? _classAlignmentDirectional;
  ClassElement? _classContainer;
  ClassElement? _classEdgeInsets;

  _WidgetDescriptionComputer(
    this.classRegistry,
    this.resolvedUnit,
    this.widgetOffset,
  );

  Future<_WidgetDescription?> compute() async {
    var node = resolvedUnit.unit.nodeCovering(offset: widgetOffset);
    if (node == null) {
      return null;
    }
    var instanceCreation = node.findInstanceCreationExpression;
    if (instanceCreation == null) {
      return null;
    }

    var constructorElement = instanceCreation.constructorName.element;
    if (constructorElement == null) {
      return null;
    }

    await _fetchClassElements();

    var properties = <PropertyDescription>[];
    _addProperties(properties: properties, instanceCreation: instanceCreation);
    _addContainerProperty(properties, instanceCreation);

    return _WidgetDescription(properties);
  }

  void _addContainerProperty(
    List<PropertyDescription> properties,
    InstanceCreationExpression widgetCreation,
  ) {
    if (!widgetCreation.isWidgetCreation) {
      return;
    }

    InstanceCreationExpression? parentCreation;
    var childArgument = widgetCreation.parent;
    if (childArgument is NamedExpression &&
        childArgument.name.label.name == 'child') {
      var argumentList = childArgument.parent;
      var argumentListParent = argumentList?.parent;
      if (argumentList is ArgumentList &&
          argumentListParent is InstanceCreationExpression) {
        parentCreation = argumentListParent;
      }
    }

    PropertyDescription containerProperty;
    if (parentCreation?.isExactlyContainerCreation ?? false) {
      containerProperty = PropertyDescription(
        resolvedUnit: resolvedUnit,
        instanceCreation: parentCreation,
        protocolProperty: protocol.FlutterWidgetProperty(
          PropertyDescription.nextId(),
          true,
          false,
          'Container',
        ),
      );
      properties.add(containerProperty);

      _addProperties(
        properties: containerProperty.children,
        parent: containerProperty,
        instanceCreation: parentCreation,
      );

      containerProperty.children.removeWhere(
        (property) => property.name == 'child',
      );
    } else {
      var classContainer = _classContainer;
      if (classContainer == null) {
        return;
      }
      var containerDescription = classRegistry.get(classContainer);
      containerProperty = PropertyDescription(
        resolvedUnit: resolvedUnit,
        classDescription: containerDescription,
        protocolProperty: protocol.FlutterWidgetProperty(
          PropertyDescription.nextId(),
          true,
          false,
          'Container',
        ),
        virtualContainer: VirtualContainerProperty(
          classContainer,
          widgetCreation,
        ),
      );
      properties.add(containerProperty);

      _addProperties(
        properties: containerProperty.children,
        parent: containerProperty,
        classDescription: containerDescription,
      );

      if (parentCreation != null &&
          parentCreation.isExactlyAlignCreation &&
          parentCreation.argumentList.byName('widthFactor') == null &&
          parentCreation.argumentList.byName('heightFactor') == null) {
        _replaceNestedContainerProperty(
          containerProperty,
          parentCreation,
          'alignment',
        );
      }

      if (parentCreation != null && parentCreation.isExactlyPaddingCreation) {
        _replaceNestedContainerProperty(
          containerProperty,
          parentCreation,
          'padding',
        );
      }
    }

    containerProperty.children.removeWhere(
      (property) => property.name == 'child',
    );
  }

  void _addProperties({
    required List<PropertyDescription> properties,
    PropertyDescription? parent,
    ClassDescription? classDescription,
    InstanceCreationExpression? instanceCreation,
    ConstructorElement? constructorElement,
  }) {
    constructorElement ??= instanceCreation?.constructorName.element;
    constructorElement ??= classDescription?.constructor;
    if (constructorElement == null) return;

    var enclosingElement = constructorElement.enclosingElement;
    if (!elementsBeingProcessed.add(enclosingElement)) return;

    var existingNamed = <String>{};
    if (instanceCreation != null) {
      for (var argumentExpression in instanceCreation.argumentList.arguments) {
        var parameter = argumentExpression.correspondingParameter;
        if (parameter == null) continue;

        Expression valueExpression;
        if (argumentExpression is NamedExpression) {
          valueExpression = argumentExpression.expression;
          existingNamed.add(parameter.name!);
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

    for (var parameter in constructorElement.formalParameters) {
      if (!parameter.isNamed) continue;
      if (existingNamed.contains(parameter.name)) continue;

      _addProperty(
        properties: properties,
        parent: parent,
        parameter: parameter,
        classDescription: classDescription,
        instanceCreation: instanceCreation,
      );
    }

    elementsBeingProcessed.remove(enclosingElement);
  }

  void _addProperty({
    required List<PropertyDescription> properties,
    PropertyDescription? parent,
    required FormalParameterElement parameter,
    ClassDescription? classDescription,
    InstanceCreationExpression? instanceCreation,
    Expression? argumentExpression,
    Expression? valueExpression,
  }) {
    var documentation = getParameterDocumentation(parameter);

    String? valueExpressionCode;
    if (valueExpression != null) {
      valueExpressionCode = resolvedUnit.content.substring(
        valueExpression.offset,
        valueExpression.end,
      );
    }

    var isSafeToUpdate = false;
    protocol.FlutterWidgetPropertyValue? value;
    if (valueExpression != null) {
      value = _toValue(valueExpression);
      isSafeToUpdate = value != null;
    } else {
      isSafeToUpdate = true;
    }

    var propertyDescription = PropertyDescription(
      parent: parent,
      resolvedUnit: resolvedUnit,
      classDescription: classDescription,
      instanceCreation: instanceCreation,
      argumentExpression: argumentExpression,
      valueExpression: valueExpression,
      parameterElement: parameter,
      protocolProperty: protocol.FlutterWidgetProperty(
        PropertyDescription.nextId(),
        parameter.isRequiredPositional,
        isSafeToUpdate,
        parameter.name!,
        documentation: documentation,
        editor: _getEditor(parameter.type),
        expression: valueExpressionCode,
        value: value,
      ),
    );
    properties.add(propertyDescription);

    var classEdgeInsets = _classEdgeInsets;
    if (classEdgeInsets != null &&
        parameter.type.isExactEdgeInsetsGeometryType) {
      propertyDescription.addEdgeInsetsNestedProperties(classEdgeInsets);
    } else if (valueExpression is InstanceCreationExpression) {
      var type = valueExpression.staticType;
      if (type != null && classRegistry.hasNestedProperties(type)) {
        _addProperties(
          properties: propertyDescription.children,
          parent: propertyDescription,
          instanceCreation: valueExpression,
        );
      }
    } else if (valueExpression == null) {
      var type = parameter.type;
      if (type is InterfaceType) {
        var classDescription = classRegistry.get(type.element);
        if (classDescription != null) {
          _addProperties(
            properties: propertyDescription.children,
            parent: propertyDescription,
            classDescription: classDescription,
          );
        }
      }
    }
  }

  List<protocol.FlutterWidgetPropertyValueEnumItem> _enumItemsForEnum(
    EnumElement element,
  ) {
    return element.fields
        .where((field) => field.isStatic && field.isEnumConstant)
        .map(_toEnumItem)
        .toList();
  }

  List<protocol.FlutterWidgetPropertyValueEnumItem> _enumItemsForStaticFields(
    ClassElement classElement,
  ) {
    return classElement.fields
        .where((f) => f.isStatic)
        .map(_toEnumItem)
        .toList();
  }

  Future<void> _fetchClassElements() async {
    var sessionHelper = AnalysisSessionHelper(resolvedUnit.session);
    _classAlignment = await sessionHelper.getFlutterClass('Alignment');
    _classAlignmentDirectional = await sessionHelper.getFlutterClass(
      'AlignmentDirectional',
    );
    _classContainer = await sessionHelper.getFlutterClass('Container');
    _classEdgeInsets = await sessionHelper.getFlutterClass('EdgeInsets');
  }

  protocol.FlutterWidgetPropertyEditor? _getEditor(DartType type) {
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
      if (classElement is EnumElement) {
        return protocol.FlutterWidgetPropertyEditor(
          protocol.FlutterWidgetPropertyEditorKind.ENUM,
          enumItems: _enumItemsForEnum(classElement),
        );
      }
      if (classElement.isExactAlignmentGeometry) {
        var items = <protocol.FlutterWidgetPropertyValueEnumItem>[];
        var classAlignment = _classAlignment;
        if (classAlignment != null) {
          items.addAll(_enumItemsForStaticFields(classAlignment));
        }
        var classAlignmentDirectional = _classAlignmentDirectional;
        if (classAlignmentDirectional != null) {
          items.addAll(_enumItemsForStaticFields(classAlignmentDirectional));
        }
        return protocol.FlutterWidgetPropertyEditor(
          protocol.FlutterWidgetPropertyEditorKind.ENUM_LIKE,
          enumItems: items,
        );
      }
    }
    return null;
  }

  /// If the [parentCreation] has a property with the given [name], replace
  /// with it the corresponding nested property of the [containerProperty].
  void _replaceNestedContainerProperty(
    PropertyDescription containerProperty,
    InstanceCreationExpression parentCreation,
    String name,
  ) {
    var argument = parentCreation.argumentList.byName(name);
    if (argument != null) {
      var staticParameterElement = argument.correspondingParameter;
      if (staticParameterElement != null) {
        var replacements = <PropertyDescription>[];
        _addProperty(
          properties: replacements,
          parent: containerProperty,
          parameter: staticParameterElement,
          instanceCreation: parentCreation,
          argumentExpression: argument,
          valueExpression: argument.expression,
        );

        var replacement = replacements[0];
        containerProperty.replaceChild(name, replacement);
        containerProperty.virtualContainer?.setParentCreation(
          parentCreation,
          argument,
        );
      }
    }
  }

  protocol.FlutterWidgetPropertyValueEnumItem _toEnumItem(FieldElement field) {
    var interfaceElement = field.enclosingElement as InterfaceElement;
    var libraryUriStr = '${interfaceElement.enclosingElement.uri}';
    var documentation = getFieldDocumentation(field);

    return protocol.FlutterWidgetPropertyValueEnumItem(
      libraryUriStr,
      interfaceElement.name!,
      field.name!,
      documentation: documentation,
    );
  }

  protocol.FlutterWidgetPropertyValue? _toValue(Expression valueExpression) {
    if (valueExpression is BooleanLiteral) {
      return protocol.FlutterWidgetPropertyValue(
        boolValue: valueExpression.value,
      );
    } else if (valueExpression is DoubleLiteral) {
      return protocol.FlutterWidgetPropertyValue(
        doubleValue: valueExpression.value,
      );
    } else if (valueExpression is Identifier) {
      var element = valueExpression.element;
      if (element is GetterElement) {
        var field = element.variable;
        if (field is FieldElement && field.isStatic) {
          var enclosingClass = field.enclosingElement as InterfaceElement;
          if (field.isEnumConstant ||
              enclosingClass.isExactAlignment ||
              enclosingClass.isExactAlignmentDirectional) {
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
