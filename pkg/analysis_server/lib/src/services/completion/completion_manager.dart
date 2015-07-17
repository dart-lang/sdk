// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.manager;

import 'dart:async';

import 'package:analysis_server/completion/completion_core.dart'
    show CompletionRequest, CompletionResult;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * [CompletionCache] contains information about the prior code completion
 * for use in the next code completion.
 */
abstract class CompletionCache {

  /**
   * The context in which the completion was computed.
   */
  final AnalysisContext context;

  /**
   * The source in which the completion was computed.
   */
  final Source source;

  CompletionCache(this.context, this.source);
}

/**
 * Manages completion contributors for a given completion request.
 */
abstract class CompletionManager {

  /**
   * The context in which the completion was computed.
   */
  final AnalysisContext context;

  /**
   * The source in which the completion was computed.
   */
  final Source source;

  /**
   * The controller used for returning completion results.
   */
  StreamController<CompletionResult> controller;

  CompletionManager(this.context, this.source);

  /**
   * Create a manager for the given request.
   */
  factory CompletionManager.create(
      AnalysisContext context, Source source, SearchEngine searchEngine) {
    if (context != null) {
      if (AnalysisEngine.isDartFileName(source.shortName)) {
        return new DartCompletionManager.create(context, searchEngine, source);
      }
      if (AnalysisEngine.isHtmlFileName(source.shortName)) {
        //TODO (danrubel) implement
//        return new HtmlCompletionManager(context, searchEngine, source, offset);
      }
    }
    return new NoOpCompletionManager(source);
  }

  /**
   * Compute and cache information in preparation for a possible code
   * completion request sometime in the future. The default implementation
   * of this method does nothing. Subclasses may override but should not
   * count on this method being called before [computeSuggestions].
   * Return a future that completes when the cache is computed with a bool
   * indicating success.
   */
  Future<bool> computeCache() {
    return new Future.value(true);
  }

  /**
   * Compute completion results for the given reqeust and append them to the stream.
   * Clients should not call this method directly as it is automatically called
   * when a client listens to the stream returned by [results].
   * Subclasses should override this method, append at least one result
   * to the [controller], and close the controller stream once complete.
   */
  void computeSuggestions(CompletionRequest request);

  /**
   * Discard any pending operations.
   * Subclasses may override but should call super.dispose
   */
  void dispose() {}

  /**
   * Generate a stream of code completion results.
   */
  Stream<CompletionResult> results(CompletionRequest request) {
    controller = new StreamController<CompletionResult>(onListen: () {
      scheduleMicrotask(() {
        computeSuggestions(request);
      });
    });
    return controller.stream;
  }
}

/**
 * Overall performance of a code completion operation.
 */
class CompletionPerformance {
  final DateTime start = new DateTime.now();
  final Map<String, Duration> _startTimes = new Map<String, Duration>();
  final Stopwatch _stopwatch = new Stopwatch();
  final List<OperationPerformance> operations = <OperationPerformance>[];

  Source source;
  String snippet = '';
  int notificationCount = -1;
  int suggestionCountFirst = -1;
  int suggestionCountLast = -1;
  Duration _firstNotification;

  CompletionPerformance() {
    _stopwatch.start();
  }

  int get elapsedInMilliseconds =>
      operations.length > 0 ? operations.last.elapsed.inMilliseconds : 0;

  int get firstNotificationInMilliseconds =>
      _firstNotification != null ? _firstNotification.inMilliseconds : 0;

  String get startTimeAndMs => '${start.millisecondsSinceEpoch} - $start';

  String get suggestionCount {
    if (notificationCount < 1) return '';
    if (notificationCount == 1) return '$suggestionCountFirst';
    return '$suggestionCountFirst,  $suggestionCountLast';
  }

  void complete([String tag = null]) {
    _stopwatch.stop();
    _logDuration(tag != null ? tag : 'total time', _stopwatch.elapsed);
  }

  logElapseTime(String tag, [f() = null]) {
    Duration start;
    Duration end = _stopwatch.elapsed;
    var result;
    if (f == null) {
      start = _startTimes[tag];
      if (start == null) {
        _logDuration(tag, null);
        return null;
      }
    } else {
      result = f();
      start = end;
      end = _stopwatch.elapsed;
    }
    _logDuration(tag, end - start);
    return result;
  }

  void logFirstNotificationComplete(String tag) {
    _firstNotification = _stopwatch.elapsed;
    _logDuration(tag, _firstNotification);
  }

  void logStartTime(String tag) {
    _startTimes[tag] = _stopwatch.elapsed;
  }

  void setContentsAndOffset(String contents, int offset) {
    snippet = _computeSnippet(contents, offset);
  }

  void _logDuration(String tag, Duration elapsed) {
    operations.add(new OperationPerformance(tag, elapsed));
  }

  static String _computeSnippet(String contents, int offset) {
    if (contents == null ||
        offset == null ||
        offset < 0 ||
        contents.length < offset) {
      return '???';
    }
    int start = offset;
    while (start > 0) {
      String ch = contents[start - 1];
      if (ch == '\r' || ch == '\n') {
        break;
      }
      --start;
    }
    int end = offset;
    while (end < contents.length) {
      String ch = contents[end];
      if (ch == '\r' || ch == '\n') {
        break;
      }
      ++end;
    }
    String prefix = contents.substring(start, offset);
    String suffix = contents.substring(offset, end);
    return '$prefix^$suffix';
  }
}

/**
 * Encapsulates information specific to a particular completion request.
 */
class CompletionRequestImpl implements CompletionRequest {

  /**
   * The underlying analysis server for this completion request.
   */
  final AnalysisServer server;

  @override
  final AnalysisContext context;

  @override
  final Source source;

  @override
  final int offset;

  CompletionRequestImpl(this.server, this.context, this.source, this.offset);

  @override
  ResourceProvider get resourceProvider => server.resourceProvider;
}

/**
 * Code completion result generated by an [CompletionManager].
 */
class CompletionResultImpl implements CompletionResult {

  /**
   * The length of the text to be replaced if the remainder of the identifier
   * containing the cursor is to be replaced when the suggestion is applied
   * (that is, the number of characters in the existing identifier).
   */
  final int replacementLength;

  /**
   * The offset of the start of the text to be replaced. This will be different
   * than the offset used to request the completion suggestions if there was a
   * portion of an identifier before the original offset. In particular, the
   * replacementOffset will be the offset of the beginning of said identifier.
   */
  final int replacementOffset;

  /**
   * The suggested completions.
   */
  final List<CompletionSuggestion> suggestions;

  /**
   * `true` if this is that last set of results that will be returned
   * for the indicated completion.
   */
  final bool last;

  CompletionResultImpl(this.replacementOffset, this.replacementLength,
      this.suggestions, this.last);

  @override
  // TODO(brianwilkerson) Figure out whether this is correct.
  bool get hasNewSuggestions => suggestions.isNotEmpty;

  @override
  bool get isLast => last;
}

class NoOpCompletionManager extends CompletionManager {
  NoOpCompletionManager(Source source) : super(null, source);

  @override
  void computeSuggestions(CompletionRequest request) {
    controller.add(new CompletionResultImpl(request.offset, 0, [], true));
  }
}

/**
 * The performance of an operation when computing code completion.
 */
class OperationPerformance {

  /**
   * The name of the operation
   */
  final String name;

  /**
   * The elapse time or `null` if undefined.
   */
  final Duration elapsed;

  OperationPerformance(this.name, this.elapsed);
}
