// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/computer/computer_signature.dart';
import 'package:analysis_server/src/computer/computer_type_arguments_signature.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

class SignatureHelpHandler
    extends LspMessageHandler<SignatureHelpParams, SignatureHelp?> {
  SignatureHelpHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_signatureHelp;

  @override
  LspJsonHandler<SignatureHelpParams> get jsonHandler =>
      SignatureHelpParams.jsonHandler;

  @override
  Future<ErrorOr<SignatureHelp?>> handle(SignatureHelpParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    // If triggered automatically by pressing the trigger character, we will
    // only provide results if the character we typed was the one that actually
    // starts the argument list. This is to avoid popping open signature help
    // whenever the user types a `(` that might not be the start of an argument
    // list, as the client does not have any context and will always send the
    // request.
    final autoTriggered = params.context?.triggerKind ==
            SignatureHelpTriggerKind.TriggerCharacter &&
        // Retriggers can be ignored (treated as manual invocations) as it's
        // fine to always generate results if the signature help is already
        // visible on the client (it will just update, it doesn't pop up new UI).
        params.context?.isRetrigger == false;

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) {
      final formats = clientCapabilities.signatureHelpDocumentationFormats;
      final dartDocInfo = server.getDartdocDirectiveInfoFor(unit.result);

      // First check if we're in a type args list and if so build some
      // signature help for that.
      final typeArgsSignature = _tryGetTypeArgsSignatureHelp(
        dartDocInfo,
        unit.result.unit,
        offset,
        autoTriggered,
        formats,
      );
      if (typeArgsSignature != null) {
        return success(typeArgsSignature);
      }

      final computer = DartUnitSignatureComputer(
        dartDocInfo,
        unit.result.unit,
        offset,
        documentationPreference:
            server.lspClientConfiguration.global.preferredDocumentation,
      );
      if (!computer.offsetIsValid) {
        return success(null); // No error, just no valid hover.
      }
      final signature = computer.compute();
      if (signature == null) {
        return success(null); // No error, just no valid hover.
      }

      // Skip results if this was an auto-trigger but not from the start of the
      // argument list.
      // The ArgumentList's offset is before the paren, but the request offset
      // will be after.
      if (autoTriggered && offset != computer.argumentList.offset + 1) {
        return success(null);
      }

      return success(toSignatureHelp(formats, signature));
    });
  }

  /// Tries to create signature information for a surrounding [TypeArgumentList].
  ///
  /// Returns `null` if [offset] is in an invalid location, not inside a type
  /// argument list or was auto-triggered in a location that was not the start
  /// of a type argument list.
  SignatureHelp? _tryGetTypeArgsSignatureHelp(
    DartdocDirectiveInfo dartDocInfo,
    CompilationUnit unit,
    int offset,
    bool autoTriggered,
    Set<MarkupKind>? formats,
  ) {
    final typeArgsComputer = DartTypeArgumentsSignatureComputer(
        dartDocInfo, unit, offset, formats,
        documentationPreference:
            server.lspClientConfiguration.global.preferredDocumentation);
    if (!typeArgsComputer.offsetIsValid) {
      return null;
    }

    final typeSignature = typeArgsComputer.compute();
    if (typeSignature == null) {
      return null;
    }

    // If auto-triggered from typing a `<`, only show if that `<` was at
    // the start of the arg list (to avoid triggering on other `<`s).
    if (autoTriggered && offset != typeArgsComputer.argumentList.offset + 1) {
      return null;
    }

    return typeSignature;
  }
}
