// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/flutter/class_description.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class PropertyDescription {
  final PropertyDescription _parent;

  /// The resolved unit, where the property value is.
  final ResolvedUnitResult _resolvedUnit;

  /// If the object that has this property is not materialized yet, so the
  /// [_instanceCreation] is `null`, the description of the object to
  /// materialize.
  final ClassDescription _classDescription;

  /// The instance creation of the object that has this property. Or `null`
  /// if the object is not materialized yet, in this case [_classDescription]
  /// is set.
  final InstanceCreationExpression _instanceCreation;

  /// Information about the `Container` property, which is not based on an
  /// actual [_instanceCreation] of the `Container` widget, i.e. is not
  /// materialized.
  final VirtualContainerProperty virtualContainer;

  /// If the property is set, the full argument expression, might be a
  /// [NamedExpression].
  final Expression _argumentExpression;

  /// If the property is set, the value part of the argument expression,
  /// the same as [_argumentExpression] if a positional argument, or the
  /// expression part of the [NamedExpression].
  final Expression _valueExpression;

  /// The parameter element in the object constructor that is actually
  /// invoked by [_instanceCreation], or will be invoked when
  /// [_classDescription] is materialized.
  final ParameterElement _parameterElement;

  /// Optional nested properties.
  final List<PropertyDescription> children = [];

  final protocol.FlutterWidgetProperty protocolProperty;

  PropertyDescription(
    this._parent,
    this._resolvedUnit,
    this._classDescription,
    this._instanceCreation,
    this._argumentExpression,
    this._valueExpression,
    this._parameterElement,
    this.protocolProperty, {
    this.virtualContainer,
  });

  String get name => protocolProperty.name;

  Future<protocol.SourceChange> changeValue(
      protocol.FlutterWidgetPropertyValue value) async {
    var changeBuilder = DartChangeBuilder(_resolvedUnit.session);

    ClassElement enumClassElement;
    var enumValue = value.enumValue;
    if (enumValue != null) {
      var helper = AnalysisSessionHelper(_resolvedUnit.session);
      enumClassElement = await helper.getClass(
        enumValue.libraryUri,
        enumValue.className,
      );
    }

    await changeBuilder.addFileEdit(_resolvedUnit.path, (builder) {
      _changeCode(builder, (builder) {
        if (enumClassElement != null) {
          builder.writeReference(enumClassElement);
          builder.write('.');
          builder.write(enumValue.name);
        } else {
          var code = _toPrimitiveValueCode(value);
          builder.write(code);
        }
      });

      var functionBody = _enclosingFunctionBody();
      builder.format(range.node(functionBody));
    });

    return changeBuilder.sourceChange;
  }

  Future<protocol.SourceChange> removeValue() async {
    var changeBuilder = DartChangeBuilder(_resolvedUnit.session);

    if (_argumentExpression != null) {
      int endOffset;
      var argumentList = _instanceCreation.argumentList;
      var arguments = argumentList.arguments;
      var argumentIndex = arguments.indexOf(_argumentExpression);
      if (argumentIndex < arguments.length - 1) {
        endOffset = arguments[argumentIndex + 1].offset;
      } else {
        endOffset = argumentList.rightParenthesis.offset;
      }

      var beginOffset = _argumentExpression.offset;
      await changeBuilder.addFileEdit(_resolvedUnit.path, (builder) {
        builder.addDeletion(
          SourceRange(beginOffset, endOffset - beginOffset),
        );
      });
    }

    return changeBuilder.sourceChange;
  }

  void replaceChild(String name, PropertyDescription newChild) {
    assert(newChild._parent == this);
    for (var i = 0; i < children.length; i++) {
      if (children[i].name == 'alignment') {
        children[i] = newChild;
        break;
      }
    }
  }

  void _changeCode(
    DartFileEditBuilder builder,
    void buildCode(DartEditBuilder builder),
  ) {
    if (_valueExpression != null) {
      builder.addReplacement(range.node(_valueExpression), buildCode);
    } else {
      var parameterName = _parameterElement.name;
      if (_instanceCreation != null) {
        var argumentList = _instanceCreation.argumentList;

        var insertOffset = 0;
        for (var argument in _instanceCreation.argumentList.arguments) {
          if (argument is NamedExpression) {
            var argumentName = argument.name.label.name;
            if (argumentName.compareTo(parameterName) > 0) {
              insertOffset = argument.offset;
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
        if (_parent.virtualContainer != null) {
          _parent._changeCodeVirtualContainer(
              builder, parameterName, buildCode);
        } else {
          _parent._changeCode(builder, (builder) {
            builder.writeReference(_classDescription.element);
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
    void writeArgumentValue(DartEditBuilder builder),
  ) {
    builder.addInsertion(
      virtualContainer.widgetCreation.offset,
      (builder) {
        builder.writeReference(virtualContainer.containerElement);
        builder.write('(');

        builder.write(parameterName);
        builder.write(': ');
        writeArgumentValue(builder);
        builder.write(', ');
        // TODO(scheglov) move parent creation attribute, sorted

        builder.write('child: ');
      },
    );
    builder.addSimpleInsertion(virtualContainer.widgetCreation.end, ',)');
  }

  FunctionBody _enclosingFunctionBody() {
    if (_parent != null) {
      return _parent._enclosingFunctionBody();
    }
    var anchorExpr = virtualContainer?.widgetCreation ?? _instanceCreation;
    return anchorExpr.thisOrAncestorOfType<FunctionBody>();
  }

  String _toPrimitiveValueCode(protocol.FlutterWidgetPropertyValue value) {
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

    throw StateError('Not a primitive value: $value');
  }
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
