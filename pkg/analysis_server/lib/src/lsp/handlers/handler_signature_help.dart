// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_signature.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';

class SignatureHelpHandler
    extends MessageHandler<SignatureHelpParams, SignatureHelp> {
  SignatureHelpHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_signatureHelp;

  @override
  LspJsonHandler<SignatureHelpParams> get jsonHandler =>
      SignatureHelpParams.jsonHandler;

  @override
  Future<ErrorOr<SignatureHelp>> handle(
      SignatureHelpParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
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
      final computer = DartUnitSignatureComputer(
          server.getDartdocDirectiveInfoFor(unit.result),
          unit.result.unit,
          offset);
      if (!computer.offsetIsValid) {
        return success(); // No error, just no valid hover.
      }
      final signature = computer.compute();
      if (signature == null) {
        return success(); // No error, just no valid hover.
      }

      // Skip results if this was an auto-trigger but not from the start of the
      // argument list.
      // The ArgumentList's offset is before the paren, but the request offset
      // will be after.
      if (autoTriggered &&
          computer.argumentList != null &&
          offset != computer.argumentList.offset + 1) {
        return success();
      }

      final formats = server?.clientCapabilities?.textDocument?.signatureHelp
          ?.signatureInformation?.documentationFormat;
      return success(toSignatureHelp(formats, signature));
    });
  }
}
