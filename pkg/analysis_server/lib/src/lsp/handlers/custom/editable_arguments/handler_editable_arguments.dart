// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/custom/editable_arguments/editable_arguments_mixin.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// Information about the values for a parameter/argument.
typedef _Values = ({DartObject? parameterValue, DartObject? argumentValue});

class EditableArgumentsHandler
    extends SharedMessageHandler<TextDocumentPositionParams, EditableArguments?>
    with EditableArgumentsMixin {
  EditableArgumentsHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.dartTextDocumentEditableArguments;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<EditableArguments?>> handle(
    TextDocumentPositionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var textDocument = params.textDocument;
    var position = params.position;

    var filePath = pathOfDoc(textDocument);
    var result = await filePath.mapResult(requireResolvedUnit);
    var docIdentifier = filePath.mapResultSync(
      (filePath) => success(extractDocumentVersion(textDocument, filePath)),
    );
    var offset = result.mapResultSync(
      (result) => toOffset(result.lineInfo, position),
    );

    return await (filePath, result, docIdentifier, offset).mapResults((
      filePath,
      result,
      docIdentifier,
      offset,
    ) async {
      // Check for document changes or cancellation after the awaits above.
      if (fileHasBeenModified(filePath, docIdentifier.version)) {
        return fileModifiedError;
      } else if (token.isCancellationRequested) {
        return cancelled(token);
      }

      // Compute the editable arguments for an invocation at `offset`.
      var editableArguments = _getEditableArguments(
        result,
        textDocument,
        offset,
      );

      return success(editableArguments);
    });
  }

  /// Computes the [EditableArguments] for an invocation at `offset`.
  ///
  /// Returns `null` if there is no suitable invocation at this location.
  EditableArguments? _getEditableArguments(
    ResolvedUnitResult result,
    TextDocumentIdentifier textDocument,
    int offset,
  ) {
    var invocationInfo = getInvocationInfo(result, offset);
    if (invocationInfo == null) {
      return null;
    }

    var textDocument = server.getVersionedDocumentIdentifier(result.path);

    var (
      :invocation,
      :widgetName,
      :widgetDocumentation,
      :parameters,
      :positionalParameterIndexes,
      :parameterArguments,
      :argumentList,
      :numPositionals,
      :numSuppliedPositionals,
    ) = invocationInfo;

    // Build the complete list of editable arguments.
    //
    // Arguments should be returned in the order of the parameters in the source
    // code. This keeps things consistent across different instances of the same
    // Widget class and prevents the order from changing as a user adds/removes
    // arguments.
    //
    // If an editor wants to sort provided arguments first (and keep these stable
    // across add/removes) it could still do so client-side, whereas if server
    // orders them that way, the opposite (using source-order) is not possible.
    var editableArguments = [
      for (var parameter in parameters)
        _toEditableArgument(
          result,
          parameter,
          parameterArguments[parameter],
          positionalIndex: positionalParameterIndexes[parameter],
          numPositionals: numPositionals,
          numSuppliedPositionals: numSuppliedPositionals,
        ),
    ];

    return EditableArguments(
      textDocument: textDocument,
      name: widgetName,
      documentation: widgetDocumentation,
      arguments: editableArguments.nonNulls.toList(),
      range: toRange(result.lineInfo, invocation.offset, invocation.length),
    );
  }

  /// Computes the values for a parameter and argument and returns them along
  /// with a flag indicating if the default parameter value is being used.
  _Values _getValues(
    FormalParameterElement parameter,
    Expression? argumentExpression,
  ) {
    var parameterValue = parameter.computeConstantValue();
    var argumentValue = argumentExpression?.computeConstantValue()?.value;

    return (parameterValue: parameterValue, argumentValue: argumentValue);
  }

  /// Converts a [parameter]/[argument] pair into an [EditableArgument] if it
  /// is an argument that can be edited.
  EditableArgument? _toEditableArgument(
    ResolvedUnitResult result,
    FormalParameterElement parameter,
    Expression? argument, {
    int? positionalIndex,
    required int numPositionals,
    required int numSuppliedPositionals,
  }) {
    var valueExpression = argument is NamedExpression
        ? argument.expression
        : argument;

    // Lazily compute the values if we will use this parameter/argument.
    late var values = _getValues(parameter, valueExpression);

    String? type;
    Object? value;
    Object? defaultValue;
    List<String>? options;

    // Determine whether a value for this parameter is editable.
    var notEditableReason = getNotEditableReason(
      argument: valueExpression,
      positionalIndex: positionalIndex,
      numPositionals: numPositionals,
      numSuppliedPositionals: numSuppliedPositionals,
    );

    if (parameter.type.isDartCoreDouble) {
      type = 'double';
      value =
          values.argumentValue?.toDoubleValue() ??
          values.argumentValue?.toIntValue();
      defaultValue =
          values.parameterValue?.toDoubleValue() ??
          values.parameterValue?.toIntValue();
    } else if (parameter.type.isDartCoreInt) {
      type = 'int';
      value = values.argumentValue?.toIntValue();
      defaultValue = values.parameterValue?.toIntValue();
    } else if (parameter.type.isDartCoreBool) {
      type = 'bool';
      value = values.argumentValue?.toBoolValue();
      defaultValue = values.parameterValue?.toBoolValue();
    } else if (parameter.type.isDartCoreString) {
      type = 'string';
      value = values.argumentValue?.toStringValue();
      defaultValue = values.parameterValue?.toStringValue();
    } else if (parameter.type case InterfaceType(:EnumElement element)) {
      type = 'enum';
      options = getQualifiedEnumConstantNames(element);
      value = values.argumentValue?.toEnumStringValue(element);
      defaultValue = values.parameterValue?.toEnumStringValue(element);
    } else {
      // TODO(dantup): Determine which parameters we don't include (such as
      //  Widgets) and which we include just without values.
      return null;
    }

    var isEditable = notEditableReason == null;

    // Compute a displayValue.
    String? displayValue;
    if (!isEditable) {
      // Not editable, so show the value or source in displayValue.
      displayValue = value?.toString() ?? valueExpression?.toSource();
      // And remove the value.
      value = null;
    } else if (valueExpression is! Literal) {
      // Also provide the source if it was not a literal.
      displayValue = valueExpression?.toSource();
    }

    // Never provide a displayValue if it's the same as value.
    if (displayValue == value) {
      displayValue = null;
    }

    var documentation = getDocumentation(result, parameter);

    return EditableArgument(
      name: parameter.displayName,
      documentation: documentation,
      type: type,
      value: value,
      displayValue: displayValue,
      options: options,
      defaultValue: defaultValue,
      hasArgument: valueExpression != null,
      isRequired: parameter.isRequired,
      isNullable:
          parameter.type.nullabilitySuffix == NullabilitySuffix.question,
      isDeprecated: parameter.isDeprecatedWithKind('use'),
      isEditable: notEditableReason == null,
      notEditableReason: notEditableReason,
    );
  }
}

extension on DartObject? {
  Object? toEnumStringValue(EnumElement element) {
    var valueObject = this;
    if (valueObject?.type case InterfaceType(
      element: EnumElement valueElement,
    ) when element == valueElement) {
      var index = valueObject?.getField('index')?.toIntValue();
      if (index != null) {
        var enumConstant = element.constants.elementAtOrNull(index);
        if (enumConstant != null) {
          return EditableArgumentsMixin.getQualifiedEnumConstantName(
            enumConstant,
          );
        }
      }
    }
    return null;
  }
}
