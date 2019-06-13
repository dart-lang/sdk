// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart' show AstNode;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/fasta/fasta_codes.dart' show Message;
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
   * Report an error with the given [errorCode] and [message]. The location of
   * the error is specified by the given [offset] and [length].
   */
  void reportErrorMessage(
      ErrorCode errorCode, int offset, int length, Message message) {
    _errorListener.onError(new AnalysisError.forValues(
        _source, offset, length, errorCode, message.message, message.tip));
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
    String computeDisplayName(DartType type) {
      if (type is FunctionType) {
        String name = type.name;
        if (name != null && name.isNotEmpty) {
          StringBuffer buffer = new StringBuffer();
          buffer.write(name);
          (type as TypeImpl).appendTo(buffer, new Set.identity());
          return buffer.toString();
        }
      }
      return type.displayName;
    }

    Map<String, List<_TypeToConvert>> typeGroups = {};
    for (int i = 0; i < arguments.length; i++) {
      Object argument = arguments[i];
      if (argument is DartType) {
        String displayName = computeDisplayName(argument);
        List<_TypeToConvert> types =
            typeGroups.putIfAbsent(displayName, () => <_TypeToConvert>[]);
        types.add(new _TypeToConvert(i, argument, displayName));
      }
    }
    for (List<_TypeToConvert> typeGroup in typeGroups.values) {
      if (typeGroup.length == 1) {
        _TypeToConvert typeToConvert = typeGroup[0];
        if (typeToConvert.type is DartType) {
          arguments[typeToConvert.index] = typeToConvert.displayName;
        }
      } else {
        Map<String, Set<Element>> nameToElementMap = {};
        for (_TypeToConvert typeToConvert in typeGroup) {
          for (Element element in typeToConvert.allElements()) {
            Set<Element> elements = nameToElementMap.putIfAbsent(
                element.name, () => new Set<Element>());
            elements.add(element);
          }
        }
        for (_TypeToConvert typeToConvert in typeGroup) {
          // TODO(brianwilkerson) When analyzer supports info or context
          //  messages, expose the additional information that way (rather
          //  than being poorly inserted into the problem message).
          StringBuffer buffer;
          for (Element element in typeToConvert.allElements()) {
            String name = element.name;
            if (nameToElementMap[name].length > 1) {
              if (buffer == null) {
                buffer = new StringBuffer();
                buffer.write('where ');
              } else {
                buffer.write(', ');
              }
              buffer.write('$name is defined in ${element.source.fullName}');
            }
          }

          if (buffer != null) {
            arguments[typeToConvert.index] =
                '${typeToConvert.displayName} ($buffer)';
          } else {
            arguments[typeToConvert.index] = typeToConvert.displayName;
          }
        }
      }
    }
  }
}

/**
 * An error listener that will record the errors that are reported to it in a
 * way that is appropriate for caching those errors within an analysis context.
 */
class RecordingErrorListener implements AnalysisErrorListener {
  Set<AnalysisError> _errors;

  /**
   * Return the errors collected by the listener.
   */
  List<AnalysisError> get errors {
    if (_errors == null) {
      return const <AnalysisError>[];
    }
    return _errors.toList();
  }

  /**
   * Return the errors collected by the listener for the given [source].
   */
  List<AnalysisError> getErrorsForSource(Source source) {
    if (_errors == null) {
      return const <AnalysisError>[];
    }
    return _errors.where((error) => error.source == source).toList();
  }

  @override
  void onError(AnalysisError error) {
    _errors ??= new HashSet<AnalysisError>();
    _errors.add(error);
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

/**
 * Used by `ErrorReporter._convertTypeNames` to keep track of a type that is
 * being converted.
 */
class _TypeToConvert {
  final int index;
  final DartType type;
  final String displayName;

  List<Element> _allElements;

  _TypeToConvert(this.index, this.type, this.displayName);

  List<Element> allElements() {
    if (_allElements == null) {
      Set<Element> elements = new Set<Element>();

      void addElementsFrom(DartType type) {
        if (type is FunctionType) {
          addElementsFrom(type.returnType);
          for (ParameterElement parameter in type.parameters) {
            addElementsFrom(parameter.type);
          }
        } else if (type is InterfaceType) {
          if (elements.add(type.element)) {
            for (DartType typeArgument in type.typeArguments) {
              addElementsFrom(typeArgument);
            }
          }
        }
      }

      addElementsFrom(type);
      _allElements = elements
          .where((element) => element.name != null && element.name.isNotEmpty)
          .toList();
    }
    return _allElements;
  }
}
