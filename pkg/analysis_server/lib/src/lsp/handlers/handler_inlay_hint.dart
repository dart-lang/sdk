// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/computer/computer_inlay_hint.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';

typedef StaticOptions =
    Either3<bool, InlayHintOptions, InlayHintRegistrationOptions>;

class InlayHintHandler
    extends LspMessageHandler<InlayHintParams, List<InlayHint>> {
  InlayHintHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_inlayHint;

  @override
  LspJsonHandler<InlayHintParams> get jsonHandler =>
      InlayHintParams.jsonHandler;

  @override
  Future<ErrorOr<List<InlayHint>>> handle(
    InlayHintParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var textDocument = params.textDocument;
    if (!isDartDocument(textDocument)) {
      return success([]);
    }

    var path = pathOfDoc(textDocument);
    return path.mapResult((path) async {
      // Capture the document version so we can verify it hasn't changed after
      // we've got a resolved unit (which is async and may wait for context
      // rebuilds).
      var docIdentifier = extractDocumentVersion(textDocument, path);

      var result = await requireResolvedUnit(path);

      if (fileHasBeenModified(path, docIdentifier.version)) {
        return fileModifiedError;
      }

      if (token.isCancellationRequested) {
        return cancelled();
      }

      return result.mapResult((result) async {
        if (!result.exists) {
          return success([]);
        }

        var computer = DartInlayHintComputer(pathContext, result);
        var hints = computer.compute();

        return success(hints);
      });
    });
  }
}

class InlayHintRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  InlayHintRegistrations(super.info);

  @override
  ToJsonable? get options => InlayHintRegistrationOptions(
    documentSelector: dartFiles,
    resolveProvider: false,
  );

  @override
  Method get registrationMethod => Method.textDocument_inlayHint;

  @override
  StaticOptions get staticOptions =>
      Either3.t2(InlayHintOptions(resolveProvider: false));

  @override
  bool get supportsDynamic => clientDynamic.inlayHints;
}
