// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.diagnostic_listener;

import 'package:front_end/src/api_unstable/dart2js.dart' as ir
    show LocatedMessage;

import '../../compiler_api.dart' as api;
import '../compiler.dart' show Compiler;
import '../elements/entities.dart';
import '../options.dart';
import 'messages.dart';
import 'source_span.dart' show SourceSpan;
import 'spannable.dart';
import 'spannable_with_entity.dart';

class DiagnosticReporter {
  final Compiler _compiler;

  CompilerOptions get options => _compiler.options;

  Entity? _currentElement;
  bool _hasCrashed = false;

  /// `true` if the last diagnostic was filtered, in which case the
  /// accompanying info message should be filtered as well.
  bool _lastDiagnosticWasFiltered = false;

  /// Map containing information about the warnings and hints that have been
  /// suppressed for each library.
  final Map<Uri, SuppressionInfo> _suppressedWarnings = {};

  DiagnosticReporter(this._compiler);

  Entity? get currentElement => _currentElement;

  DiagnosticMessage createMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    SourceSpan span = spanFromSpannable(spannable);
    MessageTemplate template = MessageTemplate.TEMPLATES[messageKind]!;
    Message message = template.message(arguments, options);
    return DiagnosticMessage(span, spannable, message);
  }

  DiagnosticCfeMessage createCfeMessage(
      Spannable spannable, MessageKind messageKind, String messageCode,
      [Map<String, String> arguments = const {}]) {
    SourceSpan span = spanFromSpannable(spannable);
    MessageTemplate template = MessageTemplate.TEMPLATES[messageKind]!;
    Message message = template.message(arguments, options);
    return DiagnosticCfeMessage(span, spannable, message, messageCode);
  }

  void reportError(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    _reportDiagnosticInternal(message, infos, api.Diagnostic.error);
  }

  void reportErrorMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    reportError(createMessage(spannable, messageKind, arguments));
  }

  void reportWarning(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    _reportDiagnosticInternal(message, infos, api.Diagnostic.warning);
  }

  void reportWarningMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    reportWarning(createMessage(spannable, messageKind, arguments));
  }

  void reportHint(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    _reportDiagnosticInternal(message, infos, api.Diagnostic.hint);
  }

  void reportHintMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    reportHint(createMessage(spannable, messageKind, arguments));
  }

  void reportInfo(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    _reportDiagnosticInternal(message, infos, api.Diagnostic.info);
  }

  void reportInfoMessage(Spannable node, MessageKind errorCode,
      [Map<String, String> arguments = const {}]) {
    reportInfo(createMessage(node, errorCode, arguments));
  }

  void _reportDiagnosticInternal(DiagnosticMessage message,
      List<DiagnosticMessage> infos, api.Diagnostic kind) {
    if (!options.showAllPackageWarnings &&
        message.spannable != NO_LOCATION_SPANNABLE) {
      switch (kind) {
        case api.Diagnostic.warning:
        case api.Diagnostic.hint:
          Entity? element = _elementFromSpannable(message.spannable);
          if (element != null && !_compiler.inUserCode(element)) {
            Uri uri = _compiler.getCanonicalUri(element)!;
            if (options.showPackageWarningsFor(uri)) {
              _reportDiagnostic(message, infos, kind);
              return;
            }
            SuppressionInfo info =
                _suppressedWarnings.putIfAbsent(uri, () => SuppressionInfo());
            if (kind == api.Diagnostic.warning) {
              info.warnings++;
            } else {
              info.hints++;
            }
            _lastDiagnosticWasFiltered = true;
            return;
          }
          break;
        case api.Diagnostic.info:
          if (_lastDiagnosticWasFiltered) {
            return;
          }
          break;
        case api.Diagnostic.error:
        case api.Diagnostic.verboseInfo:
        case api.Diagnostic.crash:
        case api.Diagnostic.context:
          break;
      }
    }
    _lastDiagnosticWasFiltered = false;
    _reportDiagnostic(message, infos, kind);
  }

  void _reportDiagnostic(DiagnosticMessage message,
      List<DiagnosticMessage> infos, api.Diagnostic kind) {
    _compiler.reportDiagnostic(message, infos, kind);
    if (kind == api.Diagnostic.error ||
        kind == api.Diagnostic.crash ||
        (options.fatalWarnings && kind == api.Diagnostic.warning)) {
      _compiler.fatalDiagnosticReported(message, infos, kind);
    }
  }

  /// Returns `true` if a crash, an error or a fatal warning has been reported.
  bool get hasReportedError => _compiler.compilationFailed;

  /// Set current element of this reporter to [element]. This is used for
  /// creating [SourceSpan] in [spanFromSpannable]. That is,
  /// [withCurrentElement] performs an operation, [f], returning the return
  /// value from [f].  If an error occurs then report it as having occurred
  /// during compilation of [element].  Can be nested.
  dynamic withCurrentElement(Entity element, dynamic f()) {
    Entity? old = currentElement;
    _currentElement = element;
    try {
      return f();
    } on SpannableAssertionFailure catch (ex) {
      if (!_hasCrashed) {
        _reportAssertionFailure(ex);
        _pleaseReportCrash();
      }
      _hasCrashed = true;
      rethrow;
    } on StackOverflowError {
      // We cannot report anything useful in this case, because we
      // do not have enough stack space.
      rethrow;
    } catch (ex) {
      if (_hasCrashed) rethrow;
      try {
        _unhandledExceptionOnElement(element);
      } catch (doubleFault) {
        // Ignoring exceptions in exception handling.
      }
      rethrow;
    } finally {
      _currentElement = old;
    }
  }

  void _reportAssertionFailure(SpannableAssertionFailure ex) {
    String message =
        (ex.message != null) ? tryToString(ex.message!) : tryToString(ex);
    _reportDiagnosticInternal(
        createMessage(ex.node, MessageKind.GENERIC, {'text': message}),
        const <DiagnosticMessage>[],
        api.Diagnostic.crash);
  }

  /// Use the compiler context [SourceSpan] from spannable using the
  /// [currentElement] as context.
  SourceSpan _spanFromStrategy(Spannable spannable) {
    return _compiler.spanFromSpannable(spannable, currentElement);
  }

  /// Creates a [SourceSpan] for [node] in scope of the current element.
  ///
  /// If [node] is a [Node] we assert in checked mode that the corresponding
  /// tokens can be found within the tokens of the current element.
  SourceSpan spanFromSpannable(Spannable spannable) {
    if (spannable == CURRENT_ELEMENT_SPANNABLE) {
      if (currentElement == null) return SourceSpan.unknown();
      spannable = currentElement!;
    } else if (spannable == NO_LOCATION_SPANNABLE) {
      if (currentElement == null) return SourceSpan.unknown();
      spannable = currentElement!;
    }
    if (spannable is SourceSpan) {
      return spannable;
    }
    if (spannable is SpannableWithEntity) {
      SourceSpan? span = spannable.sourceSpan;
      if (span != null) return span;
      Entity? element = spannable.sourceEntity ?? currentElement;
      if (element == null) return SourceSpan.unknown();
      return _spanFromStrategy(element);
    }
    return _spanFromStrategy(spannable);
  }

  Never internalError(Spannable? spannable, Object reason) {
    String message = tryToString(reason);
    _reportDiagnosticInternal(
        createMessage(spannable ?? SourceSpan.unknown(), MessageKind.GENERIC,
            {'text': message}),
        const <DiagnosticMessage>[],
        api.Diagnostic.crash);
    throw 'Internal Error: $message';
  }

  void _unhandledExceptionOnElement(Entity element) {
    if (_hasCrashed) return;
    _hasCrashed = true;
    _reportDiagnostic(createMessage(element, MessageKind.COMPILER_CRASHED),
        const <DiagnosticMessage>[], api.Diagnostic.crash);
    _pleaseReportCrash();
  }

  void _pleaseReportCrash() {
    print(MessageTemplate.TEMPLATES[MessageKind.PLEASE_REPORT_THE_CRASH]!
        .message({'buildId': _compiler.options.buildId}, options));
  }

  /// Finds the approximate [Element] for [node]. [currentElement] is used as
  /// the default value.
  Entity? _elementFromSpannable(Spannable? node) {
    Entity? element;
    if (node is Entity) {
      element = node;
    } else if (node is SpannableWithEntity) {
      element = node.sourceEntity;
    }
    return element ?? currentElement;
  }

  void log(Object message) {
    Message msg = MessageTemplate.TEMPLATES[MessageKind.GENERIC]!
        .message({'text': '$message'}, options);
    _reportDiagnostic(
        DiagnosticMessage(SourceSpan.unknown(), NO_LOCATION_SPANNABLE, msg),
        const <DiagnosticMessage>[],
        api.Diagnostic.verboseInfo);
  }

  String tryToString(Object object) {
    try {
      return object.toString();
    } catch (_) {
      return '<exception in toString()>';
    }
  }

  Future<Never> onError(Uri? uri, Object error, StackTrace stackTrace) {
    try {
      if (!_hasCrashed) {
        _hasCrashed = true;
        if (error is SpannableAssertionFailure) {
          _reportAssertionFailure(error);
        } else {
          _reportDiagnostic(
              createMessage(
                  SourceSpan(uri ?? Uri(), 0, 0), MessageKind.COMPILER_CRASHED),
              const <DiagnosticMessage>[],
              api.Diagnostic.crash);
        }
        _pleaseReportCrash();
      }
    } catch (doubleFault) {
      // Ignoring exceptions in exception handling.
    }
    return Future.error(error, stackTrace);
  }

  /// Called when an [exception] is thrown from user-provided code, like from
  /// the input provider or diagnostics handler.
  void onCrashInUserCode(
      String message, Object exception, StackTrace stackTrace) {
    _hasCrashed = true;
    print('$message: ${tryToString(exception)}');
    print(tryToString(stackTrace));
  }

  void reportSuppressedMessagesSummary() {
    if (!options.showAllPackageWarnings && !options.suppressWarnings) {
      _suppressedWarnings.forEach((Uri uri, SuppressionInfo info) {
        MessageKind kind = MessageKind.HIDDEN_WARNINGS_HINTS;
        if (info.warnings == 0) {
          kind = MessageKind.HIDDEN_HINTS;
        } else if (info.hints == 0) {
          kind = MessageKind.HIDDEN_WARNINGS;
        }
        MessageTemplate template = MessageTemplate.TEMPLATES[kind]!;
        Message message = template.message({
          'warnings': info.warnings.toString(),
          'hints': info.hints.toString(),
          'uri': uri.toString(),
        }, options);
        _reportDiagnostic(
            DiagnosticMessage(
                SourceSpan.unknown(), NO_LOCATION_SPANNABLE, message),
            const <DiagnosticMessage>[],
            api.Diagnostic.hint);
      });
    }
  }
}

