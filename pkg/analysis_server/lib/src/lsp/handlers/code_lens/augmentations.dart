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
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class AugmentationCodeLensProvider extends AbstractCodeLensProvider {
  AugmentationCodeLensProvider(super.server);

  LspClientCodeLensConfiguration get codeLens =>
      server.lspClientConfiguration.global.codeLens;

  @override
  Future<ErrorOr<List<CodeLens>>> handle(
    CodeLensParams params,
    MessageInfo message,
    CancellationToken token,
    Map<String, LineInfo?> lineInfoCache,
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
        (performance) => _getCodeLenses(
            clientCapabilities, result, token, performance, lineInfoCache),
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
    Map<String, LineInfo?> lineInfoCache,
  ) async {
    var lineInfo = result.lineInfo;
    var codeLenses = <CodeLens>[];

    /// Helper to add a CodeLens at [declaration] to [target] for [title].
    void addCodeLens(String title, Element declaration, Element target) {
      var command = getNavigationCommand(
          clientCapabilities, title, target, lineInfoCache);
      if (command != null && declaration.nameOffset != -1) {
        var range = toRange(
          lineInfo,
          declaration.nameOffset,
          declaration.nameLength,
        );
        codeLenses.add(CodeLens(range: range, command: command));
      }
    }

    var computer = _AugmentationComputer(result);
    if (codeLens.augmented) {
      for (var MapEntry(key: declaration, value: augmentated)
          in computer.augmenteds.entries) {
        addCodeLens('Go to Augmented', declaration, augmentated);
      }
    }
    if (codeLens.augmentation) {
      for (var MapEntry(key: declaration, value: augmentation)
          in computer.augmentations.entries) {
        addCodeLens('Go to Augmentation', declaration, augmentation);
      }
    }

    return success(codeLenses);
  }
}

class _AugmentationComputer {
  /// A mapping of declarations to their augmentations.
  final Map<Element, Element> augmentations = {};

  /// A mapping of augmentations to their declarations.
  final Map<Element, Element> augmenteds = {};

  final ResolvedUnitResult result;

  _AugmentationComputer(this.result) {
    result.unit.declaredElement?.accept(_AugmentationVisitor(this));
  }

  void recordAugmentation(Element declaration, Element augmentation) {
    augmentations[declaration] = augmentation;
  }

  void recordAugmented(Element declaration, Element augmented) {
    augmenteds[declaration] = augmented;
  }
}

/// Visits an AST and records mappings from augmentations to the declarations
/// they augment, and from declarations to their augmentations.
class _AugmentationVisitor extends GeneralizingElementVisitor<void> {
  final _AugmentationComputer _computer;

  _AugmentationVisitor(this._computer);

  @override
  void visitElement(Element element) {
    assert(element.source?.fullName == _computer.result.path);
    assert(element == element.declaration);

    if (!element.isSynthetic) {
      var agumentation = element.augmentation;
      if (agumentation != null) {
        _computer.recordAugmentation(element, agumentation);
      }

      var augmented = switch (element) {
        ExecutableElement element => element.augmentationTarget,
        InstanceElement element => element.augmentationTarget,
        PropertyInducingElement element => element.augmentationTarget,
        _ => null,
      };
      if (augmented != null) {
        _computer.recordAugmented(element, augmented);
      }
    }

    super.visitElement(element);
  }
}
