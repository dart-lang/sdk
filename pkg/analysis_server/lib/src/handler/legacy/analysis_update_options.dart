// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;

/// The handler for the `analysis.updateOptions` request.
class AnalysisUpdateOptionsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisUpdateOptionsHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    // options
    var params = AnalysisUpdateOptionsParams.fromRequest(request);
    var newOptions = params.options;
    var updaters = <OptionUpdater>[];
    var generateHints = newOptions.generateHints;
    if (generateHints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.warning = generateHints;
      });
    }
    var generateLints = newOptions.generateLints;
    if (generateLints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.lint = generateLints;
      });
    }
    server.updateOptions(updaters);
    sendResult(AnalysisUpdateOptionsResult());
  }
}
