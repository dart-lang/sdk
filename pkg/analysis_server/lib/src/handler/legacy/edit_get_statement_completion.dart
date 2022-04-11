// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/completion/statement/statement_completion.dart';
import 'package:analysis_server/src/utilities/progress.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// The handler for the `edit.getStatementCompletion` request.
class EditGetStatementCompletionHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditGetStatementCompletionHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = EditGetStatementCompletionParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    SourceChange? change;

    var result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = StatementCompletionContext(result, params.offset);
      var processor = StatementCompletionProcessor(context);
      var completion = await processor.compute();
      change = completion.change;
    }
    change ??= SourceChange('', edits: []);

    sendResult(EditGetStatementCompletionResult(change, false));
  }
}
