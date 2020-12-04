// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/messages/codes.dart' show Message;
import 'package:analyzer/dart/ast/ast.dart'
    show AstNode, ConstructorDeclaration;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:source_span/source_span.dart';

/// An object that listen for [AnalysisError]s being produced by the analysis
/// engine.
abstract class AnalysisErrorListener {
  /// An error listener that ignores errors that are reported to it.
  static final AnalysisErrorListener NULL_LISTENER = _NullErrorListener();

  /// This method is invoked when an [error] has been found by the analysis
  /// engine.
  void onError(AnalysisError error);
}

/// An [AnalysisErrorListener] that keeps track of whether any error has been
/// reported to it.
class BooleanErrorListener implements AnalysisErrorListener {
  /// A flag indicating whether an error has been reported to this listener.
  bool _errorReported = false;

  /// Return `true` if an error has been reported to this listener.
  bool get errorReported => _errorReported;

  @override
  void onError(AnalysisError error) {
    _errorReported = true;
  }
}

/// An object used to create analysis errors and report then to an error
/// listener.
class ErrorReporter {
  /// The error listener to which errors will be reported.
  final AnalysisErrorListener _errorListener;

  /// The default source to be used when reporting errors.
  final Source _defaultSource;

  /// Is `true` if the library being analyzed is non-nullable by default.
  final bool isNonNullableByDefault;

  /// The source to be used when reporting errors.
  Source _source;

  /// Initialize a newly created error reporter that will report errors to the
  /// given [_errorListener]. Errors will be reported against the
  /// [_defaultSource] unless another source is provided later.
  ErrorReporter(this._errorListener, this._defaultSource,
      {this.isNonNullableByDefault = false}) {
    if (_errorListener == null) {
      throw ArgumentError("An error listener must be provided");
    } else if (_defaultSource == null) {
      throw ArgumentError("A default source must be provided");
    }
    _source = _defaultSource;
  }

  Source get source => _source;

  /// Set the source to be used when reporting errors to the given [source].
  /// Setting the source to `null` will cause the default source to be used.
  @Deprecated('Create separate reporters for separate files')
  set source(Source source) {
    _source = source ?? _defaultSource;
  }

  /// Report the given [error].
  void reportError(AnalysisError error) {
    _errorListener.onError(error);
  }

  /// Report an error with the given [errorCode] and [arguments]. The [element]
  /// is used to compute the location of the error.
  void reportErrorForElement(ErrorCode errorCode, Element element,
      [List<Object> arguments]) {
    reportErrorForOffset(
        errorCode, element.nameOffset, element.nameLength, arguments);
  }

  /// Report a diagnostic with the given [code] and [arguments]. The
  /// location of the diagnostic will be the name of the [constructor].
  void reportErrorForName(ErrorCode code, ConstructorDeclaration constructor,
      {List<Object> arguments}) {
    // TODO(brianwilkerson) Consider extending this method to take any
    //  declaration and compute the correct range for the name of that
    //  declaration. This might make it easier to be consistent.
    if (constructor.name != null) {
      var offset = constructor.returnType.offset;
      reportErrorForOffset(
          code, offset, constructor.name.end - offset, arguments);
    } else {
      reportErrorForNode(code, constructor.returnType, arguments);
    }
  }

