// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:_fe_analyzer_shared/src/base/errors.dart';

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
  /// Clients that wish to present URLs as simple text can do this.  If
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
      StringBuffer result = new StringBuffer(_message);
      if (!_message.endsWith('.')) {
        result.write('.');
      }
      result.write('  See $url');
      return result.toString();
    }
    return _message;
  }
}

/// An indication of the severity of a [Diagnostic].
@AnalyzerPublicApi(
  message: 'exported by package:analyzer/diagnostic/diagnostic.dart',
)
enum Severity { error, warning, info }
