// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'engines.dart';
import 'process.dart';

const _toolProxyAddress = '/abns/dart-eng-tool-proxy/'
    'prod-dart-eng-tool-proxy-tool-proxy.annealed-tool-proxy';

const _mpaCli = '/google/bin/releases/dynamic-access-dev/reqrat/mpa';

/// How long a request may wait for MPA approval before it is abandoned.
const _approvalTimeout = Duration(hours: 48);

/// How long to wait for CIPD packages after a build was triggered.
const _buildGracePeriod = Duration(hours: 12);

/// Matches the access approval link printed by `tool-proxy-cli`, capturing
/// the approval ID.
final _approvalUrlPattern = RegExp(
  r'https://(?:aa|accessapprovals)\.corp\.google\.com/(?:mpa/)?'
  r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
);

/// Matches a reviewer who approved a request in `mpa get --explain` output,
/// e.g. `review_state:APPROVED email:"someone@google.com"`.
final _approverPattern = RegExp(r'review_state:APPROVED email:"([^"]+)"');

/// A running or completed `tool-proxy-cli --block_on_mpa` invocation that
/// waits for MPA approval and triggers the `dart-internal/ci/<browser>`
/// packaging builder.
final class BuildRequest {
  final EngineStatus status;
  final Process _process;
  final _lines = <String>[];
  final _approvalReady = Completer<void>();

  RegExpMatch? _approvalMatch;
  int? _exitCode;
  DateTime? _exitedAt;

  BuildRequest._(this.status, this._process) {
    _process.stdin.close().ignore();
    _listen(_process.stdout);
    _listen(_process.stderr);
    _process.exitCode.then((code) {
      _exitCode = code;
      _exitedAt = DateTime.now();
      if (!_approvalReady.isCompleted) _approvalReady.complete();
    });
  }

  /// The MPA approval link, once `tool-proxy-cli` has printed it.
  String? get approvalUrl => _approvalMatch?[0];

  /// The exit code of `tool-proxy-cli`, or `null` if it is still running.
  int? get exitCode => _exitCode;

  /// Whether the build was triggered over [_buildGracePeriod] ago.
  bool get hasTimedOut =>
      _exitCode == 0 &&
      DateTime.now().difference(_exitedAt!) >= _buildGracePeriod;

  /// Waits until `tool-proxy-cli` prints its approval link, exits, or
  /// [timeout] passes, and returns the approval link if one was printed.
  Future<String?> waitForApprovalUrl({
    Duration timeout = const Duration(seconds: 90),
  }) async {
    await _approvalReady.future.timeout(timeout, onTimeout: () {});
    return approvalUrl;
  }

  /// Returns the emails of the reviewers who approved this request's MPA
  /// prompt (go/mpa), or an empty list if none can be found.
  Future<List<String>> approvers() async {
    final approvalId = _approvalMatch?[1];
    if (approvalId == null) return const [];
    final output = await runChecked(_mpaCli, [
      'get',
      '--explain',
      'approvals/$approvalId',
    ]);
    return {
      for (final match in _approverPattern.allMatches(output)) match[1]!,
    }.toList();
  }

  /// Terminates the `tool-proxy-cli` process if it is still running.
  void kill() => _process.kill();

  /// The last [count] lines of output from `tool-proxy-cli`, for error
  /// reports.
  String outputTail([int count = 15]) =>
      _lines.skip(_lines.length > count ? _lines.length - count : 0).join('\n');

  void _listen(Stream<List<int>> stream) {
    stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _lines.add(line);
      if (_approvalMatch == null) {
        final match = _approvalUrlPattern.firstMatch(line);
        if (match != null) {
          _approvalMatch = match;
          if (!_approvalReady.isCompleted) _approvalReady.complete();
        }
      }
    });
  }
}

/// Requests CIPD packaging builds through the dart-eng tool proxy.
///
/// See go/dart-engprod/browsers.md#triggering-cipd.
final class ToolProxy {
  /// The go/dar-slash-notation justification for the MPA request.
  final String reason;

  ToolProxy({required this.reason});

  /// Starts `tool-proxy-cli` to request MPA approval and trigger the
  /// packaging build for [status].
  Future<BuildRequest> startBuild(EngineStatus status) async {
    final process = await startProcess('timeout', [
      '${_approvalTimeout.inSeconds}s',
      'tool-proxy-cli',
      '--tool_proxy=$_toolProxyAddress',
      '--block_on_mpa',
      '--reason=$reason',
      '-I',
      'browser',
      ':browser',
      status.engine.name,
      ':version',
      status.latest.builderVersion,
    ]);
    return BuildRequest._(status, process);
  }
}
