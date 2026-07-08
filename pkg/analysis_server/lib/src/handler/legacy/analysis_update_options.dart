// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';

/// The handler for the `analysis.updateOptions` request.
class AnalysisUpdateOptionsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  new(super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    // options
    var params = AnalysisUpdateOptionsParams.fromRequest(
      request,
      clientUriConverter: server.uriConverter,
    );
    var newOptions = params.options;
    var builderUpdaters = <AnalysisOptionsBuilderUpdater>[];
    var generateHints = newOptions.generateHints;
    if (generateHints != null) {
      builderUpdaters.add((AnalysisOptionsBuilder analysisOptionsBuilder) {
        analysisOptionsBuilder.warning = generateHints;
      });
    }
    var generateLints = newOptions.generateLints;
    if (generateLints != null) {
      builderUpdaters.add((AnalysisOptionsBuilder analysisOptionsBuilder) {
        analysisOptionsBuilder.lint = generateLints;
      });
    }
    server.updateOptions(builderUpdaters);
    sendResult(AnalysisUpdateOptionsResult());
  }
}
