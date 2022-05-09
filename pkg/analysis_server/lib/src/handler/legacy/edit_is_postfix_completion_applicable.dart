// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/completion/postfix/postfix_completion.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// The handler for the `edit.isPostfixCompletionApplicable` request.
class EditIsPostfixCompletionApplicableHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditIsPostfixCompletionApplicableHandler(AnalysisServer server,
      Request request, CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = EditGetPostfixCompletionParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var value = false;

    var result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = PostfixCompletionContext(
        result,
        params.offset,
        params.key,
      );
      var processor = PostfixCompletionProcessor(context);
      value = await processor.isApplicable();
    }

    sendResult(EditIsPostfixCompletionApplicableResult(value));
  }
}
