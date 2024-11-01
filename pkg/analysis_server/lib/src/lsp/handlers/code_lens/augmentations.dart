// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    hide Declaration, Element;
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/client_configuration.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/code_lens/abstract_code_lens_provider.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

class AugmentationCodeLensProvider extends AbstractCodeLensProvider {
  AugmentationCodeLensProvider(super.server);

  LspClientCodeLensConfiguration get codeLens =>
      server.lspClientConfiguration.global.codeLens;

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

    var performance = message.performance;
    var path = pathOfDoc(params.textDocument);
    var unit = await performance.runAsync(
      'requireResolvedUnit',
      (_) async => path.mapResult(requireResolvedUnit),
    );
    return await unit.mapResult((result) {
      return performance.runAsync(
        '_getCodeLenses',
        (performance) =>
            _getCodeLenses(clientCapabilities, result, token, performance),
      );
    });
  }

  @override
  bool isAvailable(
      LspClientCapabilities clientCapabilities, CodeLensParams params) {
    return isDartDocument(params.textDocument) &&
        // We need to run if either of these are enabled.
        (codeLens.augmentation || codeLens.augmented) &&
        clientSupportsGoToLocationCommand(clientCapabilities);
  }

  Future<ErrorOr<List<CodeLens>>> _getCodeLenses(
    LspClientCapabilities clientCapabilities,
    ResolvedUnitResult result,
    CancellationToken token,
    OperationPerformanceImpl performance,
  ) async {
    var codeLenses = <CodeLens>[];

    /// Helper to add a CodeLens at [thisFragment] to [targetFragment] with
    /// the text [title].
    void addCodeLens(
      String title,
      Fragment thisFragment,
      Fragment targetFragment,
    ) {
      var command =
          getNavigationCommand(clientCapabilities, title, targetFragment);
      var nameOffset = thisFragment.nameOffset2;
      var nameLength = thisFragment.element.displayName.length;
      if (command != null && nameOffset != null) {
        var range = toRange(
          result.lineInfo,
          nameOffset,
          nameLength,
        );
        codeLenses.add(CodeLens(range: range, command: command));
      }
    }

    // Helper to add all CodeLenses for a [fragment] and child fragments
    // recursively.
    void addCodeLenses(Fragment fragment) {
      var previousFragment = fragment.previousFragment;
      var nextFragment = fragment.nextFragment;
      if (codeLens.augmented && previousFragment != null) {
        addCodeLens('Go to Augmented', fragment, previousFragment);
      }
      if (codeLens.augmentation && nextFragment != null) {
        addCodeLens('Go to Augmentation', fragment, nextFragment);
      }

      for (var fragment in fragment.children3) {
        addCodeLenses(fragment);
      }
    }

    // Add fragments starting at the library.
    addCodeLenses(result.libraryFragment);

    return success(codeLenses);
  }
}
