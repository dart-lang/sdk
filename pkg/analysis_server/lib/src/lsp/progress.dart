// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
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
  FutureOr<void> begin(String title, {String message});

  FutureOr<void> end([String message]);
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
  Future<bool> _tokenBeginRequest;

  _ServerCreatedProgressReporter(
    LspAnalysisServer server,
    Either2<num, String> token,
  ) : super(
          server,
          token ?? Either2<num, String>.t2(_randomTokenIdentifier()),
        );

  @override
  Future<void> begin(String title, {String message}) async {
    assert(_tokenBeginRequest == null,
        'Begin should not be called more than once');

    // Put the create/begin into a future so if end() is called before the
    // begin is sent (which could happen because create is async), end will
    // not be sent/return too early.
    _tokenBeginRequest = _server
        .sendRequest(Method.window_workDoneProgress_create,
            WorkDoneProgressCreateParams(token: _token))
        .then((response) {
      // If the client did not create a token, do not send begin (and signal
      // that we should also not send end).
      if (response.error != null) return false;
      super.begin(title, message: message);
      return true;
    });

    await _tokenBeginRequest;
  }

  @override
  Future<void> end([String message]) async {
    // Only end the token after both create/begin have completed, and return
    // a Future to indicate that has happened to callers know when it's safe
    // to re-use the token identifier.
    if (_tokenBeginRequest != null) {
      final didBegin = await _tokenBeginRequest;
      if (didBegin) {
        super.end(message);
      }
      _tokenBeginRequest = null;
    }
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
