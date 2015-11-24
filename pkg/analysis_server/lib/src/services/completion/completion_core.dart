// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.services.completion.completion_core;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The information about a requested list of completions.
 */
class CompletionRequestImpl implements CompletionRequest {
  @override
  final AnalysisServer server;

  @override
  final AnalysisContext context;

  @override
  final Source source;

  @override
  final int offset;

  /**
   * Initialize a newly created completion request based on the given arguments.
   */
  CompletionRequestImpl(this.server, this.context, this.source, this.offset);

  @override
  ResourceProvider get resourceProvider => server.resourceProvider;

  @override
  ServerPlugin get serverPlugin => server.serverPlugin;
}
