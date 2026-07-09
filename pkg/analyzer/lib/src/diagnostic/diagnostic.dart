// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/diagnostic/diagnostic.dart';
/// @docImport 'package:analyzer/error/listener.dart';
library;

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:source_span/source_span.dart';

part 'package:analyzer/src/diagnostic/diagnostic.g.dart';

/// Private subtype of [DiagnosticCode] that supports runtime checking of
/// parameter types.
class DiagnosticCodeWithExpectedTypes extends DiagnosticCodeImpl {
  final List<ExpectedType>? expectedTypes;

  const DiagnosticCodeWithExpectedTypes({
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.name,
    required super.problemMessage,
    required super.type,
    required super.uniqueName,
    this.expectedTypes,
  });
}

/// A single message associated with a [Diagnostic], consisting of the text of
/// the message and the location associated with it.
///
/// Clients may not extend, implement or mix-in this class.
@AnalyzerPublicApi(
  message: 'Exported by package:analyzer/diagnostic/diagnostic.dart',
)
abstract class DiagnosticMessage {
  /// The absolute and normalized path of the file associated with this message.
  String get filePath;

  /// The length of the source range associated with this message.
  int get length;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  int get offset;

  /// The URL containing documentation about this diagnostic message, if any.
  ///
  /// Note: this should not be confused with the location in the user's code
  /// where the error was reported; that information can be obtained from
  /// [filePath], [length], and [offset].
  String? get url;

  /// Gets the text of the message.
  ///
  /// If [includeUrl] is `true`, and this diagnostic message has an associated
  /// URL, it is included in the returned value in a human-readable way.
  /// Clients that wish to present URLs as simple text can do this. If
  /// [includeUrl] is `false`, no URL is included in the returned value.
  /// Clients that have a special mechanism for presenting URLs (e.g. as a
  /// clickable link) should do this and then consult the [url] getter to access
  /// the URL.
  String messageText({required bool includeUrl});
}

/// A concrete implementation of a diagnostic message.
class DiagnosticMessageImpl implements DiagnosticMessage {
  @override
  final String filePath;

  @override
  final int length;

  final String _message;

  @override
  final int offset;

  @override
  final String? url;

  /// Initialize a newly created message to represent a [message] reported in
  /// the file at the given [filePath] at the given [offset] and with the given
  /// [length].
  DiagnosticMessageImpl({
    required this.filePath,
    required this.length,
    required String message,
    required this.offset,
    required this.url,
  }) : _message = message;

  @override
  String messageText({required bool includeUrl}) {
    if (includeUrl && url != null) {
      var result = StringBuffer(_message);
      if (!_message.endsWith('.')) {
        result.write('.');
      }
      result.write('  See $url');
      return result.toString();
    }
    return _message;
  }
}

