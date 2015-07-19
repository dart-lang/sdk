// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.services.completion.completion_dart;

import 'package:analysis_server/completion/completion_core.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The information about a requested list of completions.
 */
class CompletionRequestImpl implements CompletionRequest {
  /**
   * The analysis context in which the completion is being requested.
   */
  AnalysisContext context;

  /**
   * The resource provider associated with this request.
   */
  ResourceProvider resourceProvider;

  /**
   * The source in which the completion is being requested.
   */
  Source source;

  /**
   * The offset within the source at which the completion is being requested.
   */
  int offset;

  /**
   * Initialize a newly created completion request based on the given arguments.
   */
  CompletionRequestImpl(
      this.context, this.resourceProvider, this.source, this.offset);
}
