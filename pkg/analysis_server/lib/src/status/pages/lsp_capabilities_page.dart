// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/lsp_analysis_server.dart'
    show LspAnalysisServer;
import 'package:analysis_server/src/status/diagnostics.dart';

class LspCapabilitiesPage extends DiagnosticPageWithNav {
  @override
  LspAnalysisServer server;

  LspCapabilitiesPage(DiagnosticsSite site, this.server)
    : super(
        site,
        'lsp-capabilities',
        'LSP capabilities',
        description: 'Client and Server LSP Capabilities.',
        indentInNav: true,
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    buf.writeln('<div class="columns">');
    buf.writeln('<div class="column one-half">');
    h3('Client Capabilities');
    var clientCapabilities = server.editorClientCapabilities;
    if (clientCapabilities == null) {
      p('Client capabilities have not yet been received.');
    } else {
      prettyJson(clientCapabilities.raw.toJson());
    }
    buf.writeln('</div>');

    buf.writeln('<div class="column one-half">');
    h3('Server Capabilities');
    var capabilities = server.capabilities;
    if (capabilities == null) {
      p('Server capabilities have not yet been computed.');
    } else {
      prettyJson(capabilities.toJson());
    }
    buf.writeln('</div>'); // half for server capabilities
    buf.writeln('</div>'); // columns
  }
}
