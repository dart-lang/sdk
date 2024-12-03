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
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/lint/constants.dart';

/// Information about the values for a parameter/argument.
typedef _Values =
    ({bool isDefault, DartObject? parameterValue, DartObject? argumentValue});

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
    var invocation = getInvocationInfo(result, offset);
    if (invocation == null) {
      return null;
    }

    var textDocument = server.getVersionedDocumentIdentifier(result.path);

    var (
      :parameters,
      :positionalParameterIndexes,
      :parameterArguments,
      :argumentList,
      :numPositionals,
      :numSuppliedPositionals,
    ) = invocation;

    // Build the complete list of editable arguments.
    var editableArguments = [
      // First arguments that exist in the order they were specified.
      for (var MapEntry(key: parameter, value: argument)
          in parameterArguments.entries)
        _toEditableArgument(
          parameter,
          argument,
          numPositionals: numPositionals,
          numSuppliedPositionals: numSuppliedPositionals,
        ),
      // Then the remaining parameters that don't have existing arguments.
      for (var parameter in parameters.where(
        (p) => !parameterArguments.containsKey(p),
      ))
        _toEditableArgument(
          parameter,
          null,
          positionalIndex: positionalParameterIndexes[parameter],
          numPositionals: numPositionals,
          numSuppliedPositionals: numSuppliedPositionals,
        ),
    ];

    return EditableArguments(
      textDocument: textDocument,
      arguments: editableArguments.nonNulls.toList(),
    );
  }

  /// Computes the values for a parameter and argument and returns them along
  /// with a flag indicating if the default parameter value is being used.
  _Values _getValues(
    FormalParameterElement parameter,
    Expression? argumentExpression,
  ) {
    var parameterValue = parameter.computeConstantValue();
    var argumentValue = argumentExpression?.computeConstantValue().value;

    var isDefault =
        argumentValue == null ||
        ((parameterValue?.hasKnownValue ?? false) &&
            (argumentValue.hasKnownValue) &&
            parameterValue == argumentValue);

    return (
      isDefault: isDefault,
      parameterValue: parameterValue,
      argumentValue: argumentValue,
    );
  }

  /// Converts a [parameter]/[argument] pair into an [EditableArgument] if it
  /// is an argument that can be edited.
  EditableArgument? _toEditableArgument(
    FormalParameterElement parameter,
    Expression? argument, {
    int? positionalIndex,
    required int numPositionals,
    required int numSuppliedPositionals,
  }) {
    var valueExpression =
        argument is NamedExpression ? argument.expression : argument;

    // Lazily compute the values if we will use this parameter/argument.
    late var values = _getValues(parameter, valueExpression);

    String? type;
    Object? value;
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
          (values.argumentValue ?? values.parameterValue)?.toDoubleValue() ??
          (values.argumentValue ?? values.parameterValue)?.toIntValue();
    } else if (parameter.type.isDartCoreInt) {
      type = 'int';
      value = (values.argumentValue ?? values.parameterValue)?.toIntValue();
    } else if (parameter.type.isDartCoreBool) {
      type = 'bool';
      value = (values.argumentValue ?? values.parameterValue)?.toBoolValue();
    } else if (parameter.type.isDartCoreString) {
      type = 'string';
      value = (values.argumentValue ?? values.parameterValue)?.toStringValue();
    } else if (parameter.type case InterfaceType(:EnumElement2 element3)) {
      type = 'enum';
      options = getQualifiedEnumConstantNames(element3);

      // Try to match the argument value up with the enum.
      var valueObject = values.argumentValue ?? values.parameterValue;
      if (valueObject?.type case InterfaceType(
        element3: EnumElement2 valueElement,
      ) when element3 == valueElement) {
        var index = valueObject?.getField('index')?.toIntValue();
        if (index != null) {
          var enumConstant = element3.constants2.elementAtOrNull(index);
          if (enumConstant != null) {
            value = getQualifiedEnumConstantName(enumConstant);
          }
        }
      }
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

    return EditableArgument(
      name: parameter.displayName,
      type: type,
      value: value,
      displayValue: displayValue,
      options: options,
      isDefault: values.isDefault,
      hasArgument: valueExpression != null,
      isRequired: parameter.isRequired,
      isNullable:
          parameter.type.nullabilitySuffix == NullabilitySuffix.question,
      isEditable: notEditableReason == null,
      notEditableReason: notEditableReason,
    );
  }
}
