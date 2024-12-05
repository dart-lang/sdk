// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/custom/editable_arguments/editable_arguments_mixin.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:collection/collection.dart';

class EditArgumentHandler extends SharedMessageHandler<EditArgumentParams, Null>
    with EditableArgumentsMixin {
  EditArgumentHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.dartTextDocumentEditArgument;

  @override
  LspJsonHandler<EditArgumentParams> get jsonHandler =>
      EditArgumentParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<Null>> handle(
    EditArgumentParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var editorClientCapabilities = server.editorClientCapabilities;
    if (editorClientCapabilities == null) {
      return serverNotInitializedError;
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

      // Locate the invocation we're editing.
      var invocation = getInvocationInfo(result, offset);
      if (invocation == null) {
        return error(
          ErrorCodes.RequestFailed,
          'No invocation was found at the position',
        );
      }

      var (
        :parameters,
        :positionalParameterIndexes,
        :parameterArguments,
        :argumentList,
        :numPositionals,
        :numSuppliedPositionals,
      ) = invocation;

      // Find the parameter we're editing the argument for.
      var name = params.edit.name;
      var parameter = parameters.firstWhereOrNull((p) => p.name3 == name);
      if (parameter == null) {
        return error(
          ErrorCodes.RequestFailed,
          'Parameter "$name" was not found in ${parameters.map((p) => p.name3).join(', ')}',
        );
      }

      // Determine whether a value for this parameter is editable.
      var notEditableReason = getNotEditableReason(
        argument: parameterArguments[parameter],
        positionalIndex: positionalParameterIndexes[parameter],
        numPositionals: numPositionals,
        numSuppliedPositionals: numSuppliedPositionals,
      );
      if (notEditableReason != null) {
        // This should never happen unless a client is broken, because either
        // they should have failed the version check, or they would've already
        // known this argument was not editable.
        return error(
          ErrorCodes.RequestFailed,
          "Parameter '$name' is not editable: $notEditableReason",
        );
      }

      // Compute the new expression for this argument.
      var newValueCode = _computeValueCode(parameter, params.edit);

      // Build the edit and send it to the client.
      var workspaceEdit = await newValueCode.mapResult(
        (newValueCode) => _computeWorkspaceEdit(
          docIdentifier,
          // We use the editors capabilities here, not the caller, because it's
          // the editor that will handle this edit.
          editorClientCapabilities,
          result,
          parameters,
          argumentList,
          parameter,
          newValueCode,
        ),
      );
      return workspaceEdit.mapResult(_sendEditToClient);
    });
  }

  /// Computes the string of Dart code (including quotes) for [value].
  String _computeStringValueCode(String value) {
    const singleQuote = "'";
    const doubleQuote = '"';

    // Use single quotes unless the string contains a single quote and no
    // double quotes.
    var surroundingQuote =
        value.contains(singleQuote) && !value.contains(doubleQuote)
            ? doubleQuote
            : singleQuote;

    // TODO(dantup): Determine if we already have reusable code for this
    //  anywhere.
    // TODO(dantup): Decide whether we should write multiline and/or raw strings
    //  for some cases.
    var escaped = value
        .replaceAll(r'\', r'\\') // Escape backslashes
        .replaceAll(
          surroundingQuote,
          '\\$surroundingQuote',
        ) // Escape surrounding quotes we'll use
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n')
        .replaceAll(r'$', r'\$');

    return '$surroundingQuote$escaped$surroundingQuote';
  }

  /// Computes the string of Dart code that should be used as the new value
  /// for this argument.
  ///
  /// This is purely the expression for the value and does not take into account
  /// the parameter name or any commas that may be required.
  ErrorOr<String> _computeValueCode(
    FormalParameterElement parameter,
    ArgumentEdit edit,
  ) {
    // TODO(dantup): Should we accept arbitrary strings for all values? For
    //  example can the user choose "MyClass.foo" as the value for an integer
    //  in the editor?

    var value = edit.newValue;
    var type = parameter.type;

    // Handle nulls for all types.
    if (value == null) {
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        return success('null');
      } else {
        return error(
          ErrorCodes.RequestFailed,
          'Value for non-nullable parameter "${edit.name}" cannot be null',
        );
      }
    }

    if (type.isDartCoreDouble && (value is double || value is int)) {
      return success(value.toString());
    } else if (type.isDartCoreInt && value is int) {
      return success(value.toString());
    } else if (type.isDartCoreBool && value is bool) {
      return success(value.toString());
    } else if (type.isDartCoreString && value is String) {
      return success(_computeStringValueCode(value));
    } else if (type case InterfaceType(
      :EnumElement2 element3,
    ) when value is String?) {
      var allowedValues = getQualifiedEnumConstantNames(element3);
      if (allowedValues.contains(value)) {
        return success(value.toString());
      } else {
        return error(
          ErrorCodes.RequestFailed,
          'Value for parameter "${edit.name}" should be one of ${allowedValues.map((v) => '"$v"').join(', ')} but was "$value"',
        );
      }
    } else {
      return error(
        ErrorCodes.RequestFailed,
        'Value for parameter "${edit.name}" should be $type but was ${value.runtimeType}',
      );
    }
  }

  /// Computes a [WorkspaceEdit] to update [textDocument]/[result] so that
  /// [newValueCode] is provided for [parameter] in [argumentList].
  Future<ErrorOr<WorkspaceEdit>> _computeWorkspaceEdit(
    OptionalVersionedTextDocumentIdentifier textDocument,
    LspClientCapabilities editorClientCapabilities,
    ResolvedUnitResult result,
    List<FormalParameterElement> parameters,
    ArgumentList argumentList,
    FormalParameterElement parameter,
    String newValueCode,
  ) async {
    var argument = argumentList.arguments.firstWhereOrNull(
      (arg) => arg.correspondingParameter == parameter,
    );

    var changeBuilder = ChangeBuilder(session: result.session);
    await changeBuilder.addDartFileEdit(result.path, (builder) {
      if (argument == null) {
        _writeNewArgument(
          builder,
          parameters,
          argumentList,
          parameter,
          newValueCode,
        );
      } else {
        _writeChangedArgument(builder, argument, newValueCode);
      }
    });

    // It is a bug if we produced edits in some file other than the one we
    // expect.
    var fileEdits = changeBuilder.sourceChange.edits;
    var otherFilesEdited =
        fileEdits
            .map((edit) => edit.file)
            .where((file) => file != result.path)
            .toSet();
    if (otherFilesEdited.isNotEmpty) {
      var otherNames = otherFilesEdited.join(', ');
      throw 'Argument edit for ${result.path} unexpectedly produced edits for $otherNames';
    }

    return success(
      toWorkspaceEdit(editorClientCapabilities, [
        FileEditInformation(
          textDocument,
          result.lineInfo,
          fileEdits.expand((edit) => edit.edits).toList(),
          newFile: false,
        ),
      ]),
    );
  }

  /// Sends [workspaceEdit] to the client and returns `null` if applied
  /// successfully or an error otherwise.
  Future<ErrorOr<Null>> _sendEditToClient(WorkspaceEdit workspaceEdit) async {
    var server = this.server;
    if (server is! LspAnalysisServer) {
      return error(
        ErrorCodes.RequestFailed,
        'Sending edits is currently only supported for clients using LSP directly',
      );
    }

    var editDescription = 'Edit argument';
    var editResponse = await server.sendRequest(
      Method.workspace_applyEdit,
      ApplyWorkspaceEditParams(label: editDescription, edit: workspaceEdit),
    );

    // Handle errors from the client.
    if (editResponse.error != null) {
      return error(
        ServerErrorCodes.ClientFailedToApplyEdit,
        'Client failed to apply workspace edit: $editDescription',
        editResponse.error.toString(),
      );
    }

    // If the request was successful, check whether the client applied it.
    var editResponseResult = ApplyWorkspaceEditResult.fromJson(
      editResponse.result as Map<String, Object?>,
    );
    var ApplyWorkspaceEditResult(:applied, :failureReason) = editResponseResult;
    if (applied) {
      // Everything was good.
      return success(null);
    } else {
      // Otherwise, the client returned a successful response, but says it
      // did not apply the edit. This might be because the version has
      // changed.
      return error(
        ServerErrorCodes.ClientFailedToApplyEdit,
        'Client did not apply workspace edit: $editDescription '
        '(reason: ${failureReason ?? 'not given'})',
        workspaceEdit.toString(),
      );
    }
  }

  /// Writes a replacement for [argument] to [builder].
  void _writeChangedArgument(
    DartFileEditBuilder builder,
    Expression argument,
    String newValueCode,
  ) {
    // Only replace the value, not the name.
    var argumentValue = switch (argument) {
      NamedExpression() => argument.expression,
      _ => argument,
    };

    builder.addSimpleReplacement(
      SourceRange(argumentValue.offset, argumentValue.length),
      newValueCode,
    );
  }

  /// Writes a new argument for [parameter] into [builder].
  ///
  /// If [parameter] is positional, will insert any required defaults for
  /// earlier missing positionals.
  void _writeNewArgument(
    DartFileEditBuilder builder,
    List<FormalParameterElement> parameters,
    ArgumentList argumentList,
    FormalParameterElement parameter,
    String newValueCode,
  ) {
    // If this parameter is positional, we need to first ensure arguments for
    // any earlier positional parameters are present.
    if (parameter.isPositional) {
      var existingPositionalArguments =
          argumentList.arguments.where((a) => a is! NamedExpression).length;
      var unspecifiedPositionals = parameters
          .where((p) => p.isPositional)
          .skip(existingPositionalArguments)
          .takeWhile((p) => p != parameter);

      // This should never happen as the notEditableReason check should've
      // exited long before here.
      if (unspecifiedPositionals.isNotEmpty) {
        throw StateError(
          'Unable to add a new positional argument if all preceding positionals are not present',
        );
      }
    }

    var parameterName = parameter.name3;
    var prefix =
        parameter.isNamed && parameterName != null ? '$parameterName: ' : '';
    var argumentCodeToInsert = '$prefix$newValueCode';

    // Build the final code to insert.
    var newCode = StringBuffer();
    var hasTrailingComma =
        argumentList.arguments.lastOrNull?.endToken.next?.lexeme == ',';
    if (!hasTrailingComma && argumentList.arguments.isNotEmpty) {
      newCode.write(', ');
    } else if (hasTrailingComma) {
      newCode.write(' ');
    }
    newCode.write(argumentCodeToInsert);
    if (hasTrailingComma) {
      newCode.write(',');
    }

    builder.addSimpleInsertion(
      argumentList.rightParenthesis.offset,
      newCode.toString(),
    );
  }
}
