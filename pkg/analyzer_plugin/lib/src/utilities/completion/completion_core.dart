// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';

/**
 * An object that can collect completion suggestions.
 */
class CompletionCollectorImpl implements CompletionCollector {
  /**
   * The length of the region of text that should be replaced by the selected
   * completion suggestion.
   */
  int _length;

  /**
   * The offset of the region of text that should be replaced by the selected
   * completion suggestion.
   */
  int _offset;

  /**
   * A list of the completion suggestions that have been collected.
   */
  List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

  /**
   * Initialize a newly created completion collector.
   */
  CompletionCollectorImpl();

  /**
   * Return the length of the region of text that should be replaced by the
   * selected completion suggestion, or `null` if the length has not been set.
   */
  int get length => _length;

  @override
  void set length(int length) {
    if (_length != null) {
      throw new StateError('The length can only be set once');
    }
    _length = length;
  }

  /**
   * Return the offset of the region of text that should be replaced by the
   * selected completion suggestion, or `null` if the offset has not been set.
   */
  int get offset => _offset;

  @override
  void set offset(int length) {
    if (_offset != null) {
      throw new StateError('The offset can only be set once');
    }
    _offset = length;
  }

  @override
  void addSuggestion(CompletionSuggestion suggestion) {
    suggestions.add(suggestion);
  }
}

/**
 * Information about the completion request that was made.
 */
class CompletionRequestImpl implements CompletionRequest {
  @override
  final int offset;

  @override
  final ResourceProvider resourceProvider;

  @override
  final ResolveResult result;

  /**
   * A flag indicating whether completion has been aborted.
   */
  bool _aborted = false;

  /**
   * Initialize a newly created request.
   */
  CompletionRequestImpl(this.resourceProvider, this.result, this.offset);

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
  }
}
