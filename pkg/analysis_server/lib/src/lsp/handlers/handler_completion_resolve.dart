// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class CompletionResolveHandler
    extends MessageHandler<CompletionItem, CompletionItem> {
  CompletionResolveHandler(LspAnalysisServer server) : super(server);

  Method get handlesMessage => Method.completionItem_resolve;

  @override
  LspJsonHandler<CompletionItem> get jsonHandler => CompletionItem.jsonHandler;

  Future<ErrorOr<CompletionItem>> handle(CompletionItem item) async {
    // TODO: Implement resolution. For now just always return the same item back.
    return success(item);
  }
}
