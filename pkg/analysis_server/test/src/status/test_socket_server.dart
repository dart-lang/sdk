// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/socket_server.dart';

class TestSocketServer implements AbstractSocketServer {
  @override
  final AnalysisServer analysisServer;

  new(this.analysisServer);

  @override
  AnalysisServerOptions get analysisServerOptions => analysisServer.options;

  @override
  DiagnosticServer? get diagnosticServer => null;
}
