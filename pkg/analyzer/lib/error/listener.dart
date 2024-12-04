// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart'
    show AstNode, ConstructorDeclaration;
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

/// An object that listens for [AnalysisError]s being produced by the analysis
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

  /// The source to be used when reporting errors.
  final Source _source;

  /// The lock level, if greater than zero, no errors will be reported.
  /// This is used to prevent reporting errors inside comments.
  @internal
  int lockLevel = 0;

  /// Initializes a newly created error reporter that will report errors to the
  /// given [_errorListener].
  ///
  /// Errors will be reported against the [_source] unless another source is
  /// provided later.
  ErrorReporter(this._errorListener, this._source);

  Source get source => _source;

  /// Report a diagnostic with the given [errorCode] and [arguments].
  /// The location of the diagnostic will be the name of the [node].
  void atConstructorDeclaration(
    ConstructorDeclaration node,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    // TODO(brianwilkerson): Consider extending this method to take any
    //  declaration and compute the correct range for the name of that
    //  declaration. This might make it easier to be consistent.
    if (node.name case var nameToken?) {
      var offset = node.returnType.offset;
      atOffset(
        offset: offset,
        length: nameToken.end - offset,
        errorCode: errorCode,
        arguments: arguments,
      );
    } else {
      atNode(
        node.returnType,
        errorCode,
        arguments: arguments,
      );
    }
  }

  /// Report an error with the given [errorCode] and [arguments].
  /// The [element] is used to compute the location of the error.
  void atElement(
    Element element,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    var nonSynthetic = element.nonSynthetic;
    atOffset(
      errorCode: errorCode,
      offset: nonSynthetic.nameOffset,
      length: nonSynthetic.nameLength,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Report an error with the given [errorCode] and [arguments].
  /// The [element] is used to compute the location of the error.
  @experimental
  void atElement2(
    Element2 element,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atElement(
      element.asElement!,
      errorCode,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Report an error with the given [errorCode] and [arguments].
  /// The [entity] is used to compute the location of the error.
  void atEntity(
    SyntacticEntity entity,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atOffset(
      errorCode: errorCode,
      offset: entity.offset,
      length: entity.length,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Report an error with the given [errorCode] and [arguments].
  /// The [node] is used to compute the location of the error.
  void atNode(
    AstNode node,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atOffset(
      errorCode: errorCode,
      offset: node.offset,
      length: node.length,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Report an error with the given [errorCode] and [arguments]. The location
  /// of the error is specified by the given [offset] and [length].
  void atOffset({
    required int offset,
    required int length,
    required ErrorCode errorCode,
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    if (lockLevel != 0) {
      return;
    }

    if (arguments != null) {
      var invalid = arguments
          .whereNotType<String>()
          .whereNotType<DartType>()
          .whereNotType<Element>()
          .whereNotType<int>()
          .whereNotType<Uri>();
      if (invalid.isNotEmpty) {
        throw ArgumentError('Tried to format an error using '
            '${invalid.map((e) => e.runtimeType).join(', ')}');
      }
    }

    contextMessages ??= [];
    contextMessages.addAll(_convertTypeNames(arguments));
    _errorListener.onError(
      AnalysisError.tmp(
        source: _source,
        offset: offset,
        length: length,
        errorCode: errorCode,
        arguments: arguments ?? const [],
        contextMessages: contextMessages,
        data: data,
      ),
    );
  }

  /// Report an error with the given [errorCode] and [arguments].
  /// The [span] is used to compute the location of the error.
  void atSourceSpan(
    SourceSpan span,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atOffset(
      errorCode: errorCode,
      offset: span.start.offset,
      length: span.length,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Report an error with the given [errorCode] and [arguments]. The [token] is
  /// used to compute the location of the error.
  void atToken(
    Token token,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atOffset(
      errorCode: errorCode,
      offset: token.offset,
      length: token.length,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Report the given [error].
  void reportError(AnalysisError error) {
    _errorListener.onError(error);
  }

  /// Given an array of [arguments] that is expected to contain two or more
  /// types, convert the types into strings by using the display names of the
  /// types, unless there are two or more types with the same names, in which
  /// case the extended display names of the types will be used in order to
  /// clarify the message.
  List<DiagnosticMessage> _convertTypeNames(List<Object?>? arguments) {
    if (arguments == null) {
      return const [];
    }

    var typeGroups = <String, List<_ToConvert>>{};
    for (var i = 0; i < arguments.length; i++) {
      var argument = arguments[i];
      if (argument is TypeImpl) {
        var displayName = argument.getDisplayString(preferTypeAlias: true);
        var types = typeGroups.putIfAbsent(displayName, () => []);
        types.add(_TypeToConvert(i, argument, displayName));
      } else if (argument is Element) {
        var displayName = argument.getDisplayString();
        var types = typeGroups.putIfAbsent(displayName, () => []);
        types.add(_ElementToConvert(i, argument, displayName));
      }
    }

    var messages = <DiagnosticMessage>[];
    for (var typeGroup in typeGroups.values) {
      if (typeGroup.length == 1) {
        var typeToConvert = typeGroup[0];
        // If the display name of a type is unambiguous, just replace the type
        // in the arguments list with its display name.
        arguments[typeToConvert.index] = typeToConvert.displayName;
        continue;
      }

      const unnamedExtension = '<unnamed extension>';
      const unnamed = '<unnamed>';
      var nameToElementMap = <String, Set<Element>>{};
      for (var typeToConvert in typeGroup) {
        for (var element in typeToConvert.allElements) {
          var name = element.name;
          name ??= element is ExtensionElement ? unnamedExtension : unnamed;

          var elements = nameToElementMap.putIfAbsent(name, () => {});
          elements.add(element);
        }
      }

      for (var typeToConvert in typeGroup) {
        // TODO(brianwilkerson): When clients do a better job of displaying
        // context messages, remove the extra text added to the buffer.
        StringBuffer? buffer;
        for (var element in typeToConvert.allElements) {
          var name = element.name;
          name ??= element is ExtensionElement ? unnamedExtension : unnamed;
          var sourcePath = element.source!.fullName;
          if (nameToElementMap[name]!.length > 1) {
            if (buffer == null) {
              buffer = StringBuffer();
              buffer.write('where ');
            } else {
              buffer.write(', ');
            }
            buffer.write('$name is defined in $sourcePath');
          }
          messages.add(DiagnosticMessageImpl(
            filePath: element.source!.fullName,
            length: element.nameLength,
            message: '$name is defined in $sourcePath',
            offset: element.nameOffset,
            url: null,
          ));
        }

        arguments[typeToConvert.index] = buffer != null
            ? '${typeToConvert.displayName} ($buffer)'
            : typeToConvert.displayName;
      }
    }
    return messages;
  }
}

/// An error listener that will record the errors that are reported to it in a
/// way that is appropriate for caching those errors within an analysis context.
class RecordingErrorListener implements AnalysisErrorListener {
  Set<AnalysisError>? _errors;

  /// Return the errors collected by the listener.
  List<AnalysisError> get errors {
    if (_errors == null) {
      return const [];
    }
    return _errors!.toList();
  }

  /// Return the errors collected by the listener for the given [source].
  List<AnalysisError> getErrorsForSource(Source source) {
    if (_errors == null) {
      return const [];
    }
    return _errors!.where((error) => error.source == source).toList();
  }

  @override
  void onError(AnalysisError error) {
    (_errors ??= {}).add(error);
  }
}

/// Used by [ErrorReporter._convertTypeNames] to keep track of an error argument
/// that is an [Element], that is being converted to a display string.
class _ElementToConvert implements _ToConvert {
  @override
  final int index;

  @override
  final String displayName;

  @override
  final Iterable<Element> allElements;

  _ElementToConvert(this.index, Element element, this.displayName)
      : allElements = [element];
}

/// An [AnalysisErrorListener] that ignores error.
class _NullErrorListener implements AnalysisErrorListener {
  @override
  void onError(AnalysisError event) {
    // Ignore errors
  }
}

/// Used by [ErrorReporter._convertTypeNames] to keep track of an argument that
/// is being converted to a display string.
abstract class _ToConvert {
  /// A list of all elements involved in the [DartType] or [Element]'s display
  /// string.
  Iterable<Element> get allElements;

  /// The argument's display string, to replace the argument in the argument
  /// list.
  String get displayName;

  /// The index of the argument in the argument list.
  int get index;
}

/// Used by [ErrorReporter._convertTypeNames] to keep track of an error argument
/// that is a [DartType], that is being converted to a display string.
class _TypeToConvert implements _ToConvert {
  @override
  final int index;

  final DartType _type;

  @override
  final String displayName;

  @override
  late final Iterable<Element> allElements = () {
    var elements = <Element>{};

    void addElementsFrom(DartType type) {
      if (type is FunctionType) {
        addElementsFrom(type.returnType);
        for (var parameter in type.parameters) {
          addElementsFrom(parameter.type);
        }
      } else if (type is RecordType) {
        for (var parameter in type.fields) {
          addElementsFrom(parameter.type);
        }
      } else if (type is InterfaceType) {
        if (elements.add(type.element)) {
          for (var typeArgument in type.typeArguments) {
            addElementsFrom(typeArgument);
          }
        }
      }
    }

    addElementsFrom(_type);
    return elements.where((element) {
      var name = element.name;
      return name != null && name.isNotEmpty;
    });
  }();

  _TypeToConvert(this.index, this._type, this.displayName);
}
