// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/lsp_analysis_server.dart'
    show LspAnalysisServer;
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages/client_page.dart';

/// Overrides [ClientPage] including LSP-specific data.
class LspClientPage extends ClientPage {
  @override
  LspAnalysisServer server;

  LspClientPage(DiagnosticsSite site, this.server) : super(site, 'lsp', 'LSP');

  @override
  Future<void> generateContent(Map<String, String> params) async {
    h3('LSP Client Info');
    prettyJson({
      'Name': server.clientInfo?.name,
      'Version': server.clientInfo?.version,
      'Host': server.clientAppHost,
      'Remote': server.clientRemoteName,
    });

    h3('Initialization Options');
    prettyJson(server.initializationOptions?.raw);

    await super.generateContent(params);
  }
}
