// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/lsp_analysis_server.dart'
    show LspAnalysisServer;
import 'package:analysis_server/src/status/diagnostics.dart';

class LspRegistrationsPage extends DiagnosticPageWithNav {
  @override
  LspAnalysisServer server;

  LspRegistrationsPage(DiagnosticsSite site, this.server)
    : super(
        site,
        'lsp-registrations',
        'LSP registrations',
        description: 'Current LSP feature registrations.',
        indentInNav: true,
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    h3('Current Registrations');
    p(
      'Showing the LSP method name and the registration params sent to the '
      'client.',
    );
    prettyJson(server.capabilitiesComputer.currentRegistrations.toList());
  }
}
