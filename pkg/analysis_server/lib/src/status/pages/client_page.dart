// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';

class ClientPage extends DiagnosticPageWithNav {
  ClientPage(super.site, [super.id = 'client', super.title = 'Client'])
    : super(description: 'Information about the client.');

  @override
  Future<void> generateContent(Map<String, String> params) async {
    h3('Client Diagnostic Information');
    prettyJson(server.clientDiagnosticInformation);
  }
}
