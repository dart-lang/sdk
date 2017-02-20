// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.error.listener;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart' show AstNode;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:source_span/source_span.dart';

/**
 * An object that listen for [AnalysisError]s being produced by the analysis
 * engine.
 */
abstract class AnalysisErrorListener {
  /**
   * An error listener that ignores errors that are reported to it.
   */
  static final AnalysisErrorListener NULL_LISTENER = new _NullErrorListener();

  /**
   * This method is invoked when an [error] has been found by the analysis
   * engine.
   */
  void onError(AnalysisError error);
}

/**
 * An [AnalysisErrorListener] that keeps track of whether any error has been
 * reported to it.
 */
class BooleanErrorListener implements AnalysisErrorListener {
  /**
   * A flag indicating whether an error has been reported to this listener.
   */
  bool _errorReported = false;

  /**
   * Return `true` if an error has been reported to this listener.
   */
  bool get errorReported => _errorReported;

  @override
  void onError(AnalysisError error) {
    _errorReported = true;
  }
}

/**
 * An object used to create analysis errors and report then to an error
 * listener.
 */
class ErrorReporter {
  /**
   * The error listener to which errors will be reported.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * The default source to be used when reporting errors.
   */
  final Source _defaultSource;

  /**
   * The source to be used when reporting errors.
   */
  Source _source;

  /**
   * Initialize a newly created error reporter that will report errors to the
   * given [_errorListener]. Errors will be reported against the
   * [_defaultSource] unless another source is provided later.
   */
  ErrorReporter(this._errorListener, this._defaultSource) {
    if (_errorListener == null) {
      throw new ArgumentError("An error listener must be provided");
    } else if (_defaultSource == null) {
      throw new ArgumentError("A default source must be provided");
    }
    this._source = _defaultSource;
  }

  Source get source => _source;

  /**
   * Set the source to be used when reporting errors to the given [source].
   * Setting the source to `null` will cause the default source to be used.
   */
  void set source(Source source) {
    this._source = source ?? _defaultSource;
  }

  /**
   * Report the given [error].
   */
  void reportError(AnalysisError error) {
    _errorListener.onError(error);
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The [element]
   * is used to compute the location of the error.
   */
  void reportErrorForElement(ErrorCode errorCode, Element element,
      [List<Object> arguments]) {
    int length = 0;
    if (element is ImportElement) {
      length = 6; // 'import'.length
    } else if (element is ExportElement) {
      length = 6; // 'export'.length
    } else {
      length = element.nameLength;
    }
    reportErrorForOffset(errorCode, element.nameOffset, length, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments].
   * The [node] is used to compute the location of the error.
   *
   * If the arguments contain the names of two or more types, the method
   * [reportTypeErrorForNode] should be used and the types
   * themselves (rather than their names) should be passed as arguments.
   */
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, node.offset, node.length, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The location of
   * the error is specified by the given [offset] and [length].
   */
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length,
      [List<Object> arguments]) {
    _errorListener.onError(
        new AnalysisError(_source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The location of
   * the error is specified by the given [span].
   */
  void reportErrorForSpan(ErrorCode errorCode, SourceSpan span,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, span.start.offset, span.length, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The [token] is
   * used to compute the location of the error.
   */
  void reportErrorForToken(ErrorCode errorCode, Token token,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, token.offset, token.length, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The [node] is
   * used to compute the location of the error. The arguments are expected to
   * contain two or more types. Convert the types into strings by using the
   * display names of the types, unless there are two or more types with the
   * same names, in which case the extended display names of the types will be
   * used in order to clarify the message.
   *
   * If there are not two or more types in the argument list, the method
   * [reportErrorForNode] should be used instead.
   */
  void reportTypeErrorForNode(
      ErrorCode errorCode, AstNode node, List<Object> arguments) {
    _convertTypeNames(arguments);
    reportErrorForOffset(errorCode, node.offset, node.length, arguments);
  }

  /**
   * Given an array of [arguments] that is expected to contain two or more
   * types, convert the types into strings by using the display names of the
   * types, unless there are two or more types with the same names, in which
   * case the extended display names of the types will be used in order to
   * clarify the message.
   */
  void _convertTypeNames(List<Object> arguments) {
    String displayName(DartType type) {
      if (type is FunctionType) {
        String name = type.name;
        if (name != null && name.length > 0) {
          StringBuffer buffer = new StringBuffer();
          buffer.write(name);
          (type as TypeImpl).appendTo(buffer, new Set.identity());
          return buffer.toString();
        }
      }
      return type.displayName;
    }

    if (_hasEqualTypeNames(arguments)) {
      int count = arguments.length;
      for (int i = 0; i < count; i++) {
        Object argument = arguments[i];
        if (argument is DartType) {
          Element element = argument.element;
          if (element == null) {
            arguments[i] = displayName(argument);
          } else {
            arguments[i] =
                element.getExtendedDisplayName(displayName(argument));
          }
        }
      }
    } else {
      int count = arguments.length;
      for (int i = 0; i < count; i++) {
        Object argument = arguments[i];
        if (argument is DartType) {
          arguments[i] = displayName(argument);
        }
      }
    }
  }

  /**
   * Return `true` if the given array of [arguments] contains two or more types
   * with the same display name.
   */
  bool _hasEqualTypeNames(List<Object> arguments) {
    int count = arguments.length;
    HashSet<String> typeNames = new HashSet<String>();
    for (int i = 0; i < count; i++) {
      Object argument = arguments[i];
      if (argument is DartType && !typeNames.add(argument.displayName)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * An error listener that will record the errors that are reported to it in a
 * way that is appropriate for caching those errors within an analysis context.
 */
class RecordingErrorListener implements AnalysisErrorListener {
  /**
   * A map of sets containing the errors that were collected, keyed by each
   * source.
   */
  Map<Source, HashSet<AnalysisError>> _errors =
      new HashMap<Source, HashSet<AnalysisError>>();

  /**
   * Return the errors collected by the listener.
   */
  List<AnalysisError> get errors {
    int numEntries = _errors.length;
    if (numEntries == 0) {
      return AnalysisError.NO_ERRORS;
    }
    List<AnalysisError> resultList = new List<AnalysisError>();
    for (HashSet<AnalysisError> errors in _errors.values) {
      resultList.addAll(errors);
    }
    return resultList;
  }

  /**
   * Add all of the errors recorded by the given [listener] to this listener.
   */
  void addAll(RecordingErrorListener listener) {
    for (AnalysisError error in listener.errors) {
      onError(error);
    }
  }

  /**
   * Return the errors collected by the listener for the given [source].
   */
  List<AnalysisError> getErrorsForSource(Source source) {
    HashSet<AnalysisError> errorsForSource = _errors[source];
    if (errorsForSource == null) {
      return AnalysisError.NO_ERRORS;
    } else {
      return new List.from(errorsForSource);
    }
  }

  @override
  void onError(AnalysisError error) {
    Source source = error.source;
    HashSet<AnalysisError> errorsForSource = _errors[source];
    if (_errors[source] == null) {
      errorsForSource = new HashSet<AnalysisError>();
      _errors[source] = errorsForSource;
    }
    errorsForSource.add(error);
  }
}

/**
 * An [AnalysisErrorListener] that ignores error.
 */
class _NullErrorListener implements AnalysisErrorListener {
  @override
  void onError(AnalysisError event) {
    // Ignore errors
  }
}
