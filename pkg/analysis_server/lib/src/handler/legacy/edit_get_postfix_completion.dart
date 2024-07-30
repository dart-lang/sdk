// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/completion/postfix/postfix_completion.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// The handler for the `edit.getPostfixCompletion` request.
class EditGetPostfixCompletionHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditGetPostfixCompletionHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    var params = EditGetPostfixCompletionParams.fromRequest(request,
        clientUriConverter: server.uriConverter);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    SourceChange? change;

    var result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = PostfixCompletionContext(
        result,
        params.offset,
        params.key,
      );
      var processor = PostfixCompletionProcessor(context);
      var completion = await processor.compute();
      change = completion.change;
    }
    change ??= SourceChange('', edits: []);

    sendResult(EditGetPostfixCompletionResult(change));
  }
}