  /// Report an error with the given [errorCode] and [arguments].
  /// The [node] is used to compute the location of the error.
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, node.offset, node.length, arguments);
  }

  /// Report an error with the given [errorCode] and [arguments]. The location
  /// of the error is specified by the given [offset] and [length].
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length,
      [List<Object> arguments]) {
    _convertElements(arguments);
    var messages = _convertTypeNames(arguments);
    _errorListener.onError(
        AnalysisError(_source, offset, length, errorCode, arguments, messages));
  }

  /// Report an error with the given [errorCode] and [arguments]. The location
  /// of the error is specified by the given [span].
  void reportErrorForSpan(ErrorCode errorCode, SourceSpan span,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, span.start.offset, span.length, arguments);
  }

  /// Report an error with the given [errorCode] and [arguments]. The [token] is
  /// used to compute the location of the error.
  void reportErrorForToken(ErrorCode errorCode, Token token,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, token.offset, token.length, arguments);
  }

  /// Report an error with the given [errorCode] and [message]. The location of
  /// the error is specified by the given [offset] and [length].
  void reportErrorMessage(
      ErrorCode errorCode, int offset, int length, Message message) {
    _errorListener.onError(AnalysisError.forValues(
        _source, offset, length, errorCode, message.message, message.tip));
  }

  /// Report an error with the given [errorCode] and [arguments]. The [node] is
  /// used to compute the location of the error. The arguments are expected to
  /// contain two or more types. Convert the types into strings by using the
  /// display names of the types, unless there are two or more types with the
  /// same names, in which case the extended display names of the types will be
  /// used in order to clarify the message.
  ///
  /// If there are not two or more types in the argument list, the method
  /// [reportErrorForNode] should be used instead.
  @Deprecated('Use reportErrorForNode(), it will convert types as well')
  void reportTypeErrorForNode(
      ErrorCode errorCode, AstNode node, List<Object> arguments) {
    reportErrorForOffset(errorCode, node.offset, node.length, arguments);
  }

  /// Convert all [Element]s in the [arguments] into their display strings.
  void _convertElements(List<Object> arguments) {
    if (arguments == null) {
      return;
    }

    for (var i = 0; i < arguments.length; i++) {
      var argument = arguments[i];
      if (argument is Element) {
        arguments[i] = argument.getDisplayString(
          withNullability: isNonNullableByDefault,
        );
      }
    }
  }

  /// Given an array of [arguments] that is expected to contain two or more
  /// types, convert the types into strings by using the display names of the
  /// types, unless there are two or more types with the same names, in which
  /// case the extended display names of the types will be used in order to
  /// clarify the message.
  List<DiagnosticMessage> _convertTypeNames(List<Object> arguments) {
    var messages = <DiagnosticMessage>[];
    if (arguments == null) {
      return messages;
    }

    Map<String, List<_TypeToConvert>> typeGroups = {};
    for (int i = 0; i < arguments.length; i++) {
      Object argument = arguments[i];
      if (argument is DartType) {
        String displayName = argument.getDisplayString(
          withNullability: isNonNullableByDefault,
        );
        List<_TypeToConvert> types =
            typeGroups.putIfAbsent(displayName, () => <_TypeToConvert>[]);
        types.add(_TypeToConvert(i, argument, displayName));
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
            Set<Element> elements =
                nameToElementMap.putIfAbsent(element.name, () => <Element>{});
            elements.add(element);
          }
        }
        for (_TypeToConvert typeToConvert in typeGroup) {
          // TODO(brianwilkerson) When clients do a better job of displaying
          // context messages, remove the extra text added to the buffer.
          StringBuffer buffer;
          for (Element element in typeToConvert.allElements()) {
            String name = element.name;
            if (nameToElementMap[name].length > 1) {
              if (buffer == null) {
                buffer = StringBuffer();
                buffer.write('where ');
              } else {
                buffer.write(', ');
              }
              buffer.write('$name is defined in ${element.source.fullName}');
            }
            messages.add(DiagnosticMessageImpl(
                filePath: element.source.fullName,
                length: element.nameLength,
                message: '$name is defined in ${element.source.fullName}',
                offset: element.nameOffset));
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
    return messages;
  }
}

/// An error listener that will record the errors that are reported to it in a
/// way that is appropriate for caching those errors within an analysis context.
class RecordingErrorListener implements AnalysisErrorListener {
  Set<AnalysisError> _errors;

  /// Return the errors collected by the listener.
  List<AnalysisError> get errors {
    if (_errors == null) {
      return const <AnalysisError>[];
    }
    return _errors.toList();
  }

  /// Return the errors collected by the listener for the given [source].
  List<AnalysisError> getErrorsForSource(Source source) {
    if (_errors == null) {
      return const <AnalysisError>[];
    }
    return _errors.where((error) => error.source == source).toList();
  }

  @override
  void onError(AnalysisError error) {
    _errors ??= HashSet<AnalysisError>();
    _errors.add(error);
  }
}

/// An [AnalysisErrorListener] that ignores error.
class _NullErrorListener implements AnalysisErrorListener {
  @override
  void onError(AnalysisError event) {
    // Ignore errors
  }
}

/// Used by `ErrorReporter._convertTypeNames` to keep track of a type that is
/// being converted.
class _TypeToConvert {
  final int index;
  final DartType type;
  final String displayName;

  List<Element> _allElements;

  _TypeToConvert(this.index, this.type, this.displayName);

  List<Element> allElements() {
    if (_allElements == null) {
      Set<Element> elements = <Element>{};

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
