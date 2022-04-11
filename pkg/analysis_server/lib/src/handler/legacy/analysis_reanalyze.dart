// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// The handler for the `analysis.reanalyze` request.
class AnalysisReanalyzeHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisReanalyzeHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    server.options.analytics?.sendEvent('analysis', 'reanalyze');

    await server.reanalyze();
    //
    // Restart all of the plugins. This is an async operation that will happen
    // in the background.
    //
    server.pluginManager.restartPlugins();

    sendResult(AnalysisReanalyzeResult());
  }
}
