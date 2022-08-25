// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/lint/registry.dart';

/// The handler for the `edit.bulkFixes` request.
class EditBulkFixes extends LegacyHandler {
  static final Set<String> _errorCodes =
      errorCodeValues.map((ErrorCode code) => code.name.toLowerCase()).toSet();

  static final Set<String> _lintCodes =
      Registry.ruleRegistry.rules.map((rule) => rule.name).toSet();

  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditBulkFixes(super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    //
    // Compute bulk fixes
    //
    try {
      var params = EditBulkFixesParams.fromRequest(request);
      for (var file in params.included) {
        if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
          return;
        }
      }

      var codes = params.codes?.map((e) => e.toLowerCase()).toList();
      if (codes != null) {
        for (var code in codes) {
          if (!_errorCodes.contains(code) && !_lintCodes.contains(code)) {
            sendResult(EditBulkFixesResult(
                "The diagnostic '$code' is undefined.", [], []));
            return;
          }
        }
      }

      var collection = AnalysisContextCollectionImpl(
        includedPaths: params.included,
        resourceProvider: server.resourceProvider,
        sdkPath: server.sdkPath,
      );
      var workspace = DartChangeWorkspace(
          collection.contexts.map((c) => c.currentSession).toList());
      var processor = BulkFixProcessor(server.instrumentationService, workspace,
          useConfigFiles: params.inTestMode ?? false, codes: codes);

      var changeBuilder = await processor.fixErrors(collection.contexts);

      sendResult(EditBulkFixesResult(
          '', changeBuilder.sourceChange.edits, processor.fixDetails));
    } catch (exception, stackTrace) {
      // TODO(brianwilkerson) Move exception handling outside [handle].
      server.sendServerErrorNotification('Exception while getting bulk fixes',
          CaughtException(exception, stackTrace), stackTrace);
    }
  }
}
