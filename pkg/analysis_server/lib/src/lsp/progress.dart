// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

/// Reports progress of long-running operations to the LSP client.
abstract class ProgressReporter {
  /// A no-op reporter that does nothing.
  static final noop = _NoopProgressReporter();

  /// Creates a reporter for a token that was supplied by the client and does
  /// not need creating prior to use.
  factory ProgressReporter.clientProvided(
          LspAnalysisServer server, Either2<num, String> token) =>
      _TokenProgressReporter(server, token);

  /// Creates a reporter for a new token that must be created prior to being
  /// used.
  ///
  /// If [token] is not supplied, a random identifier will be used.
  factory ProgressReporter.serverCreated(LspAnalysisServer server,
          [Either2<num, String> token]) =>
      _ServerCreatedProgressReporter(server, token);

  ProgressReporter._();

  // TODO(dantup): Add support for cancellable progress notifications.
  void begin(String title, {String message});

  void end([String message]);
}

class _NoopProgressReporter extends ProgressReporter {
  _NoopProgressReporter() : super._();
  @override
  void begin(String title, {String message}) {}
  @override
  void end([String message]) {}
}

class _ServerCreatedProgressReporter extends _TokenProgressReporter {
  static final _random = Random();
  Future<ResponseMessage> _tokenCreateRequest;

  _ServerCreatedProgressReporter(
    LspAnalysisServer server,
    Either2<num, String> token,
  ) : super(
          server,
          token ?? Either2<num, String>.t2(_randomTokenIdentifier()),
        );

  @override
  void begin(String title, {String message}) {
    // Create the token lazily so we don't create it if it's not required.
    _tokenCreateRequest ??= _server.sendRequest(
        Method.window_workDoneProgress_create,
        WorkDoneProgressCreateParams(token: _token));

    // Chain onto the end of tokenCreateRequest so we do not try to use
    // the token without the client accepting it.
    _tokenCreateRequest.then((response) {
      if (response.error != null) return;
      super.begin(title, message: message);
    });
  }

  @override
  void end([String message]) {
    // Chain onto the end of tokenCreateRequest so we do not try to use
    // the token without the client accepting it.
    _tokenCreateRequest.then((response) {
      if (response.error != null) return;
      super.end(message);
    });
  }

  static String _randomTokenIdentifier() {
    final millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(0x3fffffff);
    return '$millisecondsSinceEpoch$random';
  }
}

class _TokenProgressReporter extends ProgressReporter {
  final LspAnalysisServer _server;
  final Either2<num, String> _token;
  bool _needsEnd = false;

  _TokenProgressReporter(this._server, this._token) : super._();

  @override
  void begin(String title, {String message}) {
    _needsEnd = true;
    _sendNotification(
        WorkDoneProgressBegin(title: title ?? 'Working…', message: message));
  }

  @override
  void end([String message]) {
    if (!_needsEnd) return;
    _needsEnd = false;
    _sendNotification(WorkDoneProgressEnd(message: message));
  }

  void _sendNotification(ToJsonable value) async {
    _server.sendNotification(NotificationMessage(
        method: Method.progress,
        params: ProgressParams(
          token: _token,
          value: value,
        ),
        jsonrpc: jsonRpcVersion));
  }
}
