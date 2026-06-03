// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/analysis_rule/analysis_rule.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/lint/registry.dart';

/// The handler for the `edit.bulkFixes` request.
class EditBulkFixes extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  new(super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    //
    // Compute bulk fixes
    //
    try {
      var params = EditBulkFixesParams.fromRequest(
        request,
        clientUriConverter: server.uriConverter,
      );
      for (var file in params.included) {
        if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
          return;
        }
      }

      var codes = params.codes?.map((e) => e.toLowerCase()).toList();
      var updatePubspec = params.updatePubspec ?? false;
      var collection = AnalysisContextCollectionImpl(
        includedPaths: params.included,
        resourceProvider: server.resourceProvider,
        sdkPath: server.sdkPath,
        byteStore: server.byteStore,
        withFineDependencies: true,
        updateAnalysisOptions4: codes != null && codes.isNotEmpty
            ? ({required analysisOptions}) {
                var rules = <AbstractAnalysisRule>[];
                for (var code in codes) {
                  var rule = Registry.ruleRegistry.getRule(code);
                  if (rule != null) {
                    rules.add(rule);
                  }
                }
                if (rules.isNotEmpty) {
                  analysisOptions.lint = true;
                  var existingNames = analysisOptions.lintRules
                      .map((rule) => rule.name)
                      .toSet();
                  for (var rule in rules) {
                    if (!existingNames.contains(rule.name)) {
                      analysisOptions.lintRules.add(rule);
                    }
                  }
                }
              }
            : null,
      );
      var workspace = DartChangeWorkspace(
        collection.contexts.map((c) => c.currentSession).toList(),
      );
      var processor = BulkFixProcessor(
        server.instrumentationService,
        workspace,
        codes: codes,
      );
      if (!updatePubspec) {
        var result = await processor.fixErrors(collection.contexts);
        var message = result.errorMessage;
        if (message != null) {
          sendResult(EditBulkFixesResult(message, [], []));
        } else {
          sendResult(
            EditBulkFixesResult(
              '',
              result.builder!.sourceChange.edits,
              processor.fixDetails,
            ),
          );
        }
      } else {
        var (:edits, :details) = await processor.fixPubspec(
          collection.contexts,
        );
        sendResult(EditBulkFixesResult('', edits, details));
      }
    } catch (exception, stackTrace) {
      // TODO(brianwilkerson): Move exception handling outside [handle].
      server.sendServerErrorNotification(
        'Exception while getting bulk fixes',
        CaughtException(exception, stackTrace),
        stackTrace,
      );
    }
  }
}
