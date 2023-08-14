// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

/// The handler for the `edit.bulkFixes` request.
class EditBulkFixes extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditBulkFixes(
      super.server, super.request, super.cancellationToken, super.performance);

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
      var collection = AnalysisContextCollectionImpl(
        includedPaths: params.included,
        resourceProvider: server.resourceProvider,
        sdkPath: server.sdkPath,
        byteStore: server.byteStore,
      );
      var workspace = DartChangeWorkspace(
          collection.contexts.map((c) => c.currentSession).toList());
      var processor = BulkFixProcessor(server.instrumentationService, workspace,
          useConfigFiles: params.inTestMode ?? false, codes: codes);
      var result = await processor.fixErrors(collection.contexts);
      var message = result.errorMessage;
      if (message != null) {
        sendResult(EditBulkFixesResult(message, [], []));
      } else {
        sendResult(EditBulkFixesResult(
            '', result.builder!.sourceChange.edits, processor.fixDetails));
      }
    } catch (exception, stackTrace) {
      // TODO(brianwilkerson) Move exception handling outside [handle].
      server.sendServerErrorNotification('Exception while getting bulk fixes',
          CaughtException(exception, stackTrace), stackTrace);
    }
  }
}
