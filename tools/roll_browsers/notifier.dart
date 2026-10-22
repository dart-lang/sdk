// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'process.dart';

/// The Dart Web team chat space.
const defaultChatSpace = 'AAAAC58FylU';

const _gchat = '/google/bin/releases/gemini-agents-gchat/gchat';

/// Prefixed to the top-level message of each run's thread, which is sent as
/// the user running the tool, so readers know it was automated.
const _chatPrefix = '🤖 roll_browsers: ';

/// Matches the thread name in `gchat mutate send-message` JSON output.
final _threadNamePattern =
    RegExp(r'"name":\s*"(spaces/[^/"]+/threads/[^/"]+)"');

/// Posts the messages of a single run to one Google Chat thread.
///
/// The first message posted (e.g. the batched MPA approval requests, or the
/// roll CL if no builds were needed) starts the thread, and everything else,
/// including failures, is posted as a reply to it. Failures that happen
/// before anything else has been posted are held back until [post] or
/// [flush], so that the thread starts with the run's main message.
///
/// Messages are sent with the user's own credentials through the internal
/// `gchat` CLI, so they need a valid `gcert`.
final class Notifier {
  /// The chat space ID for the run's thread.
  final String chatSpace;

  /// Print messages instead of sending them.
  final bool dryRun;

  /// The thread name (`spaces/<space>/threads/<thread>`) once started.
  String? _thread;

  final _pendingFailures = <String>[];

  Notifier({required this.chatSpace, required this.dryRun});

  /// Posts [message] to the run's thread, starting it if needed, followed by
  /// any failures that were held back.
  Future<void> post(String message) async {
    await _send(message);
    await flush();
  }

  /// Reports a failure in the run's thread.
  ///
  /// If the thread hasn't started yet, the failure is held back until the
  /// next [post] or [flush].
  Future<void> reportFailure(String summary, {String? details}) async {
    stderr.writeln('[failure] $summary${details == null ? '' : '\n$details'}');
    final text = [
      '❌ $summary',
      if (details != null) '```\n${details.trim()}\n```',
    ].join('\n');
    if (_thread == null && !dryRun) {
      _pendingFailures.add(text);
    } else {
      await _send(text);
    }
  }

  /// Posts any held-back failures, starting the thread if needed.
  Future<void> flush() async {
    final failures = [..._pendingFailures];
    _pendingFailures.clear();
    for (final failure in failures) {
      await _send(failure);
    }
  }

  /// Sends [message] as a reply in the run's thread, or as a new top-level
  /// message if the thread hasn't started yet. Delivery failures are printed
  /// but never fail the roll.
  Future<void> _send(String message) async {
    final thread = _thread;
    final text = thread == null ? '$_chatPrefix$message' : message;
    print('[chat $chatSpace${thread == null ? '' : ' $thread'}] $text');
    if (dryRun) return;
    try {
      final output = await runChecked(_gchat, [
        '--enable_local_proxy=false',
        'mutate',
        'send-message',
        '--space',
        chatSpace,
        if (thread != null) ...['--thread', thread],
        '--text',
        text,
      ]);
      _thread ??= _threadNamePattern.firstMatch(output)?[1];
    } on Exception catch (e) {
      stderr.writeln('Failed to send chat message: $e');
    }
  }
}