class DiagnosticMessage {
  final SourceSpan sourceSpan;
  final Spannable spannable;
  final Message message;

  DiagnosticMessage(this.sourceSpan, this.spannable, this.message);
}

/// Message generated by the CFE with an additional CFE-specific [messageCode].
class DiagnosticCfeMessage extends DiagnosticMessage {
  final String messageCode;

  DiagnosticCfeMessage(
      super.sourceSpan, super.spannable, super.message, this.messageCode);
}

/// Information about suppressed warnings and hints for a given library.
class SuppressionInfo {
  int warnings = 0;
  int hints = 0;
}

void reportLocatedMessage(DiagnosticReporter reporter,
    ir.LocatedMessage message, List<ir.LocatedMessage>? context) {
  DiagnosticMessage diagnosticMessage =
      _createDiagnosticMessage(reporter, message);
  var infos = <DiagnosticMessage>[];
  if (context != null) {
    for (ir.LocatedMessage message in context) {
      infos.add(_createDiagnosticMessage(reporter, message));
    }
  }
  reporter.reportError(diagnosticMessage, infos);
}

DiagnosticMessage _createDiagnosticMessage(
    DiagnosticReporter reporter, ir.LocatedMessage message) {
  var sourceSpan = SourceSpan(
      message.uri!, message.charOffset, message.charOffset + message.length);
  return reporter.createCfeMessage(sourceSpan, MessageKind.GENERIC,
      message.code.name, {'text': message.problemMessage});
}
