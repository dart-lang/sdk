// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.services.completion.completion_core;

import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisResult;
import 'package:analyzer/src/generated/source.dart';

/**
 * The information about a requested list of completions.
 */
class CompletionRequestImpl implements CompletionRequest {
  @override
  final AnalysisResult result;

  @override
  final AnalysisContext context;

  @override
  final Source source;

  /**
   * The content cache modification stamp of the associated [source],
   * or `null` if the content cache does not override the [source] content.
   * This is used to determine if the [source] contents have been modified
   * after the completion request was made.
   */
  final int sourceModificationStamp;

  @override
  final int offset;

  @override
  IdeOptions ideOptions;

  /**
   * The offset of the start of the text to be replaced.
   * This will be different than the [offset] used to request the completion
   * suggestions if there was a portion of an identifier before the original
   * [offset]. In particular, the [replacementOffset] will be the offset of the
   * beginning of said identifier.
   */
  int replacementOffset;

  /**
   * The length of the text to be replaced if the remainder of the identifier
   * containing the cursor is to be replaced when the suggestion is applied
   * (that is, the number of characters in the existing identifier).
   * This will be different than the [replacementOffset] - [offset]
   * if the [offset] is in the middle of an existing identifier.
   */
  int replacementLength;

  @override
  final ResourceProvider resourceProvider;

  @override
  final SearchEngine searchEngine;

  bool _aborted = false;

  final CompletionPerformance performance;

  /**
   * Initialize a newly created completion request based on the given arguments.
   */
  CompletionRequestImpl(
      this.result,
      AnalysisContext context,
      this.resourceProvider,
      this.searchEngine,
      Source source,
      int offset,
      this.performance,
      this.ideOptions)
      : this.context = context,
        this.source = source,
        this.offset = offset,
        replacementOffset = offset,
        replacementLength = 0,
        sourceModificationStamp = context?.getModificationStamp(source);

  /**
   * Return the original text from the [replacementOffset] to the [offset]
   * that can be used to filter the suggestions on the server side.
   */
  String get filterText {
    return sourceContents.substring(replacementOffset, offset);
  }

  @override
  String get sourceContents => context.getContents(source)?.data;

  /**
   * Abort the current completion request.
   */
  void abort() {
    _aborted = true;
  }

  @override
  void checkAborted() {
    if (_aborted) {
      throw new AbortCompletion();
    }
    if (sourceModificationStamp != context?.getModificationStamp(source)) {
      _aborted = true;
      throw new AbortCompletion();
    }
  }
}
