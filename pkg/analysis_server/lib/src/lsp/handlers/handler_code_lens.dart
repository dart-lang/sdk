// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/code_lens/abstract_code_lens_provider.dart';
import 'package:analysis_server/src/lsp/handlers/code_lens/augmentations.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';

class CodeLensHandler
    extends SharedMessageHandler<CodeLensParams, List<CodeLens>> {
  final List<AbstractCodeLensProvider> codeLensProviders;

  CodeLensHandler(super.server)
      : codeLensProviders = [
          AugmentationCodeLensProvider(server),
        ];

  @override
  Method get handlesMessage => Method.textDocument_codeLens;

  @override
  LspJsonHandler<CodeLensParams> get jsonHandler => CodeLensParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<List<CodeLens>>> handle(
    CodeLensParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null) {
      return serverNotInitializedError;
    }

    // Ask all providers to compute their CodeLenses.
    var providerResults = await Future.wait(
      codeLensProviders
          .where((provider) => provider.isAvailable(clientCapabilities, params))
          .map((provider) => provider.handle(params, message, token)),
    );

    // Merge the results, but if any errors, propogate the first error.
    var allResults = <CodeLens>[];
    for (var providerResult in providerResults) {
      if (providerResult.isError) {
        return failure(providerResult);
      }
      providerResult.ifResult(allResults.addAll);
    }

    return success(allResults);
  }
}

class CodeLensRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<CodeLensOptions> {
  @override
  late final options = CodeLensRegistrationOptions(
    documentSelector: dartFiles,
    resolveProvider: staticOptions.resolveProvider,
    workDoneProgress: staticOptions.workDoneProgress,
  );

  @override
  final staticOptions = CodeLensOptions();

  CodeLensRegistrations(super.info);

  @override
  Method get registrationMethod => Method.textDocument_codeLens;

  @override
  bool get supportsDynamic => clientDynamic.codeLens;
}
