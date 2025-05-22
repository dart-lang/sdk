// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart'
    show AstNode, ConstructorDeclaration;
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

/// An object that listens for [Diagnostic]s being produced by the analysis
/// engine.
abstract class AnalysisErrorListener {
  /// An error listener that ignores errors that are reported to it.
  static final AnalysisErrorListener NULL_LISTENER = _NullErrorListener();

  /// This method is invoked when an [error] has been found by the analysis
  /// engine.
  void onError(Diagnostic error);
}

/// An [AnalysisErrorListener] that keeps track of whether any error has been
/// reported to it.
class BooleanErrorListener implements AnalysisErrorListener {
  /// A flag indicating whether an error has been reported to this listener.
  bool _errorReported = false;

  /// Return `true` if an error has been reported to this listener.
  bool get errorReported => _errorReported;

  @override
  void onError(Diagnostic error) {
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

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The location of the diagnostic will be the name of the [node].
  void atConstructorDeclaration(
    ConstructorDeclaration node,
    DiagnosticCode diagnosticCode, {
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
        diagnosticCode: diagnosticCode,
        arguments: arguments,
      );
    } else {
      atNode(node.returnType, diagnosticCode, arguments: arguments);
    }
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [element] is used to compute the location of the diagnostic.
  @experimental
  void atElement2(
    Element element,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    var nonSynthetic = element.nonSynthetic2;
    atOffset(
      diagnosticCode: diagnosticCode,
      offset: nonSynthetic.firstFragment.nameOffset2 ?? -1,
      length: nonSynthetic.name3?.length ?? 0,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [entity] is used to compute the location of the diagnostic.
  void atEntity(
    SyntacticEntity entity,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atOffset(
      diagnosticCode: diagnosticCode,
      offset: entity.offset,
      length: entity.length,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [node] is used to compute the location of the diagnostic.
  void atNode(
    AstNode node,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atOffset(
      diagnosticCode: diagnosticCode,
      offset: node.offset,
      length: node.length,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] (or [errorCode],
  /// deprecated) and [arguments].
  ///
  /// The location of the diagnostic is specified by the given [offset] and
  /// [length].
  void atOffset({
    required int offset,
    required int length,
    @Deprecated("Use 'diagnosticCode' instead") DiagnosticCode? errorCode,
    DiagnosticCode? diagnosticCode,
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    if (lockLevel != 0) {
      return;
    }
    if ((errorCode == null && diagnosticCode == null) ||
        (errorCode != null && diagnosticCode != null)) {
      throw ArgumentError(
        "Exactly one of 'errorCode' (deprecated) and 'diagnosticCode' should be given",
      );
    }

    diagnosticCode ??= errorCode!;

    if (arguments != null) {
      var invalid =
          arguments
              .whereNotType<String>()
              .whereNotType<DartType>()
              .whereNotType<Element>()
              .whereNotType<int>()
              .whereNotType<Uri>();
      if (invalid.isNotEmpty) {
        throw ArgumentError(
          'Tried to format an error using '
          '${invalid.map((e) => e.runtimeType).join(', ')}',
        );
      }
    }

    contextMessages ??= [];
    contextMessages.addAll(convertTypeNames(arguments));
    _errorListener.onError(
      Diagnostic.tmp(
        source: _source,
        offset: offset,
        length: length,
        errorCode: diagnosticCode,
        arguments: arguments ?? const [],
        contextMessages: contextMessages,
        data: data,
      ),
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [span] is used to compute the location of the diagnostic.
  void atSourceSpan(
    SourceSpan span,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atOffset(
      diagnosticCode: diagnosticCode,
      offset: span.start.offset,
      length: span.length,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [token] is used to compute the location of the diagnostic.
  void atToken(
    Token token,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    atOffset(
      diagnosticCode: diagnosticCode,
      offset: token.offset,
      length: token.length,
      arguments: arguments,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// Report the given [error].
  void reportError(Diagnostic error) {
    _errorListener.onError(error);
  }
}

/// An error listener that will record the errors that are reported to it in a
/// way that is appropriate for caching those errors within an analysis context.
class RecordingErrorListener implements AnalysisErrorListener {
  Set<Diagnostic>? _errors;

  /// Return the errors collected by the listener.
  List<Diagnostic> get errors {
    if (_errors == null) {
      return const [];
    }
    return _errors!.toList();
  }

  /// Return the errors collected by the listener for the given [source].
  List<Diagnostic> getErrorsForSource(Source source) {
    if (_errors == null) {
      return const [];
    }
    return _errors!.where((error) => error.source == source).toList();
  }

  @override
  void onError(Diagnostic error) {
    (_errors ??= {}).add(error);
  }
}

/// An [AnalysisErrorListener] that ignores error.
class _NullErrorListener implements AnalysisErrorListener {
  @override
  void onError(Diagnostic event) {
    // Ignore errors
  }
}
