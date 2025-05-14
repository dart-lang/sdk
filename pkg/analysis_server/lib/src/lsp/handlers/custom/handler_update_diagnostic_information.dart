// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

/// Records a map of data provided by the client for diagnostic purposes.
///
/// This data shows up in the analyzer diagnostics page and the exportable
/// report.
class UpdateDiagnosticInformationHandler
    extends SharedMessageHandler<Map<String, Object?>?, void> {
  UpdateDiagnosticInformationHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.updateDiagnosticInformation;

  @override
  LspJsonHandler<Map<String, Object?>?> get jsonHandler =>
      LspJsonHandler((_, _) => true, (obj) => obj);

  @override
  // Only the controlling editor may provide this data.
  bool get requiresTrustedCaller => true;

  @override
  Future<ErrorOr<void>> handle(
    Map<String, Object?>? params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    server.clientDiagnosticInformation = params;
    return success(null);
  }
}
