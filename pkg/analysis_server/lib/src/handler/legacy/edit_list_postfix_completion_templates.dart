// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/completion/postfix/postfix_completion.dart';

/// The handler for the `edit.listPostfixCompletionTemplates` request.
class EditListPostfixCompletionTemplatesHandler extends LegacyHandler {
  static final _templateDescriptors = [
    for (var kind in DartPostfixCompletion.allTemplates)
      PostfixTemplateDescriptor(kind.name, kind.key, kind.example),
  ];

  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditListPostfixCompletionTemplatesHandler(
    super.server,
    super.request,
    super.cancellationToken,
    super.performance,
  );

  @override
  Future<void> handle() async {
    sendResult(EditListPostfixCompletionTemplatesResult(_templateDescriptors));
  }
}