/// Common functionality for [DiagnosticCode]-derived classes that represent
/// errors that take arguments.
///
/// This class provides a [withArguments] getter, which can be used to supply
/// arguments and produce a [LocatableDiagnostic].
///
/// Note: the type argument `T` should be instantiated with a function type. But
/// it is typed as `extends Object` in order to reduce the risk of accidental
/// dynamic invocation of [withArguments].
class DiagnosticWithArguments<T extends Object>
    extends DiagnosticCodeWithExpectedTypes {
  /// Function accepting named arguments and returning [LocatableDiagnostic].
  ///
  /// The value returned by this function can
  /// be associated with a location in the source code using the
  /// [LocatableDiagnostic.at] method, and then the result can be passed to
  /// [DiagnosticReporter.reportError].
  final T withArguments;

  const DiagnosticWithArguments({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.type,
    required super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

/// Common functionality for [DiagnosticCode]-derived classes that represent
/// errors that do not take arguments.
///
/// This class implements [LocatableDiagnostic], which means that instances can
/// be associated with a location in the source code using the [at] method, and
/// then the result can be passed to [DiagnosticReporter.reportError].
base mixin DiagnosticWithoutArguments on DiagnosticCodeImpl
    implements LocatableDiagnostic {
  @override
  List<Object> get arguments => const [];

  @override
  DiagnosticCode get code => this;

  @override
  Iterable<DiagnosticMessage> get contextMessages => const [];

  @override
  LocatedDiagnostic at(SyntacticEntity node) =>
      atOffset(offset: node.offset, length: node.length);

  @override
  LocatedDiagnostic atOffset({required int offset, required int length}) =>
      LocatedDiagnostic(this, offset, length);

  @override
  LocatedDiagnostic atSourceRange(SourceRange sourceRange) =>
      atOffset(offset: sourceRange.offset, length: sourceRange.length);

  @override
  LocatedDiagnostic atSourceSpan(SourceSpan span) {
    var trimmedSpan = span.withoutTrailingLineTerminators;
    return atOffset(
      offset: trimmedSpan.start.offset,
      length: trimmedSpan.length,
    );
  }

  @override
  LocatableDiagnostic withContextMessages(
    Iterable<DiagnosticMessage> messages,
  ) => LocatableDiagnosticImpl(code, arguments, contextMessages: [...messages]);
}

/// Concrete implementation of [DiagnosticWithoutArguments], used for diagnostic
/// messages that don't take any arguments.
///
/// This needs to be a separate class from [DiagnosticWithoutArguments] because
/// [DiagnosticWithoutArguments] is a mixin.
final class DiagnosticWithoutArgumentsImpl
    extends DiagnosticCodeWithExpectedTypes
    with DiagnosticWithoutArguments {
  const DiagnosticWithoutArgumentsImpl({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.type,
    required super.uniqueName,
    super.expectedTypes,
  });
}

/// Expected type of a diagnostic code's parameter.
enum ExpectedType { element, int, name, object, string, token, type, uri }

/// Interface for a diagnostic that does not have any unfilled template
/// parameters, and hence is ready to be associated with a location in the
/// source code.
///
/// This could either be the result of calling `withArguments` on a diagnostic
/// code that requires arguments, or it could be a diagnostic code that doesn't
/// require arguments.
abstract final class LocatableDiagnostic {
  /// The arguments that were applied to the diagnostic, or the empty list if
  /// [code] doesn't accept any arguments.
  List<Object> get arguments;

  /// The [DiagnosticCode] associated with the diagnostic.
  DiagnosticCode get code;

  /// The context messages that were applied to the diagnostic.
  Iterable<DiagnosticMessage> get contextMessages;

  /// Converts this diagnostic to a [LocatedDiagnostic] by applying it to a
  /// syntactic entity in the source code.
  ///
  /// The result may be passed to [DiagnosticReporter.reportError].
  LocatedDiagnostic at(SyntacticEntity node);

  /// Converts this diagnostic to a [LocatedDiagnostic] by applying it to a
  /// location in the source code.
  ///
  /// The result may be passed to [DiagnosticReporter.reportError].
  LocatedDiagnostic atOffset({required int offset, required int length});

  /// Converts this diagnostic to a [LocatedDiagnostic] by applying it to a
  /// location in the source code.
  ///
  /// The result may be passed to [DiagnosticReporter.reportError].
  LocatedDiagnostic atSourceRange(SourceRange sourceRange);

  /// Converts this diagnostic to a [LocatedDiagnostic] by applying it to a
  /// location in the source code.
  ///
  /// The result may be passed to [DiagnosticReporter.reportError].
  LocatedDiagnostic atSourceSpan(SourceSpan span);

  /// Attaches context messages to this diagnostic.
  ///
  /// The return value is a fresh instance of [LocatableDiagnostic]. This allows
  /// for a literate style of error reporting, e.g.:
  /// ```dart
  /// // For an diagnostic code that doesn't take arguments:
  /// diagnosticReporter.reportError(
  ///   diagnosticCode.withContextMessages(messages).at(astNode));
  ///
  /// // For a diagnostic code that does take arguments:
  /// diagnosticReporter.reportError(
  ///   diagnosticCode
  ///     .withArguments(...)
  ///     .withContextMessages(messages)
  ///     .at(astNode));
  /// ```
  LocatableDiagnostic withContextMessages(Iterable<DiagnosticMessage> messages);
}

/// Concrete implementation of [LocatableDiagnostic].
final class LocatableDiagnosticImpl implements LocatableDiagnostic {
  @override
  final DiagnosticCode code;

  @override
  final List<Object> arguments;

  @override
  final Iterable<DiagnosticMessage> contextMessages;

  LocatableDiagnosticImpl(
    this.code,
    this.arguments, {
    this.contextMessages = const [],
  });

  @override
  LocatedDiagnostic at(SyntacticEntity node) =>
      atOffset(offset: node.offset, length: node.length);

  @override
  LocatedDiagnostic atOffset({required int offset, required int length}) =>
      LocatedDiagnostic(this, offset, length);

  @override
  LocatedDiagnostic atSourceRange(SourceRange sourceRange) =>
      atOffset(offset: sourceRange.offset, length: sourceRange.length);

  @override
  LocatedDiagnostic atSourceSpan(SourceSpan span) {
    var trimmedSpan = span.withoutTrailingLineTerminators;
    return atOffset(
      offset: trimmedSpan.start.offset,
      length: trimmedSpan.length,
    );
  }

  @override
  LocatableDiagnostic withContextMessages(
    Iterable<DiagnosticMessage> messages,
  ) => LocatableDiagnosticImpl(
    code,
    arguments,
    contextMessages: [...contextMessages, ...messages],
  );
}

/// A diagnostic that does not have any unfilled template parameters, and has
/// been associated with a location in the source code.
final class LocatedDiagnostic {
  final LocatableDiagnostic locatableDiagnostic;
  final int offset;
  final int length;

  LocatedDiagnostic(this.locatableDiagnostic, this.offset, this.length);
}

extension on SourceSpan {
  SourceSpan get withoutTrailingLineTerminators {
    var end = length;
    while (end > 0) {
      var codeUnit = text.codeUnitAt(end - 1);
      if (codeUnit != 0x0A && codeUnit != 0x0D) {
        break;
      }
      end--;
    }
    return subspan(0, end);
  }
}
